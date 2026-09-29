import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/ui_kit/theme/theme_controller.dart';
import '../../domain/sudoku_difficulty.dart';
import '../controllers/sudoku_controller.dart';
import '../widgets/number_pad.dart';
import '../widgets/sudoku_grid.dart';

class SudokuPage extends ConsumerWidget {
  const SudokuPage({super.key});

  static const double maxBoardSide = 520;

  static ValueKey<String> difficultyKey(SudokuDifficulty d) =>
      ValueKey('sudoku-difficulty-${d.name}');

  static const newGameKey = ValueKey('sudoku-new-game');
  static const solvedKey = ValueKey('sudoku-solved');

  Future<void> _newGame(BuildContext context, WidgetRef ref) async {
    final state = ref.read(sudokuControllerProvider);
    final controller = ref.read(sudokuControllerProvider.notifier);
    if (state.phase != SudokuPhase.playing || !state.canUndo) {
      controller.chooseDifficulty();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New puzzle?'),
        content: const Text('Your current puzzle will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('New puzzle'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) controller.chooseDifficulty();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only the phase: moves on the board never rebuild the page.
    final (phase, difficulty) = ref.watch(
      sudokuControllerProvider.select((s) => (s.phase, s.difficulty)),
    );
    final navigator = Navigator.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          difficulty == null || phase == SudokuPhase.choosingDifficulty
              ? 'Sudoku'
              : 'Sudoku · ${difficulty.label}',
        ),
        leading: navigator.canPop()
            ? null
            : IconButton(
                tooltip: 'Menu',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => navigator.pushReplacementNamed(AppRoutes.home),
              ),
        actions: [
          if (phase != SudokuPhase.choosingDifficulty)
            IconButton(
              key: newGameKey,
              tooltip: 'New puzzle',
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _newGame(context, ref),
            ),
        ],
      ),
      body: SafeArea(
        child: switch (phase) {
          SudokuPhase.choosingDifficulty => const _DifficultyPicker(),
          SudokuPhase.generating => _Generating(difficulty: difficulty!),
          SudokuPhase.failed => const _Failed(),
          SudokuPhase.playing || SudokuPhase.solved => const _PlayArea(),
        },
      ),
    );
  }
}

class _DifficultyPicker extends ConsumerWidget {
  const _DifficultyPicker();

  static const _descriptions = {
    SudokuDifficulty.hard: 'Advanced logic, no guessing',
    SudokuDifficulty.veryHard: 'Needs one or two guesses',
    SudokuDifficulty.extreme: 'Needs three or more guesses',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Choose a difficulty',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 16),
            for (final difficulty in SudokuDifficulty.values) ...[
              Material(
                color: palette.boardBackground,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  key: SudokuPage.difficultyKey(difficulty),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  title: Text(
                    difficulty.label,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _descriptions[difficulty]!,
                    style: TextStyle(color: palette.textSecondary),
                  ),
                  trailing: Icon(
                    Icons.play_arrow_rounded,
                    color: palette.accent,
                  ),
                  onTap: () => ref
                      .read(sudokuControllerProvider.notifier)
                      .newGame(difficulty),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _Generating extends ConsumerWidget {
  const _Generating({required this.difficulty});

  final SudokuDifficulty difficulty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: palette.accent),
          const SizedBox(height: 16),
          Text(
            'Generating a ${difficulty.label} puzzle…',
            style: TextStyle(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Failed extends ConsumerWidget {
  const _Failed();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    final state = ref.watch(sudokuControllerProvider);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not generate a puzzle.\n${state.errorMessage ?? ''}',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.textSecondary),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref
                  .read(sudokuControllerProvider.notifier)
                  .newGame(state.difficulty!),
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Board, tools and number pad, plus keyboard shortcuts: 1-9, Backspace /
/// Delete, arrows to move, D for draft mode, Ctrl/Cmd+Z to undo.
class _PlayArea extends ConsumerStatefulWidget {
  const _PlayArea();

  @override
  ConsumerState<_PlayArea> createState() => _PlayAreaState();
}

class _PlayAreaState extends ConsumerState<_PlayArea> {
  final _focusNode = FocusNode(debugLabel: 'sudoku');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final controller = ref.read(sudokuControllerProvider.notifier);
    final key = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;

    final digit = int.tryParse(event.character ?? '');
    if (digit != null && digit >= 1 && digit <= 9) {
      controller.enterNumber(digit);
    } else if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      controller.erase();
    } else if (key == LogicalKeyboardKey.keyZ &&
        (keyboard.isControlPressed || keyboard.isMetaPressed)) {
      controller.undo();
    } else if (key == LogicalKeyboardKey.keyD) {
      controller.toggleInputMode();
    } else if (_move(key) case (final dr, final dc)) {
      final selected = ref.read(sudokuControllerProvider).selectedIndices;
      final from = selected.isEmpty ? 40 : selected.last;
      final row = (from ~/ 9 + dr) % 9, col = (from % 9 + dc) % 9;
      controller.select(row * 9 + col);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  static (int, int)? _move(LogicalKeyboardKey key) => switch (key) {
    LogicalKeyboardKey.arrowUp => (-1, 0),
    LogicalKeyboardKey.arrowDown => (1, 0),
    LogicalKeyboardKey.arrowLeft => (0, -1),
    LogicalKeyboardKey.arrowRight => (0, 1),
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final isSolved = ref.watch(
      sudokuControllerProvider.select((s) => s.phase == SudokuPhase.solved),
    );

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const controlsHeight = 190.0;
          final side = min(
            min(
              constraints.maxWidth - 24,
              constraints.maxHeight - controlsHeight,
            ),
            SudokuPage.maxBoardSide,
          ).floorToDouble();
          return Center(
            child: SizedBox(
              width: side,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SudokuGrid(side: side),
                  const SizedBox(height: 12),
                  if (isSolved)
                    const _SolvedBanner()
                  else ...[
                    const SudokuToolbar(),
                    const SizedBox(height: 8),
                    const NumberPad(),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SolvedBanner extends ConsumerWidget {
  const _SolvedBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    return Column(
      key: SudokuPage.solvedKey,
      children: [
        Text(
          'Solved!',
          style: TextStyle(
            color: palette.accent,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: ref
              .read(sudokuControllerProvider.notifier)
              .chooseDifficulty,
          icon: const Icon(Icons.replay_rounded),
          label: const Text('New puzzle'),
          style: FilledButton.styleFrom(
            backgroundColor: palette.accent,
            foregroundColor: palette.background,
          ),
        ),
      ],
    );
  }
}
