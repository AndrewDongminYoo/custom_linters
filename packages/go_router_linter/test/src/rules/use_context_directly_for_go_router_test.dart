// ignore_for_file: non_constant_identifier_names

// 📦 Package imports:
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

// 🌎 Project imports:
import 'package:go_router_linter/src/rules/use_context_directly_for_go_router.dart';

const _message = 'Use GoRouterHelper extension.';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UseContextDirectlyForGoRouterTest);
  });
}

@reflectiveTest
class UseContextDirectlyForGoRouterTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = UseContextDirectlyForGoRouter();
    super.setUp();
  }

  Future<void> test_reportsEveryDirectRouteMethodCall() async {
    const source = '''
class GoRouter {
  static GoRouter of(Object context) => GoRouter();

  void go(String value) {}
  void push(String value) {}
  void pushReplacement(String value) {}
  void replace(String value) {}
  void goNamed(String value) {}
  void namedLocation(String value) {}
  void pushNamed(String value) {}
  void pushReplacementNamed(String value) {}
  void replaceNamed(String value) {}
  void canPop() {}
  void pop() {}
}

void navigate(Object context) {
  GoRouter.of(context).go('/home');
  GoRouter.of(context).push('/home');
  GoRouter.of(context).pushReplacement('/home');
  GoRouter.of(context).replace('/home');
  GoRouter.of(context).goNamed('home');
  GoRouter.of(context).namedLocation('home');
  GoRouter.of(context).pushNamed('home');
  GoRouter.of(context).pushReplacementNamed('home');
  GoRouter.of(context).replaceNamed('home');
  GoRouter.of(context).canPop();
  GoRouter.of(context).pop();
}
''';
    const expectations = {
      "GoRouter.of(context).go('/home')": 'go',
      "GoRouter.of(context).push('/home')": 'push',
      "GoRouter.of(context).pushReplacement('/home')": 'pushReplacement',
      "GoRouter.of(context).replace('/home')": 'replace',
      "GoRouter.of(context).goNamed('home')": 'goNamed',
      "GoRouter.of(context).namedLocation('home')": 'namedLocation',
      "GoRouter.of(context).pushNamed('home')": 'pushNamed',
      "GoRouter.of(context).pushReplacementNamed('home')":
          'pushReplacementNamed',
      "GoRouter.of(context).replaceNamed('home')": 'replaceNamed',
      'GoRouter.of(context).canPop()': 'canPop',
      'GoRouter.of(context).pop()': 'pop',
    };

    await assertDiagnostics(source, [
      for (final MapEntry(key: invocation, value: method)
          in expectations.entries)
        lint(
          source.indexOf(invocation),
          invocation.length,
          messageContainsAll: [_exact(_message)],
          correctionContains: _exact(
            'Use context.$method instead of GoRouter.of(context).$method.',
          ),
        ),
    ]);
  }

  Future<void> test_usesActualSimpleIdentifierInCorrection() async {
    const source = '''
class GoRouter {
  static GoRouter of(Object context) => GoRouter();
  void go(String value) {}
}

void navigate(Object nestedContext) {
  GoRouter.of(nestedContext).go('/home');
}
''';
    const invocation = "GoRouter.of(nestedContext).go('/home')";

    await assertDiagnostics(source, [
      lint(
        source.indexOf(invocation),
        invocation.length,
        messageContainsAll: [_exact(_message)],
        correctionContains: _exact(
          'Use nestedContext.go instead of GoRouter.of(nestedContext).go.',
        ),
      ),
    ]);
  }

  Future<void> test_preservesSimpleIdentifierAndDirectTargetBoundaries() async {
    await assertNoDiagnostics('''
class GoRouter {
  static GoRouter of(Object context) => GoRouter();

  Object get routerDelegate => Object();
  void refresh() {}
  void go(String value) {}
}

class Scope {
  const Scope(this.context);
  final Object context;
}

Object getContext() => Object();

void inspect(Object context, Scope scope) {
  GoRouter.of(context).routerDelegate;
  GoRouter.of(context).refresh();
  GoRouter.of(scope.context).go('/home');
  GoRouter.of(getContext()).go('/home');
  (GoRouter.of(context)).go('/home');
}
''');
  }
}

RegExp _exact(String value) => RegExp('^${RegExp.escape(value)}\$');
