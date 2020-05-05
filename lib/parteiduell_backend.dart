import 'dart:convert';
import 'dart:io';
import "package:path/path.dart" as path;

import 'package:parteiduell_backend/models/quiz_question.dart';
import 'package:parteiduell_backend/models/quizthese.dart';

const apiVersion = 8;

final String __filename = Platform.script.path.replaceFirst('/', '');
final String __dirname = path.dirname(__filename);

List<QuizThese> quizFragen = [];

List scoreboard = [];

// Bekannte Parteien, die standardmäßig verwendet werden
List<String> commonParties = [
  "SPD",
  "CDU/CSU",
  "GRÜNE",
  "FDP",
  "PIRATEN",
  "DIE LINKE",
  "NPD",
  "Die PARTEI",
  "AfD"
];

Set<String> allParties = {};

// Quellen, die standardmäßig verwendet werden
List<String> commonSources = [
  "Bundestagswahl 2005",
  "Bundestagswahl 2009",
  "Bundestagswahl 2013",
  "Bundestagswahl 2017",
];

Set<String> allSources = {};

Map<String, Set<String>> sourceParties = {};

bool debugOutputEnabled = false;

// Ausgabe von Debug-Infos
debugPrint(s) {
  if (debugOutputEnabled) print(s.toString());
}

run({bool debug}) async {
  debugOutputEnabled = debug;

  print('Loading DB...');

  // Einlesen der Daten
  for (File file in Directory('/' + __dirname + '/data/wahlomat').listSync())
    quizFragen.addAll(json
        .decode(file.readAsStringSync())
        .map<QuizThese>((m) => QuizThese.fromJson(m)));

  // Auslesen aller möglichen Datenquellen
  quizFragen.forEach((t) => allSources.add(t.context));
  print('All Sources: $allSources');

  for (var source in allSources) {
    sourceParties[source] = {};
  }

  // Auslesen aller möglichen Parteien
  quizFragen.forEach((t) {
    t.statements.keys.toList().forEach((k) => allParties.add(k));
    t.statements.keys.toList().forEach((k) => sourceParties[t.context].add(k));
  });
  print('All Parties: $allParties');

  print('Loaded. These Count: ${quizFragen.length}');

  scoreboard = json.decode(
      File('/' + __dirname + '/data/db/scoreboard.json').readAsStringSync());

  // Server Port
  var portEnv = Platform.environment['PORT'];
  var port = portEnv == null ? 3000 : int.parse(portEnv);

  // Starten des Servers
  var server = await HttpServer.bind('0.0.0.0', port);

  print("Serving at ${server.address}:${server.port}");

  // Beantworten jeder Anfrage
  await for (var request in server) {
    print(
        '[${DateTime.now().toIso8601String()}] ${request.method} from ${request.connectionInfo.remoteAddress} at ${request.uri}');
    try {
      await execute(request);
    } catch (e, st) {
      print('$e');
      print('$st');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.close();
    }
  }
}

saveScoreboard() async {
  File('/' + __dirname + '/data/db/scoreboard.json')
      .writeAsString(json.encode(scoreboard));
}

// Bearbeitung der Anfragen
execute(HttpRequest request) async {
  HttpResponse response = request.response;
  response.headers.contentType =
      ContentType("application", "json", charset: "utf-8");

  // Setzen von CORS-Headern
  response.headers.add('Access-Control-Allow-Origin', '*');

  if (request.uri.path == '/') {
    if (request.method == 'GET') {
      // Redirecten zum Repository, wenn keine Methode angegeben ist.
      request.response.redirect(Uri.https("github.com", "Parteiduell/backend"));
    } else {
      response.statusCode = HttpStatus.methodNotAllowed;
    }
  } else if (request.uri.path == '/list') {
    if (request.method == 'GET') {
      //
      // Abrufen von Quizfragen
      //

      // Übergebene Parameter
      int count = int.tryParse(request.uri.queryParameters['count'] ?? '') ?? 1;
      bool filterWithTag =
          (request.uri.queryParameters['filterWithTag'] ?? 'false') == 'true';
      String reqParties = request.uri.queryParameters['parties'] ?? '';
      String reqSources = request.uri.queryParameters['sources'] ?? '';

      String id = request.uri.queryParameters['id'];

      List<String> requestedSources = [];
      if (reqSources.isNotEmpty) {
        requestedSources.addAll(reqSources.split(','));
      } else {
        requestedSources.addAll(commonSources);
      }

      // Nicht gewünschte Quellen herausfiltern
      List<QuizThese> quizFragenAuswahl = quizFragen
          .where((t) => requestedSources.contains(t.context))
          .toList();
      if (id != null) {
        quizFragenAuswahl.retainWhere((t) => t.id == id);
      }
      quizFragenAuswahl.shuffle();

      List<QuizQuestion> questions = [];

      // Solange Quizfragen aussuchen, bis die gewünschte Anzahl erreicht oder keine Thesen mehr übrig sind
      for (int i = 0; i < count; i++) {
        if (i >= quizFragenAuswahl.length) break;
        QuizThese these = quizFragenAuswahl[i];

        var question = QuizQuestion(
            context: these.context, source: these.source, these: these.these);

        List<String> parties = these.statements.keys.toList();

        // Unbekannte oder nicht angefragte Parteien herausfiltern
        List<String> requestedParties = [];
        if (reqParties.isNotEmpty) {
          requestedParties.addAll(reqParties.split(','));
        } else {
          requestedParties.addAll(commonParties);
        }
        parties.removeWhere((p) => !requestedParties.contains(p));

        // Entfernen von Parteien, die keine Antwort abgegeben haben
        parties.removeWhere((p) => these.statements[p].isEmpty);
        debugPrint('Parteien: $parties');
        debugPrint('${parties.length}/${requestedParties.length}');

        // Wenn weniger als zwei Parteien übrig bleiben, wird eine andere These verwendet
        if (parties.length < 2) {
          count++;
          continue;
        }

        // Parteien aussuchen und durchmischen
        parties.shuffle();
        parties = parties.take(4).toList();

        question.possibleAnswers = {};

        // Generieren der Antwortmöglichkeiten
        for (String key in parties) {
          String statement = these.statements[key];
          if (statement.trim().length == 0)
            statement =
                'Diese Partei hat keine Erklärung zu dieser These abgegeben.';

          question.possibleAnswers[key] = statement;
        }
        question.possibleParties = parties;
        question.theseId = these.id;

        questions.add(question);
      }

      request.response.write(json.encode(questions));
    } else {
      response.statusCode = HttpStatus.methodNotAllowed;
    }
  } else if (request.uri.path == '/allParties') {
    // Abrufen aller Parteien
    if (request.method == 'GET') {
      String source = request.uri.queryParameters['sources'] ?? '';
      Set<String> sourcePartiesSet = {};
      if (source.isEmpty) {
        response.write(json.encode(allParties.toList()));
      } else {
        for (String source in source.split(',')) {
          sourcePartiesSet.addAll(sourceParties[source]);
        }
        response.write(json.encode(sourcePartiesSet.toList()));
      }
    } else {
      response.statusCode = HttpStatus.methodNotAllowed;
    }
  } else if (request.uri.path == '/allSources') {
    // Abrufen aller Quellen
    if (request.method == 'GET') {
      request.response.write(json.encode(allSources.toList()));
    } else {
      response.statusCode = HttpStatus.methodNotAllowed;
    }
  } else if (request.uri.path == '/submitScore') {
    if (request.method == 'POST') {
      String content = await utf8.decoder.bind(request).join();
      var data = json.decode(content);

      // Limits
      // Name: 20 Chars
      // Score: 100
      if (data['score'] > 100 || data['score'] < 0) {
        response.statusCode = HttpStatus.badRequest;
      } else if (data['name'].length > 20 || data['name'].length == 0) {
        response.statusCode = HttpStatus.badRequest;
      } else {
        scoreboard.add({'name': data['name'], 'score': data['score']});
        scoreboard.sort((a, b) => -a['score'].compareTo(b['score']));
        if (scoreboard.length > 10) {
          scoreboard.removeRange(10, scoreboard.length);
        }
        saveScoreboard();
      }
    } else {
      response.statusCode = HttpStatus.methodNotAllowed;
    }
  } else if (request.uri.path == '/scoreboard') {
    if (request.method == 'GET') {
      request.response.write(json.encode(scoreboard));
    } else {
      response.statusCode = HttpStatus.methodNotAllowed;
    }
  } else if (request.uri.path == '/ping') {
    if (request.method == 'GET') {
      request.response.write("Pong!");
    } else {
      response.statusCode = HttpStatus.methodNotAllowed;
    }
  } else if (request.uri.path == '/version') {
    if (request.method == 'GET') {
      request.response.write(json.encode({'version': apiVersion}));
    } else {
      response.statusCode = HttpStatus.methodNotAllowed;
    }
  } else if (request.uri.path == '/listMock') {
    if (request.method == 'GET') {
      request.response.write('''
[
  {
    "these": "Der Ausbau erneuerbarer Energien soll vom Bund dauerhaft finanziell gefördert werden.",
    "possibleAnswers": {
      "AfD": "Auch die sogenannten erneuerbaren Energien müssen sich am Markt bewähren. Sie bringen zudem nicht nur Vorteile, sondern auch viele Nachteile mit sich. Die Dauersubventionierung belastet die deutsche Volkswirtschaft in erheblichen Maße. Soweit die Subventionierung über Sonderabgaben erfolgt, wie die die Stromabgabe, entstehen der Wirtschaft Kostennachteile, die zur Verlagerung ganzer Industriezweige ins Ausland führen. Zudem werden die Privathaushalte schon derzeit mit ca. 25 Mrd. durch solche Maßnahmen belastet. Diese Mittel fehlen den Bürgern für den eigenen Lebensbedarf und insbesondere für eine notwendige Altersvorsorge.",
      "NPD": "Der Ausbau erneuerbarer Energien ist nicht nur aus Gründen des Umweltschutzes, sondern auch zur Erlangung größerer Unabhängigkeit von Energie-Importen aus dem Ausland grundsätzlich zu begrüßen. Bei der Förderung sollte allerdings ein Schwerpunkt auf die Erforschung geeigneter Speichertechnologien gelegt werden, um eine bessere dezentrale Verfügbarkeit zu erreichen, Energieverluste zu vermeiden und auf gigantische und die Landschaft verschandelnde Windparks verzichten zu können.",
      "FDP": "Erneuerbare Energien sind für uns ein wichtiges Element im Energiemix der Zukunft. Auch für die erneuerbaren Energieträger müssen in Zukunft aber die Regeln des Marktes mit allen Chancen und Risiken gelten. Denn nachhaltige und subventionsfreie Geschäftsmodelle lassen sich nur im technologieneutralen Wettbewerb unter marktwirtschaftlichen Bedingungen durchsetzen.",
      "DIE LINKE": "Wir wollen den Klimawandel stoppen. Dafür setzen wir auf erneuerbare Energien. █████ will eine echte Energiewende finanzieren, in der die fossilen, umweltschädlichen Energien durch regenerative ersetzt werden. Sie soll bürgernah - v.a. durch Genossenschaften und Stadtwerke - organisiert sein und als Teil der öffentlichen Daseinsvorsorge. Die Verbraucher entlasten wir durch soziale Preisgestaltung und einen Energiewendefonds."
    },
    "answer": "NPD",
    "source": "wahlometer.watch",
    "context": "Bundestagswahl 2017",
    "statement": "Der Ausbau erneuerbarer Energien ist nicht nur aus Gründen des Umweltschutzes, sondern auch zur Erlangung größerer Unabhängigkeit von Energie-Importen aus dem Ausland grundsätzlich zu begrüßen. Bei der Förderung sollte allerdings ein Schwerpunkt auf die Erforschung geeigneter Speichertechnologien gelegt werden, um eine bessere dezentrale Verfügbarkeit zu erreichen, Energieverluste zu vermeiden und auf gigantische und die Landschaft verschandelnde Windparks verzichten zu können.",
    "possibleParties": [
      "AfD",
      "NPD",
      "FDP",
      "DIE LINKE"
    ]
  },
    {
    "these": "Deutschland soll zu einer nationalen Währung zurückkehren.",
    "possibleAnswers": {
      "Die PARTEI": "Deutschland soll natürlich zu zwei nationalen Währungen zurückkehren, zur D- und zur Ostmarkt. Wir sind zwei Volk!",
      "AfD": "Da der Euro gescheitert ist, muss Deutschland entweder mit anderen, ökonomisch zu uns passenden Staaten einen Währungsverbund schaffen oder zur D-Mark zurückkehren. Wir wollen deshalb für die Wiedereinführung einer neuen nationalen Währung rechtzeitige Vorkehrungen treffen. Das im Ausland gelagerte Gold der Bundesbank muss vollständig und umgehend nach Deutschland überführt werden. Bei der Wiedereinführung der Deutschen Mark könnte Deutschland das Gold als temporäre Deckungsoption benötigen.",
      "SPD": "Deutschland profitiert vom Euro. Die europäische Währung ist ein integraler Bestandteil des europäischen Projekts, nicht nur in ökonomischer, sondern auch in politischer Hinsicht. Ein Austritt aus dem Euro hätte schwere ökonomische und soziale Verwerfungen zur Folge. Wir sehen erste negative Folgen bereits in Großbritannien durch den Brexit.",
      "GRÜNE": "Der Euro ist eine große Errungenschaft für Europa und für Deutschland: er erleichtert den Handel und Zahlungsverkehr. Wichtig ist aber, dass innerhalb des Währungsraums ein solidarischer Ausgleich geschaffen wird und Ungleichgewichte verhindert werden. Die Währungsunion muss fortentwickelt und durch eine gemeinsame Wirtschafts- und Fiskalpolitik ergänzt werden. Ein Austritt eines Mitgliedslands aus dem Euro hätte unabsehbare negative Folgen für Wohlstand und Arbeitsplätze in Deutschland."
    },
    "answer": "AfD",
    "source": "wahlometer.watch",
    "context": "Bundestagswahl 2017",
    "statement": "Da der Euro gescheitert ist, muss Deutschland entweder mit anderen, ökonomisch zu uns passenden Staaten einen Währungsverbund schaffen oder zur D-Mark zurückkehren. Wir wollen deshalb für die Wiedereinführung einer neuen nationalen Währung rechtzeitige Vorkehrungen treffen. Das im Ausland gelagerte Gold der Bundesbank muss vollständig und umgehend nach Deutschland überführt werden. Bei der Wiedereinführung der Deutschen Mark könnte Deutschland das Gold als temporäre Deckungsoption benötigen.",
    "possibleParties": [
      "Die PARTEI",
      "AfD",
      "SPD",
      "GRÜNE"
    ]
  }
]
''');
    } else {
      response.statusCode = HttpStatus.methodNotAllowed;
    }
  } else {
    response.statusCode = HttpStatus.notFound;
  }
  // Schließen der Verbindung
  await response.close();
}
