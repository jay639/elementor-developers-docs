import 'dart:ui' as ui;

import 'package:arrow_engine/arrow_engine.dart';
import 'package:arrow_escape/core/theme/app_theme.dart';
import 'package:arrow_escape/core/theme/board_style.dart';
import 'package:arrow_escape/features/game/presentation/board_animations.dart';
import 'package:arrow_escape/features/game/presentation/board_painter.dart';
import 'package:arrow_escape/features/game/presentation/track.dart';
import 'package:arrow_escape/features/settings/domain/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const size = Size(390, 600);

  final styles = [
    for (final b in Brightness.values)
      for (final settings in const [
        AppSettings(),
        AppSettings(thickArrows: true),
        AppSettings(highContrast: true),
        AppSettings(colorblind: true),
      ])
        BoardStyle.of(
          AppTheme.build(b, highContrast: settings.highContrast),
          settings,
        ),
  ];

  test('paints every sample level in every style, mid-animation', () {
    for (final level in sampleLevels) {
      final rules = Rules(level);
      final board = rules.initialState;
      final rest = [
        for (var i = 0; i < level.pieces.length; i++)
          Track.forPiece(level, i, const []),
      ];
      final animations = <int, PieceAnimation>{};
      final flashes = <FlashAnimation>[];
      for (var i = 0; i < level.pieces.length; i++) {
        final out = rules.evaluate(board, i);
        final track = Track.forPiece(level, i, switch (out) {
          ExitMove(:final path) => path,
          BlockedMove(:final path, :final freeSteps) => path.sublist(
            0,
            freeSteps.clamp(0, path.length),
          ),
        });
        animations[i] = switch (out) {
          ExitMove() => ExitAnimation(i, track, Duration.zero),
          BlockedMove() => BumpAnimation(
            i,
            track,
            Duration.zero,
            distance: BumpAnimation.distanceFor(out),
          ),
        };
        if (out is BlockedMove) {
          flashes.add(
            FlashAnimation(
              piece: out.blockerPiece,
              cell: out.blockerCell ?? level.pieces[i].head,
              start: Duration.zero,
            ),
          );
        }
      }
      for (final style in styles) {
        for (final showPaths in [false, true]) {
          for (final anim in [<int, PieceAnimation>{}, animations]) {
            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);
            BoardBackgroundPainter(
              level: level,
              style: style,
            ).paint(canvas, size);
            BoardPiecesPainter(
              rules: rules,
              restTracks: rest,
              board: board,
              style: style,
              showPaths: showPaths,
              animations: anim,
              flashes: flashes,
              now: () => const Duration(milliseconds: 120),
            ).paint(canvas, size);
            recorder.endRecording().dispose();
          }
        }
      }
    }
  });

  test('bump goes out and comes back', () {
    final level = parseAsciiLevel('>..^');
    final track = Track.forPiece(level, 0, const [1, 2]);
    final bump = BumpAnimation(0, track, Duration.zero, distance: 2.28);
    expect(bump.offsetAt(Duration.zero), 0);
    expect(bump.offsetAt(bump.impact), closeTo(2.28, 1e-6));
    expect(bump.offsetAt(bump.duration), closeTo(0, 1e-6));
    expect(bump.isDone(bump.duration), isTrue);
  });

  test('exit animation ends fully off the board', () {
    final level = parseAsciiLevel('>..');
    final track = Track.forPiece(level, 0, const [1, 2]);
    final exit = ExitAnimation(0, track, Duration.zero);
    expect(exit.offsetAt(exit.duration), track.exitTravel);
    expect(exit.remainsOnBoard, isFalse);
  });

  test('reduce motion shortens animations', () {
    final level = parseAsciiLevel('>.........');
    final track = Track.forPiece(level, 0, List.generate(9, (i) => i + 1));
    expect(
      ExitAnimation(0, track, Duration.zero, fast: true).duration,
      lessThan(ExitAnimation(0, track, Duration.zero).duration),
    );
  });

  test('flash pulses then fades', () {
    final f = FlashAnimation(cell: 0, start: const Duration(milliseconds: 100));
    expect(f.intensity(Duration.zero), 0);
    expect(f.intensity(const Duration(milliseconds: 310)), greaterThan(0.9));
    expect(f.isDone(const Duration(milliseconds: 600)), isTrue);
  });
}
