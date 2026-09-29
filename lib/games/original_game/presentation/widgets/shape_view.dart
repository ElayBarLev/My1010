import 'package:flutter/material.dart';

import '../../domain/entities/shape.dart';
import 'block_tile.dart';

/// Draws a [Shape] with the given cell size and spacing.
class ShapeView extends StatelessWidget {
  const ShapeView({
    super.key,
    required this.shape,
    required this.cellSize,
    required this.gap,
    required this.color,
  });

  final Shape shape;
  final double cellSize;
  final double gap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pitch = cellSize + gap;
    return SizedBox(
      width: shape.width * pitch - gap,
      height: shape.height * pitch - gap,
      child: Stack(
        children: [
          for (final cell in shape.cells)
            Positioned(
              left: cell.col * pitch,
              top: cell.row * pitch,
              child: BlockTile(color: color, size: cellSize),
            ),
        ],
      ),
    );
  }
}
