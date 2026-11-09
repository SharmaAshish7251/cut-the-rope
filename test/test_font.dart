import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadTestFonts() async {
  try {
    final fredoka = FontLoader('Fredoka');
    fredoka.addFont(rootBundle.load('assets/fonts/Fredoka-Regular.ttf'));
    fredoka.addFont(rootBundle.load('assets/fonts/Fredoka-Bold.ttf'));
    await fredoka.load();

    final nunito = FontLoader('Nunito');
    nunito.addFont(rootBundle.load('assets/fonts/Nunito-Regular.ttf'));
    nunito.addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'));
    await nunito.load();
    print('Fonts loaded successfully!');
  } catch (e) {
    print('Error loading fonts: $e');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test Font Rendering', (tester) async {
    await loadTestFonts();

    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: Container(
            width: 400,
            height: 200,
            color: const Color(0xFFFFF9F0),
            padding: const EdgeInsets.all(20),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cut the Cable',
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B3D),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'A sweet puzzle adventure',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final file = File('screenshots/test_font.png');
      await file.writeAsBytes(bytes);
      print('Saved test_font.png: ${bytes.length} bytes');
    });
  });
}
