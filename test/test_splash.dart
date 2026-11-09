import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cut_the_cable/app/providers.dart';
import 'package:cut_the_cable/app/theme/app_theme.dart';
import 'package:cut_the_cable/config/game_config.dart';
import 'package:cut_the_cable/data/models/player_progress.dart';
import 'package:cut_the_cable/features/splash/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test splash capture', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final config = await GameConfig.load();
    final mockProgress = PlayerProgress.initial(100).copyWith(
      totalStars: 45,
      currency: 350,
      tutorialCompleted: true,
    );

    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    final key = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gameConfigProvider.overrideWith((ref) => Future.value(config)),
          progressProvider.overrideWith((ref) {
            final repo = ref.watch(saveRepositoryProvider);
            final notifier = ProgressNotifier(repo, 100);
            notifier.state = AsyncValue.data(mockProgress);
            return notifier;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.themeData,
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: const SplashScreen(),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;

    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final file = File('screenshots/01_splash_screen.png');
      await file.writeAsBytes(bytes);
      print('Saved splash screenshot: ${file.lengthSync()} bytes');
    });
  });
}
