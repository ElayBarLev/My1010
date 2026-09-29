import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my1010/core/storage/shared_preferences_provider.dart';
import 'package:my1010/games/sudoku/data/puzzle_source.dart';
import 'package:my1010/games/sudoku/domain/sudoku_difficulty.dart';
import 'package:my1010/games/sudoku/presentation/controllers/sudoku_controller.dart';
import 'package:my1010/games/sudoku/presentation/pages/sudoku_page.dart';
import 'package:my1010/games/sudoku/presentation/widgets/draft_marks.dart';
import 'package:my1010/games/sudoku/presentation/widgets/number_pad.dart';
import 'package:my1010/games/sudoku/presentation/widgets/sudoku_cell_view.dart';
import 'package:my1010/games/sudoku/presentation/widgets/sudoku_grid.dart';
import 'package:my1010/games/sudoku/sudoku_game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/sudoku_fixtures.dart';

/// Pumps the Sudoku screen on a phone-sized surface and starts a game.
Future<ProviderContainer> pumpSudoku(
  WidgetTester tester, {
  FakePuzzleSource? source,
  bool start = true,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        sudokuPuzzleSourceProvider.overrideWithValue(
          source ?? FakePuzzleSource(twoEmptyRows),
        ),
      ],
      child: MaterialApp(home: const SudokuGame().buildGameScreen()),
    ),
  );
  if (start) {
    await tester.tap(
      find.byKey(SudokuPage.difficultyKey(SudokuDifficulty.extreme)),
    );
    await tester.pumpAndSettle();
  }
  return ProviderScope.containerOf(tester.element(find.byType(SudokuPage)));
}

Offset cellCenter(WidgetTester tester, int index) =>
    tester.getCenter(find.byKey(SudokuCellView.keyFor(index)));

SudokuCellViewData view(ProviderContainer c, int index) =>
    SudokuCellViewData.of(c.read(sudokuControllerProvider), index);

void main() {
  testWidgets('pick a difficulty, wait for QQWing, then play', (tester) async {
    final source = FakePuzzleSource(twoEmptyRows, hold: true);
    await pumpSudoku(tester, source: source, start: false);

    expect(find.text('Choose a difficulty'), findsOneWidget);
    await tester.tap(
      find.byKey(SudokuPage.difficultyKey(SudokuDifficulty.veryHard)),
    );
    await tester.pump();
    expect(find.text('Generating a Very Hard puzzle…'), findsOneWidget);

    source.release();
    await tester.pumpAndSettle();
    expect(find.text('Sudoku · Very Hard'), findsOneWidget);
    expect(find.byType(SudokuCellView), findsNWidgets(81));
    expect(find.byType(RepaintBoundary).evaluate().length, greaterThan(81));
  });

  testWidgets('tap selects a cell and the pad fills it', (tester) async {
    final container = await pumpSudoku(tester);

    await tester.tapAt(cellCenter(tester, 3));
    await tester.pump();
    expect(container.read(sudokuControllerProvider).selectedIndices, {3});

    await tester.tap(find.byKey(NumberPad.keyFor(solvedGrid[3])));
    await tester.pump();
    expect(
      container.read(sudokuControllerProvider).board![3].enteredValue,
      solvedGrid[3],
    );
  });

  testWidgets('dragging across cells multi-selects them', (tester) async {
    final container = await pumpSudoku(tester);

    // Along row 0, from column 0 to column 4.
    final gesture = await tester.startGesture(cellCenter(tester, 0));
    for (var col = 1; col <= 4; col++) {
      await gesture.moveTo(cellCenter(tester, col));
      await tester.pump();
    }
    await gesture.up();
    await tester.pump();
    expect(container.read(sudokuControllerProvider).selectedIndices, {
      0,
      1,
      2,
      3,
      4,
    });

    // One fast diagonal jump still selects the cells in between.
    final fast = await tester.startGesture(cellCenter(tester, 0));
    await fast.moveTo(cellCenter(tester, 0) + const Offset(0, 30));
    await fast.moveTo(cellCenter(tester, 8 * 9 + 8));
    await fast.up();
    await tester.pump();
    expect(
      container.read(sudokuControllerProvider).selectedIndices,
      containsAll([for (var i = 0; i < 9; i++) i * 9 + i]),
    );
  });

  testWidgets('drafts render as a 3×3 grid and clean up on placement', (
    tester,
  ) async {
    final container = await pumpSudoku(tester);

    await tester.tap(find.byKey(SudokuToolbar.draftKey));
    final gesture = await tester.startGesture(cellCenter(tester, 0));
    await gesture.moveTo(cellCenter(tester, 1));
    await gesture.up();
    await tester.pump();
    await tester.tap(find.byKey(NumberPad.keyFor(2)));
    await tester.tap(find.byKey(NumberPad.keyFor(8)));
    await tester.pump();

    final marks = find.descendant(
      of: find.byKey(SudokuCellView.keyFor(1)),
      matching: find.byType(DraftMarks),
    );
    expect(marks, findsOneWidget);
    expect(
      find.descendant(of: marks, matching: find.byType(Text)),
      findsNWidgets(2),
    );

    // Back to normal mode: placing 2 in cell 0 removes the 2 draft from
    // its peer, cell 1.
    await tester.tap(find.byKey(SudokuToolbar.draftKey));
    await tester.tapAt(cellCenter(tester, 0));
    await tester.pump();
    await tester.tap(find.byKey(NumberPad.keyFor(2)));
    await tester.pump();
    expect(container.read(sudokuControllerProvider).board![1].drafts, [8]);
  });

  testWidgets('highlights the selection, matching numbers and drafts', (
    tester,
  ) async {
    final container = await pumpSudoku(tester);
    final active = solvedGrid[40]; // a given in the centre

    // Note the active number as a draft in cell 9 (row 1).
    await tester.tap(find.byKey(SudokuToolbar.draftKey));
    await tester.tapAt(cellCenter(tester, 9));
    await tester.pump();
    await tester.tap(find.byKey(NumberPad.keyFor(active)));
    await tester.tap(find.byKey(SudokuToolbar.draftKey));

    await tester.tapAt(cellCenter(tester, 40));
    await tester.pump();

    expect(view(container, 40).isSelected, isTrue);
    final matching = [
      for (var i = 0; i < 81; i++)
        if (view(container, i).matchesActiveNumber) i,
    ];
    expect(matching, hasLength(7), reason: 'rows 2-8 each hold it once');
    expect(view(container, 9).highlightedDraft, active);
    expect(view(container, 10).highlightedDraft, 0);
    expect(view(container, 41).isPeerOfSelection, isTrue);
  });

  testWidgets('conflicts are flagged the moment a number is entered', (
    tester,
  ) async {
    final container = await pumpSudoku(tester);
    await tester.tapAt(cellCenter(tester, 0));
    await tester.pump();
    await tester.tap(find.byKey(NumberPad.keyFor(solvedGrid[18])));
    await tester.pump();

    expect(view(container, 0).isError, isTrue);
    final text = tester.widget<Text>(
      find.descendant(
        of: find.byKey(SudokuCellView.keyFor(0)),
        matching: find.byType(Text),
      ),
    );
    expect(
      text.style!.color,
      Theme.of(tester.element(find.byType(SudokuGrid))).colorScheme.error,
    );
  });

  testWidgets('a keystroke rebuilds only the cells whose look changed', (
    tester,
  ) async {
    final container = await pumpSudoku(tester);
    await tester.tapAt(cellCenter(tester, 0));
    await tester.pump();

    final before = [for (var i = 0; i < 81; i++) view(container, i)];
    final rebuilt = <Widget>[];
    debugOnRebuildDirtyWidget = (element, _) => rebuilt.add(element.widget);
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    await tester.tap(find.byKey(NumberPad.keyFor(solvedGrid[0])));
    await tester.pump();
    debugOnRebuildDirtyWidget = null;

    final changed = {
      for (var i = 0; i < 81; i++)
        if (view(container, i) != before[i]) i,
    };
    final rebuiltCells = {
      for (final w in rebuilt.whereType<SudokuCellView>()) w.index,
    };
    expect(changed, isNotEmpty);
    expect(rebuiltCells, changed);
    expect(rebuiltCells.length, lessThan(81));
    expect(rebuilt.whereType<SudokuGrid>(), isEmpty);
    expect(rebuilt.whereType<SudokuPage>(), isEmpty);
  });

  testWidgets('solving shows the banner; new puzzle returns to the picker', (
    tester,
  ) async {
    await pumpSudoku(tester, source: FakePuzzleSource(puzzleWithHoles([0])));
    await tester.tapAt(cellCenter(tester, 0));
    await tester.pump();
    await tester.tap(find.byKey(NumberPad.keyFor(solvedGrid[0])));
    await tester.pumpAndSettle();

    expect(find.byKey(SudokuPage.solvedKey), findsOneWidget);
    expect(find.byType(NumberPad), findsNothing);

    await tester.tap(find.text('New puzzle'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a difficulty'), findsOneWidget);
  });

  testWidgets('keyboard: digits, arrows, D and backspace', (tester) async {
    final container = await pumpSudoku(tester);
    await tester.tapAt(cellCenter(tester, 0));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(container.read(sudokuControllerProvider).selectedIndices, {1});
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    expect(container.read(sudokuControllerProvider).board![1].enteredValue, 5);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    expect(container.read(sudokuControllerProvider).board![1].isEmpty, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    expect(container.read(sudokuControllerProvider).board![1].drafts, [5]);
  });

  test('the game is registered without a leaderboard', () {
    const game = SudokuGame();
    expect(game.id, 'sudoku');
    expect(game.supportsLeaderboard, isFalse);
  });
}
