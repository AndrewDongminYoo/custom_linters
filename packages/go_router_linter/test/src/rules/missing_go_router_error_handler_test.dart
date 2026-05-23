// 🌎 Project imports:
import 'package:go_router_linter/go_router_linter.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

import '../lint_test_utils.dart';

void main() {
  group('MissingGoRouterErrorHandler', () {
    test('reports GoRouter without error handler', () async {
      final errors = await analyzeLintRule(
        const MissingGoRouterErrorHandler(),
        '''
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
''',
      );

      expect(errors, everyElement('missing_go_router_error_handler'));
      expect(errors, hasLength(1));
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
  });
}
