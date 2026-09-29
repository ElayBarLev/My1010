import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my1010/core/storage/shared_preferences_provider.dart';
import 'package:my1010/features/board/data/game_state_repository.dart';
import 'package:my1010/features/board/domain/entities/grid_point.dart';
import 'package:my1010/features/board/domain/game_engine.dart';
import 'package:my1010/features/board/domain/game_mode.dart';
import 'package:my1010/features/board/domain/services/shape_generator.dart';
import 'package:my1010/features/board/presentation/controllers/game_controller.dart';

import '../../../helpers/test_shapes.dart';

Future<ProviderContainer> makeContainer(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      gameEngineProvider.overrideWithValue(
        GameEngine(
          mode: GameModes.classic,
          generator: SequenceShapeGenerator([square2, dot, line5h]),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  const saveKey = 'game.classic.save';
  const bestKey = 'game.classic.best';

  test('every move is saved and restored on the next launch', () async {
    final first = await makeContainer({});
    first.read(gameControllerProvider.notifier).place(0, const GridPoint(2, 2));
    await pumpEventQueue();
    final saved = first.read(sharedPreferencesProvider).getString(saveKey);
    expect(saved, isNotNull);

    final second = await makeContainer({saveKey: saved!, bestKey: 4});
    final restored = second.read(gameControllerProvider);
    expect(restored.board.isFilled(const GridPoint(3, 3)), isTrue);
    expect(restored.tray, [null, dot, line5h]);
    expect(restored.score, 4);
    expect(restored.bestScore, 4);
  });

  test('best score persists across restarts', () async {
    final container = await makeContainer({bestKey: 3});
    final controller = container.read(gameControllerProvider.notifier);
    expect(container.read(gameControllerProvider).bestScore, 3);

    controller.place(0, GridPoint.zero); // +4
    await pumpEventQueue();
    controller.restart();
    await pumpEventQueue();

    final prefs = container.read(sharedPreferencesProvider);
    expect(prefs.getInt(bestKey), 4);
    expect(prefs.getString(saveKey), isNull, reason: 'restart clears save');
    expect(container.read(gameControllerProvider).bestScore, 4);
    expect(container.read(gameControllerProvider).score, 0);
  });

  test('a corrupt save is ignored instead of crashing', () async {
    final container = await makeContainer({saveKey: '{not json'});
    final state = container.read(gameControllerProvider);
    expect(state.board.isEmpty, isTrue);
    expect(state.tray, [square2, dot, line5h]);
  });

  test('a save with an unknown version is ignored', () async {
    final container = await makeContainer({
      saveKey: jsonEncode({'version': 999}),
    });
    expect(container.read(gameControllerProvider).board.isEmpty, isTrue);
  });

  test('repository only raises the best score', () async {
    SharedPreferences.setMockInitialValues({bestKey: 50});
    final repo = GameStateRepository(await SharedPreferences.getInstance());
    await repo.saveBestScore('classic', 20);
    expect(repo.loadBestScore('classic'), 50);
    await repo.saveBestScore('classic', 70);
    expect(repo.loadBestScore('classic'), 70);
  });
}
