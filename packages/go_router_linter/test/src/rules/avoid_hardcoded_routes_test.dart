// ignore_for_file: non_constant_identifier_names

// 📦 Package imports:
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

// 🌎 Project imports:
import 'package:go_router_linter/src/rules/avoid_hardcoded_routes.dart';

const _message =
    'Avoid hardcoded route paths. Use constants or enums for routes.';
const _correction =
    'Use a constant, enum, or a variable instead of a hardcoded string.';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidHardcodedRoutesTest);
  });
}

@reflectiveTest
class AvoidHardcodedRoutesTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidHardcodedRoutes();
    super.setUp();
  }

  Future<void> test_reportsEveryHardcodedContextRouteArgument() async {
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

    await assertDiagnostics(source, [
      for (final literal in literals)
        lint(
          source.indexOf(literal),
          literal.length,
          messageContainsAll: [_exact(_message)],
          correctionContains: _exact(_correction),
        ),
    ]);
  }

  Future<void> test_reportsTypedTargetAndSupportedConstructors() async {
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

    await assertDiagnostics(source, [
      for (final literal in literals)
        lint(
          source.indexOf(literal),
          literal.length,
          messageContainsAll: [_exact(_message)],
          correctionContains: _exact(_correction),
        ),
    ]);
  }

  Future<void> test_ignoresConstantsNonContextTargetsAndOtherTypes() async {
    await assertNoDiagnostics('''
class Router {
  void go(String value) {}
}

class GoRouter {
  GoRouter({this.initialLocation});
  final String? initialLocation;
}

class GoRoute {
  GoRoute({this.path, this.name, this.redirect});
  final String? path;
  final String? name;
  final String? Function()? redirect;
}

class Route {
  const Route({required this.path});
  final String path;
}

const routePath = '/home';

void navigate(Router router, Router ctx) {
  router.go('/router');
  ctx.go('/ctx');
  GoRouter(initialLocation: routePath);
  GoRoute(path: routePath, name: routePath, redirect: () => routePath);
  const Route(path: '/route');
}
''');
  }
}

RegExp _exact(String value) => RegExp('^${RegExp.escape(value)}\$');
