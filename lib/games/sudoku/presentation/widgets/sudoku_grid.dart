import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui_kit/theme/theme_controller.dart';
import '../controllers/sudoku_controller.dart';
import 'sudoku_cell_view.dart';

/// The 9×9 board. Tap a cell to select it; drag across cells to select
/// several at once.
///
/// The grid itself never rebuilds during play: each [SudokuCellView]
/// watches its own slice of the state and sits behind its own
/// [RepaintBoundary], so entering a number repaints only the cells whose
/// look changed.
class SudokuGrid extends ConsumerStatefulWidget {
  const SudokuGrid({super.key, required this.side});

  /// Width and height in logical pixels.
  final double side;

  static const gridKey = ValueKey('sudoku-grid');

  @override
  ConsumerState<SudokuGrid> createState() => _SudokuGridState();
}

class _SudokuGridState extends ConsumerState<SudokuGrid> {
  final _boardKey = GlobalKey();
  Offset? _lastPanPosition;

  SudokuController get _controller =>
      ref.read(sudokuControllerProvider.notifier);

  /// Maps a global pointer position to a cell index, or `null` outside.
  int? _indexAt(Offset globalPosition) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final local = box.globalToLocal(globalPosition);
    final size = box.size;
    if (local.dx < 0 ||
        local.dy < 0 ||
        local.dx >= size.width ||
        local.dy >= size.height) {
      return null;
    }
    final row = (local.dy / size.height * 9).floor();
    final col = (local.dx / size.width * 9).floor();
    return row * 9 + col;
  }

  void _onTapDown(TapDownDetails details) {
    final index = _indexAt(details.globalPosition);
    if (index != null) _controller.select(index);
  }

  void _onPanStart(DragStartDetails details) {
    _lastPanPosition = details.globalPosition;
    final index = _indexAt(details.globalPosition);
    if (index != null) _controller.select(index);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final from = _lastPanPosition ?? details.globalPosition;
    final to = details.globalPosition;
    _lastPanPosition = to;
    // Fast swipes can jump over cells between two events: sample the
    // segment every third of a cell so none is skipped.
    final step = widget.side / 27;
    final steps = max(1, ((to - from).distance / step).ceil());
    for (var i = 1; i <= steps; i++) {
      final index = _indexAt(Offset.lerp(from, to, i / steps)!);
      if (index != null) _controller.extendSelection(index);
    }
  }

  void _onPanEnd() => _lastPanPosition = null;

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(paletteProvider);
    final cell = widget.side / 9;

    return RepaintBoundary(
      child: GestureDetector(
        key: SudokuGrid.gridKey,
        behavior: HitTestBehavior.opaque,
        // Report the pan from where the finger went down, so the first
        // cell of a drag is the one touched, not the one after the slop.
        dragStartBehavior: DragStartBehavior.down,
        onTapDown: _onTapDown,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: (_) => _onPanEnd(),
        onPanCancel: _onPanEnd,
        child: CustomPaint(
          key: _boardKey,
          size: Size.square(widget.side),
          foregroundPainter: _GridLinesPainter(
            thin: palette.emptyCell,
            thick: palette.textSecondary,
          ),
          child: SizedBox.square(
            dimension: widget.side,
            child: Column(
              children: [
                for (var row = 0; row < 9; row++)
                  Row(
                    children: [
                      for (var col = 0; col < 9; col++)
                        RepaintBoundary(
                          child: SudokuCellView(
                            index: row * 9 + col,
                            size: cell,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thin lines between cells, thick ones around the 3×3 blocks.
class _GridLinesPainter extends CustomPainter {
  const _GridLinesPainter({required this.thin, required this.thick});

  final Color thin;
  final Color thick;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 9;
    final thinPaint = Paint()
      ..color = thin
      ..strokeWidth = 1;
    final thickPaint = Paint()
      ..color = thick
      ..strokeWidth = 2;
    for (var i = 0; i <= 9; i++) {
      final paint = i % 3 == 0 ? thickPaint : thinPaint;
      final offset = (i * cell).clamp(1.0, size.width - 1);
      canvas
        ..drawLine(Offset(offset, 0), Offset(offset, size.height), paint)
        ..drawLine(Offset(0, offset), Offset(size.width, offset), paint);
    }
  }

  @override
  bool shouldRepaint(_GridLinesPainter old) =>
      old.thin != thin || old.thick != thick;
}
