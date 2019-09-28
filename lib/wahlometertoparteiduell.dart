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
      json.decode(File('data/source/wahlometer-watch.json').readAsStringSync());

  for (Map occasion in content) {
    var result = [];

    for (var these in occasion['theses']) {
      Map statements = {};
      for (Map position in these['positions']) {
        statements[position['party']] = position['text'];
      }

      result.add(QuizThese(
          these: these['text'],
          statements: statements,
          source: "wahlometer.watch",
          context: occasion['occasion']['title']));
    }

    File("data/wahlomat/quizQuestions - ${occasion['occasion']['title']}.json")
        .writeAsStringSync(json.encode(result));
  }
}
