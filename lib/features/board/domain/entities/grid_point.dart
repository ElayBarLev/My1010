import 'package:meta/meta.dart';

/// An immutable (row, column) coordinate on the board.
@immutable
class GridPoint {
  const GridPoint(this.row, this.col);

  static const zero = GridPoint(0, 0);

  final int row;
  final int col;

  GridPoint operator +(GridPoint other) =>
      GridPoint(row + other.row, col + other.col);

  @override
  bool operator ==(Object other) =>
      other is GridPoint && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'GridPoint($row, $col)';
}
