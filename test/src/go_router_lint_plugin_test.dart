// 📦 Package imports:
import 'package:custom_lint_builder/custom_lint_builder.dart';

// 🌎 Project imports:
import 'package:go_router_linter/go_router_linter.dart';

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
        expect(rules, hasLength(3));
        expect(rules[0], isA<UseContextDirectlyForGoRouter>());
        expect(rules[1], isA<MissingGoRouteNameProperty>());
        expect(rules[2], isA<AvoidHardcodedRoutes>());
      });
    });
  });
}
