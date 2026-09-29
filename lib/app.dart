import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_routes.dart';
import 'features/board/domain/entities/game_state.dart';
import 'features/board/presentation/controllers/game_controller.dart';
import 'features/board/presentation/pages/game_page.dart';
import 'features/leaderboard/presentation/leaderboard_page.dart';
import 'features/leaderboard/presentation/leaderboard_providers.dart';
import 'features/themes/presentation/theme_controller.dart';

class TenTenApp extends ConsumerWidget {
  const TenTenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Composition root: features don't know about each other, the app wires
    // "game ended" to "submit score".
    ref.listen<GameState>(gameControllerProvider, (previous, next) {
      if (next.isGameOver && !(previous?.isGameOver ?? false)) {
        ref
            .read(scoreSubmitterProvider)
            .submit(modeId: next.modeId, score: next.score);
      }
    });

    final palette = ref.watch(paletteProvider);
    return MaterialApp(
      title: '1010!',
      debugShowCheckedModeBanner: false,
      theme: palette.toThemeData(),
      initialRoute: AppRoutes.game,
      routes: {
        AppRoutes.game: (_) => const GamePage(),
        AppRoutes.leaderboard: (_) => const LeaderboardPage(),
      },
    );
  }
}
