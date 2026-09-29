import 'package:meta/meta.dart';

import 'grid_point.dart';
import 'shape.dart';

/// Rows and columns that are completely filled.
@immutable
class LineClear {
  const LineClear({this.rows = const [], this.cols = const []});

  static const none = LineClear();

  final List<int> rows;
  final List<int> cols;

  int get count => rows.length + cols.length;
  bool get isEmpty => count == 0;

  /// Flat indices of every cell covered by these lines. Cells at the
  /// intersection of a cleared row and column appear once.
  Set<int> cellIndices(int boardSize) => {
    for (final r in rows)
      for (var c = 0; c < boardSize; c++) r * boardSize + c,
    for (final c in cols)
      for (var r = 0; r < boardSize; r++) r * boardSize + c,
  };
}

/// An immutable square matrix of cells.
///
/// Each cell is either `null` (empty) or the colour slot of the piece that
/// filled it. All operations return new boards, which keeps undo, previews
/// and tests trivial.
@immutable
class Board {
  Board.empty([this.size = 10])
    : _cells = List<int?>.unmodifiable(List<int?>.filled(size * size, null));

  Board.fromCells(this.size, List<int?> cells)
    : _cells = List<int?>.unmodifiable(cells) {
    if (cells.length != size * size) {
      throw ArgumentError(
        'Expected ${size * size} cells for a ${size}x$size board, '
        'got ${cells.length}.',
      );
    }
  }

  final int size;
  final List<int?> _cells;

  /// Row-major, read-only view of every cell.
  List<int?> get cells => _cells;

  int indexOf(GridPoint p) => p.row * size + p.col;
  GridPoint pointOf(int index) => GridPoint(index ~/ size, index % size);

  bool contains(GridPoint p) =>
      p.row >= 0 && p.row < size && p.col >= 0 && p.col < size;

  int? cellAt(GridPoint p) => _cells[indexOf(p)];
  bool isFilled(GridPoint p) => cellAt(p) != null;

  int get filledCount => _cells.where((c) => c != null).length;
  bool get isEmpty => filledCount == 0;

  /// Whether [shape] fits with its top-left at [origin]: every cell must be
  /// inside the board (bounds check) and currently empty (collision check).
  bool canPlace(Shape shape, GridPoint origin) {
    for (final offset in shape.cells) {
      final p = origin + offset;
      if (!contains(p) || isFilled(p)) return false;
    }
    return true;
  }

  /// Flat indices [shape] would occupy at [origin]. Does not validate.
  List<int> footprint(Shape shape, GridPoint origin) => [
    for (final offset in shape.cells) indexOf(origin + offset),
  ];

  /// Returns a new board with [shape] stamped at [origin].
  ///
  /// Throws a [StateError] if the placement is invalid; call [canPlace]
  /// first when the input is untrusted.
  Board place(Shape shape, GridPoint origin) {
    if (!canPlace(shape, origin)) {
      throw StateError('Cannot place ${shape.id} at $origin.');
    }
    final next = List<int?>.of(_cells);
    for (final i in footprint(shape, origin)) {
      next[i] = shape.colorSlot;
    }
    return Board.fromCells(size, next);
  }

  /// All rows and columns that are completely filled.
  LineClear findFullLines() {
    final rows = <int>[];
    final cols = <int>[];
    for (var i = 0; i < size; i++) {
      var rowFull = true;
      var colFull = true;
      for (var j = 0; j < size; j++) {
        if (_cells[i * size + j] == null) rowFull = false;
        if (_cells[j * size + i] == null) colFull = false;
        if (!rowFull && !colFull) break;
      }
      if (rowFull) rows.add(i);
      if (colFull) cols.add(i);
    }
    return LineClear(rows: rows, cols: cols);
  }

  /// Returns a new board with every cell in [lines] emptied. Rows and
  /// columns are cleared simultaneously, as in 1010!.
  Board clearLines(LineClear lines) {
    if (lines.isEmpty) return this;
    final next = List<int?>.of(_cells);
    for (final i in lines.cellIndices(size)) {
      next[i] = null;
    }
    return Board.fromCells(size, next);
  }

  /// Every top-left origin where [shape] currently fits.
  Iterable<GridPoint> validOrigins(Shape shape) sync* {
    for (var r = 0; r <= size - shape.height; r++) {
      for (var c = 0; c <= size - shape.width; c++) {
        final origin = GridPoint(r, c);
        if (canPlace(shape, origin)) yield origin;
      }
    }
  }

  bool canPlaceAnywhere(Shape shape) => validOrigins(shape).isNotEmpty;

  List<int?> toJson() => _cells;

  factory Board.fromJson(int size, List<dynamic> json) =>
      Board.fromCells(size, [for (final c in json) c as int?]);

  /// Debug rendering, e.g. for test failure messages.
  String toAscii() => [
    for (var r = 0; r < size; r++)
      [for (var c = 0; c < size; c++) _cells[r * size + c] == null ? '.' : '#']
          .join(),
  ].join('\n');

  @override
  bool operator ==(Object other) {
    if (other is! Board || other.size != size) return false;
    for (var i = 0; i < _cells.length; i++) {
      if (other._cells[i] != _cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(size, Object.hashAll(_cells));
}
