import 'dart:convert';
import 'dart:io';

import 'package:parteiduell_backend/models/quizthese.dart';

// Alternative Keys für die einzelnen Parteien
Map partyMap = {
  'BÜNDNIS 90/DIE GRÜNEN': 'GRÜNE',
  'Bündnis 90/ Die Grünen': 'GRÜNE',
  'DIE LINKE.PDS': 'DIE LINKE',
  'CDU / CSU': 'CDU/CSU'
};

run() {
  var content =
      json.decode(File('data/source/wahlometer-watch.json').readAsStringSync());

  for (Map occasion in content) {
    var result = [];

    for (var these in occasion['theses']) {
      Map statements = {};
      for (Map position in these['positions']) {
        String party = position['party'];

        if (partyMap.containsKey(party)) party = partyMap[party];
        statements[party] = position['text'];
      }

      result.add(QuizThese(
          these: these['text'],
          statements: statements,
          source: 'wahlometer.watch',
          context: occasion['occasion']['title']));
    }

    File('data/wahlomat/quizQuestions - ${occasion['occasion']['title']}.json')
        .writeAsStringSync(json.encode(result));
  }
}
