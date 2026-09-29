import 'package:meta/meta.dart';

/// One player's best score for one game mode.
@immutable
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.score,
    required this.modeId,
    this.updatedAt,
  });

  final String uid;
  final String displayName;
  final int score;
  final String modeId;

  /// `null` while a server timestamp is still pending.
  final DateTime? updatedAt;

  static const int maxNameLength = 20;

  /// Trims and bounds a user-entered display name.
  static String sanitizeName(String raw) {
    final trimmed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) return 'Player';
    return trimmed.length > maxNameLength
        ? trimmed.substring(0, maxNameLength)
        : trimmed;
  }
}
