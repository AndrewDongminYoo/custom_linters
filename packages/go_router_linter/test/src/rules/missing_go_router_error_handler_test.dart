// ignore_for_file: non_constant_identifier_names

// 📦 Package imports:
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

// 🌎 Project imports:
import 'package:go_router_linter/src/rules/missing_go_router_error_handler.dart';

const _message = 'GoRouter should define an error handler for unknown routes.';
const _correction = 'Add an `errorBuilder` or `errorPageBuilder` argument.';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MissingGoRouterErrorHandlerTest);
  });
}

@reflectiveTest
class MissingGoRouterErrorHandlerTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = MissingGoRouterErrorHandler();
    super.setUp();
  }

  Future<void> test_reportsCompleteGoRouterWithoutErrorHandler() async {
    const source = '''
class GoRouter {
  const GoRouter({required this.routes, this.errorBuilder, this.errorPageBuilder});

  final List<Object> routes;
  final Object? errorBuilder;
  final Object? errorPageBuilder;
}

const router = GoRouter(routes: []);
''';
    const invocation = 'GoRouter(routes: [])';

    await assertDiagnostics(source, [
      lint(
        source.indexOf(invocation),
        invocation.length,
        messageContainsAll: [_exact(_message)],
        correctionContains: _exact(_correction),
      ),
    ]);
  }

  Future<void> test_ignoresErrorBuilder() async {
    await assertNoDiagnostics('''
class GoRouter {
  const GoRouter({required this.routes, this.errorBuilder});
  final List<Object> routes;
  final Object? errorBuilder;
}

const router = GoRouter(routes: [], errorBuilder: Object());
''');
  }

  Future<void> test_ignoresErrorPageBuilder() async {
    await assertNoDiagnostics('''
class GoRouter {
  const GoRouter({required this.routes, this.errorPageBuilder});
  final List<Object> routes;
  final Object? errorPageBuilder;
}

const router = GoRouter(routes: [], errorPageBuilder: Object());
''');
  }

  Future<void> test_ignoresBothErrorHandlers() async {
    await assertNoDiagnostics('''
class GoRouter {
  const GoRouter({required this.errorBuilder, required this.errorPageBuilder});
  final Object errorBuilder;
  final Object errorPageBuilder;
}

const router = GoRouter(
  errorBuilder: Object(),
  errorPageBuilder: Object(),
);
''');
  }

  Future<void> test_ignoresOtherConstructors() async {
    await assertNoDiagnostics('''
class RouterConfiguration {
  const RouterConfiguration({required this.routes});
  final List<Object> routes;
}

const router = RouterConfiguration(routes: []);
''');
  }
}

RegExp _exact(String value) => RegExp('^${RegExp.escape(value)}\$');
