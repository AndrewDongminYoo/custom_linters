// 🌎 Project imports:
import 'package:go_router_linter/go_router_linter.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

import '../lint_test_utils.dart';

void main() {
  group('AvoidHardcodedRoutes', () {
    test('reports hardcoded route identifiers', () async {
      final errors = await analyzeLintRule(
        const AvoidHardcodedRoutes(),
        '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/home',
      name: 'home',
      redirect: (BuildContext context, GoRouterState state) => '/login',
      builder: (BuildContext context, GoRouterState state) {
        context.namedLocation('home');
        return const SizedBox.shrink();
      },
    ),
  ],
);
''',
      );

      expect(errors, everyElement('avoid_hardcoded_routes'));
      expect(errors, hasLength(4));
    });

    test('ignores non-route string arguments', () async {
      final errors = await analyzeLintRule(
        const AvoidHardcodedRoutes(),
        '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

const routeName = 'home';

void navigate(BuildContext context) {
  context.goNamed(routeName, queryParameters: {'tab': 'profile'});
}
''',
      );

      expect(errors, isEmpty);
    });

    test('reports hardcoded initialLocation in GoRouter', () async {
      final errors = await analyzeLintRule(
        const AvoidHardcodedRoutes(),
        '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/home',
  routes: [],
);
''',
      );

      expect(errors, everyElement('avoid_hardcoded_routes'));
      expect(errors, hasLength(1));
    });

    test('ignores constant initialLocation in GoRouter', () async {
      final errors = await analyzeLintRule(
        const AvoidHardcodedRoutes(),
        '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

const homeRoute = '/home';

final router = GoRouter(
  initialLocation: homeRoute,
  routes: [],
);
''',
      );

      expect(errors, isEmpty);
    });
  });
}
