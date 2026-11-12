# Pausen-Timer zwischen Sätzen

Nach jedem gespeicherten Satz läuft eine Stoppuhr, die zeigt, wie lange die Pause schon dauert. Dazu gibt es Haken für erledigte Sätze, den Hinweis auf die nächste Übung und eine Pausen-Statistik in der Historie.

## Verhalten

| Situation | Was passiert |
|---|---|
| Im Eingabedialog einer Übung **Aktualisieren** oder **Hinzufügen** tippen, Datum heute | Timer startet bei 0:00 neu, ein Satz-Ereignis wird gespeichert |
| Eintrag für einen anderen Tag | kein Timer, kein Satz-Ereignis |
| Einstellung „Pausen-Timer“ aus | kein Timer; Satz-Ereignisse (Haken) werden trotzdem gespeichert, nur ohne Pausenzeit |
| Übung hat eine Satzanzahl (z. B. 3) | Anzeige „Satz 2 von 3“; beim 3. Speichern „Bankdrücken fertig · Als Nächstes: …“ |
| Mehr Speichern als Sätze geplant | Timer startet trotzdem (so gewünscht); Text bleibt „fertig“ |
| Übung ohne Satzanzahl | Timer startet immer, Anzeige „Satz 4“ ohne „von“ |
| Timer läuft | Uhr links im Balken: der Zeiger dreht sich flüssig, eine volle Umdrehung = Zielpause (ohne Zielpause 60 s). Nach der Zielpause dreht er weiter. Bei „Bewegung reduzieren“ springt er nur jede Sekunde |
| Zielpause erreicht | Zeit und Uhr im Balken werden grün; Handy vibriert über die Benachrichtigung (auch gesperrt) |
| Auto-Aus erreicht (Standard 15 min, 1–60) | Timer endet, die nächste Pause wird nicht gezählt |
| ■ im Balken oder „Stopp“ in der Benachrichtigung | Timer endet sofort |
| Balken antippen | öffnet die Eingabe der Übung für den nächsten Satz |

„Als Nächstes“ ist die nächste **Haupt**-Übung des Trainingstags (Alternativen werden übersprungen), die heute noch nicht alle Sätze hat. Ist keine mehr offen: „Workout geschafft“.

Haken: Unter jeder Übungskarte ein Kreis pro geplantem Satz, grün für erledigte. Sind alle geschafft, steht ein grüner Haken neben dem Namen. Gezählt wird pro logischem Tag (`DayCycle`), egal unter welchem Trainingstag gespeichert wurde.

Neu hinzukommende Haken zeichnen sich an ihrer Stelle selbst (`AnimatedCheck`, 1,1 s): das Symbol ploppt auf, der Kreis wird gezogen, dann der Haken. Das ist eine Flutter-Übersetzung des SVG/CSS-Snippets „Animated Success Checkmark“ (stroke-dashoffset + Pop-in, gleiche Zeiten und Kurve `cubic-bezier(0.34, 1.56, 0.64, 1)`). Haken, die beim Aufbau der Karte schon da sind, bleiben still. Bei „Bewegung reduzieren“ gibt es keine Animation.

## Wo man es einstellt

- **Je Übung:** Drei-Punkte-Menü der Übung → „Sätze & Pause“ (`RestSettingsDialog`). Satzanzahl 0–20, Zielpause 0–10 min in 15-s-Schritten. 0 heißt „Aus“ und wird als `null` gespeichert.
- **Global:** Functions-Tab → Optionen → „Pausen-Timer“ (Schalter, darunter „Automatisch aus“).

## Ablauf im Code

```
LogInputDialog (Aktualisieren)
  → GymScreen._addLog(workoutId, log)
      → if (isToday) _startRestAfterSet(workoutId, log.day)
          → RestTracking: Satznummer, fertig?, nächste offene Übung
          → RestTimerController.startRest(...)   // gibt die beendete Pause zurück (oder null)
          → SetEvent(at, day, restBeforeSeconds) speichern
RestTimerController
  → notifyListeners jede Sekunde → RestTimerBar (GymScreen + DayDetailScreen)
  → TimerLivePresentationService.startLiveTimer(countUp, preempt: true) → Sperrbildschirm
```

`_addLog` wird von allen drei Eingabewegen benutzt (Übungsliste über `_trackWorkout`, Tagesseite über `_openDayDetail`, neue Übung über den +-Knopf / `WorkoutPickerSheet`). Neue Eingabewege müssen ebenfalls über `_addLog` gehen, sonst gibt es keinen Timer.

## Dateien

| Datei | Aufgabe |
|---|---|
| `lib/features/gym/domain/usecases/rest_tracking.dart` | reine Logik: Sätze pro Tag, fertig?, nächste offene Übung, Pausen je Log |
| `lib/features/gym/presentation/controllers/rest_timer_controller.dart` | `RestTimerController` (App-weit in `main.dart`), `RestSession`, `describeRest()` (Text für Balken **und** Sperrbildschirm) |
| `lib/features/gym/presentation/widgets/rest_timer_bar.dart` | Balken unten mit Uhr, Zeit, Ziel, Stopp |
| `lib/features/gym/presentation/widgets/rest_clock_icon.dart` | animierte Uhr (`CustomPainter` + `Ticker`, Zeigerstellung über `turnFraction`) |
| `lib/features/gym/presentation/widgets/set_progress_widgets.dart` | `SetProgressDots`, `ExerciseCardTitle` (Haken; merken sich, welche Haken neu sind) |
| `lib/features/gym/presentation/widgets/animated_check.dart` | `AnimatedCheck`: Haken im Kreis, der sich einzeichnet (`CustomPainter`, `PathMetric.extractPath`) |
| `lib/features/gym/presentation/widgets/rest_settings_dialog.dart` / `rest_settings_tile.dart` | Einstellungen je Übung und Menüzeile |
| `lib/features/gym/presentation/widgets/options_menu_tile.dart` | gemeinsame Menüzeile (auch für `WeightSettingsTile`) |
| `lib/features/gym/data/models/gym_models.dart` | `ExerciseRestSettings`, `SetEvent` |
| `lib/features/gym/data/datasources/gym_local_data_source.dart` | Speicherung (Keys unten) |
| `lib/core/settings/settings_controller.dart` | `restTimerEnabled`, `restAutoOffMinutes` |
| `lib/core/utils/duration_format.dart` | `formatClockDuration` („1:05“) |
| `GymScreen` (`gym_screen.dart`) | Abschnitt `// ---- Rest timer ----`: Verdrahtung, Löschen der Ereignisse |
| `DayDetailScreen` | bekommt `restSettingsFor`, `setsDoneToday`, `onEditRestSettings` als Callbacks |

## Gespeicherte Daten (SharedPreferences, JSON)

| Key | Inhalt |
|---|---|
| `gym_exercise_rest_settings_v1` | `{workoutId: {targetSets?, targetRestSeconds?}}` |
| `gym_set_events_v1` | `{workoutId: [{at: ISO-8601, day: "Pull", restBeforeSeconds?}]}` |
| `settings_rest_timer_enabled_v1` | bool, Standard `true` |
| `settings_rest_auto_off_minutes_v1` | int 1–60, Standard 15 |

Satz-Ereignisse werden mitgelöscht: „Nur diesen Tag löschen“ entfernt die Ereignisse mit diesem `day`, „Alle Logs löschen“ alle Ereignisse der Übung. Die Liste wächst sonst mit jedem Satz (klein, ein Eintrag pro Speichern).

`restBeforeSeconds` gehört zu dem Satz **nach** der Pause. Die Pause vor dem ersten Satz einer Übung ist also die Wechselzeit von der vorigen Übung.

## Grenzen

- Der laufende Timer liegt nur im Speicher. Wird die App beendet, ist er weg (Haken bleiben).
- iOS: Die Benachrichtigung kann nicht live hochzählen (dafür bräuchte es eine Live Activity); sie zeigt die Startzeit. Auto-Aus greift dort erst, wenn die App wieder geöffnet wird.
- Desktop/Web: kein Sperrbildschirm, der Balken in der App funktioniert.

## Tests

- `test/rest_tracking_test.dart` – Zählen pro logischem Tag, fertig?, nächste Übung, Pausen je Log, JSON-Rundreise
- `test/rest_timer_controller_test.dart` – Neustart, Zielpause, Auto-Aus, Schalter aus, Texte von `describeRest`
- `test/duration_format_test.dart` – Zeitformat
- `test/rest_clock_icon_test.dart` – Zeigerstellung (eine Umdrehung = Zielpause), Ticker endet beim Entfernen
- `test/animated_check_test.dart` – nur neue Haken animieren, Animation endet, Bewegung reduzieren

## Von Hand prüfen

1. Gym → Tag öffnen → ⋮ bei einer Übung → „Sätze & Pause“: 3 Sätze, 0:30.
2. Übung antippen → Aktualisieren: Balken „0:00 / 0:30 · … · Satz 1 von 3“, erster Kreis grün.
3. 30 s warten: Zeit grün, Handy vibriert (auch gesperrt, Android).
4. Noch zweimal speichern: „… fertig · Als Nächstes: …“, grüner Haken am Namen.
5. Optionen → Pausen-Timer aus: läuft ein Timer, verschwindet er binnen einer Sekunde; neues Speichern startet keinen.
