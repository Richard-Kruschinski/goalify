# Animiertes Sortier-Icon

Der Sortier-Button im Header (Daily und Gym) zeigt drei Zustände: graue Doppelpfeile für die eigene Reihenfolge, einen roten Pfeil nach oben für aufsteigend und einen roten Pfeil nach unten für absteigend. Beim Wechsel springt das Icon nicht, sondern verwandelt sich in 300 ms in den neuen Zustand. Die Farbe blendet im selben Takt von Grau nach Rot und zurück.

## Dateien

| Datei | Inhalt |
|---|---|
| `lib/core/widgets/animated_sort_icon.dart` | `SortIconState` (none, ascending, descending) und `AnimatedSortIcon`, gezeichnet mit einem `CustomPainter` |
| `lib/core/widgets/sort_menu_button.dart` | `SortMenuButton` (Gym) nutzt das Icon im Header und im Menü beim aktiven Eintrag |
| `lib/features/tasks/presentation/pages/daily_tasks_screen.dart` | Eigener Sortier-Button im Daily-Header, Getter `_sortIconState` |
| `test/animated_sort_icon_test.dart` | Widget-Tests: kein Abspielen beim ersten Bauen, jeder Wechsel läuft und endet, Abbruch mitten drin, reduzierte Bewegung |

Bilddateien gibt es keine. Die Pfeile sind Striche mit runden Enden (2 px bei 24 px Größe), Schaft plus Spitze.

## Übergänge

| Von → nach | Was passiert |
|---|---|
| Doppelpfeil → hoch | Der linke Pfeil (zeigt hoch) rutscht in die Mitte und wird größer, der rechte blendet an seinem Platz aus und schrumpft |
| Doppelpfeil → runter | Genauso, nur wandert der rechte Pfeil in die Mitte |
| hoch/runter → Doppelpfeil | Rückwärts: der Pfeil rutscht auf seine Seite und wird kleiner, der andere wächst an seinem Platz ein |
| hoch ↔ runter | Der Pfeil dreht sich um 180°, immer im Uhrzeigersinn |

Kurve: `Curves.easeInOutCubic`. Die Farbe wird mit `Color.lerp` zwischen `AppColors.muted` und `AppColors.accent` gemischt, Light und Dark Mode kommen also von selbst.

## Wie es gerechnet wird

Jeder Pfeil ist eine `_ArrowPose`: Winkel (0 = hoch, π = runter), Versatz zur Mitte, Länge, Spitzengröße, Deckkraft. Es gibt immer genau zwei Pfeile. Ein Übergang ist eine lineare Interpolation von zwei Posen-Listen.

`_targetPoses` ordnet die Ziel-Posen den aktuellen Pfeilen zu, so dass jeder Pfeil den kürzesten Weg nimmt:

- Ziel einzelner Pfeil: von den sichtbaren Pfeilen geht der in die Mitte, der schon richtig zeigt. Ist nur einer sichtbar, dreht er sich. Der andere blendet aus.
- Ziel Doppelpfeil: der sichtbarste Pfeil geht auf die Seite, deren Richtung seiner am nächsten ist. Der andere nimmt die übrige Seite.
- Ein unsichtbarer Pfeil fliegt nie sichtbar ein. Er startet klein an seinem Zielplatz und wächst dort ein (`_snapIfHidden`).

Wechselt der Zustand mitten in einer Animation, wird das aktuell gezeichnete Bild als Startpunkt genommen. Es gibt keinen Sprung.

## Wann es abspielt

- Nur in `didUpdateWidget`, wenn sich `state` geändert hat. Ein neuer State (z. B. weil `MainNav` den Tab neu baut) zeigt sofort das fertige Bild.
- `animate: false` lässt einen Wechsel springen. Daily und Gym übergeben `_loaded`, damit das Laden der gespeicherten Sortierung beim Öffnen des Tabs keine Animation auslöst.
- Bei „Bewegung reduzieren“ (`MediaQuery.disableAnimations`) springt das Icon ebenfalls.
- Im Gym hat jeder Unter-Tab (Übungen, Workouts, Splits) eine eigene Sortierung. Ein Wechsel des Unter-Tabs kann deshalb den Pfeil ändern und animiert dann auch.

## Testen

- `flutter test test/animated_sort_icon_test.dart`
- Im Browser: `flutter build web`, Launch-Konfiguration `goalify-web`, im Daily- oder Gym-Header sortieren. Ist der Browser-Bereich ausgeblendet, drosselt der Browser die Frames, und Screenshots zeigen oft nur den Endzustand. Für Zwischenbilder kurz `duration` hochsetzen oder in einem Test per `RepaintBoundary.toImage` einzelne Frames rendern.

## Anpassen

- Länge: Parameter `duration` (Standard 300 ms).
- Größe: Parameter `size`. Gezeichnet wird in einem 24×24-Raster und skaliert.
- Form: die Konstanten `_pairUp`, `_pairDown` und `_single` in `animated_sort_icon.dart`.
- Andere Farbe: Parameter `color` überschreibt Grau/Rot.
- Neuer Sortier-Button: `SortMenuButton` nehmen, oder direkt `AnimatedSortIcon(state: ..., animate: _loaded)` als Icon setzen.
