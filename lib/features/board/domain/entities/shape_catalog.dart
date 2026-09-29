import 'package:meta/meta.dart';

import 'shape.dart';

/// A shape paired with its relative spawn weight.
@immutable
class WeightedShape {
  const WeightedShape(this.shape, this.weight) : assert(weight > 0);

  final Shape shape;
  final int weight;
}

/// The set of shapes a game mode can spawn.
class ShapeCatalog {
  ShapeCatalog(List<WeightedShape> entries)
    : entries = List.unmodifiable(entries),
      _byId = {for (final e in entries) e.shape.id: e.shape} {
    if (_byId.length != entries.length) {
      throw ArgumentError('Shape ids in a catalog must be unique.');
    }
  }

  final List<WeightedShape> entries;
  final Map<String, Shape> _byId;

  List<Shape> get shapes => [for (final e in entries) e.shape];

  Shape? byId(String id) => _byId[id];

  /// The 19 standard 1010! pieces: the dot, straight lines of 2–5 in both
  /// orientations, 2×2 and 3×3 squares and the four rotations of the small
  /// and large corners. Weights make the awkward pieces (3×3, 5-lines, big
  /// corners) rarer, roughly matching the original's feel.
  static final ShapeCatalog standard = ShapeCatalog([
    _w('dot', ShapeKind.dot, ['#'], 2),

    _w('line2_h', ShapeKind.line2, ['##'], 3),
    _w('line2_v', ShapeKind.line2, ['#', '#'], 3),
    _w('line3_h', ShapeKind.line3, ['###'], 3),
    _w('line3_v', ShapeKind.line3, ['#', '#', '#'], 3),
    _w('line4_h', ShapeKind.line4, ['####'], 2),
    _w('line4_v', ShapeKind.line4, ['#', '#', '#', '#'], 2),
    _w('line5_h', ShapeKind.line5, ['#####'], 2),
    _w('line5_v', ShapeKind.line5, ['#', '#', '#', '#', '#'], 2),

    _w('square2', ShapeKind.square2, ['##', '##'], 6),
    _w('square3', ShapeKind.square3, ['###', '###', '###'], 2),

    _w('cornerSmall_nw', ShapeKind.cornerSmall, ['##', '#.'], 2),
    _w('cornerSmall_ne', ShapeKind.cornerSmall, ['##', '.#'], 2),
    _w('cornerSmall_sw', ShapeKind.cornerSmall, ['#.', '##'], 2),
    _w('cornerSmall_se', ShapeKind.cornerSmall, ['.#', '##'], 2),

    _w('cornerLarge_nw', ShapeKind.cornerLarge, ['###', '#..', '#..'], 1),
    _w('cornerLarge_ne', ShapeKind.cornerLarge, ['###', '..#', '..#'], 1),
    _w('cornerLarge_sw', ShapeKind.cornerLarge, ['#..', '#..', '###'], 1),
    _w('cornerLarge_se', ShapeKind.cornerLarge, ['..#', '..#', '###'], 1),
  ]);

  static WeightedShape _w(
    String id,
    ShapeKind kind,
    List<String> pattern,
    int weight,
  ) => WeightedShape(
    Shape.fromPattern(id: id, kind: kind, pattern: pattern),
    weight,
  );
}
