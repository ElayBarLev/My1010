import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/game_constants.dart';
import '../../domain/entities/shape.dart';
import '../layout/board_metrics.dart';
import 'shape_view.dart';

/// Payload carried from the tray to the board.
@immutable
class TrayDragData {
  const TrayDragData({required this.slot, required this.shape});

  final int slot;
  final Shape shape;
}

/// A tray piece that can be dragged onto the board.
///
/// Touch handling details:
/// * [Draggable] (not `LongPressDraggable`) starts on the very first move,
///   and the whole tray slot is the hit area ([HitTestBehavior.opaque]), so
///   small pieces are as easy to grab as big ones.
/// * The feedback is drawn at full board scale and anchored so its bottom
///   edge floats [GameConstants.dragLift] px above the finger.
/// * `feedbackOffset` moves the drag-target hit-test point from the finger
///   to the centre of the floating shape, so the board reacts to where the
///   piece *is*, not to where the finger is.
class DraggableShape extends StatelessWidget {
  const DraggableShape({
    super.key,
    required this.slot,
    required this.shape,
    required this.metrics,
    required this.color,
    required this.fits,
    this.trayScale = GameConstants.trayScale,
  });

  final int slot;
  final Shape shape;
  final BoardMetrics metrics;
  final Color color;

  /// Whether the piece can go anywhere; unplayable pieces are dimmed.
  final bool fits;

  /// Size of the resting piece relative to board cells.
  final double trayScale;

  @override
  Widget build(BuildContext context) {
    final size = metrics.shapeSize(shape);
    const lift = GameConstants.dragLift;

    return Draggable<TrayDragData>(
      data: TrayDragData(slot: slot, shape: shape),
      maxSimultaneousDrags: 1,
      hitTestBehavior: HitTestBehavior.opaque,
      dragAnchorStrategy: (_, _, _) =>
          Offset(size.width / 2, size.height + lift),
      feedbackOffset: Offset(0, -(size.height / 2 + lift)),
      onDragStarted: HapticFeedback.selectionClick,
      feedback: ShapeView(
        shape: shape,
        cellSize: metrics.cellSize,
        gap: metrics.gap,
        color: color,
      ),
      childWhenDragging: const SizedBox.expand(),
      child: SizedBox.expand(
        child: Center(
          child: AnimatedOpacity(
            opacity: fits ? 1 : 0.3,
            duration: const Duration(milliseconds: 200),
            child: ShapeView(
              shape: shape,
              cellSize: metrics.cellSize * trayScale,
              gap: metrics.gap * trayScale,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
