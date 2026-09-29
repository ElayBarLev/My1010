/// Global, mode-independent tuning values.
///
/// Anything a future game mode may want to change lives on `GameMode`
/// instead; these are the defaults those modes fall back to.
abstract final class GameConstants {
  /// Width and height of the classic board.
  static const int boardSize = 10;

  /// Number of shapes offered at once.
  static const int traySize = 3;

  /// Logical pixels between the user's finger and the bottom edge of the
  /// dragged shape, so the shape is never hidden under the finger.
  static const double dragLift = 64;

  /// Gap between cells expressed as a fraction of one cell pitch.
  static const double cellGapFraction = 0.1;

  /// Scale of shapes resting in the tray relative to the board cells.
  static const double trayScale = 0.55;

  /// Total duration of the line-clear animation (including stagger).
  static const Duration clearAnimation = Duration(milliseconds: 420);

  /// Duration of the "pop" when a shape lands on the board.
  static const Duration placeAnimation = Duration(milliseconds: 160);
}
