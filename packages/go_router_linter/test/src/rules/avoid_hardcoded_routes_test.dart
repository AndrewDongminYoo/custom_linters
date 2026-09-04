// 🌎 Project imports:
import 'package:go_router_linter/go_router_linter.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

import '../lint_test_utils.dart';

void main() {
  group('AvoidHardcodedRoutes', () {
    test('reports hardcoded route identifiers', () async {
      const source = '''
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
''';
      final errors = await analyzeLintRule(
        const AvoidHardcodedRoutes(),
        source,
      );

      const literals = ["'/home'", "'home'", "'/login'"];
      final literalOffsets = <String, int>{
        for (final literal in literals) literal: source.indexOf(literal),
      };
      final methodLiteralOffset = source.lastIndexOf("'home'");
      expect(errors, hasLength(4));
      for (final MapEntry(key: literal, value: offset)
          in literalOffsets.entries) {
        final diagnostic = errors.singleWhere(
          (error) => error.offset == offset,
        );
        expectLintDiagnostic(
          diagnostic,
          code: 'avoid_hardcoded_routes',
          message:
              'Avoid hardcoded route paths. Use constants or enums for routes.',
          correctionMessage:
              'Use a constant, enum, or a variable instead of a hardcoded string.',
          offset: offset,
          length: literal.length,
        );
      }
      final methodDiagnostic = errors.singleWhere(
        (error) => error.offset == methodLiteralOffset,
      );
      expectLintDiagnostic(
        methodDiagnostic,
        code: 'avoid_hardcoded_routes',
        message:
            'Avoid hardcoded route paths. Use constants or enums for routes.',
        correctionMessage:
            'Use a constant, enum, or a variable instead of a hardcoded string.',
        offset: methodLiteralOffset,
        length: "'home'".length,
      );
    });

    test('reports every hardcoded context route argument', () async {
      const source = '''
class ContextLike {
  void go(String value) {}
  void push(String value) {}
  void pushReplacement(String value) {}
  void replace(String value) {}
  void goNamed(String value) {}
  void namedLocation(String value) {}
  void pushNamed(String value) {}
  void pushReplacementNamed(String value) {}
  void replaceNamed(String value) {}
}

void navigate(ContextLike context) {
  context.go('/go');
  context.push('/push');
  context.pushReplacement('/push-replacement');
  context.replace('/replace');
  context.goNamed('go-named');
  context.namedLocation('named-location');
  context.pushNamed('push-named');
  context.pushReplacementNamed('push-replacement-named');
  context.replaceNamed('replace-named');
}
''';
      final errors = await analyzeLintRule(
        const AvoidHardcodedRoutes(),
        source,
      );

      const literals = [
        "'/go'",
        "'/push'",
        "'/push-replacement'",
        "'/replace'",
        "'go-named'",
        "'named-location'",
        "'push-named'",
        "'push-replacement-named'",
        "'replace-named'",
      ];
      expect(errors, hasLength(literals.length));
      for (final literal in literals) {
        final offset = source.indexOf(literal);
        final diagnostic = errors.singleWhere(
          (error) => error.offset == offset,
        );
        expectLintDiagnostic(
          diagnostic,
          code: 'avoid_hardcoded_routes',
          message:
              'Avoid hardcoded route paths. Use constants or enums for routes.',
          correctionMessage:
              'Use a constant, enum, or a variable instead of a hardcoded string.',
          offset: offset,
          length: literal.length,
        );
      }
    });

    test('reports GoRouter targets and supported constructor arguments', () async {
      const source = r'''
class GoRouter {
  GoRouter({this.initialLocation, this.path, this.name, this.redirect});
  final String? initialLocation;
  final String? path;
  final String? name;
  final String? Function()? redirect;
  void go(String value) {}
}

class GoRoute {
  GoRoute({this.path, this.name, this.redirect});
  final String? path;
  final String? name;
  final String? Function()? redirect;
}

class ShellRoute {
  ShellRoute({this.path, this.name, this.redirect});
  final String? path;
  final String? name;
  final String? Function()? redirect;
}

class StatefulShellRoute {
  StatefulShellRoute({this.path, this.name, this.redirect});
  final String? path;
  final String? name;
  final String? Function()? redirect;
}

void navigate(GoRouter router, String segment) {
  router.go('/typed-target');
  GoRouter(
    initialLocation: '/initial',
    path: '/router-path',
    name: 'router-name',
    redirect: () => '/router-redirect',
  );
  GoRoute(
    path: '/route-path',
    name: 'route-name',
    redirect: () {
      if (segment.isEmpty) {
        return '/nested-redirect';
      }
      return '/fallback-${segment}';
    },
  );
  ShellRoute(path: '/shell-path', name: 'shell-name');
  StatefulShellRoute(path: '/stateful-path', name: 'stateful-name');
}
''';
      final errors = await analyzeLintRule(
        const AvoidHardcodedRoutes(),
        source,
      );

      const literals = [
        "'/typed-target'",
        "'/initial'",
        "'/router-path'",
        "'router-name'",
        "'/router-redirect'",
        "'/route-path'",
        "'route-name'",
        "'/nested-redirect'",
        r"'/fallback-${segment}'",
        "'/shell-path'",
        "'shell-name'",
        "'/stateful-path'",
        "'stateful-name'",
      ];
      expect(errors, hasLength(literals.length));
      for (final literal in literals) {
        final offset = source.indexOf(literal);
        final diagnostic = errors.singleWhere(
          (error) => error.offset == offset,
        );
        expectLintDiagnostic(
          diagnostic,
          code: 'avoid_hardcoded_routes',
          message:
              'Avoid hardcoded route paths. Use constants or enums for routes.',
          correctionMessage:
              'Use a constant, enum, or a variable instead of a hardcoded string.',
          offset: offset,
          length: literal.length,
        );
      }
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
      const source = '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/home',
  routes: [],
);
''';
      final errors = await analyzeLintRule(
        const AvoidHardcodedRoutes(),
        source,
      );

      expect(errors, hasLength(1));
      const literal = "'/home'";
      expectLintDiagnostic(
        errors.single,
        code: 'avoid_hardcoded_routes',
        message:
            'Avoid hardcoded route paths. Use constants or enums for routes.',
        correctionMessage:
            'Use a constant, enum, or a variable instead of a hardcoded string.',
        offset: source.indexOf(literal),
        length: literal.length,
      );
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

    test('ignores non-context targets and unsupported constructors', () async {
      final errors = await analyzeLintRule(
        const AvoidHardcodedRoutes(),
        '''
class Router {
  void go(String value) {}
}

class Route {
  const Route({required this.path});

  final String path;
}

void navigate(Router router, Router ctx) {
  router.go('/router');
  ctx.go('/ctx');
  const Route(path: '/route');
}
''',
      );

      expect(errors, isEmpty);
    });
  });
}
