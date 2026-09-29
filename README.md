# ten_ten_clone — a 2016-style 1010! puzzle

A minimalist, ad-free clone of the original **1010!** block puzzle, built with
Flutter, Riverpod, SharedPreferences and Firebase (Firestore + Auth).

Drag pieces onto the 10×10 board. Fill a row or column to clear it. The game
ends when none of the three pieces fit anywhere.

## Features

- **Headless game engine**: pure Dart, no Flutter imports, fully unit-tested.
- **The 19 standard pieces** (dot, lines 2–5 in both orientations, 2×2 and 3×3
  squares, small and large corners in all rotations), with weighted spawning.
- **Classic scoring**: 1 point per placed cell, plus a line bonus of
  `10·n(n+1)/2` (1 line = 10, 2 = 30, 3 = 60, …).
- **Touch handling**: drags start on the first move, the whole tray slot is
  grabbable, and the piece floats 64 px above your finger at full board scale.
  The drop target hit-tests at the piece's centre (not the finger), so
  bottom-row drops work naturally. Cells snap to the nearest grid position.
- **Hover ghost**: a preview of where the piece lands, and the lines it would
  clear light up in its colour.
- **Animations**: placed cells pop in; cleared cells shrink and fade in a ripple
  that spreads out from the placed piece.
- **4 themes**: Classic 2016, Neon, Pastel, Solarized Dark. Each has a colour
  for every piece family, and the choice is saved.
- **Save state**: every move is saved, so the game survives an app kill. The
  local best score is stored per mode.
- **Global leaderboard**: Firestore with anonymous auth. If Firebase isn't
  configured, the app falls back to an offline in-memory leaderboard
  automatically.

## Architecture

Feature-first clean architecture: each feature has `domain` (pure logic),
`data` (IO) and `presentation` (Riverpod + widgets).

```
lib/
├── main.dart                      # bootstrap: prefs, Firebase (graceful), ProviderScope
├── app.dart                       # MaterialApp + composition root (game over → submit score)
├── firebase_options.dart          # placeholder, replaced by `flutterfire configure`
├── core/
│   ├── constants/game_constants.dart
│   ├── firebase/firebase_bootstrap.dart
│   ├── routing/app_routes.dart
│   └── storage/shared_preferences_provider.dart
└── features/
    ├── board/
    │   ├── domain/                # ← headless engine, no Flutter
    │   │   ├── entities/          # Board, Shape, ShapeCatalog, GridPoint, GameState
    │   │   ├── services/          # ShapeGenerator, ScoringRules
    │   │   ├── game_mode.dart     # GameMode + registry (extension point)
    │   │   └── game_engine.dart   # place / preview / newGame
    │   ├── data/game_state_repository.dart
    │   └── presentation/          # GameController, BoardGrid (DragTarget), DraggableShape, …
    ├── themes/                    # GamePalette, 4 palettes, PaletteController, picker sheet
    └── leaderboard/               # LeaderboardRepository, Firestore + in-memory impls, page
```

### Adding a game mode

Everything mode-specific lives on `GameMode`
(`lib/features/board/domain/game_mode.dart`):

```dart
class MiniMode extends GameMode {
  const MiniMode();
  @override String get id => 'mini';
  @override String get displayName => 'Mini 8×8';
  @override int get boardSize => 8;
  @override ScoringRules get scoring => const ClassicScoring(pointsPerLine: 15);
}
```

Then add it to `GameModes.all` and override `gameModeProvider`, for example
from a mode picker. The engine, save slots (`game.<id>.save`), best scores and
leaderboard buckets (`leaderboards/<id>/scores`) are all keyed by the mode, so
nothing else needs to change. For custom rules, override `isGameOver`,
`createShapeGenerator` or `catalog`.

## Getting started

```bash
git clone https://github.com/ElayBarLev/My1010.git && cd My1010
flutter pub get
flutter run            # Android / iOS / web (Chrome)
flutter test           # unit + widget tests
flutter analyze
```

Requires Flutter 3.47.5 (stable, Dart 3.13) or newer.

- **CI** (`.github/workflows/ci.yml`) runs the format check, analyze and tests
  on every push and PR.
- **Web deploy** (`.github/workflows/deploy-web.yml`) publishes the game to
  GitHub Pages on every push to `main`. It's a one-time switch: repo
  **Settings → Pages → Source: GitHub Actions**. The game will then be at
  `https://elaybarlev.github.io/My1010/`.
- **Claude Code on the web**: `.claude/hooks/session-start.sh` installs Flutter
  automatically in cloud sessions.

## Android

**Quick test (USB):** enable Developer options → USB debugging on the phone,
plug it in, then run `flutter devices` and `flutter run --release`.

**Auto-updating installs (Obtainium):** `.github/workflows/release-android.yml`
builds a signed APK and publishes it as a GitHub Release whenever you push a
`v*` tag, e.g. `git tag v1.0.1 && git push origin v1.0.1`. You can also run it
manually from the Actions tab. On the phone, install
[Obtainium](https://github.com/ImranR98/Obtainium) and add
`https://github.com/ElayBarLev/My1010`; it installs and updates from those
releases.

The official F-Droid repository doesn't accept apps that use Firebase
(proprietary Google libraries), so Obtainium is the simplest way to get
F-Droid-style updates.

One-time signing setup. Every update must be signed with the same key, so
keep a backup of the `.jks` file:

```powershell
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
```

Then add these repo secrets under Settings → Secrets and variables → Actions:
`ANDROID_KEYSTORE_BASE64` (paste the clipboard), `ANDROID_KEYSTORE_PASSWORD`,
`ANDROID_KEY_ALIAS` (`upload`) and `ANDROID_KEY_PASSWORD`.

For signed release builds on your own machine, create
`android/key.properties` (git-ignored) containing `storeFile`,
`storePassword`, `keyAlias` and `keyPassword`.

## Online leaderboard (Firebase)

**Where things run:** GitHub stores the code and can host the *web build*
(GitHub Pages), but it can't run a database. The leaderboard data lives in
**Firebase (Cloud Firestore)**, which is Google's hosted service: it's always
online, with no server for you to keep running. The free **Spark** plan
(50k reads and 20k writes per day) is plenty for this game.

**No login for players:** the app signs each device in with Firebase
*Anonymous Auth*, which is invisible to the player. They only type a name,
on the game-over screen or on the leaderboard page. The anonymous id is
what lets `firestore.rules` guarantee a player can only write their own
entry, and that scores only go up.

Until Firebase is configured, the app runs with an offline, on-device
leaderboard and shows an "Offline mode" notice.

### One-time setup (about 10 minutes)

1. Create a project at <https://console.firebase.google.com> (Analytics not
   needed).
2. In the console (the left menu no longer has a "Build" section; use the
   search box or these URLs):
   - `https://console.firebase.google.com/project/<project-id>/firestore`:
     **Create database** (Standard edition, production mode, pick a region
     close to your players).
   - `https://console.firebase.google.com/project/<project-id>/authentication/providers`:
     **Anonymous → Enable → Save**.
   - `https://console.firebase.google.com/project/<project-id>/authentication/settings`:
     **Authorized domains → Add domain** `elaybarlev.github.io` (needed for
     the GitHub Pages build).
3. On your machine (Flutter 3.47+ required; run `flutter upgrade` first):
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   firebase login
   flutterfire configure --project=<your-project-id> --platforms=android,ios,web
   firebase use <your-project-id>
   firebase deploy --only firestore        # security rules + indexes
   ```
   On Windows, if `flutterfire` isn't recognized, add
   `%LOCALAPPDATA%\Pub\Cache\bin` to PATH, or run it as
   `dart pub global run flutterfire_cli:flutterfire configure ...`.
4. Commit the generated files, which are not secrets: Firebase client keys
   are public identifiers, and access is enforced by `firestore.rules`.
   ```bash
   git add lib/firebase_options.dart android/app/google-services.json \
           ios/Runner/GoogleService-Info.plist firebase.json
   git commit -m "chore: configure Firebase"
   git push
   ```
   Every build, including the GitHub Pages site, now uses the online
   leaderboard.

**Data model:** `leaderboards/{modeId}/scores/{uid}` holds
`{uid, displayName, score, modeId, updatedAt}`, one document per player per
mode storing their best score. The rules validate the shape, cap names at 20
characters, and only allow the score to go up.
