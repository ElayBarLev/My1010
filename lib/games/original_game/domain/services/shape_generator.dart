import 'dart:math';

import '../entities/shape.dart';
import '../entities/shape_catalog.dart';

/// Supplies the next piece to put in the tray.
///
/// Game modes pick (or implement) a generator, e.g. a weighted random bag
/// for classic play or a fixed script for puzzles and tests.
abstract interface class ShapeGenerator {
  Shape next();
}

/// Picks shapes at random, proportionally to their catalog weight.
class WeightedRandomShapeGenerator implements ShapeGenerator {
  WeightedRandomShapeGenerator(this.catalog, {Random? random})
    : _random = random ?? Random(),
      _totalWeight = catalog.entries.fold(0, (sum, e) => sum + e.weight);

  final ShapeCatalog catalog;
  final Random _random;
  final int _totalWeight;

  @override
  Shape next() {
    var roll = _random.nextInt(_totalWeight);
    for (final entry in catalog.entries) {
      roll -= entry.weight;
      if (roll < 0) return entry.shape;
    }
    return catalog.entries.last.shape; // Unreachable; keeps analyzer happy.
  }
}

/// Cycles through a fixed list of shapes. Useful for tests, tutorials and
/// scripted puzzle modes.
class SequenceShapeGenerator implements ShapeGenerator {
  SequenceShapeGenerator(List<Shape> shapes)
    : assert(shapes.isNotEmpty),
      _shapes = List.unmodifiable(shapes);

  final List<Shape> _shapes;
  int _index = 0;

  @override
  Shape next() => _shapes[_index++ % _shapes.length];
}
