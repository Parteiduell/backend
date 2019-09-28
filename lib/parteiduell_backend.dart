import 'dart:convert';
import 'dart:io';

class QuizFrage {
  String frage;
  List<String> antworten;
  String richtigeAntwort;
  String thema;
  String kontext;

  QuizFrage(this.frage, this.antworten, this.richtigeAntwort,
      {this.thema, this.kontext});

  QuizFrage.fromJson(Map<String, dynamic> json)
      : frage = json['frage'] ?? '',
        antworten = json['antworten'] ?? [],
        richtigeAntwort = json['richtigeAntwort'] ?? '',
        thema = json['thema'] ?? '',
        kontext = json['kontext'] ?? '';

  Map<String, dynamic> toJson() => {
        'frage': frage,
        'antworten': antworten,
        'richtigeAntwort': richtigeAntwort,
        'thema': thema,
        'kontext': kontext,
      };
}

run() async {
  var server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print("Serving at ${server.address}:${server.port}");

  await for (var request in server) {
    execute(request);
  }
}

execute(HttpRequest request) async {
  //ContentType contentType = request.headers.contentType;
  HttpResponse response = request.response;

  if (request.uri.path == '/list') {
    if (request.method == 'GET') {
      List<QuizFrage> quizFragen = [
        QuizFrage('Es gibt keinen menschengemachten Klimawandel',
            ['CDU', 'AFD', 'GRUENE'], 'AFD',
            kontext: 'Hier steht etwas Kontext oder Quellen zu der Aussage',
            thema: 'Umwelt & Klima')
      ];

      response.write(json.encode(quizFragen));
    } else {
      response.statusCode = HttpStatus.methodNotAllowed;
    }
  } else {
    response.statusCode = HttpStatus.notFound;
  }
  await response.close();
}
