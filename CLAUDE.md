# Goalify – Hinweise für die nächste Sitzung

Flutter-App (Paketname `Goalify`) für Daily Tasks, Gym-Tracking, Fortschritt und Fokus-Timer. Alle Daten liegen lokal auf dem Gerät, ein Server wird nicht gebraucht. Der Ordner `backend/` ist nicht im Git und wird von der App nicht benutzt.

## Befehle

```bash
flutter pub get
flutter analyze                 # muss sauber sein (1 alter Hinweis in pomodoro_screen.dart:855 ist bekannt)
flutter test                    # widget_test.dart schlägt fehl (alter Template-Test, startet die App nicht), Rest grün
flutter gen-l10n                # nach jeder Änderung an lib/l10n/*.arb
flutter build apk --release     # kompiliert auch den Kotlin-Code
flutter build web               # für einen schnellen Blick im Browser, .claude/launch.json serviert build/web
```

Werkzeugstand: Flutter 3.50, AGP 9.3.1, Gradle 9.5.0, Built-in Kotlin (kein `kotlin-android`-Plugin in `android/app`), `compileSdk = 37` (permission_handler 13 verlangt das, `targetSdk` folgt weiter Flutter).

## Aufbau

```
lib/
  main.dart            App-Shell: MultiProvider, MainNav (Tabs: 0 Progress, 1 Daily, 2 Gym, 3 Functions)
  core/                feature-übergreifend
    i18n/              CurrentL10n (Texte ohne BuildContext, z. B. für Timer-Benachrichtigungen)
    models/            TimerLiveState
    services/          TimerLivePresentationService (Sperrbildschirm-Timer, siehe docs/live-timer.md)
    settings/          SettingsController (Theme, Sprache, Tagesbeginn, Pausen-Timer)
    utils/             DayCycle, LocalStorage, duration_format, ...
    widgets/           wiederverwendbare Widgets (ValueStepper, TimeWheelPicker, ...)
  features/<feature>/
    data/              datasources (einziger Ort mit Speicher-Keys), models, repositories (Impl)
    domain/            repositories (Interfaces), usecases (reine Logik, unit-getestet)
    presentation/      pages, widgets, controllers
  l10n/                app_en.arb (Vorlage), app_de.arb, app_ru.arb, generated/
android/ ios/          native Teile: Timer-Benachrichtigung, App-Blocker
docs/                  Feature-Dokus
test/                  Unit- und Widget-Tests
```

## Regeln, die im Projekt gelten

- **Schichten einhalten:** UI → Repository-Interface (`domain/repositories`) → Impl (`data/repositories`) → LocalDataSource. Nur die DataSource kennt Speicher-Keys und JSON.
- **Speicher-Keys** sind versioniert (`..._v1`). Ändert sich das Format, neuen Key nehmen und alten beim Laden migrieren (Beispiel: Tagesbeginn in `SettingsController.load`).
- **"Heute" immer über `DayCycle`** (`DayCycle.today()`, `DayCycle.dayOf(ts)`), nie `DateTime.now()` direkt vergleichen. Der Tag kann z. B. erst um 02:00 wechseln.
- **App-weite Controller** (alles, was einen Tab-Wechsel überleben muss) werden in `main.dart` per `ChangeNotifierProvider` angelegt. `MainNav` baut den aktiven Tab bei jedem Wechsel neu, State in einem Screen geht dabei verloren.
- **Texte** nur über `AppLocalizations` (de, en, ru pflegen). Ohne Context: `CurrentL10n.of`.
- **Fachlogik** gehört in `domain/usecases` als reine Klasse und bekommt Unit-Tests (Beispiele: `RestTracking`, `BestSetCache`).
- **Wiederverwenden statt kopieren:** Für Menüzeilen `OptionsMenuTile`, für "− Wert +" `ValueStepper`, für Zeitformate `core/utils/duration_format.dart`.
- **Commits:** englisch, Präfix im Stil `Feat(gym): ...`, `Fix(gym): ...`, `Chore(deps): ...`. Keine Co-Authored-By-Zeile.

## Stolperfallen

- `lib/features/gym/presentation/pages/gym_screen.dart` hat über 5000 Zeilen. Gezielt per Suche springen, nicht ganz lesen. Neue Logik lieber in eigene Dateien (usecases, widgets, controllers) legen.
- Einige Dateien beginnen mit einem UTF-8-BOM (`gym_screen.dart`, alle `.arb`). Beim Bearbeiten per Skript erhalten, beim JSON-Parsen `utf-8-sig` nutzen.
- Der native Sperrbildschirm zeigt **einen** Timer gleichzeitig. Wer einen neuen Timer anbindet, liest vorher `docs/live-timer.md` (Vorrang-Regel, `timerId` bei pause/stop/finish mitgeben).
- iOS wurde in dieser Umgebung nie kompiliert (kein Mac). Änderungen an `ios/Runner/*.swift` sind ungetestet, bis jemand auf einem Mac baut.

## Feature-Dokus

- [docs/pausen-timer.md](docs/pausen-timer.md) – Pausen-Timer zwischen Sätzen, Satz-Haken, Pausen-Statistik
- [docs/live-timer.md](docs/live-timer.md) – Timer auf dem Sperrbildschirm (Dart ↔ Android/iOS)
- [docs/samsung-einrichtung.md](docs/samsung-einrichtung.md) – Handy-Einstellungen für Samsung
