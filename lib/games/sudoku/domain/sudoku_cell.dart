import 'package:meta/meta.dart';

/// One square of the 9×9 grid.
///
/// Pencil marks ("drafts") are a bitmask: bit `n` (1-9) is set when `n` is
/// noted as a candidate, so bit 0 is always clear and a full set of
/// candidates is [allDrafts].
@immutable
class SudokuCell {
  const SudokuCell({
    required this.row,
    required this.col,
    required this.correctValue,
    this.enteredValue = 0,
    this.draftMask = 0,
    this.isGiven = false,
    this.isError = false,
  });

  final int row;
  final int col;

  /// The value in the puzzle's unique solution (1-9).
  final int correctValue;

  /// The player's value (0 when empty). Givens hold their clue here.
  final int enteredValue;

  final int draftMask;

  /// A clue from the puzzle; can't be edited.
  final bool isGiven;

  /// Whether [enteredValue] duplicates a value in its row, column or block.
  final bool isError;

  /// Every candidate 1-9 noted.
  static const int allDrafts = 0x3FE;

  /// The [draftMask] bit of [number]; throws unless it is 1-9.
  static int bit(int number) {
    RangeError.checkValueInInterval(number, 1, 9, 'number');
    return 1 << number;
  }

  int get index => row * 9 + col;

  /// The 3×3 block, numbered 0-8 left to right, top to bottom.
  int get block => row ~/ 3 * 3 + col ~/ 3;

  bool get isEmpty => enteredValue == 0;

  bool get isEditable => !isGiven;

  bool get isCorrect => enteredValue == correctValue;

  bool hasDraft(int number) => draftMask & bit(number) != 0;

  /// The noted candidates in ascending order.
  List<int> get drafts => [
    for (var n = 1; n <= 9; n++)
      if (hasDraft(n)) n,
  ];

  SudokuCell withDraft(int number) =>
      copyWith(draftMask: draftMask | bit(number));

  SudokuCell withoutDraft(int number) =>
      copyWith(draftMask: draftMask & ~bit(number));

  SudokuCell copyWith({int? enteredValue, int? draftMask, bool? isError}) =>
      SudokuCell(
        row: row,
        col: col,
        correctValue: correctValue,
        enteredValue: enteredValue ?? this.enteredValue,
        draftMask: draftMask ?? this.draftMask,
        isGiven: isGiven,
        isError: isError ?? this.isError,
      );

  @override
  bool operator ==(Object other) =>
      other is SudokuCell &&
      other.row == row &&
      other.col == col &&
      other.correctValue == correctValue &&
      other.enteredValue == enteredValue &&
      other.draftMask == draftMask &&
      other.isGiven == isGiven &&
      other.isError == isError;

  @override
  int get hashCode => Object.hash(
    row,
    col,
    correctValue,
    enteredValue,
    draftMask,
    isGiven,
    isError,
  );

  @override
  String toString() =>
      'SudokuCell($row,$col: ${isGiven ? 'given ' : ''}$enteredValue'
      '${draftMask == 0 ? '' : ' drafts $drafts'}${isError ? ' error' : ''})';
}
