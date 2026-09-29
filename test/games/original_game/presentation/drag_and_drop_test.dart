import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my1010/games/original_game/domain/entities/grid_point.dart';
import 'package:my1010/games/original_game/presentation/controllers/game_controller.dart';
import 'package:my1010/games/original_game/presentation/widgets/block_tile.dart';
import 'package:my1010/games/original_game/presentation/widgets/board_grid.dart';
import 'package:my1010/games/original_game/presentation/widgets/draggable_shape.dart';
import 'package:my1010/games/original_game/presentation/widgets/shape_tray.dart';
import 'package:my1010/core/firebase/in_memory_leaderboard_repository.dart';
import 'package:my1010/core/ui_kit/theme/palettes.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/test_shapes.dart';

void main() {
  testWidgets('renders a 10×10 grid and three draggable pieces', (
    tester,
  ) async {
    await pumpGame(tester, shapes: [square2, line5h, dot]);

    expect(find.byType(GridView), findsOneWidget);
    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate = grid.childrenDelegate as SliverChildBuilderDelegate;
    expect(delegate.estimatedChildCount, 100);
    expect(find.byType(DraggableShape), findsNWidgets(3));
  });

  testWidgets('dragging a piece onto the board places it and scores', (
    tester,
  ) async {
    final container = await pumpGame(tester, shapes: [square2, line5h, dot]);

    await dragShapeTo(
      tester,
      slot: 0,
      shape: square2,
      origin: const GridPoint(3, 4),
    );

    final state = container.read(gameControllerProvider);
    expect(state.board.filledCount, 4, reason: state.board.toAscii());
    for (final p in const [
      GridPoint(3, 4),
      GridPoint(3, 5),
      GridPoint(4, 4),
      GridPoint(4, 5),
    ]) {
      expect(
        state.board.isFilled(p),
        isTrue,
        reason: '$p\n${state.board.toAscii()}',
      );
    }
    expect(state.tray[0], isNull);
    expect(state.score, 4);
    expect(find.text('4'), findsWidgets);
    expect(find.byType(DraggableShape), findsNWidgets(2));
  });

  testWidgets('pieces can be dropped on the bottom-right corner', (
    tester,
  ) async {
    // The shape floats above the finger, so bottom-row drops rely on the
    // hit-test point following the shape rather than the finger.
    final container = await pumpGame(tester, shapes: [square2, line5h, dot]);

    await dragShapeTo(
      tester,
      slot: 0,
      shape: square2,
      origin: const GridPoint(8, 8),
    );
    await dragShapeTo(
      tester,
      slot: 1,
      shape: line5h,
      origin: const GridPoint(9, 0),
    );

    final board = container.read(gameControllerProvider).board;
    expect(
      board.isFilled(const GridPoint(9, 9)),
      isTrue,
      reason: board.toAscii(),
    );
    expect(
      board.isFilled(const GridPoint(9, 0)),
      isTrue,
      reason: board.toAscii(),
    );
    expect(board.filledCount, 9);
  });

  testWidgets('dropping onto an occupied area is rejected', (tester) async {
    final container = await pumpGame(tester, shapes: [square2, square2, dot]);

    await dragShapeTo(
      tester,
      slot: 0,
      shape: square2,
      origin: const GridPoint(0, 0),
    );
    await dragShapeTo(
      tester,
      slot: 1,
      shape: square2,
      origin: const GridPoint(1, 1),
    );

    final state = container.read(gameControllerProvider);
    expect(state.board.filledCount, 4);
    expect(state.tray[1], same(square2), reason: 'piece returns to the tray');
    expect(state.score, 4);
  });

  testWidgets('dropping outside the board leaves the game untouched', (
    tester,
  ) async {
    final container = await pumpGame(tester, shapes: [square2, line5h, dot]);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(ShapeTray.slotKey(2))),
    );
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final state = container.read(gameControllerProvider);
    expect(state.board.isEmpty, isTrue);
    expect(state.tray.whereType<Object>(), hasLength(3));
  });

  testWidgets('hovering shows a ghost before committing the move', (
    tester,
  ) async {
    final container = await pumpGame(tester, shapes: [square2, line5h, dot]);
    final ghost = GamePalettes.classic
        .blockColor(square2.colorSlot)
        .withValues(alpha: 0.45);
    Finder ghostTiles() =>
        find.byWidgetPredicate((w) => w is BlockTile && w.color == ghost);
    expect(ghostTiles(), findsNothing);

    final gesture = await dragShapeTo(
      tester,
      slot: 0,
      shape: square2,
      origin: const GridPoint(5, 5),
      release: false,
    );

    // Mid-drag: a 4-cell ghost is shown but nothing is committed yet.
    expect(ghostTiles(), findsNWidgets(4));
    expect(container.read(gameControllerProvider).board.isEmpty, isTrue);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(ghostTiles(), findsNothing);
    expect(
      container
          .read(gameControllerProvider)
          .board
          .isFilled(const GridPoint(5, 5)),
      isTrue,
    );
  });

  testWidgets('clearing a line animates and awards the bonus', (tester) async {
    final container = await pumpGame(tester, shapes: [line5h, line5h, dot]);

    await dragShapeTo(
      tester,
      slot: 0,
      shape: line5h,
      origin: const GridPoint(9, 0),
    );
    await dragShapeTo(
      tester,
      slot: 1,
      shape: line5h,
      origin: const GridPoint(9, 5),
    );

    final state = container.read(gameControllerProvider);
    expect(state.board.isEmpty, isTrue, reason: state.board.toAscii());
    expect(state.score, 5 + 5 + 10);
    expect(state.lastMove!.linesCleared, 1);
  });

  testWidgets('game over submits the score to the leaderboard', (tester) async {
    final leaderboard = InMemoryLeaderboardRepository();
    final container = await pumpGame(
      tester,
      shapes: [square3, square3, square3],
      leaderboard: leaderboard,
    );
    final controller = container.read(gameControllerProvider.notifier);
    // Pack 3×3 squares on a 3×3 lattice with 1-cell gaps: 9 squares leave no
    // 3×3 hole and never complete a line.
    const origins = [
      GridPoint(0, 0),
      GridPoint(0, 3),
      GridPoint(0, 6),
      GridPoint(3, 0),
      GridPoint(3, 3),
      GridPoint(3, 6),
      GridPoint(6, 0),
      GridPoint(6, 3),
      GridPoint(6, 6),
    ];
    for (var i = 0; i < origins.length; i++) {
      expect(controller.place(i % 3, origins[i]), isTrue, reason: '$i');
    }
    await tester.pumpAndSettle();

    expect(container.read(gameControllerProvider).isGameOver, isTrue);
    expect(find.text('No more space'), findsOneWidget);

    final top = await leaderboard.watchTopScores(gameId: 'classic').first;
    expect(top.single.score, 81);

    await tester.tap(find.byKey(const ValueKey('play-again')));
    await tester.pumpAndSettle();
    expect(container.read(gameControllerProvider).board.isEmpty, isTrue);
    expect(find.text('No more space'), findsNothing);
  });

  testWidgets('blocks in a line about to clear keep their own colours', (
    tester,
  ) async {
    final line2h = shapeById('line2_h');
    final container = await pumpGame(
      tester,
      shapes: [line2h, line2h, line2h, line2h, square2, dot],
    );
    final controller = container.read(gameControllerProvider.notifier);
    // Fill row 9, columns 0-7, with yellow 2-lines.
    for (final (slot, col) in const [(0, 0), (1, 2), (2, 4), (0, 6)]) {
      expect(controller.place(slot, GridPoint(9, col)), isTrue);
    }
    await tester.pumpAndSettle();

    // Hover the green square over the gap so it would complete row 9.
    final gesture = await dragShapeTo(
      tester,
      slot: 1,
      shape: square2,
      origin: const GridPoint(8, 8),
      release: false,
    );

    const palette = GamePalettes.classic;
    final yellow = palette.blockColor(line2h.colorSlot);
    final green = palette.blockColor(square2.colorSlot);
    int tiles(Color c) => tester
        .widgetList<BlockTile>(
          find.descendant(
            of: find.byType(BoardGrid),
            matching: find.byType(BlockTile),
          ),
        )
        .where((t) => t.color == c)
        .length;

    // Existing blocks stay yellow (lightened as a hint), never turn green.
    expect(tiles(Color.lerp(yellow, Colors.white, 0.3)!), 8);
    // The dragged piece: solid where it completes the line, ghost above.
    expect(tiles(green), 2);
    expect(tiles(green.withValues(alpha: 0.45)), 2);

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
