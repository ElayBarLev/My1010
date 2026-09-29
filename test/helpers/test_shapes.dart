import 'package:my1010/games/original_game/domain/entities/board.dart';
import 'package:my1010/games/original_game/domain/entities/grid_point.dart';
import 'package:my1010/games/original_game/domain/entities/shape.dart';
import 'package:my1010/games/original_game/domain/entities/shape_catalog.dart';

Shape shapeById(String id) => ShapeCatalog.standard.byId(id)!;

final dot = shapeById('dot');
final square2 = shapeById('square2');
final square3 = shapeById('square3');
final line5h = shapeById('line5_h');
final line5v = shapeById('line5_v');
final cornerLargeSe = shapeById('cornerLarge_se');

/// Builds a board from rows of `#` (filled, colour slot 0) and `.` (empty).
Board boardFromAscii(List<String> rows) {
  final size = rows.length;
  return Board.fromCells(size, [
    for (final row in rows)
      for (final ch in row.split('')) ch == '#' ? 0 : null,
  ]);
}

/// A 10×10 board where [row] is full except for the cells in [gaps].
Board boardWithRowGaps(int row, Set<int> gaps) {
  var board = Board.empty();
  for (var c = 0; c < 10; c++) {
    if (!gaps.contains(c)) board = board.place(dot, GridPoint(row, c));
  }
  return board;
}
