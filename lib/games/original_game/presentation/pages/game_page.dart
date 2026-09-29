import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui_kit/theme/theme_controller.dart';
import '../controllers/game_controller.dart';
import '../layout/board_metrics.dart';
import '../widgets/board_grid.dart';
import '../widgets/game_over_overlay.dart';
import '../widgets/score_display.dart';
import '../widgets/score_header.dart';
import '../widgets/shape_tray.dart';

class GamePage extends ConsumerWidget {
  const GamePage({super.key, this.gameOverExtra});

  /// Extra content for the game-over overlay (see [GameOverOverlay.extra]).
  final Widget? gameOverExtra;

  /// Largest board side on tablets / desktop windows.
  static const double maxBoardSide = 520;

  static const double headerHeight = 48;
  static const double scoreHeight = 76;

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
            final width = constraints.maxWidth;
            // Space left for board + tray once the fixed rows are laid out.
            final available =
                constraints.maxHeight - headerHeight - scoreHeight;
            // The board takes the width, but never so much height that the
            // tray gets less than about a third of the free space.
            final side = min(min(width - 24, available * 0.66), maxBoardSide);
            final metrics = BoardMetrics(side: side, size: boardSize);

            return Stack(
              children: [
                Column(
                  children: [
                    SizedBox(
                      height: headerHeight,
                      child: ScoreHeader(
                        onRestart: () => _confirmRestart(context, ref),
                      ),
                    ),
                    const SizedBox(height: scoreHeight, child: ScoreDisplay()),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette.boardBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: BoardGrid(metrics: metrics),
                    ),
                    // The tray uses all the remaining space below the board.
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          width: side + 8,
                          child: ShapeTray(metrics: metrics),
                        ),
                      ),
                    ),
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
