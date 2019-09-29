# parteiduell_backend

Das Backend für [parteiduell_frontend](https://github.com/Jugendhackt/parteiduell-frontend/), verantwortlich für Erstellung und Ausliefern der Quizfragen.

## Server lokal starten

1. [Dart SDK installieren](https://dart.dev/get-dart)

2. Backend lokal clonen
`git clone https://github.com/Jugendhackt/parteiduell-backend`

3. Projekt initialisieren
`pub get` - 
alternativ (Linux): `/usr/lib/dart/bin/pub get`

4. Server starten
`dart bin/main.dart`

Der Server läuft jetzt standardmäßig unter `localhost:3000`.

## Wahlometer-Daten neu einlesen und parsen

`dart bin/processing.dart`
