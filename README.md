[![Jugend hackt](https://jhbadge.com/?year=2019&evt=ffm)](https://jugendhackt.org)

# parteiduell_backend

Das Backend für [parteiduell_frontend](https://github.com/Jugendhackt/parteiduell-frontend/), verantwortlich für Erstellung und Ausliefern der Quizfragen.

## Server lokal starten

1. [Dart SDK installieren](https://dart.dev/get-dart)

2. Backend lokal clonen
`git clone https://github.com/Jugendhackt/parteiduell-backend`

3. Ordner wechseln
`cd parteiduell-backend`

4. Projekt initialisieren
`pub get` - 
alternativ (Linux): `/usr/lib/dart/bin/pub get`

5. Server starten
`dart bin/main.dart`

Der Server läuft jetzt standardmäßig unter `localhost:3000`.

## Wahlometer-Daten neu einlesen und parsen

`dart bin/processing.dart`
