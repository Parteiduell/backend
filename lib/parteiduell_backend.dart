import 'dart:convert';
import 'dart:io';
import 'package:alfred/alfred.dart';
import 'package:http/http.dart' as http;

import 'package:parteiduell_backend/models/quizthese.dart';
import 'package:parteiduell_backend/routes/all_parties.dart';
import 'package:parteiduell_backend/routes/all_sources.dart';
import 'package:parteiduell_backend/routes/list.dart';
import 'package:parteiduell_backend/version.dart';

const apiVersion = 8;

List<QuizThese> quizFragen = [];

List scoreboard = [];

// Bekannte Parteien, die standardmäßig verwendet werden
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

Set<String> allParties = {};

// Quellen, die standardmäßig verwendet werden
List<String> commonSources = [
  "Bundestagswahl 2005",
  "Bundestagswahl 2009",
  "Bundestagswahl 2013",
  "Bundestagswahl 2017",
];

Set<String> allSources = {};

Map<String, Set<String>> sourceParties = {};

bool debugOutputEnabled = false;

// Ausgabe von Debug-Infos
debugPrint(s) {
  if (debugOutputEnabled) print(s.toString());
}

run({bool debug}) async {
  debugOutputEnabled = debug;

  print('Downloading file index...');

  final listRes = await http.get(
    Uri.parse(
      'https://api.github.com/repos/Parteiduell/data/contents/quizQuestions',
    ),
  );

  final list = json.decode(listRes.body);

  // Einlesen der Daten
  for (final item in list) {
    print('Downloading file ${item['name']}...');
    final res = await http.get(Uri.parse(item['download_url']));

    quizFragen.addAll(
        json.decode(res.body).map<QuizThese>((m) => QuizThese.fromJson(m)));
  }

  // Auslesen aller möglichen Datenquellen
  quizFragen.forEach((t) => allSources.add(t.context));
  print('All Sources: $allSources');

  for (var source in allSources) {
    sourceParties[source] = {};
  }

  // Auslesen aller möglichen Parteien
  quizFragen.forEach((t) {
    t.statements.keys.toList().forEach((k) => allParties.add(k));
    t.statements.keys.toList().forEach((k) => sourceParties[t.context].add(k));
  });
  print('All Parties: $allParties');

  print('Loaded. These Count: ${quizFragen.length}');

  /* scoreboard = json.decode(
      File('/' + __dirname + '/data/db/scoreboard.json').readAsStringSync()); */

  // Einrichtung des Servers
  final app = Alfred(logLevel: debug ? LogType.debug : LogType.info);

  // CORS erlauben
  app.all('*', cors(origin: '*'));

  // Routen einrichten

  app.get('/', (req, res) {
    // Redirecten zum Repository, wenn keine Methode angegeben ist.
    res.redirect(Uri.https("github.com", "Parteiduell/backend"));
  });

  // Abrufen von Quizfragen
  app.get('/list', handleListRequest);

  // Abrufen aller Parteien
  app.get('/allParties', handleAllPartiesRequest);

  // Abrufen aller Quellen
  app.get('/allSources', handleAllSourcesRequest);

  app.get('/ping', (req, res) => 'Pong!');

  app.get(
    '/version',
    (req, res) => {
      'version': apiVersion,
      'apiVersion': apiVersion,
      'versionName': versionName,
    },
  );

  // Server Port
  var portEnv = Platform.environment['PORT'];
  var port = portEnv == null ? 3000 : int.parse(portEnv);

  // Starten des Servers
  await app.listen(port);
}
