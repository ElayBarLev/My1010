import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../board/presentation/controllers/game_controller.dart';
import '../../themes/presentation/theme_controller.dart';
import '../domain/leaderboard_entry.dart';
import 'leaderboard_providers.dart';

class LeaderboardPage extends ConsumerWidget {
  const LeaderboardPage({super.key});

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDialog(initial: ref.read(playerNameProvider)),
    );
    if (name != null) await ref.read(playerNameProvider.notifier).rename(name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    final mode = ref.watch(gameModeProvider);
    final repository = ref.watch(leaderboardRepositoryProvider);
    final scores = ref.watch(topScoresProvider(mode.id));
    final playerName = ref.watch(playerNameProvider);
    final localBest = ref.watch(
      gameControllerProvider.select((s) => s.bestScore),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${mode.displayName} leaderboard'),
        actions: [
          IconButton(
            tooltip: 'Change name',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _rename(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!repository.isRemote)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.emptyCell,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Offline mode — Firebase is not configured, so scores are '
                'kept on this device only.',
                style: TextStyle(color: palette.textPrimary, fontSize: 13),
              ),
            ),
          ListTile(
            leading: Icon(Icons.person_outline, color: palette.textSecondary),
            title: Text(
              playerName,
              style: TextStyle(color: palette.textPrimary),
            ),
            subtitle: Text(
              'Personal best $localBest',
              style: TextStyle(color: palette.textSecondary),
            ),
          ),
          Divider(color: palette.emptyCell, height: 1),
          Expanded(
            child: scores.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load the leaderboard.\n$error',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.textSecondary),
                  ),
                ),
              ),
              data: (entries) => entries.isEmpty
                  ? Center(
                      child: Text(
                        'No scores yet — finish a game to get on the board.',
                        style: TextStyle(color: palette.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final entry = entries[i];
                        final isMe = entry.uid == repository.currentUserId;
                        return ListTile(
                          leading: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: palette.textSecondary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          title: Text(
                            entry.displayName,
                            style: TextStyle(
                              color: isMe
                                  ? palette.accent
                                  : palette.textPrimary,
                              fontWeight: isMe ? FontWeight.w700 : null,
                            ),
                          ),
                          trailing: Text(
                            '${entry.score}',
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Owns its [TextEditingController] so it is disposed only after the
/// dialog's exit animation has finished.
class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: LeaderboardEntry.maxNameLength,
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
