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
  "BVB / FREIE WÄHLER": "FREIE WÄHLER",
  "FBI Freie Wähler": "FREIE WÄHLER",
  "FBI": "FREIE WÄHLER",
  "FBI/FWG": "FREIE WÄHLER",
  "FBI/Freie Wähler": "FREIE WÄHLER",
  "FREIE WÄHLER BREMEN": "FREIE WÄHLER",
  "FREIE WÄHLER": "FREIE WÄHLER",
  "FW FREIE WÄHLER": "FREIE WÄHLER",
  "Freie Wähler Bayern": "FREIE WÄHLER",
  "PDS": "DIE LINKE",
  "ödp": "ÖDP"
};

run() {
  // Einlesen der Daten
  var content =
      json.decode(File('data/source/wahlometer-watch.json').readAsStringSync());

  // Alle Wahlen bzw. Quellen durchgehen
  for (Map occasion in content) {
    var result = [];

    // Alle Thesen dieser Wahl abarbeiten
    for (var these in occasion['theses']) {
      Map statements = {};
      // Die Aussagen jeder Partei sammeln und normalisieren (Alternative Schreibweisen entfernen)
      for (Map position in these['positions']) {
        String party = position['party'];

        if (partyMap.containsKey(party)) party = partyMap[party];
        statements[party] = position['text'];
      }

      // Neue These der Auswahl hinzufügen
      result.add(QuizThese(
          these: these['text'],
          id: these['id'],
          statements: statements,
          source: 'wahlometer.watch',
          context: occasion['occasion']['title']));
    }

    // Alle Thesen mit antowrtmöglichkeiten in Datei speichern
    File('data/wahlomat/quizQuestions - ${occasion['occasion']['title']}.json')
        .writeAsStringSync(json.encode(result));
  }
}
