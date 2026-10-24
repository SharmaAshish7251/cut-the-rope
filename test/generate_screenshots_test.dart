import 'dart:convert';
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
import 'package:cut_the_cable/features/shop/daily_rewards.dart';
import 'package:cut_the_cable/features/achievements/achievements_screen.dart';
import 'package:cut_the_cable/features/gameplay/gameplay_screen.dart';
import 'package:cut_the_cable/features/pause/pause_overlay.dart';
import 'package:cut_the_cable/features/victory/victory_overlay.dart';
import 'package:cut_the_cable/features/failure/failure_overlay.dart';
import 'package:cut_the_cable/features/hints/hint_overlay.dart';
import 'package:cut_the_cable/features/boosters/booster_overlay.dart';
import 'package:cut_the_cable/features/victory/grand_finale_screen.dart';
import 'package:cut_the_cable/data/models/inventory_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.now();
  SharedPreferences.setMockInitialValues({
    'player_inventory_v1': jsonEncode(
      Inventory(
        claimHistory: {
          'daily_${now.year}-${now.month}-${now.day}': now,
        },
        hintCredits: 2,
        boosters: {
          for (final type in BoosterType.values) type: 1,
        },
      ).toJson(),
    ),
  });

  Future<void> captureWidget(
    WidgetTester tester,
    Widget widget,
    String fileName,
  ) async {
    final key = GlobalKey();

    await tester.binding.setSurfaceSize(const Size(393, 851));
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

    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 250)),
    );
    await tester.pump();

    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.75);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final dir = Directory('screenshots');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final file = File('screenshots/$fileName');
      await file.writeAsBytes(pngBytes);
      print('Saved screenshot: ${file.path}');
    });

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    await tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
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

  testWidgets('Generate Gameplay Screen Screenshot', (tester) async {
    await captureWidget(
      tester,
      const GameplayScreen(levelId: 1),
      '08_gameplay_screen.png',
    );
  });

  testWidgets('Generate Daily Reward Screenshot', (tester) async {
    await captureWidget(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: DailyRewardSheet(
          currentDay: 1,
          alreadyClaimed: false,
          onClaim: () {},
          onDismiss: () {},
        ),
      ),
      '09_daily_reward.png',
    );
  });

  testWidgets('Generate Pause Overlay Screenshot', (tester) async {
    await captureWidget(
      tester,
      PauseOverlay(
        onResume: () {},
        onRestart: () {},
        onHome: () {},
        onLevelMap: () {},
      ),
      '10_pause_overlay.png',
    );
  });

  testWidgets('Generate Victory Overlay Screenshot', (tester) async {
    await captureWidget(
      tester,
      VictoryOverlay(
        score: 6500,
        stars: 3,
        levelId: 1,
        currencyEarned: 25,
        onReplay: () {},
        onNext: () {},
        onLevelMap: () {},
      ),
      '11_victory_overlay.png',
    );
  });

  testWidgets('Generate Failure Overlay Screenshot', (tester) async {
    await captureWidget(
      tester,
      FailureOverlay(
        onRetry: () {},
        onHome: () {},
        onLevelMap: () {},
        onHint: () {},
        onBooster: () {},
      ),
      '12_failure_overlay.png',
    );
  });

  testWidgets('Generate Hint Dialog Screenshot', (tester) async {
    await captureWidget(
      tester,
      HintDialog(
        hasCredits: true,
        creditCount: 2,
        hintText: 'Cut the lower rope after the candy swings right.',
        onUseHint: () {},
        onEarnHint: () {},
        onCancel: () {},
      ),
      '13_hint_dialog.png',
    );
  });

  testWidgets('Generate Offline Hint Dialog Screenshot', (tester) async {
    await captureWidget(
      tester,
      HintOfflineDialog(onDismiss: () {}),
      '14_offline_hint_dialog.png',
    );
  });

  testWidgets('Generate Booster Overlay Screenshot', (tester) async {
    await captureWidget(
      tester,
      BoosterOverlay(
        inventory: Inventory(
          hintCredits: 2,
          boosters: {
            for (final type in BoosterType.values) type: 1,
          },
        ),
        onActivate: (_) {},
        onEarn: (_) {},
        onCancel: () {},
      ),
      '15_booster_overlay.png',
    );
  });

  testWidgets('Generate Grand Finale Screenshot', (tester) async {
    await captureWidget(
      tester,
      GrandFinaleScreen(
        totalStars: 300,
        finalScore: 100000,
        onReplay: () {},
      ),
      '16_grand_finale_screen.png',
    );
  });
}
