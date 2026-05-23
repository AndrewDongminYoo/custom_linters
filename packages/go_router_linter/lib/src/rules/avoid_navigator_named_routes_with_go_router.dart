// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// {@template avoid_navigator_named_routes_with_go_router}
/// Reports Navigator named-route APIs in projects that use go_router.
/// {@endtemplate}
class AvoidNavigatorNamedRoutesWithGoRouter extends DartLintRule {
  /// {@macro avoid_navigator_named_routes_with_go_router}
  const AvoidNavigatorNamedRoutesWithGoRouter() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_navigator_named_routes_with_go_router',
    problemMessage:
        'Avoid Navigator named routes in projects that use go_router.',
    correctionMessage:
        'Use go_router navigation APIs so routes stay declarative and deep-linkable.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    final hasGoRouter =
        context.pubspec.dependencies.containsKey('go_router') ||
        context.pubspec.devDependencies.containsKey('go_router');

    if (!hasGoRouter) return;

    context.registry.addMethodInvocation((node) {
      if (!_namedNavigatorMethods.contains(node.methodName.name)) {
        return;
      }

      final target = node.target;
      final isNavigatorStaticCall =
          target is Identifier && target.name == 'Navigator';
      final isNavigatorStateCall =
          target?.staticType?.element?.name == 'NavigatorState';

      if (isNavigatorStaticCall || isNavigatorStateCall) {
        reporter.atNode(node, _code);
      }
    });
  }
}

const _namedNavigatorMethods = {
  'pushNamed',
  'pushReplacementNamed',
  'popAndPushNamed',
  'pushNamedAndRemoveUntil',
  'restorablePushNamed',
  'restorablePushReplacementNamed',
  'restorablePopAndPushNamed',
  'restorablePushNamedAndRemoveUntil',
};
