# Bike Navi – Kartenbilder

Öffentliche Offline-Karten für Braunschweig, Wolfsburg, Gifhorn, Helmstedt,
Peine, Salzgitter, Wolfenbüttel und den Elm. Dieses Repository enthält nur
den Karten-Publisher und öffentlich verfügbare Kartendaten.

Jeden Montag erstellt GitHub Actions aus dem neuesten erreichbaren
Protomaps-Build einen PMTiles-Ausschnitt (9,90–11,40° Ost / 51,95–52,75° Nord,
Zoom 0–15, etwa 106 MB). Ein manueller Start ist unter **Actions → Kartenbild
bereitstellen → Run workflow** möglich. Der eigene Rechner wird nicht benötigt.

Die Android-App liest `releases/latest/download/map.json` und lädt die darin
verlinkte datierte Datei. Größe und SHA-256 werden vor dem Ersetzen geprüft.
Die Veröffentlichung erfolgt erst, wenn Karte und Manifest vollständig
hochgeladen sind. Bereits veröffentlichte Karten werden bei Wiederholungen
wiederverwendet.

`latest.json` hält den veröffentlichten Stand zusätzlich im Repository fest.
Der wöchentliche Commit dokumentiert die Aktualisierung und hält das
Repository aktiv, damit GitHub den Zeitplan nicht wegen Inaktivität abschaltet.

Kartendaten: © [OpenStreetMap-Mitwirkende](https://www.openstreetmap.org/copyright),
[ODbL](https://opendatacommons.org/licenses/odbl/1-0/).
Basemap und Werkzeug: [Protomaps](https://protomaps.com/).

Publisher-Code: MIT.
