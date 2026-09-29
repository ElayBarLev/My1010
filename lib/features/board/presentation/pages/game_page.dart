import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/game_constants.dart';
import '../../../themes/presentation/theme_controller.dart';
import '../controllers/game_controller.dart';
import '../layout/board_metrics.dart';
import '../widgets/board_grid.dart';
import '../widgets/game_over_overlay.dart';
import '../widgets/score_header.dart';
import '../widgets/shape_tray.dart';

class GamePage extends ConsumerWidget {
  const GamePage({super.key, this.gameOverExtra});

  /// Extra content for the game-over overlay (see [GameOverOverlay.extra]).
  final Widget? gameOverExtra;

  /// Largest board side on tablets / desktop windows.
  static const double maxBoardSide = 520;

  Future<void> _confirmRestart(BuildContext context, WidgetRef ref) async {
    final game = ref.read(gameControllerProvider);
    final controller = ref.read(gameControllerProvider.notifier);
    if (game.moveCount == 0 || game.isGameOver) {
      controller.restart();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start over?'),
        content: const Text('Your current game will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) controller.restart();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    final boardSize = ref.watch(gameModeProvider).boardSize;
    final isGameOver = ref.watch(
      gameControllerProvider.select((s) => s.isGameOver),
    );

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = min(
              min(constraints.maxWidth - 32, constraints.maxHeight * 0.6),
              maxBoardSide,
            );
            final metrics = BoardMetrics(side: side, size: boardSize);
            // Tall enough for a 5-cell piece at tray scale, plus breathing room.
            final trayHeight = metrics.pitch * 5 * GameConstants.trayScale + 32;

            return Stack(
              children: [
                Column(
                  children: [
                    ScoreHeader(onRestart: () => _confirmRestart(context, ref)),
                    Expanded(
                      child: Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: palette.boardBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: BoardGrid(metrics: metrics),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: trayHeight,
                      width: min(constraints.maxWidth, maxBoardSide + 32),
                      child: ShapeTray(metrics: metrics),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !isGameOver,
                    child: AnimatedOpacity(
                      opacity: isGameOver ? 1 : 0,
                      duration: const Duration(milliseconds: 350),
                      child: isGameOver
                          ? GameOverOverlay(extra: gameOverExtra)
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
