# Frost-Animation beim Freeze-Token

Wenn im Daily-Tab ein Freeze-Token für den angezeigten Tag eingesetzt wird, friert die Aufgabenliste sichtbar ein. Eiskristalle wachsen von den Rändern nach innen, die Karten bekommen einen kühlen Blauschleier, und aus der Mitte springt eine große Schneeflocke mit kleinen Flocken drumherum. Nach 1,5 s ist alles wieder weg, und es bleibt der normale eingefrorene Zustand mit dem Banner „Tag eingefroren“.

Vorbild war ein Bild mit Raureif am Fensterrand: Kristalle als Rahmen um eine freie Mitte, in den Ecken dichter.

## Dateien

| Datei | Inhalt |
|---|---|
| `lib/features/tasks/presentation/widgets/freeze_frost_overlay.dart` | `FreezeFrostOverlay`, die ganze Animation (Widget, Farben, Kristall-Muster, Painter) |
| `lib/features/tasks/presentation/pages/daily_tasks_screen.dart` | Zähler `_freezeFxTick`, wird in `_freezeDay` erhöht. `FreezeFrostOverlay` umschließt Banner und Aufgabenliste im `build` |

Bilddateien gibt es keine, gezeichnet wird alles mit einem `CustomPainter`.

## Auslösen

`FreezeFrostOverlay` hat den Parameter `trigger` (int). Die Animation startet nur in `didUpdateWidget`, wenn sich der Wert geändert hat. Ein normaler Rebuild, ein Tab-Wechsel oder das Öffnen eines schon eingefrorenen Tages spielt sie deshalb nicht ab, denn beim ersten Bauen startet nichts.

In `_freezeDay(dateKey)` wird `_freezeFxTick` nur erhöht, wenn `dateKey` der gerade angezeigte Tag ist. So läuft die Animation an allen drei Stellen, an denen ein Token eingesetzt wird:

| Stelle | Methode |
|---|---|
| Schneeflocken-Chip im Header | `_openFreezeSheet` → `FreezeSheet` |
| Aktionsmenü einer Streak-Aufgabe („Tag einfrieren“) | Eintrag `freezeForToday` im Aktions-Sheet |
| Nachträglich einfrieren beim Tageswechsel | `_maybeOfferRetroFreeze` → `RetroFreezeDialog` |

Beim nachträglichen Einfrieren wird meist der Vortag eingefroren, während heute angezeigt wird. Dann läuft keine Animation, weil die Karten auf dem Bildschirm gar nicht eingefroren sind.

Alle drei Wege laufen über ein Sheet oder einen Dialog. Deshalb wartet die Animation `startDelay` (Standard 220 ms), bis das Sheet weggefahren ist.

## Ablauf

Die Gesamtdauer ist 1500 ms (`_duration`). `t` läuft von 0 bis 1.

| Teil | Zeitfenster (t) | Was passiert |
|---|---|---|
| Kristalle | 0 bis 0,5 | Wachsen per `easeOutCubic` von der Wurzel am Rand nach innen |
| Randschleier | 0 bis 0,5 | Vier `LinearGradient`-Streifen an den Kanten, bis 90 px tief |
| Blauschleier | 0 bis 0,5 | Fläche in `AppColors.info` mit bis zu 14 % Deckkraft |
| Ring | 0,12 bis 0,75 | Kreis wächst aus der Mitte auf die halbe kürzere Seite und blendet aus |
| Große Flocke | 0,12 bis 0,75 | Springt per `easeOutBack` auf, dreht sich um 30°, blendet ab 0,45 aus |
| Kleine Flocken | 0,12 bis 0,75 | 12 Stück fliegen nach außen und drehen sich |
| Ausblenden | 0,68 bis 1 | Alles zusammen per `easeIn` auf 0 |

Das Banner „Tag eingefroren“ erscheint sofort beim `setState` und liegt unter dem Frost. Es wird beim Ausblenden sichtbar.

## Kristall-Muster

`_FrostPattern.generate(size)` baut das Muster einmal pro Größe und mit festem Seed (`Random(7)`). Pro Frame wird nichts neu erzeugt, und derselbe Bildschirm friert immer gleich ein.

Ein Kristall startet an einer Randstelle und zeigt nach innen (±0,45 rad Streuung). Der Hauptast hat 4 Stücke, die Seitenäste 3, deren Seitenäste 2, also drei Ebenen. Seitenäste gehen in etwa 60° ab und werden zur Spitze hin kürzer. Jedes Stück (`_Segment`) speichert, bei welcher Wachstumsdistanz es anfängt (`d0`) und fertig ist (`d1`). Der Painter zeichnet ein Stück nur so weit, wie die aktuelle Distanz reicht. Deshalb wachsen die Kristalle von innen nach außen.

| Wert | Größe |
|---|---|
| Abstand der Kristalle am Rand | etwa 34 px, ±30 % |
| Grundlänge | 20 % der kürzeren Seite, begrenzt auf 40 bis 120 px |
| Ecken | je 3 zusätzliche Kristalle, 1,7-mal so lang |
| Strichstärke je Ebene | 2,2 / 1,4 / 0,9 px, darunter ein dreimal so breiter, blasser Strich als Schein |

Bei einem Tablet im Querformat sind das einige tausend Linienstücke. Die werden pro Ebene in einen gemeinsamen `Path` gelegt, also 6 `drawPath`-Aufrufe pro Frame.

## Farben

Im Light Mode wäre weißer Frost auf den weißen Karten unsichtbar, deshalb ist er dort blau.

| Farbe | Light | Dark |
|---|---|---|
| Kristalle und Flocken (`frost`) | `#6FA6DE` | `#E4F1FF` |
| Schein um die Striche (`glow`) | `#BFDAF5` | `#9CC8F5` |
| Randschleier (`edge`) | `#8DBBE8` | `#9CC8F5` |
| Blauschleier (`tint`) | `AppColors.info` | `AppColors.info` |

## Verhalten am Rand

- Das Overlay liegt in einem `IgnorePointer`. Antippen, Scrollen und Ziehen gehen während der Animation normal weiter.
- Es existiert nur, solange der `AnimationController` läuft. Danach ist im Baum nur noch das Kind.
- Ist „Bewegung reduzieren“ an (`MediaQuery.disableAnimations`), läuft nichts.
- `RepaintBoundary` trennt das Neuzeichnen von der Liste darunter.

## Testen im Browser

1. `flutter build web`, dann die Launch-Konfiguration `goalify-web` starten.
2. Ist die Liste leer, Testaufgaben direkt in den `localStorage` schreiben. Werte liegen dort als JSON-String in einem JSON-String:

   ```js
   const mk = (id, title, streak) => ({id, title, category: 'Lernen', points: 1, keep: true,
     done: false, streak, bestStreak: streak, repeatStartKey: '2026-11-01', customDays: 1,
     weeklyDays: [], checklist: [], completedCount: 0});
   localStorage.setItem('flutter.daily_tasks_v1', JSON.stringify(JSON.stringify([mk('t1', 'Lesen', 6)])));
   ```

3. Zum Wiederholen den Freeze zurücksetzen und neu laden:

   ```js
   localStorage.removeItem('flutter.daily_freeze_usage_v1');
   localStorage.setItem('flutter.daily_freeze_tokens_v1', '"2"');
   location.reload();
   ```

4. Ist der Browser-Bereich der App ausgeblendet, drosselt der Browser die Frames, und Screenshots verpassen die 1,5 s. Für Screenshots kurz `_duration` hochsetzen (zum Beispiel 15 s), neu bauen und danach wieder auf 1500 ms zurückstellen.

Auf einem echten Handy ist die Animation in voller Geschwindigkeit noch nicht angeschaut worden.

## Anpassen

- Länge: `_duration` in `_FreezeFrostOverlayState`. Die Zeitfenster in `_FrostPainter.paint` und `_paintBurst` sind Anteile davon und passen sich mit an.
- Dichte des Frosts: `spacing` und `baseLen` in `_FrostPattern.generate`.
- Farben: `_FrostPalette.of`.
- An anderer Stelle nutzen: Widget um den Bereich legen und einen int-Zähler als `trigger` übergeben, der nur bei der auslösenden Aktion erhöht wird.
