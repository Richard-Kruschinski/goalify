# Liquid-Glass-Schalter

Segmentierter Schalter mit einer gläsernen Kapsel als Auswahl. Im Einsatz für das Theme (System / Hell / Dunkel) unter Funktionen → Optionen → Erscheinungsbild. Die Kapsel gleitet beim Tippen oder Ziehen zum neuen Segment, wird dabei etwas größer und biegt am Rand die Icons und Texte darunter wie echtes Glas. In der Mitte zeigt sie alles unverzerrt.

Sehr geholfen hat der Artikel [Liquid Glass in the Browser: Refraction with CSS and SVG](https://kube.io/blog/liquid-glass-css-svg/) von kube.io. Von dort stammen die Idee mit flacher Mitte und gewölbtem Rand, die Verschiebung nur entlang der Randnormalen und die Lichtkante. Der Artikel setzt das mit SVG-Displacement-Maps als `backdrop-filter` um (nur Chrome). Hier ist es ein Fragment-Shader in Flutter.

## Dateien

| Datei | Inhalt |
|---|---|
| `lib/core/widgets/liquid_glass_segmented.dart` | Widget `LiquidGlassSegmented<T>` und `LiquidGlassSegment<T>`, Animation, Gesten, Painter |
| `shaders/liquid_glass.frag` | Shader, der die Kapsel aus einem Bild der Icon-Zeile malt und am Rand biegt |
| `pubspec.yaml` | Eintrag `flutter: shaders: - shaders/liquid_glass.frag` |
| `test/liquid_glass_segmented_test.dart` | Widget-Test: Tippen und Ziehen mit aktivem Shader, ohne Exception |
| `lib/features/functions/settings/presentation/pages/settings_screen.dart` | Einbau für den Theme-Modus |

## Verwendung

```dart
LiquidGlassSegmented<ThemeMode>(
  selected: settings.themeMode,
  onChanged: settings.setThemeMode,
  segments: [
    LiquidGlassSegment(value: ThemeMode.system, icon: Icons.contrast, label: l10n.themeSystem),
    LiquidGlassSegment(value: ThemeMode.light, icon: Icons.light_mode_outlined, label: l10n.themeLight),
    LiquidGlassSegment(value: ThemeMode.dark, icon: Icons.dark_mode_outlined, label: l10n.themeDark),
  ],
)
```

Das Widget hält keinen eigenen Auswahlzustand. Es ruft `onChanged` auf und animiert, sobald `selected` sich ändert. Die Breite kommt vom Elternteil, die Höhe ist fest 64 px. Funktioniert mit beliebig vielen Segmenten.

## Aufbau von unten nach oben

Alles liegt in einem `Stack` mit `Clip.none`, damit die Kapsel beim Anheben über die Spur hinausragen darf.

1. **Spur:** `ShapeDecoration` mit `StadiumBorder`, Farbe `AppColors.chip` (hell) bzw. `AppColors.card` (dunkel), Rand 1 px in Schwarz 5 % (hell) bzw. Weiß 6 % (dunkel).
2. **Icon-Zeile:** `Row` mit einem `Expanded` je Segment (Icon 22 px, 3 px Abstand, Text 12,5 px w600), 4 px Einzug links und rechts. Sie steckt in einem `RepaintBoundary` mit `GlobalKey`, damit man sie als Bild abgreifen kann. Die Farbe jedes Segments ist `Color.lerp(ink, muted, |position - i|)`, das Segment unter der Kapsel ist also dunkel (bzw. hell im Dark Mode) und die anderen grau.
3. **Kapsel** (`_GlassCapsule`, in `IgnorePointer`), selbst wieder in Schichten:
   - `_OuterShadowPainter`: Schatten nur außerhalb der Kapsel (Clip mit `PathFillType.evenOdd`), sonst würde er das Glas von hinten abdunkeln. Zwei Lagen: 4 px versetzt mit Blur 8, 1 px versetzt mit Blur 1,5.
   - `ClipPath` auf `StadiumBorder`, darin der `_RefractionPainter` mit dem Shader. Er malt das ganze Innere der Kapsel neu.
   - Darüber als Vordergrund-Dekoration eine leichte weiße Tönung von oben nach unten.
   - `_RimPainter` als `foregroundPainter`: Lichtkante und Schimmer, im Light Mode zusätzlich eine dunkle Innenkante.
4. **Tippflächen:** eine `Row` aus unsichtbaren `GestureDetector`s ganz oben, je Segment mit `Semantics(button: true, selected: …, label: …)`.

## Die Brechung

### Prinzip aus dem Artikel

Man stellt sich die Kapsel als Glasstück vor, das in der Mitte flach ist und zum Rand hin abfällt (konvexer Rand, englisch Bezel). Licht, das senkrecht durch die flache Mitte fällt, wird nicht abgelenkt. Am Rand trifft es auf eine schräge Fläche und wird zur Mitte hin gebrochen. Für das Bild heißt das: Ein Pixel am Rand zeigt, was eigentlich ein Stück weiter innen liegt. Die Verschiebung zeigt immer entlang der Normalen der Randkurve nach innen und hängt nur vom Abstand zum Rand ab, nicht von der Größe der Kapsel.

### Umsetzung in Flutter

Der Shader bekommt kein Bild vom Hintergrund des Fensters, sondern ein Bild der Icon-Zeile:

1. `_RefractionPainter.paint` holt sich den `RenderRepaintBoundary` der Icon-Zeile über den `GlobalKey` und ruft `toImageSync(pixelRatio: devicePixelRatio)` auf. Das klappt im selben Frame, weil die Zeile im `Stack` vor der Kapsel gezeichnet wird.
2. Das Bild wird in `_ContentSnapshot` gehalten und erst beim nächsten Frame freigegeben.
3. Der Shader wird als normaler Paint-Shader benutzt (`Paint()..shader = fragmentShader`, `canvas.drawRect`). Das läuft auf Skia, Impeller und im Web gleich, weil `FlutterFragCoord()` hier lokale Koordinaten der Kapsel liefert.
4. Der Shader malt jeden Pixel der Kapsel aus diesem Bild, mit der Spurfarbe dahinter. Das Original unter der Kapsel ist damit komplett verdeckt.

`shouldRepaint` gibt immer `true` zurück, weil sich die Farben der Icon-Zeile mit der Kapselposition ändern.

### Uniforms des Shaders

| Index | Uniform | Wert |
|---|---|---|
| 0-1 | `uSize` | Größe der Kapsel (logische px) |
| 2-5 | `uImageRect` | Lage des Bildes relativ zur Kapsel: `(4 - capsule.left, -capsule.top, rowWidth, 64)` |
| 6 | `uBezel` | Breite des gewölbten Rands: 12 px in Ruhe, 14 px angehoben |
| 7 | `uDepth` | maximale Verschiebung ganz außen: 4,5 px in Ruhe, 6 px angehoben |
| 8-11 | `uTrack` | Spurfarbe, vormultipliziert (r·a, g·a, b·a, a) |
| Sampler 0 | `uContent` | Bild der Icon-Zeile |

### Rechnung im Shader

```glsl
float d = -sdStadium(local, halfSize);      // Abstand nach innen vom Rand
float x = clamp(d / uBezel, 0.0, 1.0);      // 0 am Rand, 1 wo die flache Mitte beginnt
vec2  n = normalize(Gradient von sdStadium); // Normale nach außen
float bend = (1.0 - x) * (1.0 - x);          // 1 am Rand, 0 mit Steigung 0 am Ende des Rands
fragColor = contentAt(p - n * uDepth * bend);
```

`sdStadium` ist die vorzeichenbehaftete Distanz zu einer Kapsel (Rechteck mit Radius = halbe Höhe). `contentAt` liest das Bild und legt es über die Spurfarbe; außerhalb des Bildes gibt es nur die Spurfarbe.

### Warum `(1 - x)²` und nicht die Squircle-Kurve

Der Artikel empfiehlt als Randprofil eine konvexe Squircle-Kurve. Deren Steigung ist am äußersten Rand sehr steil. Als Verschiebung übernommen, kippt die Abbildung dort um: Zwei Pixel nebeneinander zeigen dieselbe Stelle, und Teile von Icons erscheinen doppelt. Damit die Abbildung nie umklappt, muss gelten:

```
Ableitung von (Position - Verschiebung) > 0   ⇔   2 · uDepth / uBezel < 1
```

Mit `(1 - x)²` ist die stärkste Steigung `2 / uBezel`, also reicht `2 · 4,5 < 12` bzw. `2 · 6 < 14`. Wer die Werte ändert, muss diese Bedingung einhalten.

## Animation und Gesten

| Wert | Größe |
|---|---|
| Kurve (überall dieselbe) | `Curves.easeOutCubic` |
| Gleiten (`_slide`) | 320 ms |
| Anheben und Absenken (`_lift`) | 200 ms |
| Größe angehoben | 111 % von Breite und Höhe der Ruhegröße |
| Ruhegröße | ein Segment breit, Höhe 64 - 2·4 = 56 px |

Ablauf beim Tippen: `onChanged` → Eltern setzen `selected` → `didUpdateWidget` startet `_glideTo`: Kapsel hebt an und gleitet gleichzeitig. Ist `_slide` fertig, senkt sie sich wieder ab (`_onSlideStatus`).

Ablauf beim Ziehen:

- `GestureDetector` mit `dragStartBehavior: DragStartBehavior.down`. Ohne das verschluckt Flutter den Anfang der Bewegung, und bei langen Zügen landet die Kapsel ein Segment zu früh.
- Start: Gleiten stoppen, Position merken, anheben.
- Update: Position += `delta.dx / segmentWidth`, begrenzt auf 0 bis Anzahl-1.
- Ende: Ziel = gerundete Position plus ein kleiner Schwung aus der Geschwindigkeit (`velocity.dx / segmentWidth * 0.08`). `_to` wird vor `onChanged` gesetzt, damit `didUpdateWidget` nicht ein zweites Mal animiert. Danach gleiten und absenken wie beim Tippen.

## Farben und Licht

| Element | Light Mode | Dark Mode |
|---|---|---|
| Tönung oben → unten (Ruhe) | Weiß 12 % → 4 % | Weiß 10 % → 4 % |
| Tönung oben → unten (angehoben) | Weiß 6 % → 2 % | Weiß 6 % → 2 % |
| Lichtkante 1 px, oben / unten | Weiß 100 % / 60 % | Weiß 55 % / 18 % |
| Schimmer unter der Oberkante | `#F8FBFF` 95 % → 0 | Weiß 10 % → 0 |
| Dunkle Innenkante 1,5 px | Schwarz 0 % oben, 6 % Mitte, 10 % unten | keine |
| Schatten groß / klein | Schwarz 14 % / 6 % | Schwarz 45 % / 30 % |

Lichtkante: ein Verlauf von oben nach unten auf dem Rand der Kapsel mit den Stopps 0 / 0,42 / 0,6 / 1, in der Mitte durchsichtig. Schimmer: eine flache Kapsel ab 1,5 px unter der Oberkante, 28 % der Höhe hoch, links und rechts um 45 % der Höhe eingerückt.

Die dunkle Innenkante gibt es nur im Light Mode. Auf der hellgrauen Spur sind weiße Reflexe sonst unsichtbar, und die Kapsel sieht aus wie eine Plastikpille. Erst die dunkle Kante darunter macht die weiße Lichtkante sichtbar.

## Stolperfallen

- **Kein `BackdropFilter` für die Brechung.** Der erste Versuch las mit `ImageFilter.shader` bzw. `ImageFilter.matrix` den Hintergrund. Auf Windows lag die Leseposition daneben, die Kapsel war einfach weiß. `ImageFilter.shader` geht außerdem nur mit Impeller.
- **Keine vergrößerte Kopie als Ersatz.** Eine um die Kapselmitte skalierte Kopie der Icon-Zeile verschiebt Punkte umso stärker, je weiter sie von der Mitte weg sind (bei 450 px breiter Kapsel rund 40 px). Mit einem Ring am Rand gibt es dazu eine harte Kante. Beides erzeugt doppelte Icons.
- **Das Original muss verdeckt sein.** Der Shader malt das ganze Innere deckend (Bild über Spurfarbe). Ist die Kapsel irgendwo durchsichtig, sieht man das unverzerrte Original neben dem gebogenen.
- **Reihenfolge im `Stack`.** Die Icon-Zeile muss vor der Kapsel stehen, sonst ist ihr Layer beim `toImageSync` noch nicht aktuell.
- **Neuer Shader = Neustart.** Nach Änderungen an `pubspec.yaml` oder an der `.frag`-Datei reicht Hot Reload nicht, die App muss neu gestartet werden.
- **Lädt der Shader nicht,** gibt `_LiquidGlassProgram.load()` `null` zurück und schreibt eine Meldung ins Log. Die Kapsel ist dann klares Glas ohne Brechung, alles andere funktioniert weiter.

## Prüfen

```bash
flutter analyze
flutter test test/liquid_glass_segmented_test.dart
```

Von Hand: Funktionen → Optionen → Erscheinungsbild, die Kapsel langsam von „System“ nach „Dunkel“ ziehen und auf halber Strecke festhalten. Icons unter dem Kapselrand werden gebogen, aber nirgends doppelt angezeigt. Im Light und Dark Mode gleichermaßen, schmal und breit (Handy und Windows-Fenster).
