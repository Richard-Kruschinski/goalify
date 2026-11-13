# Lauf-Tracking (Tab „Cardio“)

Zeichnet Laufen, Gehen oder Radfahren per GPS auf und zeigt die Strecke auf einer dunklen Vektorkarte (OpenFreeMap).

## Ablauf

1. Im Tab **Cardio** die Art wählen und auf **Start** tippen.
2. Die App fragt nach dem Standort-Recht. Ist der Standort aus oder das Recht dauerhaft verweigert, bietet die Snackbar einen Sprung in die Einstellungen an.
3. Die Live-Seite zeigt die Karte und darüber eine schwebende Karte mit Status-Leiste („Läuft“ in der Akzentfarbe, „Pausiert“ in Orange) und den Werten **Zeit | Tempo (groß) | Distanz**. Das Tempo erscheint erst ab 50 m.
4. Während des Laufs gibt es nur **Pause**. In der Pause gibt es **Weiter** und **Beenden**. Nach „Weiter“ beginnt ein neues Teilstück.
5. **Beenden** öffnet einen Dialog mit Speichern und Verwerfen. Gespeichert wird erst ab 50 m Strecke (`RouteStats.isWorthSaving`), weil auch Stillstehen GPS-Punkte liefert. Bei kürzerer Strecke bietet der Dialog „Verwerfen“ oder „Weiter“ an.

Verlässt man die Live-Seite, läuft die Aufzeichnung weiter. Im Tab erscheint dann eine Karte „Läuft“, die zurückführt.

## Live-Seite

- **Keine Titelleiste:** Die Karte reicht bis zum oberen Rand, die Statusleiste des Handys ist hell. Die runden Knöpfe (`MapCircleButton`) rücken unter die Statusleiste.
- **Oben links:** Zurück.
- **Oben rechts, untereinander:**
  - Einstellungen (noch ohne Funktion, zeigt „Bald verfügbar“)
  - Kompass: Die Nadel zeigt die Nordrichtung der Karte, Tippen dreht sie nach Norden.
  - Zentrieren: erscheint, wenn man die Karte verschoben hat.
- **Blickrichtungs-Kegel:** am Positionspunkt, zeigt, wohin das Handy zeigt. Die Richtung kommt aus `flutter_compass` und gibt es nur auf Android und iOS.
- **Zentrieren und Norden:** Die Karte springt nicht, sondern fliegt in 0,9 s hin (Verschieben, Zoom und Drehung zusammen). Fasst man die Karte währenddessen an, stoppt der Flug.

## Aufbau

| Teil | Datei |
|---|---|
| Modell `Run`, `RoutePoint`, `RunActivity` | `lib/features/runs/data/models/run.dart` |
| Speicher (Key `runs_v1`) | `lib/features/runs/data/datasources/runs_local_data_source.dart` |
| Distanz, Pace, Speicher-Grenze, GPS-Filter | `lib/features/runs/domain/usecases/route_stats.dart` (Tests: `test/features/runs/`) |
| Aufzeichnung | `lib/features/runs/presentation/controllers/run_controller.dart` (app-weit in `main.dart`) |
| Seiten | `runs_screen.dart`, `run_tracking_page.dart`, `run_detail_page.dart` |
| Karte, Route, Marker, Kegel, Kompass | `presentation/widgets/run_route_map.dart` |
| Kartenstil (einmal geladen) | `presentation/widgets/run_map_style.dart` |
| Werte-Zeile, runde Knöpfe, Formate | `run_stats_row.dart`, `map_circle_button.dart`, `run_format.dart` |

## Wichtige Entscheidungen

- **Teilstücke statt einer Linie:** Jede Pause beginnt ein neues Teilstück. So zeichnet die Karte keine gerade Linie über die Pause, und die Lücke zählt nicht zur Distanz.
- **GPS-Filter:** Fixe mit einer Genauigkeit über 25 m werden verworfen, ebenso Sprünge, die schneller sind als 12 m/s (Laufen, Gehen) bzw. 30 m/s (Rad). Punkte, die weniger als 3 m auseinanderliegen, liefert das System gar nicht erst.
- **Speicherformat:** Pro Teilstück eine flache Liste `[lat, lng, Sekunden seit Start, ...]` mit 6 Nachkommastellen. Eine Stunde Laufen braucht damit nur einige zehn KB.
- **Distanz wird nicht gespeichert**, sondern beim Anzeigen aus den Punkten berechnet.

## Bildschirm aus

- **Android:** `geolocator` startet beim Tracking einen eigenen Vordergrunddienst (Typ `location`) mit Benachrichtigung „Goalify zeichnet auf“. Weil der Dienst bei offener App startet, ist `ACCESS_BACKGROUND_LOCATION` nicht nötig.
- **iOS:** `UIBackgroundModes: location` und `allowBackgroundLocationUpdates`. Ungetestet, weil hier kein Mac zur Verfügung steht.
- Der Sperrbildschirm-Timer aus [live-timer.md](live-timer.md) ist **nicht** angebunden.

## Karte

- **Quelle:** [OpenFreeMap](https://openfreemap.org), Stil „Fiord“ (dunkelblau). Der Dienst ist kostenlos, auch kommerziell, und braucht keinen Key. Die URL steht in `run_map_style.dart`.
- **Vektorkarte:** Das Handy zeichnet die Karte selbst, mit dem Paket `flutter_map_vector_tiles`. Der Stil wird einmal pro App-Start geladen und von allen Karten geteilt.
- **Beschriftung:** Auf Android und iOS `LabelMode.screen`. Die Namen werden über die Karte gezeichnet und bleiben beim Drehen aufrecht lesbar (Orte, Straßen, alles). Das kostet etwas Rechenzeit pro Bild. Im Web gilt `LabelMode.tile`, weil `screen` dort gar keine Namen zeichnete. Dort sind die Namen in die Kacheln eingebacken und drehen sich mit.
- **Route:** in der Akzentfarbe der App, mit breiter, blasser Kopie darunter als Leuchten. Weißer Punkt mit Rand = Start, gefüllter Punkt mit Leuchten = aktuelle Position.
- **Zoom-Grenze:** Die Welt wiederholt sich links und rechts, die Karte läuft also rundum. Herauszoomen geht nur so weit, bis eine Welt die längere Seite der Karte füllt, sonst stünden mehrere Kopien nebeneinander. Über die Pole hinaus lässt sie sich nicht schieben.
- **Quellenangabe:** Pflicht. Sie steckt hinter dem (i)-Knopf unten links und sitzt auf der Live-Seite über der schwebenden Karte.
- **Offline:** Stil und zuletzt gesehene Kacheln liegen im Cache (nur nativ). Ohne Netz und ohne Cache bleibt der Hintergrund einfarbig, die Strecke wird trotzdem aufgezeichnet.

## Build-Hinweise (harmlos)

- **Windows:** „Nuget.exe not found, trying to download …“ kommt von `geolocator_windows`. Der Build lädt `nuget.exe` dann selbst. Mit `winget install Microsoft.NuGet` verschwindet die Meldung.
- **Android:** „LocationMapper.java verwendet … eine veraltete API“ ist eine Java-Warnung aus `geolocator_android`, nicht aus unserem Code.
- **Android:** `flutter_compass` baut mit SDK Platform 34. Gradle installiert sie beim ersten Build automatisch nach.
