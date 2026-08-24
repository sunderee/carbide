# AGENTS.md

## Cursor Cloud specific instructions

Carbide is a Flutter package (an IBM Carbon Design System port). It contains two
Dart packages:

- Root package `carbide` (`lib/`) — the design-system library (the product).
- `example/` — `carbide_gallery`, a runnable Flutter app that showcases every
  component. It depends on the root package via a local `path: ../`.

These are two independent packages (no pub `workspace`), so dependencies must be
fetched in both (`flutter pub get` in the repo root and in `example/`). The
startup update script already does this.

### Toolchain

- CI and other workflows install the **latest Flutter stable** (no
  `flutter-version` pin). The SDK on this VM is at `~/flutter` and added to
  `PATH` via `~/.bashrc`. If `flutter` is not found in a non-login shell, run
  `export PATH="$HOME/flutter/bin:$PATH"`.
- Only the **web** and (headless) test toolchains are set up. The Android and
  Linux-desktop toolchains are intentionally not installed — the gallery only
  ships web/Android/iOS runners and the web target is the canonical demo.

### Running the gallery (dev mode)

From `example/`, serve it headlessly and open it in a browser:

```sh
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
```

First compile takes ~15-20s before `... is being served at http://0.0.0.0:8080`
appears; the page is blank until then. Use `-d chrome` instead if you want
Flutter to launch Chrome directly. Press `r` in the run session for hot reload.

### Lint / test / build

Standard commands are documented in `CONTRIBUTING.md` (`Local checks` and `CI`);
don't duplicate them here. Key non-obvious notes:

- Golden tests are **Linux-authoritative** (text goldens compare strictly on
  Linux, leniently elsewhere) — this VM is Linux, so golden failures here are
  real. Regenerate goldens via the `regenerate-goldens.yml` workflow, not by
  committing local macOS/Windows output.
- CI's icon-lockfile drift guards (`tool/*_lock.py`) need `python3`, which is
  preinstalled.
- The coverage gate is `dart run tool/coverage_gate.dart --floor 90` after
  `flutter test --coverage`.
- The `documentation/` git submodules are upstream Carbon reference sources and
  are **not** needed to build, run, or test.
