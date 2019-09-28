import 'dart:convert';
import 'dart:io';

import 'package:parteiduell_backend/models/quizthese.dart';

// List<String> interesting_parties = [
//   "SPD",
//   "CDU",
//   "GRÜNE",
//   "FDP",
//   "PIRATEN",
//   "DIE LINKE",
//   "NPD",
//   "Die PARTEI",
//   "AFD"
// ];

run() {
  var content =
      json.decode(File('data/wahlometer-watch.json').readAsStringSync());

  var result = [];

  for (var these in content.last['theses']) {
    Map statements = {};
    for (Map position in these['positions']) {
      statements[position['party']] = position['text'];
    }

    result.add(QuizThese(
        these: these['text'],
        statements: statements,
        source: "wahlometer.watch",
        context: "Bundestagswahl 2017"));
  }

  File("data/quizQuestions.json").writeAsStringSync(json.encode(result));
}
