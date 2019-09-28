import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:parteiduell_backend/models/quiz_question.dart';
import 'package:parteiduell_backend/models/quizthese.dart';

List<QuizThese> quizFragen;

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
  quizFragen = json
      .decode(File('data/quizQuestions.json').readAsStringSync())
      .map<QuizThese>((m) => QuizThese.fromJson(m))
      .toList();

  // Starten des Servers
  var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 3000);
  print("Serving at ${server.address}:${server.port}");

  await for (var request in server) {
    execute(request);
  }
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
        for (String key in parties) {
          List<String> toReplace = [key];
          String statement = these.statements[key];

          switch (key) {
            case 'CDU/CSU':
              toReplace.addAll(['CDU', 'CSU']);
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

          question.possibleAnswers[key] = statement;
        }
        question.statement = question.possibleAnswers[party];

        questions.add(question);
      }

      request.response.write(json.encode(questions));
    } else {
      response.statusCode = HttpStatus.methodNotAllowed;
    }
  } else {
    response.statusCode = HttpStatus.notFound;
  }
  await response.close();
}
