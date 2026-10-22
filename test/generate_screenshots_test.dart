import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:cut_the_cable/app/theme/app_theme.dart';
import 'package:cut_the_cable/features/splash/splash_screen.dart';
import 'package:cut_the_cable/features/onboarding/onboarding_screen.dart';
import 'package:cut_the_cable/features/home/home_screen.dart';
import 'package:cut_the_cable/features/level_selection/level_selection_screen.dart';
import 'package:cut_the_cable/features/settings/settings_screen.dart';
import 'package:cut_the_cable/features/shop/shop_screen.dart';
import 'package:cut_the_cable/features/achievements/achievements_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  Future<void> captureWidget(
    WidgetTester tester,
    Widget widget,
    String fileName,
  ) async {
    final key = GlobalKey();

    await tester.binding.setSurfaceSize(const Size(1080, 2340));
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.themeData,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: widget,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final dir = Directory('screenshots');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final file = File('screenshots/$fileName');
    await file.writeAsBytes(pngBytes);
    print('Saved screenshot: ${file.path}');
  }

  testWidgets('Generate Splash Screen Screenshot', (tester) async {
    await captureWidget(tester, const SplashScreen(), '01_splash_screen.png');
  });

  testWidgets('Generate Onboarding Screen Screenshot', (tester) async {
    await captureWidget(tester, const OnboardingScreen(), '02_onboarding_screen.png');
  });

  testWidgets('Generate Home Screen Screenshot', (tester) async {
    await captureWidget(tester, const HomeScreen(), '03_home_screen.png');
  });

  testWidgets('Generate Level Selection Screen Screenshot', (tester) async {
    await captureWidget(tester, const LevelSelectionScreen(), '04_level_selection_screen.png');
  });

  testWidgets('Generate Shop Screen Screenshot', (tester) async {
    await captureWidget(tester, const ShopScreen(), '05_shop_screen.png');
  });

  testWidgets('Generate Achievements Screen Screenshot', (tester) async {
    await captureWidget(tester, const AchievementsScreen(), '06_achievements_screen.png');
  });

  testWidgets('Generate Settings Screen Screenshot', (tester) async {
    await captureWidget(tester, const SettingsScreen(), '07_settings_screen.png');
  });
}
