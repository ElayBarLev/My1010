// Generates the app icon for every platform from vector drawing code.
//
// Run from the project root:
//   flutter test tool/icon/generate_icons_test.dart
//
// The icon is a rounded square with a white question mark. The "?" is
// built from strokes (an arc, a curve and a dot) rather than a font, so the
// output is identical on every machine. Tweak the constants below and re-run
// to restyle it.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const background = Color(0xFF5BBEE5); // Classic palette "sky" block colour.
const glyph = Colors.white;

/// Paints the "?" inside [box].
void paintQuestionMark(Canvas canvas, Rect box, Color color) {
  double x(double u) => box.left + u * box.width;
  double y(double v) => box.top + v * box.height;
  final s = box.width;

  final stroke = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.13 * s
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  const r = 0.19;
  final path = Path()
    ..addArc(
      Rect.fromCircle(center: Offset(x(0.5), y(0.30)), radius: r * s),
      pi, // start on the left
      4 * pi / 3, // over the top, ending lower-right
    )
    ..quadraticBezierTo(x(0.5), y(0.51), x(0.5), y(0.60))
    ..lineTo(x(0.5), y(0.64));
  canvas.drawPath(path, stroke);

  canvas.drawCircle(Offset(x(0.5), y(0.84)), 0.085 * s, Paint()..color = color);
}

enum Style {
  /// Rounded square on transparency (Android legacy, web, favicon).
  rounded,

  /// Full-bleed square, no transparency (iOS applies its own mask).
  fullBleed,

  /// Glyph only on transparency, inside the adaptive-icon safe zone.
  foreground,

  /// Full-bleed with the glyph inside the maskable safe zone (web PWA).
  maskable,
}

Future<List<int>> render(int size, Style style) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final full = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
  final fill = Paint()..color = background;

  double glyphFraction;
  switch (style) {
    case Style.rounded:
      final inset = full.deflate(size * 0.04);
      canvas.drawRRect(
        RRect.fromRectAndRadius(inset, Radius.circular(size * 0.22)),
        fill,
      );
      glyphFraction = 0.62;
    case Style.fullBleed:
      canvas.drawRect(full, fill);
      glyphFraction = 0.62;
    case Style.foreground:
      // Adaptive icons: 108dp canvas, only the central 66dp is guaranteed
      // visible, so keep the glyph well inside it.
      glyphFraction = 0.44;
    case Style.maskable:
      canvas.drawRect(full, fill);
      glyphFraction = 0.5;
  }

  final g = size * glyphFraction;
  paintQuestionMark(
    canvas,
    Rect.fromCenter(center: full.center, width: g, height: g),
    glyph,
  );

  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

void main() {
  testWidgets('generate app icons', (tester) async {
    final outputs = <String, (int, Style)>{
      // Android legacy launcher icons.
      for (final (dir, px) in const [
        ('mdpi', 48),
        ('hdpi', 72),
        ('xhdpi', 96),
        ('xxhdpi', 144),
        ('xxxhdpi', 192),
      ]) ...{
        'android/app/src/main/res/mipmap-$dir/ic_launcher.png': (
          px,
          Style.rounded,
        ),
        // Adaptive icon foreground (108dp canvas).
        'android/app/src/main/res/mipmap-$dir/ic_launcher_foreground.png': (
          px * 108 ~/ 48,
          Style.foreground,
        ),
      },
      // iOS (must be opaque).
      for (final (name, px) in const [
        ('20x20@1x', 20),
        ('20x20@2x', 40),
        ('20x20@3x', 60),
        ('29x29@1x', 29),
        ('29x29@2x', 58),
        ('29x29@3x', 87),
        ('40x40@1x', 40),
        ('40x40@2x', 80),
        ('40x40@3x', 120),
        ('60x60@2x', 120),
        ('60x60@3x', 180),
        ('76x76@1x', 76),
        ('76x76@2x', 152),
        ('83.5x83.5@2x', 167),
        ('1024x1024@1x', 1024),
      ])
        'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-$name.png': (
          px,
          Style.fullBleed,
        ),
      // Web.
      'web/favicon.png': (32, Style.rounded),
      'web/icons/Icon-192.png': (192, Style.rounded),
      'web/icons/Icon-512.png': (512, Style.rounded),
      'web/icons/Icon-maskable-192.png': (192, Style.maskable),
      'web/icons/Icon-maskable-512.png': (512, Style.maskable),
      // Preview for the README.
      'tool/icon/preview.png': (512, Style.rounded),
    };

    await tester.runAsync(() async {
      for (final MapEntry(key: path, value: (px, style)) in outputs.entries) {
        final file = File(path)..createSync(recursive: true);
        file.writeAsBytesSync(await render(px, style));
      }
    });
  });
}
