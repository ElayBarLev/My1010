import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../themes/presentation/theme_controller.dart';
import '../../../themes/presentation/theme_picker_sheet.dart';
import '../controllers/game_controller.dart';

/// Best score, current score and the three menu buttons.
class ScoreHeader extends ConsumerWidget {
  const ScoreHeader({super.key, required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    final score = ref.watch(gameControllerProvider.select((s) => s.score));
    final best = ref.watch(gameControllerProvider.select((s) => s.bestScore));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 4),
      child: Row(
        children: [
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
          Expanded(
            child: Center(
              child: TweenAnimationBuilder<int>(
                tween: IntTween(end: score),
                duration: const Duration(milliseconds: 300),
                builder: (_, value, _) => Text(
                  '$value',
                  key: const ValueKey('score'),
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
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
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.leaderboard),
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
