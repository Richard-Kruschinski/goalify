# Skeleton-Loading

Graue Platzhalter in der Form der echten Inhalte, die zu sehen sind, solange eine Liste oder ein Bild noch lädt. Ein heller Streifen läuft von links nach rechts darüber. Sobald die Daten da sind, verschwindet das Skeleton im nächsten Frame.

Grundregel: **Skeleton nur dort, wo wirklich gewartet wird.** Es gibt keine künstliche Verzögerung und keine Mindestanzeigedauer. Ist die Ladung sofort fertig, sieht man kein Skeleton.

## Dateien

| Datei | Inhalt |
|---|---|
| `lib/core/widgets/skeleton.dart` | `Skeleton`, `SkeletonBox`, `SkeletonCardList` |
| `lib/features/tasks/presentation/pages/daily_tasks_screen.dart` | Flag `_loaded`, Skeleton statt Leerzustand, bis `_load()` fertig ist |
| `lib/features/gym/presentation/pages/gym_screen.dart` | Flag `_loaded`, Skeleton statt Leerzustand (alle drei Ansichten), bis `_bootstrap()` fertig ist |
| `lib/features/gym/presentation/widgets/exercise_icon.dart` | `placeholderBuilder` von `SvgPicture.asset` zeigt ein `SkeletonBox` |

## Die Widgets

| Widget | Aufgabe |
|---|---|
| `Skeleton` | Hält **eine** Animation (1,3 s, endlos) und gibt sie über ein `InheritedWidget` an alle `SkeletonBox`es darunter weiter. So laufen alle Blöcke im Takt. |
| `SkeletonBox` | Ein abgerundeter Block (`width`, `height`, `radius`, Standard 8). Ohne Größe füllt er den Platz, den er bekommt. In unbegrenztem Platz bleibt er 0 groß und kann also nichts sprengen. |
| `SkeletonCardList` | Fertige Liste mit `count` Karten (Standard 4) in der Form der Listenkarten von Daily und Gym: Abstand 20/16, Karte mit Ecken 16, `AppColors.cardShadow`, 48-px-Icon-Kachel, Titelzeile (60 % breit) und Unterzeile (35 %). Nicht scrollbar. |

```dart
// ganze Liste
const SkeletonCardList()

// eigene Form
Skeleton(
  child: Column(children: [
    SkeletonBox(width: 120, height: 14),
    SizedBox(height: 8),
    SkeletonBox(width: 80, height: 12),
  ]),
)
```

`SkeletonBox` ohne `Skeleton` darüber ist ein ruhiger grauer Block ohne Animation.

## Farben und Bewegung

| Punkt | Umsetzung |
|---|---|
| Grundfarbe | `AppColors.chip(context)` |
| Lichtstreifen | Grundfarbe mit 6 % `AppColors.ink` darübergelegt, im Light Mode etwas dunkler, im Dark Mode etwas heller |
| Streifen | `LinearGradient` mit Stopps 0,3 / 0,5 / 0,7, per `GradientTransform` von −1 bis +1 Blockbreite verschoben |
| „Bewegung reduzieren“ | Ist `MediaQuery.disableAnimationsOf` an, steht die Animation still und die Blöcke sind einfarbig |

## Wo es eingebaut ist und warum dort

| Stelle | Warum dort wirklich gewartet wird |
|---|---|
| Daily-Tab | Der Tab wird bei jedem Wechsel neu gebaut. `_load()` liest viele Keys, macht den Tageswechsel und **schreibt** mehrmals in den nativen Speicher, erst danach folgt `setState`. Vorher blitzte „Noch keine Aufgaben“ auf. |
| Gym-Tab | Der Tab wird bei jedem Wechsel neu gebaut. `_bootstrap()` lädt `assets/workouts.json` und die Übersetzungs-JSON (beim ersten Mal über den Asset-Kanal), danach Logs, Kalender, Kreatin und Bestwerte nacheinander. Vorher blitzte „Noch keine Workouts“ auf. |
| Übungsbilder | Einige SVGs sind über 200 KB groß (`leg_press.svg` hat 633 KB) und werden beim ersten Anzeigen geparst. Danach kommen sie aus dem Cache, und der Platzhalter erscheint nicht mehr. |

Das Flag `_loaded` wird in `initState` über `whenComplete` gesetzt. Damit verschwindet das Skeleton auch dann, wenn das Laden mit einem Fehler abbricht, und es erscheint wieder der normale Leerzustand. Spätere Neuladungen (zum Beispiel beim Tageswechsel) zeigen kein Skeleton mehr, die alten Daten bleiben stehen, bis die neuen da sind.

## Bewusst ohne Skeleton

| Stelle | Grund |
|---|---|
| Progress-Tab (`_loadAll`) | Liest nur aus `SharedPreferences`, die schon in `main()` geladen werden. Fertig nach 1 Frame, ein Skeleton würde nur flackern. |
| Controller für Pomodoro, Blocker, Musik und Intervall | Laden einmal pro App-Start und nur lesend, also genauso schnell. |
| Native Blocker-Abfragen (`getBlockedSelectionCount` …) | Wenige ms und nur ein kleiner Zähler. |
| Ringe in Pomodoro und Intervall-Timer | `CircularProgressIndicator` als Fortschrittsanzeige, kein Laden. |
| Spinner im Login-Button | Der Login wird ohne Server nicht genutzt. |

## Neue Stelle anbinden

1. Prüfen, ob dort wirklich gewartet wird: Asset beim ersten Laden, Schreibzugriff, Native-Call mit spürbarer Dauer oder großes Bild. Reines Lesen aus `LocalStorage` zählt nicht.
2. Ein Flag `bool _loaded = false;` anlegen und im `initState` per `_load().whenComplete(() { if (mounted) setState(() => _loaded = true); })` setzen.
3. Im `build` `!_loaded ? const SkeletonCardList() : …` vor den Leerzustand setzen. Passt die Kartenform nicht, aus `Skeleton` und `SkeletonBox` eine eigene Form bauen.
4. Keine `Future.delayed` und keine Mindestdauer einbauen.
