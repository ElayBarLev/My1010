import 'package:flutter_test/flutter_test.dart';
import 'package:my1010/features/board/domain/entities/grid_point.dart';
import 'package:my1010/features/board/presentation/controllers/game_controller.dart';
import 'package:my1010/features/board/presentation/widgets/score_display.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/test_shapes.dart';

void main() {
  test('early milestones fire once when crossed', () {
    expect(ScoreMilestones.crossed(90, 104), 100);
    expect(ScoreMilestones.crossed(240, 260), 250);
    expect(ScoreMilestones.crossed(480, 510), 500);
  });

  test('every thousand is a milestone', () {
    expect(ScoreMilestones.crossed(990, 1010), 1000);
    expect(ScoreMilestones.crossed(2950, 3040), 3000);
  });

  test('no milestone when nothing is crossed', () {
    expect(ScoreMilestones.crossed(101, 140), isNull);
    expect(ScoreMilestones.crossed(1001, 1990), isNull);
    expect(ScoreMilestones.crossed(500, 500), isNull);
  });

  test('a big jump reports the highest milestone passed', () {
    expect(ScoreMilestones.crossed(80, 520), 500);
  });

  test('restarting (score going down) never pops', () {
    expect(ScoreMilestones.crossed(1500, 0), isNull);
  });

  testWidgets('the score pops with a label when reaching 100', (tester) async {
    final container = await pumpGame(tester, shapes: [line5h]);
    final controller = container.read(gameControllerProvider.notifier);
    int freeSlot() => container
        .read(gameControllerProvider)
        .tray
        .indexWhere((s) => s != null);

    // Two 5-lines complete a row: 5 + 5 + 10 = 20 points per row.
    var row = 0;
    void clearRow() {
      controller.place(freeSlot(), GridPoint(row, 0));
      controller.place(freeSlot(), GridPoint(row, 5));
      row++;
    }

    for (var i = 0; i < 4; i++) {
      clearRow();
    }
    await tester.pumpAndSettle();
    expect(container.read(gameControllerProvider).score, 80);
    expect(find.byKey(ScoreDisplay.milestoneKey), findsNothing);

    clearRow(); // 100
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('100!'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
