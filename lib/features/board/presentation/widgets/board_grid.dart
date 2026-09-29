import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/game_constants.dart';
import '../../../themes/presentation/theme_controller.dart';
import '../../domain/entities/game_state.dart';
import '../../domain/game_engine.dart';
import '../controllers/game_controller.dart';
import '../layout/board_metrics.dart';
import 'block_tile.dart';
import 'draggable_shape.dart';

/// The 10×10 grid and the drop target for tray pieces.
///
/// While a piece hovers, a ghost shows where it will land and the lines it
/// would complete light up in its colour.
class BoardGrid extends ConsumerStatefulWidget {
  const BoardGrid({super.key, required this.metrics});

  final BoardMetrics metrics;

  @override
  ConsumerState<BoardGrid> createState() => _BoardGridState();
}

class _BoardGridState extends ConsumerState<BoardGrid> {
  PlacementPreview? _preview;

  BoardMetrics get _metrics => widget.metrics;

  /// Converts the dragged feedback's global top-left into a board origin.
  PlacementPreview? _previewFor(DragTargetDetails<TrayDragData> details) {
    final box = context.findRenderObject()! as RenderBox;
    final origin = _metrics.nearestOrigin(box.globalToLocal(details.offset));
    return ref
        .read(gameControllerProvider.notifier)
        .preview(details.data.slot, origin);
  }

  void _onMove(DragTargetDetails<TrayDragData> details) {
    final next = _previewFor(details);
    // Only rebuild when the snapped cell actually changes.
    if (next?.origin == _preview?.origin && next?.slot == _preview?.slot) {
      return;
    }
    setState(() => _preview = next);
  }

  void _onAccept(DragTargetDetails<TrayDragData> details) {
    final preview = _previewFor(details);
    setState(() => _preview = null);
    if (preview == null) return;
    final placed = ref
        .read(gameControllerProvider.notifier)
        .place(preview.slot, preview.origin);
    if (placed) HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider);
    final palette = ref.watch(paletteProvider);
    final board = game.board;
    final preview = _preview;
    final previewColor = preview == null
        ? null
        : palette.blockColor(preview.colorSlot);

    return DragTarget<TrayDragData>(
      onWillAcceptWithDetails: (_) => !game.isGameOver,
      onMove: _onMove,
      onLeave: (_) {
        if (_preview != null) setState(() => _preview = null);
      },
      onAcceptWithDetails: _onAccept,
      builder: (context, _, _) => SizedBox.square(
        dimension: _metrics.side,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: board.size,
            mainAxisSpacing: _metrics.gap,
            crossAxisSpacing: _metrics.gap,
          ),
          itemCount: board.size * board.size,
          itemBuilder: (context, index) {
            final slot = board.cells[index];
            final isGhost = preview?.cells.contains(index) ?? false;
            final willClear = preview?.clearingCells.contains(index) ?? false;
            Color color;
            if (isGhost) {
              // The dragged piece: solid if it completes a line, else a ghost.
              color = willClear
                  ? previewColor!
                  : previewColor!.withValues(alpha: 0.45);
            } else if (slot != null) {
              // Existing blocks keep their own colour; blocks about to be
              // cleared are lightened slightly as a hint.
              color = willClear
                  ? Color.lerp(palette.blockColor(slot), Colors.white, 0.3)!
                  : palette.blockColor(slot);
            } else {
              color = palette.emptyCell;
            }
            return _BoardCell(
              key: ValueKey(index),
              index: index,
              color: color,
              size: _metrics.cellSize,
              move: game.lastMove,
              boardSize: board.size,
              clearedColor: game.lastMove?.clearedCells[index] == null
                  ? null
                  : palette.blockColor(game.lastMove!.clearedCells[index]!),
            );
          },
        ),
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    super.key,
    required this.index,
    required this.color,
    required this.size,
    required this.move,
    required this.boardSize,
    required this.clearedColor,
  });

  final int index;
  final Color color;
  final double size;
  final MoveEvent? move;
  final int boardSize;
  final Color? clearedColor;

  @override
  Widget build(BuildContext context) {
    Widget tile = BlockTile(color: color, size: size);
    final move = this.move;
    if (move == null) return tile;

    if (clearedColor != null) {
      tile = Stack(
        children: [
          tile,
          _ClearBurst(
            key: ValueKey('clear-${move.sequence}'),
            color: clearedColor!,
            size: size,
            delay: _staggerFraction(move),
          ),
        ],
      );
    } else if (move.placedCells.contains(index)) {
      tile = TweenAnimationBuilder<double>(
        key: ValueKey('pop-${move.sequence}'),
        tween: Tween(begin: 0.82, end: 1),
        duration: GameConstants.placeAnimation,
        curve: Curves.easeOutBack,
        builder: (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: tile,
      );
    }
    return tile;
  }

  /// Cells closer to the placed piece vanish first, giving a ripple that
  /// travels outward along the cleared lines.
  double _staggerFraction(MoveEvent move) {
    final row = index ~/ boardSize;
    final col = index % boardSize;
    var nearest = boardSize * 2;
    for (final p in move.placedCells) {
      final d = (p ~/ boardSize - row).abs() + (p % boardSize - col).abs();
      if (d < nearest) nearest = d;
    }
    return (nearest.clamp(0, boardSize) / boardSize) * 0.45;
  }
}

/// A cleared block shrinking and fading out in its original colour.
class _ClearBurst extends StatelessWidget {
  const _ClearBurst({
    super.key,
    required this.color,
    required this.size,
    required this.delay,
  });

  final Color color;
  final double size;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final curve = Interval(delay, delay + 0.55, curve: Curves.easeInCubic);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: GameConstants.clearAnimation,
      builder: (_, t, child) {
        final progress = curve.transform(t);
        if (progress >= 1) return const SizedBox.shrink();
        return Opacity(
          opacity: 1 - progress,
          child: Transform.scale(scale: 1 - 0.5 * progress, child: child),
        );
      },
      child: BlockTile(color: color, size: size),
    );
  }
}
