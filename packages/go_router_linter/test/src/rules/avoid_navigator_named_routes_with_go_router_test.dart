// ignore_for_file: non_constant_identifier_names

// 📦 Package imports:
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

// 🌎 Project imports:
import 'package:go_router_linter/src/rules/avoid_navigator_named_routes_with_go_router.dart';

const _message = 'Avoid Navigator named routes in projects that use go_router.';
const _correction =
    'Use go_router navigation APIs so routes stay declarative and deep-linkable.';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidNavigatorNamedRoutesWithGoRouterTest);
  });
}

@reflectiveTest
class AvoidNavigatorNamedRoutesWithGoRouterTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = AvoidNavigatorNamedRoutesWithGoRouter();
    super.setUp();
  }

  Future<void> test_reportsEveryMethodForDependency() async {
    _writePubspec('''
name: test_project
dependencies:
  go_router: any
''');
    const source = '''
class Navigator {
  static void pushNamed(Object context, String route) {}
  static void pushReplacementNamed(Object context, String route) {}
  static void popAndPushNamed(Object context, String route) {}
  static void pushNamedAndRemoveUntil(
    Object context,
    String route,
    bool Function(Object) predicate,
  ) {}
  static void restorablePushNamed(Object context, String route) {}
  static void restorablePushReplacementNamed(Object context, String route) {}
  static void restorablePopAndPushNamed(Object context, String route) {}
  static void restorablePushNamedAndRemoveUntil(
    Object context,
    String route,
    bool Function(Object) predicate,
  ) {}
}

void navigate(Object context) {
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
    const multilineInvocation =
        'Navigator.restorablePushNamedAndRemoveUntil(\n'
        '    context,\n'
        "    '/details',\n"
        '    (_) => false,\n'
        '  )';
    const invocations = [
      "Navigator.pushNamed(context, '/details')",
      "Navigator.pushReplacementNamed(context, '/details')",
      "Navigator.popAndPushNamed(context, '/details')",
      "Navigator.pushNamedAndRemoveUntil(context, '/details', (_) => false)",
      "Navigator.restorablePushNamed(context, '/details')",
      "Navigator.restorablePushReplacementNamed(context, '/details')",
      "Navigator.restorablePopAndPushNamed(context, '/details')",
      multilineInvocation,
    ];

    await assertDiagnostics(source, [
      for (final invocation in invocations)
        lint(
          source.indexOf(invocation),
          invocation.length,
          messageContainsAll: [_exact(_message)],
          correctionContains: _exact(_correction),
        ),
    ]);
  }

  Future<void> test_activatesForDevelopmentDependency() async {
    _writePubspec('''
name: test_project
dev_dependencies:
  go_router: any
''');
    const source = '''
class Navigator {
  static void pushNamed(Object context, String route) {}
}

void navigate(Object context) {
  Navigator.pushNamed(context, '/details');
}
''';
    const invocation = "Navigator.pushNamed(context, '/details')";

    await assertDiagnostics(source, [
      lint(
        source.indexOf(invocation),
        invocation.length,
        messageContainsAll: [_exact(_message)],
        correctionContains: _exact(_correction),
      ),
    ]);
  }

  Future<void> test_matchesSyntacticNavigatorAndNavigatorState() async {
    _writePubspec('''
name: test_project
dependencies:
  go_router: any
''');
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
    const invocations = [
      "Navigator.pushNamed(context, '/details')",
      "state.pushReplacementNamed('/details')",
    ];

    await assertDiagnostics(source, [
      for (final invocation in invocations)
        lint(
          source.indexOf(invocation),
          invocation.length,
          messageContainsAll: [_exact(_message)],
          correctionContains: _exact(_correction),
        ),
    ]);
  }

  Future<void> test_ignoresNamedMethodsWithoutDependency() async {
    _writePubspec('name: test_project');

    await assertNoDiagnostics('''
class Navigator {
  static void pushNamed(Object context, String route) {}
}

void navigate(Object context) {
  Navigator.pushNamed(context, '/details');
}
''');
  }

  Future<void> test_ignoresMalformedPubspec() async {
    _writePubspec('dependencies: [');

    await assertNoDiagnostics('''
class Navigator {
  static void pushNamed(Object context, String route) {}
}

void navigate(Object context) {
  Navigator.pushNamed(context, '/details');
}
''');
  }

  Future<void> test_ignoresUnrelatedMethodsAndTargets() async {
    _writePubspec('''
name: test_project
dependencies:
  go_router: any
''');

    await assertNoDiagnostics('''
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
''');
  }

  Future<void> test_isolatesOwningPackages_dependencyThenAbsent() async {
    final fixtures = _writeOwningPackageFixtures();

    await _assertPackageDiagnostic(fixtures.withDependencyPath, fixtures);
    await _assertPackageHasNoDiagnostics(fixtures.withoutDependencyPath);
  }

  Future<void> test_isolatesOwningPackages_absentThenDependency() async {
    final fixtures = _writeOwningPackageFixtures();

    await _assertPackageHasNoDiagnostics(fixtures.withoutDependencyPath);
    await _assertPackageDiagnostic(fixtures.withDependencyPath, fixtures);
  }

  Future<void> _assertPackageDiagnostic(
    String path,
    _OwningPackageFixtures fixtures,
  ) async {
    result = await resolveFile(convertPath(path));
    assertDiagnosticsIn(result.diagnostics.toList(), [
      lint(
        fixtures.diagnosticOffset,
        fixtures.diagnosticLength,
        messageContainsAll: [_exact(_message)],
        correctionContains: _exact(_correction),
      ),
    ]);
  }

  Future<void> _assertPackageHasNoDiagnostics(String path) async {
    result = await resolveFile(convertPath(path));
    assertDiagnosticsIn(result.diagnostics.toList(), const []);
  }

  _OwningPackageFixtures _writeOwningPackageFixtures() {
    const source = '''
class Navigator {
  static void pushNamed(Object context, String route) {}
}

void navigate(Object context) {
  Navigator.pushNamed(context, '/details');
}
''';
    const invocation = "Navigator.pushNamed(context, '/details')";
    const withDependencyRoot = '/home/with_go_router';
    const withoutDependencyRoot = '/home/without_go_router';
    const withDependencyPath = '$withDependencyRoot/lib/test.dart';
    const withoutDependencyPath = '$withoutDependencyRoot/lib/test.dart';

    newPubspecYamlFile(withDependencyRoot, '''
name: with_go_router
dependencies:
  go_router: any
''');
    newPubspecYamlFile(withoutDependencyRoot, 'name: without_go_router');
    for (final packageRoot in [withDependencyRoot, withoutDependencyRoot]) {
      writePackageConfig2(packageRoot);
      newAnalysisOptionsYamlFile(
        packageRoot,
        analysisOptionsContent(rules: [rule.name]),
      );
    }
    newFile(withDependencyPath, source);
    newFile(withoutDependencyPath, source);

    return _OwningPackageFixtures(
      withDependencyPath: withDependencyPath,
      withoutDependencyPath: withoutDependencyPath,
      diagnosticOffset: source.indexOf(invocation),
      diagnosticLength: invocation.length,
    );
  }

  void _writePubspec(String content) {
    newFile(testPackagePubspecPath, content);
  }
}

final class _OwningPackageFixtures {
  const _OwningPackageFixtures({
    required this.withDependencyPath,
    required this.withoutDependencyPath,
    required this.diagnosticOffset,
    required this.diagnosticLength,
  });

  final String withDependencyPath;
  final String withoutDependencyPath;
  final int diagnosticOffset;
  final int diagnosticLength;
}

RegExp _exact(String value) => RegExp('^${RegExp.escape(value)}\$');
