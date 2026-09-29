import '../entities/shape.dart';

/// How points are awarded. Swap implementations per game mode.
abstract interface class ScoringRules {
  /// Points for putting [shape] on the board.
  int placementPoints(Shape shape);

  /// Bonus for clearing [lines] rows/columns with a single placement.
  int clearBonus(int lines);
}

/// 1010! scoring: one point per placed cell, plus a line bonus that grows
/// triangularly so combos pay off: 1 line = 10, 2 = 30, 3 = 60, 4 = 100 …
/// i.e. `10 * n * (n + 1) / 2`.
class ClassicScoring implements ScoringRules {
  const ClassicScoring({this.pointsPerLine = 10});

  final int pointsPerLine;

  @override
  int placementPoints(Shape shape) => shape.cellCount;

  @override
  int clearBonus(int lines) {
    if (lines <= 0) return 0;
    return pointsPerLine * lines * (lines + 1) ~/ 2;
  }
}
