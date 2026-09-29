import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import '../../data/puzzle_source.dart';
import '../../domain/sudoku_board.dart';
import '../../domain/sudoku_cell.dart';
import '../../domain/sudoku_difficulty.dart';

/// What the number pad does: write values, or toggle pencil marks.
enum InputMode { normal, draft }

enum SudokuPhase { choosingDifficulty, generating, playing, solved, failed }

@immutable
class SudokuState {
  const SudokuState({
    this.phase = SudokuPhase.choosingDifficulty,
    this.difficulty,
    this.board,
    this.selectedIndices = const {},
    this.inputMode = InputMode.normal,
    this.activeNumber,
    this.canUndo = false,
    this.errorMessage,
  });

  final SudokuPhase phase;
  final SudokuDifficulty? difficulty;

  /// The 81 cells; `null` until a puzzle has been generated.
  final SudokuBoard? board;

  /// Selected cell indices (row * 9 + col); several when drag-selecting.
  final Set<int> selectedIndices;

  final InputMode inputMode;

  /// The number being highlighted across the grid (1-9), if any.
  final int? activeNumber;

  final bool canUndo;
  final String? errorMessage;

  bool get isPlaying => phase == SudokuPhase.playing;

  SudokuState copyWith({
    SudokuPhase? phase,
    SudokuBoard? board,
    Set<int>? selectedIndices,
    InputMode? inputMode,
    int? Function()? activeNumber,
    bool? canUndo,
  }) => SudokuState(
    phase: phase ?? this.phase,
    difficulty: difficulty,
    board: board ?? this.board,
    selectedIndices: selectedIndices ?? this.selectedIndices,
    inputMode: inputMode ?? this.inputMode,
    activeNumber: activeNumber == null ? this.activeNumber : activeNumber(),
    canUndo: canUndo ?? this.canUndo,
    errorMessage: errorMessage,
  );
}

/// Kept alive while the app runs, so leaving and re-entering Sudoku keeps
/// the current puzzle.
final sudokuControllerProvider =
    NotifierProvider<SudokuController, SudokuState>(SudokuController.new);

class SudokuController extends Notifier<SudokuState> {
  static const int maxUndo = 200;

  final List<SudokuBoard> _history = [];

  /// Bumped per request so a slow generation can't overwrite a newer one.
  int _request = 0;

  @override
  SudokuState build() => const SudokuState();

  Future<void> newGame(SudokuDifficulty difficulty) async {
    final request = ++_request;
    _history.clear();
    state = SudokuState(phase: SudokuPhase.generating, difficulty: difficulty);
    try {
      final puzzle = await ref
          .read(sudokuPuzzleSourceProvider)
          .generate(difficulty);
      if (!ref.mounted || request != _request) return;
      state = SudokuState(
        phase: SudokuPhase.playing,
        difficulty: difficulty,
        board: SudokuBoard.fromPuzzle(puzzle),
      );
    } on Object catch (error) {
      if (!ref.mounted || request != _request) return;
      state = SudokuState(
        phase: SudokuPhase.failed,
        difficulty: difficulty,
        errorMessage: '$error',
      );
    }
  }

  /// Back to the difficulty picker (abandons any running generation).
  void chooseDifficulty() {
    _request++;
    _history.clear();
    state = const SudokuState();
  }

  /// Selects only [index]; its number (if any) becomes the active one.
  void select(int index) {
    final board = state.board;
    if (!state.isPlaying || board == null) return;
    final value = board[index].enteredValue;
    state = state.copyWith(
      selectedIndices: {index},
      activeNumber: () => value == 0 ? null : value,
    );
  }

  /// Adds [index] to the selection (drag-selecting).
  void extendSelection(int index) {
    if (!state.isPlaying || state.selectedIndices.contains(index)) return;
    state = state.copyWith(selectedIndices: {...state.selectedIndices, index});
  }

  void clearSelection() {
    if (state.selectedIndices.isEmpty) return;
    state = state.copyWith(selectedIndices: const {});
  }

  void toggleInputMode() => state = state.copyWith(
    inputMode: state.inputMode == InputMode.normal
        ? InputMode.draft
        : InputMode.normal,
  );

  /// Applies [number] to the selection: writes it (clearing it from peer
  /// drafts) in normal mode, toggles the pencil mark in draft mode. With
  /// nothing selected it just toggles which number is highlighted.
  void enterNumber(int number) {
    SudokuCell.bit(number); // validates the range
    final board = state.board;
    if (!state.isPlaying || board == null) return;
    if (state.selectedIndices.isEmpty) {
      state = state.copyWith(
        activeNumber: () => state.activeNumber == number ? null : number,
      );
      return;
    }
    final next = switch (state.inputMode) {
      InputMode.normal => board.placeNumber(state.selectedIndices, number),
      InputMode.draft => board.toggleDraft(state.selectedIndices, number),
    };
    _apply(next, activeNumber: number);
  }

  /// Clears the selected cells' values, or their drafts when empty.
  void erase() {
    final board = state.board;
    if (!state.isPlaying || board == null) return;
    _apply(board.erase(state.selectedIndices));
  }

  void undo() {
    if (!state.isPlaying || _history.isEmpty) return;
    state = state.copyWith(
      board: _history.removeLast(),
      canUndo: _history.isNotEmpty,
    );
  }

  void _apply(SudokuBoard next, {int? activeNumber}) {
    final previous = state.board!;
    if (!identical(next, previous)) {
      _history.add(previous);
      if (_history.length > maxUndo) _history.removeAt(0);
    }
    final solved = next.isSolved;
    state = state.copyWith(
      board: next,
      phase: solved ? SudokuPhase.solved : null,
      selectedIndices: solved ? const {} : null,
      activeNumber: activeNumber == null ? null : () => activeNumber,
      canUndo: _history.isNotEmpty,
    );
  }
}
