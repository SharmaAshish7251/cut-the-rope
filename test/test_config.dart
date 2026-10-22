import 'package:flutter_test/flutter_test.dart';
import 'package:cut_the_cable/config/game_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Check GameConfig.load() in test', () async {
    final config = await GameConfig.load();
    print('Loaded config: ${config.game.title}, totalLevels: ${config.game.totalLevels}');
  });
}
