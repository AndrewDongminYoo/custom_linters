// 📦 Package imports:
import 'package:custom_lint_builder/custom_lint_builder.dart';

// 🌎 Project imports:
import 'package:go_router_linter/src/go_router_linter.dart';
import 'package:go_router_linter/src/rules/use_context_directly_for_go_router.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

void main() {
  group('UseContextDirectlyForGoRouter', () {
    test('reports error for GoRouter.of(context)', () {
      const rule = UseContextDirectlyForGoRouter();
      expect(rule.code.name, equals('use_context_directly_for_go_router'));
      expect(rule.code.problemMessage, equals('Use GoRouterHelper extension.'));
    });

    group('_GoRouterLintPlugin', () {
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
        expect(rules, isA<List<LintRule>>());
        expect(rules, hasLength(1));
        expect(rules.first, isA<UseContextDirectlyForGoRouter>());
      });
    });
  });
}
