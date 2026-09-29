import 'package:meta/meta.dart';

import 'grid_point.dart';

/// The families of pieces found in 1010!.
///
/// Every orientation of a family shares one colour; [colorSlot] is the index
/// into a palette's block colours, which keeps the domain free of UI types.
enum ShapeKind {
  dot,
  line2,
  line3,
  line4,
  line5,
  square2,
  square3,
  cornerSmall,
  cornerLarge;

  int get colorSlot => index;
}

/// A polyomino described by the cells it occupies, relative to its top-left.
@immutable
class Shape {
  const Shape._({
    required this.id,
    required this.kind,
    required this.cells,
    required this.width,
    required this.height,
  });

  /// Builds a shape from an ASCII pattern where `#` marks a filled cell,
  /// e.g. `['#..', '#..', '###']`. The pattern is normalised so its top-left
  /// filled bounding box starts at (0, 0).
  factory Shape.fromPattern({
    required String id,
    required ShapeKind kind,
    required List<String> pattern,
  }) {
    final raw = <GridPoint>[
      for (var r = 0; r < pattern.length; r++)
        for (var c = 0; c < pattern[r].length; c++)
          if (pattern[r][c] == '#') GridPoint(r, c),
    ];
    if (raw.isEmpty) {
      throw ArgumentError.value(pattern, 'pattern', 'must contain a "#"');
    }
    final minRow = raw.map((p) => p.row).reduce((a, b) => a < b ? a : b);
    final minCol = raw.map((p) => p.col).reduce((a, b) => a < b ? a : b);
    final cells = List<GridPoint>.unmodifiable(
      raw.map((p) => GridPoint(p.row - minRow, p.col - minCol)),
    );
    return Shape._(
      id: id,
      kind: kind,
      cells: cells,
      width: cells.map((p) => p.col).reduce((a, b) => a > b ? a : b) + 1,
      height: cells.map((p) => p.row).reduce((a, b) => a > b ? a : b) + 1,
    );
  }

  /// Stable identifier used for persistence (e.g. `cornerLarge_ne`).
  final String id;
  final ShapeKind kind;
  final List<GridPoint> cells;
  final int width;
  final int height;

  int get cellCount => cells.length;
  int get colorSlot => kind.colorSlot;

  @override
  bool operator ==(Object other) => other is Shape && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Shape($id)';
}
