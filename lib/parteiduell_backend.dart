import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:parteiduell_backend/models/quiz_question.dart';
import 'package:parteiduell_backend/models/quizthese.dart';

List<QuizThese> quizFragen = [];

List scoreboard = [];

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

run() async {
  print('Loading DB...');

  // Einlesen der Daten
  for (File file in Directory('data/release').listSync())
    quizFragen.addAll(json
        .decode(file.readAsStringSync())
        .map<QuizThese>((m) => QuizThese.fromJson(m)));

  print('Loaded. These Count: ${quizFragen.length}');

  scoreboard = json.decode(File('data/db/scoreboard.json').readAsStringSync());

  // Starten des Servers
  var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);
  print("Serving at ${server.address}:${server.port}");

  await for (var request in server) {
    try {
      await execute(request);
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.close();
    }
  }
}

saveScoreboard() async {
  File('data/db/scoreboard.json').writeAsString(json.encode(scoreboard));
}

// Bearbeitung der Anfragen
execute(HttpRequest request) async {
  HttpResponse response = request.response;

  response.headers.add('Access-Control-Allow-Origin', '*');

  if (request.uri.path == '/list') {
    if (request.method == 'GET') {
      int count = int.tryParse(request.uri.queryParameters['count'] ?? '') ?? 1;
      quizFragen.shuffle();

      List<QuizQuestion> questions = [];

      for (QuizThese these in quizFragen.take(count)) {
        var question = QuizQuestion(
            context: these.context, source: these.source, these: these.these);

        List<String> parties = these.statements.keys.toList();
        //print(parties);
        parties.removeWhere((p) => !commonParties.contains(p));

        parties.shuffle();
        parties = parties.take(4).toList();

        String party = parties.first;

        question.answer = party;

        question.possibleAnswers = {};
        parties.shuffle();
        for (String key in parties) {
          List<String> toReplace = [key];
          String statement = these.statements[key];

          switch (key) {
            case 'CDU/CSU':
              toReplace.addAll(['CDU', 'CSU', 'CDU und CSU']);
              break;
            case 'FDP':
              statement = statement.replaceAll('Freie Demokraten ', '');
              break;
            case 'GRÜNE':
              toReplace.addAll(['BÜNDNIS 90/DIE GRÜNEN']);
              break;
          }

          for (String s in toReplace) {
            statement = statement.replaceAll(
                RegExp('' + s + '', caseSensitive: false), '█████');
          }
          if (statement.trim().length == 0)
            statement =
                'Diese Partei hat keine Erklärung zu dieser These abgegeben.';

          question.possibleAnswers[key] = statement;
        }
        question.statement = question.possibleAnswers[party];
        question.possibleParties = parties;

        questions.add(question);
      }

      request.response.write(json.encode(questions));
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
  } else {
    response.statusCode = HttpStatus.notFound;
  }
  await response.close();
}
