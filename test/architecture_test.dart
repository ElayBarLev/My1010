import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Enforces the module layering: core ← features ← games ← app.dart.
void main() {
  final imports = <String, List<String>>{};
  final libDir = Directory('lib');
  final directive = RegExp(
    r'''^(?:import|export)\s+'([^']+)'.*$''',
    multiLine: true,
  );
  for (final file in libDir.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart')) continue;
    final from = file.path.replaceAll(r'\', '/');
    imports[from] = [
      for (final match in directive.allMatches(file.readAsStringSync()))
        _resolve(from, match.group(1)!),
    ];
  }

  List<String> violations(bool Function(String from, String to) isBad) => [
    for (final MapEntry(key: from, value: targets) in imports.entries)
      for (final to in targets)
        if (isBad(from, to)) '$from -> $to',
  ];

  test('core depends on nothing app-specific', () {
    expect(
      violations(
        (from, to) =>
            from.startsWith('lib/core/') &&
            (to.startsWith('lib/features/') || to.startsWith('lib/games/')),
      ),
      isEmpty,
    );
  });

  test('features never depend on games', () {
    expect(
      violations(
        (from, to) =>
            from.startsWith('lib/features/') && to.startsWith('lib/games/'),
      ),
      isEmpty,
    );
  });

  test('games are isolated from each other', () {
    String? gameOf(String path) {
      final parts = path.split('/');
      return parts.length > 3 && parts[1] == 'games' ? parts[2] : null;
    }

    expect(
      violations((from, to) {
        final a = gameOf(from), b = gameOf(to);
        return a != null && b != null && a != b;
      }),
      isEmpty,
    );
  });

  test('game domains are pure Dart', () {
    expect(
      violations(
        (from, to) =>
            RegExp(r'^lib/games/\w+/domain/').hasMatch(from) &&
            (to.startsWith('package:flutter') || to == 'dart:ui'),
      ),
      isEmpty,
    );
  });
}

/// Turns a relative or `package:my1010/` URI into a `lib/...` path; other
/// URIs (dart:, other packages) are returned unchanged.
String _resolve(String from, String uri) {
  if (uri.startsWith('package:my1010/')) {
    return 'lib/${uri.substring('package:my1010/'.length)}';
  }
  if (uri.contains(':')) return uri;
  return Uri.parse(from).resolve(uri).path;
}
