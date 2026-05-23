// 📦 Package imports:
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/flutter_best_practices_lints.dart';

void main() {
  group('FlutterBestPracticesLints', () {
    test('can be instantiated', () {
      expect(FlutterBestPracticesPlugin(), isNotNull);
    });

    test('creates plugin with correct rules', () {
      final plugin = createPlugin();
      expect(plugin, isA<PluginBase>());

      final rules = plugin.getLintRules(
        // ignore: invalid_use_of_internal_member
        const CustomLintConfigs(
          enableAllLintRules: true,
          verbose: true,
          debug: true,
          rules: <String, LintOptions>{},
        ),
      );

      expect(rules, hasLength(4));
      expect(rules[0], isA<SingleClassPerFile>());
      expect(rules[1], isA<MatchingClassAndFileName>());
      expect(rules[2], isA<PreferWidgetClassOverWidgetHelper>());
      expect(rules[3], isA<AvoidWidgetOperatorEquals>());
    });
  });
}
