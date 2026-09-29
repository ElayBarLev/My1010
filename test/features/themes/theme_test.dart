import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ten_ten_clone/core/storage/shared_preferences_provider.dart';
import 'package:ten_ten_clone/features/board/domain/entities/shape.dart';
import 'package:ten_ten_clone/features/themes/data/palettes.dart';
import 'package:ten_ten_clone/features/themes/presentation/theme_controller.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/test_shapes.dart';

void main() {
  test('there are four palettes with unique ids and a colour per piece', () {
    expect(GamePalettes.all, hasLength(4));
    expect(GamePalettes.all.map((p) => p.id).toSet(), hasLength(4));
    for (final p in GamePalettes.all) {
      expect(p.blocks.length, greaterThanOrEqualTo(ShapeKind.values.length));
    }
  });

  test('unknown ids fall back to Classic', () {
    expect(GamePalettes.byId('missing'), GamePalettes.classic);
    expect(GamePalettes.byId(null), GamePalettes.classic);
  });

  test('selected palette is persisted and restored', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    ProviderContainer make() => ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );

    final first = make();
    expect(first.read(paletteProvider), GamePalettes.classic);
    await first.read(paletteProvider.notifier).select(GamePalettes.neon);
    first.dispose();

    final second = make();
    expect(second.read(paletteProvider), GamePalettes.neon);
    second.dispose();
  });

  testWidgets('picking a theme from the sheet restyles the app', (
    tester,
  ) async {
    await pumpGame(tester, shapes: [square2, dot, line5h]);
    Color scaffoldColor() =>
        Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor;
    expect(scaffoldColor(), GamePalettes.classic.background);

    await tester.tap(find.byTooltip('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('palette-solarized_dark')));
    await tester.pumpAndSettle();

    expect(scaffoldColor(), GamePalettes.solarizedDark.background);
  });
}
