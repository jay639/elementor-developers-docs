// Renders the launcher icons from the in-app logo (not part of CI):
//   flutter test test_screens/icon_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:arrow_escape/core/widgets/arrow_logo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('render icons', (tester) async {
    await tester.runAsync(() async {
      for (final (name, square) in [
        ('icon_round', false),
        ('icon_square', true),
      ]) {
        const s = 1024.0;
        final recorder = ui.PictureRecorder();
        paintLogo(ui.Canvas(recorder), s, 0, square);
        final image = await recorder.endRecording().toImage(1024, 1024);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory('test_screens/out').createSync(recursive: true);
        File(
          'test_screens/out/$name.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
      }
    });
  });
}
