
class QuizFrage {
  String frage;
  List<String> antworten;
  String richtigeAntwort;
  String thema;
  String kontext;
  String quelle;

  QuizFrage(this.frage, this.antworten, this.richtigeAntwort,
      {this.thema, this.kontext});

  QuizFrage.fromJson(Map<String, dynamic> json)
      : frage = json['frage'] ?? '',
        antworten = json['antworten'].cast<String>() ?? [],
        richtigeAntwort = json['richtigeAntwort'] ?? '',
        thema = json['thema'] ?? '',
        kontext = json['kontext'] ?? '',
        quelle = json['quelle'] ?? '';

  Map<String, dynamic> toJson() => {
        'frage': frage,
        'antworten': antworten,
        'richtigeAntwort': richtigeAntwort,
        'thema': thema,
        'kontext': kontext,
        'quelle': quelle,
      };
}