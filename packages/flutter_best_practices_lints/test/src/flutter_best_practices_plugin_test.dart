// 📦 Package imports:
import 'package:analysis_server_plugin/plugin.dart';
import 'package:flutter_best_practices_lints/main.dart' as entrypoint;

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/flutter_best_practices_lints.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

void main() {
  group('FlutterBestPracticesPlugin', () {
    test('exposes the official top-level plugin', () {
      expect(entrypoint.plugin, isA<Plugin>());
      expect(entrypoint.plugin, isA<FlutterBestPracticesPlugin>());
      expect(entrypoint.plugin.name, 'flutter_best_practices_lints');
    });
  });
}
