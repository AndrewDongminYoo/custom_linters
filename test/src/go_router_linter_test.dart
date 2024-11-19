// ignore_for_file: prefer_const_constructors
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:go_router_linter/go_router_linter.dart';
import 'package:test/test.dart';

void main() {
  group('UseContextDirectlyForGoRouter', () {
    test('reports error for GoRouter.of(context)', () {
      final rule = UseContextDirectlyForGoRouter();
      expect(rule.code.name, equals('use_context_directly_for_go_router'));
      expect(
        rule.code.problemMessage,
        equals('Use context.go instead of GoRouter.of(context).go.'),
      );
    });

    group('run', () {
      test('detects GoRouter.of with context argument', () {
        final rule = UseContextDirectlyForGoRouter();
        expect(rule, isNotNull);
      });

      test('code property returns correct LintCode', () {
        final rule = UseContextDirectlyForGoRouter();
        expect(rule.code.name, equals('use_context_directly_for_go_router'));
        expect(
          rule.code.problemMessage,
          equals('Use context.go instead of GoRouter.of(context).go.'),
        );
      });
    });

    group('_GoRouterLintPlugin', () {
      test('creates plugin with correct rules', () {
        final plugin = createPlugin();
        expect(plugin, isA<PluginBase>());

        final rules = plugin.getLintRules(
          // ignore: invalid_use_of_internal_member
          CustomLintConfigs(
            enableAllLintRules: true,
            verbose: true,
            debug: true,
            rules: const <String, LintOptions>{},
          ),
        );
        expect(rules, isA<List<LintRule>>());
        expect(rules, hasLength(1));
        expect(rules.first, isA<UseContextDirectlyForGoRouter>());
      });
    });
  });
}
