import 'package:alfred/alfred.dart';
import 'package:parteiduell_backend/models/quiz_question.dart';
import 'package:parteiduell_backend/models/quizthese.dart';
import 'package:parteiduell_backend/parteiduell_backend.dart';

dynamic handleListRequest(HttpRequest req, HttpResponse res) {
  // Übergebene Parameter
  int count = int.tryParse(req.uri.queryParameters['count'] ?? '') ?? 1;
  bool filterWithTag =
      (req.uri.queryParameters['filterWithTag'] ?? 'false') == 'true';
  String reqParties = req.uri.queryParameters['parties'] ?? '';
  String reqSources = req.uri.queryParameters['sources'] ?? '';

  String id = req.uri.queryParameters['id'];

  List<String> requestedSources = [];
  if (reqSources.isNotEmpty) {
    requestedSources.addAll(reqSources.split(','));
  } else {
    requestedSources.addAll(commonSources);
  }

  // Nicht gewünschte Quellen herausfiltern
  List<QuizThese> quizFragenAuswahl =
      quizFragen.where((t) => requestedSources.contains(t.context)).toList();
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

  return questions;
}
