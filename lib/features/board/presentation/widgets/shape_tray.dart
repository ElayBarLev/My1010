import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../themes/presentation/theme_controller.dart';
import '../controllers/game_controller.dart';
import '../layout/board_metrics.dart';
import 'draggable_shape.dart';

/// The row of pieces waiting to be placed.
class ShapeTray extends ConsumerWidget {
  const ShapeTray({super.key, required this.metrics});

  final BoardMetrics metrics;

  static Key slotKey(int slot) => ValueKey('tray-slot-$slot');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final palette = ref.watch(paletteProvider);

    return Row(
      children: [
        for (var slot = 0; slot < game.tray.length; slot++)
          Expanded(
            key: slotKey(slot),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              // A used piece must vanish instantly (it is now on the board).
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
                    '${shape.id}-$slot-${game.moveCount ~/ game.tray.length}',
                  ),
                  slot: slot,
                  shape: shape,
                  metrics: metrics,
                  color: palette.blockColor(shape.colorSlot),
                  fits: game.board.canPlaceAnywhere(shape),
                ),
              },
            ),
          ),
      ],
    );
  }
}
