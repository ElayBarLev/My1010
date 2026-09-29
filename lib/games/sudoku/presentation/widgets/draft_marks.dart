import 'package:flutter/material.dart';

import '../../domain/sudoku_cell.dart';

/// Pencil marks laid out as a compact 3×3 keypad: 1 top-left, 9
/// bottom-right, each in its own slot so digits never shift around.
class DraftMarks extends StatelessWidget {
  const DraftMarks({
    super.key,
    required this.mask,
    required this.highlighted,
    required this.size,
    required this.color,
    required this.highlightColor,
  });

  /// [SudokuCell.draftMask].
  final int mask;

  /// The draft to emphasise (the active number), or 0.
  final int highlighted;

  /// The cell's side length.
  final double size;
  final Color color;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final slot = size / 3;
    return Wrap(
      children: [
        for (var n = 1; n <= 9; n++)
          SizedBox.square(
            dimension: slot,
            child: mask & SudokuCell.bit(n) == 0
                ? null
                : _Mark(
                    number: n,
                    slot: slot,
                    isHighlighted: n == highlighted,
                    color: color,
                    highlightColor: highlightColor,
                  ),
          ),
      ],
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({
    required this.number,
    required this.slot,
    required this.isHighlighted,
    required this.color,
    required this.highlightColor,
  });

  final int number;
  final double slot;
  final bool isHighlighted;
  final Color color;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      '$number',
      style: TextStyle(
        fontSize: slot * 0.78,
        height: 1,
        fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w500,
        color: isHighlighted ? highlightColor : color,
      ),
    );
    if (!isHighlighted) return Center(child: text);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlightColor.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Center(child: text),
    );
  }
}
