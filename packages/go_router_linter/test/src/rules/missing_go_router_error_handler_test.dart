// 🌎 Project imports:
import 'package:go_router_linter/go_router_linter.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

import '../lint_test_utils.dart';

void main() {
  group('MissingGoRouterErrorHandler', () {
    test('reports GoRouter without error handler', () async {
      const source = '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const SizedBox.shrink(),
    ),
  ],
);
''';
      final errors = await analyzeLintRule(
        const MissingGoRouterErrorHandler(),
        source,
      );

      expect(errors, hasLength(1));
      const invocation = '''GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const SizedBox.shrink(),
    ),
  ],
)''';
      expectLintDiagnostic(
        errors.single,
        code: 'missing_go_router_error_handler',
        message: 'GoRouter should define an error handler for unknown routes.',
        correctionMessage:
            'Add an `errorBuilder` or `errorPageBuilder` argument.',
        offset: source.indexOf(invocation),
        length: invocation.length,
      );
    });

    test('ignores GoRouter with errorBuilder', () async {
      final errors = await analyzeLintRule(
        const MissingGoRouterErrorHandler(),
        '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [],
  errorBuilder: (context, state) => const SizedBox.shrink(),
);
''',
      );

      expect(errors, isEmpty);
    });

    test('ignores GoRouter with errorPageBuilder', () async {
      final errors = await analyzeLintRule(
        const MissingGoRouterErrorHandler(),
        '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [],
  errorPageBuilder: (context, state) =>
      const NoTransitionPage(child: SizedBox.shrink()),
);
''',
      );

      expect(errors, isEmpty);
    });

    test('ignores GoRouter with both error handlers', () async {
      final errors = await analyzeLintRule(
        const MissingGoRouterErrorHandler(),
        '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [],
  errorBuilder: (context, state) => const SizedBox.shrink(),
  errorPageBuilder: (context, state) =>
      const NoTransitionPage(child: SizedBox.shrink()),
);
''',
      );

      expect(errors, isEmpty);
    });

    test('ignores constructors that are not GoRouter', () async {
      final errors = await analyzeLintRule(
        const MissingGoRouterErrorHandler(),
        '''
class RouterConfiguration {
  const RouterConfiguration({required this.routes});

  final List<Object> routes;
}

const router = RouterConfiguration(routes: []);
''',
      );

      expect(errors, isEmpty);
    });
  });
}
