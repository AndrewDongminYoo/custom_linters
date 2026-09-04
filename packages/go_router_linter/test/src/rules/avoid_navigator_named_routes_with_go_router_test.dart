// 🌎 Project imports:
import 'package:go_router_linter/go_router_linter.dart';

// 📦 Package imports:
import 'package:pubspec_parse/pubspec_parse.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

import '../lint_test_utils.dart';

void main() {
  group('AvoidNavigatorNamedRoutesWithGoRouter', () {
    test(
      'reports every Navigator named route call when go_router is a dependency',
      () async {
        const source = '''
import 'package:flutter/widgets.dart';

void navigate(BuildContext context) {
  Navigator.pushNamed(context, '/details');
  Navigator.pushReplacementNamed(context, '/details');
  Navigator.popAndPushNamed(context, '/details');
  Navigator.pushNamedAndRemoveUntil(context, '/details', (_) => false);
  Navigator.restorablePushNamed(context, '/details');
  Navigator.restorablePushReplacementNamed(context, '/details');
  Navigator.restorablePopAndPushNamed(context, '/details');
  Navigator.restorablePushNamedAndRemoveUntil(
    context,
    '/details',
    (_) => false,
  );
}
''';
        final errors = await analyzeLintRule(
          const AvoidNavigatorNamedRoutesWithGoRouter(),
          source,
          pubspec: Pubspec.parse('''
name: test_project
dependencies:
  go_router: any
'''),
        );

        const invocations = [
          "Navigator.pushNamed(context, '/details')",
          "Navigator.pushReplacementNamed(context, '/details')",
          "Navigator.popAndPushNamed(context, '/details')",
          "Navigator.pushNamedAndRemoveUntil(context, '/details', (_) => false)",
          "Navigator.restorablePushNamed(context, '/details')",
          "Navigator.restorablePushReplacementNamed(context, '/details')",
          "Navigator.restorablePopAndPushNamed(context, '/details')",
          '''Navigator.restorablePushNamedAndRemoveUntil(
    context,
    '/details',
    (_) => false,
  )''',
        ];
        expect(errors, hasLength(invocations.length));
        for (final invocation in invocations) {
          final offset = source.indexOf(invocation);
          final diagnostic = errors.singleWhere(
            (error) => error.offset == offset,
          );
          expectLintDiagnostic(
            diagnostic,
            code: 'avoid_navigator_named_routes_with_go_router',
            message:
                'Avoid Navigator named routes in projects that use go_router.',
            correctionMessage:
                'Use go_router navigation APIs so routes stay declarative and deep-linkable.',
            offset: offset,
            length: invocation.length,
          );
        }
      },
    );

    test('activates for a go_router development dependency', () async {
      const source = '''
import 'package:flutter/widgets.dart';

void navigate(BuildContext context) {
  Navigator.pushNamed(context, '/details');
}
''';
      final errors = await analyzeLintRule(
        const AvoidNavigatorNamedRoutesWithGoRouter(),
        source,
        pubspec: Pubspec.parse('''
name: test_project
dev_dependencies:
  go_router: any
'''),
      );

      expect(errors, hasLength(1));
      const invocation = "Navigator.pushNamed(context, '/details')";
      expectLintDiagnostic(
        errors.single,
        code: 'avoid_navigator_named_routes_with_go_router',
        message: 'Avoid Navigator named routes in projects that use go_router.',
        correctionMessage:
            'Use go_router navigation APIs so routes stay declarative and deep-linkable.',
        offset: source.indexOf(invocation),
        length: invocation.length,
      );
    });

    test('preserves syntactic Navigator and NavigatorState matching', () async {
      const source = '''
class Navigator {
  static void pushNamed(Object context, String route) {}
}

class NavigatorState {
  void pushReplacementNamed(String route) {}
}

void navigate(Object context, NavigatorState state) {
  Navigator.pushNamed(context, '/details');
  state.pushReplacementNamed('/details');
}
''';
      final errors = await analyzeLintRule(
        const AvoidNavigatorNamedRoutesWithGoRouter(),
        source,
        pubspec: Pubspec.parse('''
name: test_project
dependencies:
  go_router: any
'''),
      );

      const invocations = [
        "Navigator.pushNamed(context, '/details')",
        "state.pushReplacementNamed('/details')",
      ];
      expect(errors, hasLength(invocations.length));
      for (final invocation in invocations) {
        final offset = source.indexOf(invocation);
        final diagnostic = errors.singleWhere(
          (error) => error.offset == offset,
        );
        expectLintDiagnostic(
          diagnostic,
          code: 'avoid_navigator_named_routes_with_go_router',
          message:
              'Avoid Navigator named routes in projects that use go_router.',
          correctionMessage:
              'Use go_router navigation APIs so routes stay declarative and deep-linkable.',
          offset: offset,
          length: invocation.length,
        );
      }
    });

    test('ignores Navigator named route calls without go_router', () async {
      final errors = await analyzeLintRule(
        const AvoidNavigatorNamedRoutesWithGoRouter(),
        '''
import 'package:flutter/widgets.dart';

void navigate(BuildContext context) {
  Navigator.pushNamed(context, '/details');
}
''',
      );

      expect(errors, isEmpty);
    });

    test('ignores unrelated methods and targets', () async {
      final errors = await analyzeLintRule(
        const AvoidNavigatorNamedRoutesWithGoRouter(),
        '''
class Navigator {
  static void push(Object context, String route) {}
}

class Router {
  void pushNamed(String route) {}
}

void navigate(Object context, Router router) {
  Navigator.push(context, '/details');
  router.pushNamed('/details');
}
''',
        pubspec: Pubspec.parse('''
name: test_project
dependencies:
  go_router: any
'''),
      );

      expect(errors, isEmpty);
    });
  });
}
