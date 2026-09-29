import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../themes/presentation/theme_controller.dart';
import '../controllers/game_controller.dart';

/// Shown when no remaining piece fits.
class GameOverOverlay extends ConsumerWidget {
  const GameOverOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    final game = ref.watch(gameControllerProvider);
    final isNewBest = game.score > 0 && game.score >= game.bestScore;

    return ColoredBox(
      color: palette.background.withValues(alpha: 0.88),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'No more space',
              style: TextStyle(
                color: palette.textSecondary,
                fontSize: 18,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${game.score}',
              style: TextStyle(
                color: palette.accent,
                fontSize: 64,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              isNewBest ? 'New best!' : 'Best ${game.bestScore}',
              style: TextStyle(color: palette.textPrimary, fontSize: 16),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              key: const ValueKey('play-again'),
              onPressed: ref.read(gameControllerProvider.notifier).restart,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Play again'),
              style: FilledButton.styleFrom(
                backgroundColor: palette.accent,
                foregroundColor: palette.background,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.leaderboard),
              style: TextButton.styleFrom(foregroundColor: palette.textPrimary),
              child: const Text('Leaderboard'),
            ),
          ],
        ),
      ),
    );
  }
}
