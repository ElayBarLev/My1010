import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Initializes Firebase if the project has been configured.
///
/// Returns `false` (instead of throwing) when `lib/firebase_options.dart` is
/// still the placeholder or the platform isn't configured, so the game keeps
/// working fully offline with the in-memory leaderboard.
abstract final class FirebaseBootstrap {
  static Future<bool> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      return true;
    } catch (error) {
      debugPrint('Firebase unavailable, using offline leaderboard: $error');
      return false;
    }
  }
}
