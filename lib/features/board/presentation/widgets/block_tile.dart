import 'package:flutter/material.dart';

/// A single rounded square — the visual atom of the board and the pieces.
class BlockTile extends StatelessWidget {
  const BlockTile({super.key, required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.18),
        ),
      ),
    );
  }
}
