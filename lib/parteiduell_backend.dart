import 'dart:convert';
import 'dart:io';

import 'models/quizfrage.dart';


List<QuizFrage> quizFragen;

run() async {
  print('Loading DB...');
  // Einlesen der Daten
  quizFragen = json
      .decode(File('data/quizFragen.json').readAsStringSync())
      .map<QuizFrage>((m) => QuizFrage.fromJson(m))
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

  if (request.uri.path == '/list') {
    if (request.method == 'GET') {
      quizFragen.shuffle();

      request.response.write(json.encode(quizFragen.take(10).toList()));
    } else {
      response.statusCode = HttpStatus.methodNotAllowed;
    }
  } else {
    response.statusCode = HttpStatus.notFound;
  }
  await response.close();
}
