// PLACEHOLDER — replace by running `flutterfire configure`.
//
// The FlutterFire CLI overwrites this file with the real per-platform
// options. Until then, [DefaultFirebaseOptions.currentPlatform] throws and
// `FirebaseBootstrap` falls back to the offline (in-memory) leaderboard.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase is not configured. Run `flutterfire configure` to generate '
      'lib/firebase_options.dart.',
    );
  }
}
