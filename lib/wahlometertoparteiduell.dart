import 'dart:convert';
import 'dart:io';

import 'package:parteiduell_backend/models/quizthese.dart';

// Alternative Keys für die einzelnen Parteien
Map partyMap = {
  'BÜNDNIS 90/DIE GRÜNEN': 'GRÜNE',
  'Bündnis 90/ Die Grünen': 'GRÜNE',
  'GRÜNE/B 90': 'GRÜNE',
  'Bündnis 90/Die Grünen': 'GRÜNE',
  'Die Grünen': 'GRÜNE',
  'DIE LINKE.PDS': 'DIE LINKE',
  'Die LINKE': 'DIE LINKE',
  'DIE LINKE.': 'DIE LINKE',
  'Die Linke': 'DIE LINKE',
  'CDU / CSU': 'CDU/CSU',
  'CDU': 'CDU/CSU',
  'CSU': 'CDU/CSU',
  'DIE PARTEI': 'Die PARTEI',
  'Die PARTEI ': 'Die PARTEI',
  'PIRATEN ': 'PIRATEN',
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
