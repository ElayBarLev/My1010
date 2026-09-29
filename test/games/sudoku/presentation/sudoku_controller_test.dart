import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my1010/games/sudoku/data/puzzle_source.dart';
import 'package:my1010/games/sudoku/domain/sudoku_difficulty.dart';
import 'package:my1010/games/sudoku/presentation/controllers/sudoku_controller.dart';

import '../../../helpers/sudoku_fixtures.dart';

void main() {
  late FakePuzzleSource source;
  late ProviderContainer container;
  SudokuController controller() =>
      container.read(sudokuControllerProvider.notifier);
  SudokuState state() => container.read(sudokuControllerProvider);

  Future<void> start({FakePuzzleSource? using}) async {
    source = using ?? FakePuzzleSource(twoEmptyRows);
    container = ProviderContainer(
      overrides: [sudokuPuzzleSourceProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);
    await controller().newGame(SudokuDifficulty.extreme);
  }

  test('generating, then playing an 81-cell board', () async {
    source = FakePuzzleSource(twoEmptyRows, hold: true);
    container = ProviderContainer(
      overrides: [sudokuPuzzleSourceProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);
    expect(state().phase, SudokuPhase.choosingDifficulty);

    final pending = controller().newGame(SudokuDifficulty.veryHard);
    expect(state().phase, SudokuPhase.generating);
    source.release();
    await pending;

    expect(state().phase, SudokuPhase.playing);
    expect(state().difficulty, SudokuDifficulty.veryHard);
    expect(state().board!.cells, hasLength(81));
    expect(source.requests, [SudokuDifficulty.veryHard]);
  });

  test('a stale generation never replaces a newer choice', () async {
    source = FakePuzzleSource(twoEmptyRows, hold: true);
    container = ProviderContainer(
      overrides: [sudokuPuzzleSourceProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);
    final first = controller().newGame(SudokuDifficulty.hard);
    controller().chooseDifficulty();
    source.release();
    await first;
    expect(state().phase, SudokuPhase.choosingDifficulty);
  });

  test('generation errors are shown, not thrown', () async {
    await start(using: FakePuzzleSource(twoEmptyRows, error: StateError('x')));
    expect(state().phase, SudokuPhase.failed);
    expect(state().errorMessage, contains('x'));
  });

  test('tap selects one cell, drag extends the selection', () async {
    await start();
    controller().select(0);
    controller().extendSelection(1);
    controller().extendSelection(10);
    expect(state().selectedIndices, {0, 1, 10});
    controller().select(5);
    expect(state().selectedIndices, {5});
    controller().clearSelection();
    expect(state().selectedIndices, isEmpty);
  });

  test('selecting a filled cell makes its number active', () async {
    await start();
    controller().select(40); // a given
    expect(state().activeNumber, solvedGrid[40]);
    controller().select(0); // empty
    expect(state().activeNumber, isNull);
  });

  test('normal mode writes values to the whole selection', () async {
    await start();
    controller()
      ..select(0)
      ..extendSelection(1)
      ..enterNumber(7);
    expect(state().board![0].enteredValue, 7);
    expect(state().board![1].enteredValue, 7);
    expect(state().board![0].isError, isTrue, reason: 'duplicate in row');
    expect(state().activeNumber, 7);
    expect(state().canUndo, isTrue);
  });

  test(
    'draft mode toggles pencil marks; placing a number cleans them',
    () async {
      await start();
      controller()
        ..toggleInputMode()
        ..select(0)
        ..extendSelection(1)
        ..enterNumber(3)
        ..enterNumber(4);
      expect(state().inputMode, InputMode.draft);
      expect(state().board![1].drafts, [3, 4]);

      controller()
        ..toggleInputMode()
        ..select(0)
        ..enterNumber(3);
      expect(state().board![0].draftMask, 0);
      expect(state().board![1].drafts, [4]);
    },
  );

  test('with nothing selected a number only toggles the highlight', () async {
    await start();
    final board = state().board;
    controller().enterNumber(5);
    expect(state().activeNumber, 5);
    controller().enterNumber(5);
    expect(state().activeNumber, isNull);
    expect(identical(state().board, board), isTrue);
  });

  test('undo restores previous boards', () async {
    await start();
    controller()
      ..select(0)
      ..enterNumber(1)
      ..enterNumber(2)
      ..erase();
    expect(state().board![0].isEmpty, isTrue);
    controller().undo();
    expect(state().board![0].enteredValue, 2);
    controller().undo();
    expect(state().board![0].enteredValue, 1);
    controller().undo();
    expect(state().board![0].isEmpty, isTrue);
    expect(state().canUndo, isFalse);
  });

  test('filling the last cell solves the puzzle and locks input', () async {
    await start(using: FakePuzzleSource(puzzleWithHoles([0, 1])));
    controller()
      ..select(0)
      ..enterNumber(solvedGrid[0])
      ..select(1)
      ..enterNumber(solvedGrid[1]);
    expect(state().phase, SudokuPhase.solved);
    expect(state().selectedIndices, isEmpty);

    final board = state().board;
    controller()
      ..select(0)
      ..erase();
    expect(identical(state().board, board), isTrue);
  });
}
