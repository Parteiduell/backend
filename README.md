[![Jugend hackt](https://jhbadge.com/?year=2019&evt=ffm)](https://jugendhackt.org)

# parteiduell-backend

Das Backend für [parteiduell-frontend](https://github.com/Jugendhackt/parteiduell-frontend/), verantwortlich für Erstellung und Ausliefern der Quizfragen.

## Server lokal starten

1. [Dart SDK installieren](https://dart.dev/get-dart)

Getestet mit Dart `2.5.1`.

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

## Binärdatei kompilieren

Hierfür wird das Dart SDK in Version `2.6.0-dev.4.0` oder neuer benötigt.

`dart2native bin/main.dart -o parteiduell_backend-linux-x64-release`

Starten des Servers:

`./parteiduell_backend-linux-x64-release`

Der kompilierte Server benötigt natürlich noch die Daten im `data` Ordner.

## Wahlometer-Daten neu einlesen und parsen

`dart bin/processing.dart`
