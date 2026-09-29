import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my1010/app.dart';
import 'package:my1010/games/original_game/domain/game_constants.dart';
import 'package:my1010/core/storage/shared_preferences_provider.dart';
import 'package:my1010/games/original_game/domain/entities/grid_point.dart';
import 'package:my1010/games/original_game/domain/entities/shape.dart';
import 'package:my1010/games/original_game/domain/game_engine.dart';
import 'package:my1010/games/original_game/domain/game_mode.dart';
import 'package:my1010/games/original_game/domain/services/shape_generator.dart';
import 'package:my1010/games/original_game/presentation/controllers/game_controller.dart';
import 'package:my1010/games/original_game/presentation/layout/board_metrics.dart';
import 'package:my1010/games/original_game/presentation/widgets/board_grid.dart';
import 'package:my1010/games/original_game/presentation/widgets/shape_tray.dart';
import 'package:my1010/core/firebase/in_memory_leaderboard_repository.dart';
import 'package:my1010/core/firebase/leaderboard_repository_provider.dart';
import 'package:my1010/features/home/home_page.dart';

/// Pumps the full app on a phone-sized surface with a scripted tray, then
/// opens the 1010! game from the home menu.
Future<ProviderContainer> pumpGame(
  WidgetTester tester, {
  required List<Shape> shapes,
  Map<String, Object> prefs = const {},
  InMemoryLeaderboardRepository? leaderboard,
}) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        gameEngineProvider.overrideWithValue(
          GameEngine(
            mode: GameModes.classic,
            generator: SequenceShapeGenerator(shapes),
          ),
        ),
        if (leaderboard != null)
          leaderboardRepositoryProvider.overrideWithValue(leaderboard),
      ],
      child: const TenTenApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(HomePage.tileKey(GameModes.classic.id)));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(BoardGrid)));
}

/// Drags the piece in tray [slot] so that its top-left lands on [origin],
/// moving the finger exactly like a user would: the shape floats
/// [GameConstants.dragLift] px above the pointer, centred horizontally.
///
/// Returns the still-active gesture when [release] is `false`.
Future<TestGesture> dragShapeTo(
  WidgetTester tester, {
  required int slot,
  required Shape shape,
  required GridPoint origin,
  bool release = true,
}) async {
  final boardFinder = find.byType(BoardGrid);
  final boardTopLeft = tester.getTopLeft(boardFinder);
  final metrics = BoardMetrics(
    side: tester.getSize(boardFinder).width,
    size: GameConstants.boardSize,
  );
  final size = metrics.shapeSize(shape);
  final anchor = Offset(size.width / 2, size.height + GameConstants.dragLift);
  // A little jitter inside the cell proves snapping is forgiving.
  final target =
      boardTopLeft +
      metrics.cellOffset(origin) +
      Offset(metrics.pitch * 0.3, -metrics.pitch * 0.3) +
      anchor;

  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(ShapeTray.slotKey(slot))),
  );
  await tester.pump();
  // Travel in steps, as a real finger would.
  final start = tester.getCenter(find.byKey(ShapeTray.slotKey(slot)));
  for (var i = 1; i <= 5; i++) {
    await gesture.moveTo(Offset.lerp(start, target, i / 5)!);
    await tester.pump(const Duration(milliseconds: 16));
  }
  if (release) {
    await gesture.up();
    await tester.pumpAndSettle();
  }
  return gesture;
}
