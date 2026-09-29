import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/game/game_interface.dart';
import '../../core/routing/app_routes.dart';
import '../../core/ui_kit/theme/theme_controller.dart';
import '../../core/ui_kit/theme/theme_picker_sheet.dart';

/// The game menu, rendered from whatever games the app registers.
class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.games});

  final List<GameInterface> games;

  static ValueKey<String> tileKey(String gameId) =>
      ValueKey('home-game-$gameId');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('my1010'),
        actions: [
          IconButton(
            tooltip: 'Theme',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => ThemePickerSheet.show(context),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final game = games[i];
              final enabled = game.isAvailable;
              return Material(
                color: palette.boardBackground,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  key: tileKey(game.id),
                  enabled: enabled,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Icon(
                    game.menuIcon,
                    size: 36,
                    color: enabled ? palette.accent : palette.textSecondary,
                  ),
                  title: Text(
                    game.displayName,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: enabled
                      ? null
                      : Text(
                          'Not available on this platform',
                          style: TextStyle(color: palette.textSecondary),
                        ),
                  trailing: game.supportsLeaderboard
                      ? IconButton(
                          tooltip: '${game.displayName} leaderboard',
                          color: palette.textSecondary,
                          icon: const Icon(Icons.leaderboard_outlined),
                          onPressed: () =>
                              Navigator.of(context)
                                  .pushNamed(AppRoutes.leaderboard(game.id)),
                        )
                      : null,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.game(game.id)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
