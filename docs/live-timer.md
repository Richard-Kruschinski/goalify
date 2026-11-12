# Timer auf dem Sperrbildschirm

Pomodoro, Musik-Timer, Intervall-Timer und der Gym-Pausen-Timer zeigen sich außerhalb der App als Benachrichtigung. Die Brücke ist `TimerLivePresentationService` (`lib/core/services/timer_live_presentation_service.dart`) mit dem MethodChannel `com.goalify/timer_service`.

## Bausteine

| Seite | Datei | Aufgabe |
|---|---|---|
| Dart | `core/models/timer_live_state.dart` | Zustand, der zur nativen Seite geht (`toMap`) |
| Dart | `core/services/timer_live_presentation_service.dart` | Aufrufe an native Seite, Rückmeldungen (Knöpfe, Antippen) an die Controller |
| Android | `android/.../services/TimerForegroundService.kt` | Foreground-Service, zählt selbst (alle 500 ms), baut die Benachrichtigung |
| Android | `android/.../receivers/TimerActionReceiver.kt` | Knöpfe der Benachrichtigung → Service + Dart |
| Android | `android/.../MainActivity.kt` | Channel-Handler, Antippen → `navigateToTimer` |
| iOS | `ios/Runner/AppDelegate.swift`, `TimerNotificationManager.swift` | lokale Benachrichtigungen (keine Live Activity) |

## Channel-Methoden (Dart → nativ)

| Methode | Argumente | Hinweis |
|---|---|---|
| `startTimer` | `TimerLiveState.toMap()` + `labels` | startet oder ersetzt die Anzeige |
| `pauseTimer` | – | |
| `resumeTimer` | `remainingSeconds` | |
| `stopTimer` | – | entfernt die Anzeige |
| `finishTimer` | `message` | kurze „Fertig“-Meldung |
| `updatePhase` | Phase, Runde, Zeit | Phasenwechsel (z. B. Fokus → Pause) |

Nativ → Dart: `onTimerAction` mit `pause`/`resume`/`stop`/`skip`, und `navigateToTimer` mit dem Timer-Typ. Der Typ `rest` öffnet den Gym-Tab, alle anderen den Functions-Tab.

`labels` sind die Knopf- und Statustexte in der App-Sprache: `pause`, `resume`, `stop`, `skip`, `paused`, `done`, `restAlert`. Wer einen neuen Text braucht, ergänzt ihn in `_labels()` **und** in `LABEL_KEYS` (Kotlin).

## Hochzähl-Modus (Pausen-Timer)

`TimerLiveState(countUp: true, alertAtSeconds: 90, autoStopSeconds: 900)`:

- `remainingSeconds` bedeutet hier „schon vergangen“ (0 beim Start).
- **Android:** zählt hoch, zeigt nur einen Stopp-Knopf, schickt bei `alertAtSeconds` einmal eine vibrierende Meldung über den eigenen Kanal `timer_alert_channel` (der Hauptkanal ist absichtlich stumm), stoppt sich bei `autoStopSeconds` selbst und meldet `stop` an Dart.
- **iOS:** zeigt die Startzeit (`startCountUp`) und plant die Meldung für `alertAtSeconds`. Kein Auto-Stopp im Hintergrund.

## Ein Platz, Vorrang-Regel

Es gibt nur **eine** Anzeige. Damit sich Timer nicht gegenseitig kaputt machen:

- `startLiveTimer(state, preempt: true)` nimmt sich den Platz (nur der Pausen-Timer tut das). Ein laufender Timer wird „verdrängt“ und läuft in der App weiter.
- Solange der Vorrang-Timer läuft, werden Aufrufe anderer Timer ignoriert. Deshalb geben alle Controller bei `pauseLiveTimer`, `stopLiveTimer`, `finishLiveTimer` ihre `timerId` mit.
- Endet der Vorrang-Timer (`stopLiveTimer(timerId: 'rest')`), ruft der Service beim verdrängten Timer `currentLiveState()` auf und zeigt ihn wieder an (bei Pause auch pausiert).
- Endet der verdrängte Timer vorher, wird er vergessen und nicht wiederhergestellt.

## Einen neuen Timer anbinden

1. `TimerType` erweitern, falls nötig Icon/Farbe in `timerSmallIcon()`/`timerColor()` (Kotlin).
2. Im Controller-Konstruktor `registerCallbacks(id, onPause:, onResume:, onStop:, currentLiveState: () => läuft ? _buildLiveState() : null)`.
3. Bei allen Aufrufen die eigene `timerId` mitgeben.
4. Controller App-weit in `main.dart` anlegen, damit er Tab-Wechsel übersteht.

## Bekannt

- iOS-Code ist in dieser Umgebung nie gebaut worden.
- Android 16 „Live Updates“ (Now Bar) braucht auf Samsung eine Einstellung, siehe `docs/samsung-einrichtung.md`.
