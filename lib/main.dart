import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/storage/shared_preferences_provider.dart';
import 'features/leaderboard/data/firestore_leaderboard_repository.dart';
import 'features/leaderboard/presentation/leaderboard_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final firebaseReady = await FirebaseBootstrap.initialize();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (firebaseReady)
          leaderboardRepositoryProvider.overrideWith(
            (ref) => FirestoreLeaderboardRepository(
              firestore: FirebaseFirestore.instance,
              auth: FirebaseAuth.instance,
            ),
          ),
      ],
      child: const TenTenApp(),
    ),
  );
}
