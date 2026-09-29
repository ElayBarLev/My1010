import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/ui_kit/theme/theme_controller.dart';
import '../../../../core/ui_kit/theme/theme_picker_sheet.dart';
import '../controllers/game_controller.dart';

/// Top bar: back to the menu and best score on the left, buttons on the
/// right.
class ScoreHeader extends ConsumerWidget {
  const ScoreHeader({super.key, required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    final best = ref.watch(gameControllerProvider.select((s) => s.bestScore));

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(
        children: [
          _HeaderButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Menu',
            color: palette.textSecondary,
            onPressed: () => _backToMenu(context),
          ),
          Icon(
            Icons.emoji_events_rounded,
            color: palette.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            '$best',
            key: const ValueKey('best-score'),
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          _HeaderButton(
            icon: Icons.palette_outlined,
            tooltip: 'Theme',
            color: palette.textSecondary,
            onPressed: () => ThemePickerSheet.show(context),
          ),
          _HeaderButton(
            icon: Icons.leaderboard_outlined,
            tooltip: 'Leaderboard',
            color: palette.textSecondary,
            onPressed: () => openLeaderboard(context, ref),
          ),
          _HeaderButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Restart',
            color: palette.textSecondary,
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}

/// Pops back to the game menu, or replaces this page with it when the game
/// was opened directly (e.g. a web deep link).
void _backToMenu(BuildContext context) {
  final navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
  } else {
    navigator.pushReplacementNamed(AppRoutes.home);
  }
}

/// Opens the current mode's leaderboard, passing the local best along.
void openLeaderboard(BuildContext context, WidgetRef ref) {
  final game = ref.read(gameControllerProvider);
  Navigator.of(context)
      .pushNamed(AppRoutes.leaderboard(game.modeId), arguments: game.bestScore);
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon),
    tooltip: tooltip,
    color: color,
    onPressed: onPressed,
  );
}
