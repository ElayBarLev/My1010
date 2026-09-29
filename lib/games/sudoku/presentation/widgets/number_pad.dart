import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui_kit/theme/theme_controller.dart';
import '../controllers/sudoku_controller.dart';

/// Digits 1-9. Each key rebuilds on its own when its count, the active
/// number or the input mode changes.
class NumberPad extends StatelessWidget {
  const NumberPad({super.key});

  static ValueKey<String> keyFor(int number) => ValueKey('sudoku-key-$number');

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: Row(
      children: [
        for (var n = 1; n <= 9; n++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _NumberKey(number: n),
            ),
          ),
      ],
    ),
  );
}

class _NumberKey extends ConsumerWidget {
  const _NumberKey({required this.number});

  final int number;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    final (remaining, isActive, isDraft) = ref.watch(
      sudokuControllerProvider.select(
        (s) => (
          9 - (s.board?.countOf(number) ?? 0),
          s.activeNumber == number,
          s.inputMode == InputMode.draft,
        ),
      ),
    );
    final done = remaining <= 0;
    final color = done ? palette.textSecondary : palette.accent;

    return SizedBox(
      height: 60,
      child: Material(
        color: isActive
            ? palette.accent.withValues(alpha: 0.18)
            : palette.boardBackground,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          key: NumberPad.keyFor(number),
          borderRadius: BorderRadius.circular(10),
          onTap: () =>
              ref.read(sudokuControllerProvider.notifier).enterNumber(number),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Expanded(
                  child: FittedBox(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        fontSize: isDraft ? 20 : 28,
                        fontWeight: isDraft ? FontWeight.w400 : FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ),
                Text(
                  done ? '' : '$remaining',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Undo, erase and the normal / draft switch.
class SudokuToolbar extends ConsumerWidget {
  const SudokuToolbar({super.key});

  static const undoKey = ValueKey('sudoku-undo');
  static const eraseKey = ValueKey('sudoku-erase');
  static const draftKey = ValueKey('sudoku-draft');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    final (canUndo, isDraft) = ref.watch(
      sudokuControllerProvider.select(
        (s) => (s.canUndo, s.inputMode == InputMode.draft),
      ),
    );
    final controller = ref.read(sudokuControllerProvider.notifier);

    Widget tool({
      required Key key,
      required IconData icon,
      required String label,
      required VoidCallback? onPressed,
      bool selected = false,
    }) => Expanded(
      child: TextButton(
        key: key,
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: selected ? palette.accent : palette.textSecondary,
          backgroundColor: selected
              ? palette.accent.withValues(alpha: 0.14)
              : null,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Icon(icon), const SizedBox(height: 2), Text(label)],
        ),
      ),
    );

    return RepaintBoundary(
      child: Row(
        children: [
          tool(
            key: undoKey,
            icon: Icons.undo_rounded,
            label: 'Undo',
            onPressed: canUndo ? controller.undo : null,
          ),
          tool(
            key: eraseKey,
            icon: Icons.backspace_outlined,
            label: 'Erase',
            onPressed: controller.erase,
          ),
          tool(
            key: draftKey,
            icon: Icons.edit_note_rounded,
            label: isDraft ? 'Draft: on' : 'Draft: off',
            onPressed: controller.toggleInputMode,
            selected: isDraft,
          ),
        ],
      ),
    );
  }
}
