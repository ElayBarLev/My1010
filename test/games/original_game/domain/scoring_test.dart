import 'package:flutter_test/flutter_test.dart';
import 'package:my1010/games/original_game/domain/services/scoring_rules.dart';

import '../../../helpers/test_shapes.dart';

void main() {
  const scoring = ClassicScoring();

  test('placement awards one point per cell', () {
    expect(scoring.placementPoints(dot), 1);
    expect(scoring.placementPoints(square2), 4);
    expect(scoring.placementPoints(line5h), 5);
    expect(scoring.placementPoints(cornerLargeSe), 5);
    expect(scoring.placementPoints(square3), 9);
  });

  test('line bonus grows triangularly to reward combos', () {
    expect(scoring.clearBonus(0), 0);
    expect(scoring.clearBonus(1), 10);
    expect(scoring.clearBonus(2), 30);
    expect(scoring.clearBonus(3), 60);
    expect(scoring.clearBonus(4), 100);
    expect(scoring.clearBonus(6), 210);
  });

  test('negative line counts are treated as zero', () {
    expect(scoring.clearBonus(-1), 0);
  });

  test('pointsPerLine is configurable for other modes', () {
    expect(const ClassicScoring(pointsPerLine: 20).clearBonus(2), 60);
  });
}
