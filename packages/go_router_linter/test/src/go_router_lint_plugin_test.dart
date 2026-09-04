// 📦 Package imports:
import 'package:analysis_server_plugin/plugin.dart';
import 'package:go_router_linter/main.dart' as entrypoint;

// 🧪 Test imports:
import 'package:test/test.dart';

void main() {
  group('GoRouterLintPlugin', () {
    test('exposes the official top-level plugin', () {
      expect(entrypoint.plugin, isA<Plugin>());
      expect(entrypoint.plugin.name, 'go_router_linter');
    });
  });
}
