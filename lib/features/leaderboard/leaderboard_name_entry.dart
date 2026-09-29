import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firebase/leaderboard_entry.dart';
import '../../core/ui_kit/theme/theme_controller.dart';
import 'leaderboard_providers.dart';

/// Game-over name field: no account needed. The score is already submitted
/// automatically; saving a name renames the player and re-submits it.
class LeaderboardNameEntry extends ConsumerStatefulWidget {
  const LeaderboardNameEntry({
    super.key,
    required this.gameId,
    required this.score,
  });

  final String gameId;

  /// The finished game's score, re-submitted under the new name.
  final int score;

  static const fieldKey = ValueKey('leaderboard-name-field');
  static const saveKey = ValueKey('leaderboard-name-save');

  @override
  ConsumerState<LeaderboardNameEntry> createState() =>
      _LeaderboardNameEntryState();
}

class _LeaderboardNameEntryState extends ConsumerState<LeaderboardNameEntry> {
  late final _controller = TextEditingController(
    text: ref.read(playerNameProvider),
  );
  bool _saved = false;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    await ref.read(playerNameProvider.notifier).rename(_controller.text);
    _controller.text = ref.read(playerNameProvider);
    await ref
        .read(scoreSubmitterProvider)
        .submit(gameId: widget.gameId, score: widget.score);
    if (mounted) {
      setState(() {
        _saving = false;
        _saved = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(paletteProvider);
    return SizedBox(
      width: 280,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: LeaderboardNameEntry.fieldKey,
              controller: _controller,
              maxLength: LeaderboardEntry.maxNameLength,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_saved) setState(() => _saved = false);
              },
              onSubmitted: (_) => _save(),
              style: TextStyle(color: palette.textPrimary),
              decoration: InputDecoration(
                labelText: 'Name on leaderboard',
                counterText: '',
                isDense: true,
                labelStyle: TextStyle(color: palette.textSecondary),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            key: LeaderboardNameEntry.saveKey,
            tooltip: 'Save name',
            onPressed: _saving ? null : _save,
            icon: Icon(_saved ? Icons.check_rounded : Icons.send_rounded),
          ),
        ],
      ),
    );
  }
}
