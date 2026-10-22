import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app/router.dart';
import 'app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce edge-to-edge layout from the very first frame, before any
  // other platform channel calls. This prevents Android from initially
  // sizing the window around system bar insets (the "small top-left" flash).
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };

  ui.PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught Platform Error: $error');
    return true;
  };

  // Lock to portrait (also declared natively in AndroidManifest.xml)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize MobileAds asynchronously without blocking runApp()
  MobileAds.instance.initialize().then((status) {
    debugPrint('MobileAds initialized: ${status.adapterStatuses}');
  }).catchError((e) {
    debugPrint('MobileAds init error: $e');
  });

  runApp(const ProviderScope(child: CutTheCableApp()));
}

class CutTheCableApp extends StatelessWidget {
  const CutTheCableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cut the Cable',
      theme: AppTheme.themeData,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
