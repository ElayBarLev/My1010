import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui_kit/theme/theme_controller.dart';
import '../controllers/game_controller.dart';
import '../layout/board_metrics.dart';
import 'draggable_shape.dart';

/// The row of pieces waiting to be placed. Fills whatever space it is given:
/// each of the slots is an equal column, and pieces are scaled to fit.
class ShapeTray extends ConsumerWidget {
  const ShapeTray({super.key, required this.metrics});

  final BoardMetrics metrics;

  static Key slotKey(int slot) => ValueKey('tray-slot-$slot');

  /// Largest piece extent (in cells) a slot must accommodate, plus padding.
  static const double _cellsPerSlot = 5.6;

  /// Tray pieces never look bigger than this fraction of a board cell.
  static const double _maxScale = 0.8;

  /// One shared scale for every slot, so all pieces look consistent: the
  /// longest piece (5 cells) must fit a slot's width and the tray's height.
  static double trayScaleFor(Size area, BoardMetrics metrics, int slots) {
    final slotWidth = area.width / slots;
    final fitPitch = min(slotWidth, area.height) / _cellsPerSlot;
    return min(fitPitch / metrics.pitch, _maxScale);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final palette = ref.watch(paletteProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = trayScaleFor(
          constraints.biggest,
          metrics,
          game.tray.length,
        );
        return Row(
          children: [
            for (var slot = 0; slot < game.tray.length; slot++)
              Expanded(
                key: slotKey(slot),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  // A used piece must vanish instantly (it is on the board).
                  reverseDuration: Duration.zero,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: switch (game.tray[slot]) {
                    null => const SizedBox.expand(),
                    final shape => DraggableShape(
                      // Keyed per deal so a refilled tray animates in.
                      key: ValueKey(
                        '${shape.id}-$slot-'
                        '${game.moveCount ~/ game.tray.length}',
                      ),
                      slot: slot,
                      shape: shape,
                      metrics: metrics,
                      trayScale: scale,
                      color: palette.blockColor(shape.colorSlot),
                      fits: game.board.canPlaceAnywhere(shape),
                    ),
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
