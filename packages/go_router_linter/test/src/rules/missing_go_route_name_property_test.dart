// ignore_for_file: non_constant_identifier_names

// 📦 Package imports:
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

// 🌎 Project imports:
import 'package:go_router_linter/src/rules/missing_go_route_name_property.dart';

const _message = 'GoRoute definition should include a `name` property.';
const _correction = 'Add a `name` property to this GoRoute.';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingGoRouteNamePropertyTest);
  });
}

@reflectiveTest
class MissingGoRouteNamePropertyTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = MissingGoRouteNameProperty();
    super.setUp();
  }

  Future<void> test_reportsCompleteGoRouteWithoutName() async {
    const source = '''
class GoRoute {
  const GoRoute({required this.path, this.name});

  final String path;
  final String? name;
}

const route = GoRoute(path: '/');
''';
    const invocation = "GoRoute(path: '/')";

    await assertDiagnostics(source, [
      lint(
        source.indexOf(invocation),
        invocation.length,
        messageContainsAll: [_exact(_message)],
        correctionContains: _exact(_correction),
      ),
    ]);
  }

  Future<void> test_ignoresGoRouteWithNameArgument() async {
    await assertNoDiagnostics('''
class GoRoute {
  const GoRoute({required this.path, this.name});

  final String path;
  final String? name;
}

const route = GoRoute(path: '/', name: 'home');
''');
  }

  Future<void> test_ignoresOtherConstructors() async {
    await assertNoDiagnostics('''
class RouteConfiguration {
  const RouteConfiguration({required this.path});

  final String path;
}

const route = RouteConfiguration(path: '/');
''');
  }
}

RegExp _exact(String value) => RegExp('^${RegExp.escape(value)}\$');
