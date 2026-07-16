# AGENTS.md

## Cursor Cloud specific instructions

Patta Safar is a single offline Flutter/Dart mobile game (no backend, no database, no
external services). All game logic lives in `lib/main.dart`; unit tests live in
`test/hand_evaluator_test.dart`. Standard commands are documented in `README.md`.

### Toolchain
- The Flutter SDK (stable, includes Dart) is pre-installed at `~/flutter` and is added to
  `PATH` via `~/.bashrc`. In non-login shells it may not be on `PATH`; call it with the full
  path `~/flutter/bin/flutter` if `flutter`/`dart` are "command not found".
- The update script runs `flutter pub get` on startup to refresh pub dependencies.

### Running the app in the cloud VM
- There is no Android/iOS emulator here. Run the app as a Flutter **web** app and drive it
  with Chrome (installed at `/usr/local/bin/google-chrome`):
  `flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0`, then open
  `http://localhost:8080`. First web compile takes ~15-20s; the page is blank until then.
- Platform scaffolding (`android/`, `ios/`, `web/`, `linux/`) is generated locally via
  `flutter create` and is intentionally **not** committed. If those folders are missing on a
  fresh checkout, regenerate them once with:
  `flutter create --platforms=android,ios,web,linux .` (do not commit the output).
- `flutter create` also drops a default `test/widget_test.dart` counter smoke test that
  references a non-existent `MyApp` and will not compile against this app. Delete it after
  running `flutter create`; only `test/hand_evaluator_test.dart` is a real test.

### Lint / test
- Lint: `flutter analyze`
- Tests: `flutter test`
