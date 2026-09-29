import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui_kit/theme/theme_controller.dart';
import '../../domain/sudoku_board.dart';
import '../controllers/sudoku_controller.dart';
import 'draft_marks.dart';

/// Everything one cell needs to paint. Cells watch only their own slice of
/// the state, so a keystroke rebuilds just the cells whose look changed.
@immutable
class SudokuCellViewData {
  const SudokuCellViewData({
    required this.value,
    required this.isGiven,
    required this.isError,
    required this.draftMask,
    required this.isSelected,
    required this.isPeerOfSelection,
    required this.matchesActiveNumber,
    required this.highlightedDraft,
  });

  factory SudokuCellViewData.of(SudokuState state, int index) {
    // Selectors still run once when the board goes away (new puzzle),
    // before the cells unmount.
    final board = state.board;
    if (board == null) return empty;
    final cell = board[index];
    final selected = state.selectedIndices;
    final active = state.activeNumber;
    return SudokuCellViewData(
      value: cell.enteredValue,
      isGiven: cell.isGiven,
      isError: cell.isError,
      draftMask: cell.draftMask,
      isSelected: selected.contains(index),
      isPeerOfSelection:
          selected.length == 1 &&
          SudokuBoard.peers[selected.first].contains(index),
      matchesActiveNumber: active != null && cell.enteredValue == active,
      highlightedDraft: active != null && cell.isEmpty && cell.hasDraft(active)
          ? active
          : 0,
    );
  }

  static const empty = SudokuCellViewData(
    value: 0,
    isGiven: false,
    isError: false,
    draftMask: 0,
    isSelected: false,
    isPeerOfSelection: false,
    matchesActiveNumber: false,
    highlightedDraft: 0,
  );

  final int value;
  final bool isGiven;
  final bool isError;
  final int draftMask;
  final bool isSelected;

  /// Shares a row, column or block with the single selected cell.
  final bool isPeerOfSelection;

  /// Shows the number currently highlighted across the grid.
  final bool matchesActiveNumber;

  /// The draft equal to the active number (0 when none), drawn emphasised.
  final int highlightedDraft;

  @override
  bool operator ==(Object other) =>
      other is SudokuCellViewData &&
      other.value == value &&
      other.isGiven == isGiven &&
      other.isError == isError &&
      other.draftMask == draftMask &&
      other.isSelected == isSelected &&
      other.isPeerOfSelection == isPeerOfSelection &&
      other.matchesActiveNumber == matchesActiveNumber &&
      other.highlightedDraft == highlightedDraft;

  @override
  int get hashCode => Object.hash(
    value,
    isGiven,
    isError,
    draftMask,
    isSelected,
    isPeerOfSelection,
    matchesActiveNumber,
    highlightedDraft,
  );
}

class SudokuCellView extends ConsumerWidget {
  const SudokuCellView({super.key, required this.index, required this.size});

  final int index;

  /// Side length in logical pixels.
  final double size;

  static ValueKey<String> keyFor(int index) => ValueKey('sudoku-cell-$index');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(
      sudokuControllerProvider.select((s) => SudokuCellViewData.of(s, index)),
    );
    final palette = ref.watch(paletteProvider);
    final errorColor = Theme.of(context).colorScheme.error;

    final Color background;
    if (data.isSelected) {
      background = Color.lerp(palette.boardBackground, palette.accent, 0.42)!;
    } else if (data.matchesActiveNumber) {
      background = Color.lerp(palette.boardBackground, palette.accent, 0.22)!;
    } else if (data.isPeerOfSelection) {
      background = Color.lerp(palette.boardBackground, palette.accent, 0.08)!;
    } else {
      background = palette.boardBackground;
    }

    final Widget content;
    if (data.value != 0) {
      content = Center(
        child: Text(
          '${data.value}',
          style: TextStyle(
            fontSize: size * 0.58,
            height: 1,
            fontWeight: data.isGiven ? FontWeight.w700 : FontWeight.w500,
            color: data.isError
                ? errorColor
                : data.isGiven
                ? palette.textPrimary
                : palette.accent,
          ),
        ),
      );
    } else if (data.draftMask != 0) {
      content = DraftMarks(
        mask: data.draftMask,
        highlighted: data.highlightedDraft,
        size: size,
        color: palette.textSecondary,
        highlightColor: palette.accent,
      );
    } else {
      content = const SizedBox.shrink();
    }

    return ColoredBox(
      key: keyFor(index),
      color: background,
      child: SizedBox.square(dimension: size, child: content),
    );
  }
}
