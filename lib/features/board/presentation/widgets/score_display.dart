import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../themes/presentation/theme_controller.dart';
import '../controllers/game_controller.dart';

/// Score milestones that trigger a celebration pop.
abstract final class ScoreMilestones {
  static const List<int> _early = [100, 250, 500];

  /// Every 1,000 after the early ones.
  static const int step = 1000;

  static bool isMilestone(int score) =>
      _early.contains(score) || (score > 0 && score % step == 0);

  /// The highest milestone passed when the score went from [previous] to
  /// [current], or `null` if none was crossed.
  static int? crossed(int previous, int current) {
    if (current <= previous) return null;
    int? hit;
    for (final m in _early) {
      if (previous < m && current >= m) hit = m;
    }
    final lastStep = current ~/ step * step;
    if (lastStep > 0 && previous < lastStep) hit = lastStep;
    return hit;
  }
}

/// The current score, big and centred above the board. Counts up smoothly
/// and pops, with a short label, whenever a milestone is crossed.
class ScoreDisplay extends ConsumerStatefulWidget {
  const ScoreDisplay({super.key});

  static const milestoneKey = ValueKey('score-milestone');

  @override
  ConsumerState<ScoreDisplay> createState() => _ScoreDisplayState();
}

class _ScoreDisplayState extends ConsumerState<ScoreDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.35,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 25,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.35,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 75,
    ),
  ]).animate(_pop);

  int? _milestone;

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(gameControllerProvider.select((s) => s.score), (
      previous,
      next,
    ) {
      final hit = ScoreMilestones.crossed(previous ?? next, next);
      if (hit != null) {
        setState(() => _milestone = hit);
        _pop.forward(from: 0);
      }
    });

    final palette = ref.watch(paletteProvider);
    final score = ref.watch(gameControllerProvider.select((s) => s.score));

    return SizedBox(
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          ScaleTransition(
            scale: _scale,
            child: TweenAnimationBuilder<int>(
              tween: IntTween(end: score),
              duration: const Duration(milliseconds: 300),
              builder: (_, value, _) => Text(
                '$value',
                key: const ValueKey('score'),
                style: TextStyle(
                  color: palette.accent,
                  fontSize: 48,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          if (_milestone != null)
            Positioned(
              top: 0,
              child: FadeTransition(
                opacity: TweenSequence<double>([
                  TweenSequenceItem(
                    tween: Tween<double>(begin: 0, end: 1),
                    weight: 15,
                  ),
                  TweenSequenceItem(
                    tween: ConstantTween<double>(1),
                    weight: 55,
                  ),
                  TweenSequenceItem(
                    tween: Tween<double>(begin: 1, end: 0),
                    weight: 30,
                  ),
                ]).animate(_pop),
                child: Text(
                  '${_milestone!}!',
                  key: ScoreDisplay.milestoneKey,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
