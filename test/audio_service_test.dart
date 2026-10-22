import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cut_the_cable/services/audio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
  });

  group('AudioService Tests', () {
    test('initializes with default enabled state', () {
      final audio = AudioService();
      expect(audio.musicEnabled, isTrue);
      expect(audio.soundEnabled, isTrue);
    });

    test('configures music and sound states correctly', () {
      final audio = AudioService();
      audio.configure(music: false, sound: false);
      expect(audio.musicEnabled, isFalse);
      expect(audio.soundEnabled, isFalse);

      audio.configure(music: true, sound: true);
      expect(audio.musicEnabled, isTrue);
      expect(audio.soundEnabled, isTrue);
    });

    test('toggles music and sound independently', () {
      final audio = AudioService();
      audio.toggleMusic();
      expect(audio.musicEnabled, isFalse);
      expect(audio.soundEnabled, isTrue);

      audio.toggleSound();
      expect(audio.musicEnabled, isFalse);
      expect(audio.soundEnabled, isFalse);

      audio.toggleMusic();
      expect(audio.musicEnabled, isTrue);
      expect(audio.soundEnabled, isFalse);
    });
  });
}
