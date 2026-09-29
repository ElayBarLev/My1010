import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../../../core/constants/game_constants.dart';
import '../../domain/entities/grid_point.dart';
import '../../domain/entities/shape.dart';

/// Pixel geometry of the board, shared by the grid, the drag feedback and
/// the tray so a dragged shape lines up with the cells exactly.
///
/// The board is `size` cells separated by `size - 1` gaps, where
/// `gap = pitch * cellGapFraction`, so `side = pitch * (size - fraction)`.
@immutable
class BoardMetrics {
  const BoardMetrics({required this.side, required this.size});

  final double side;
  final int size;

  /// Distance from one cell's top-left to the next.
  double get pitch => side / (size - GameConstants.cellGapFraction);
  double get gap => pitch * GameConstants.cellGapFraction;
  double get cellSize => pitch - gap;

  Offset cellOffset(GridPoint p) => Offset(p.col * pitch, p.row * pitch);

  /// Pixel size of [shape] when drawn at board scale.
  Size shapeSize(Shape shape, {double scale = 1}) => Size(
    (shape.width * pitch - gap) * scale,
    (shape.height * pitch - gap) * scale,
  );

  /// The board cell nearest to a shape whose top-left is at [local]
  /// (relative to the board's top-left). Rounding gives forgiving snapping.
  GridPoint nearestOrigin(Offset local) =>
      GridPoint((local.dy / pitch).round(), (local.dx / pitch).round());

  @override
  bool operator ==(Object other) =>
      other is BoardMetrics && other.side == side && other.size == size;

  @override
  int get hashCode => Object.hash(side, size);
}
