// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// {@template missing_go_router_error_handler}
/// Reports `GoRouter` constructor calls that define no `errorBuilder` or
/// `errorPageBuilder`.
///
/// Without an error handler, navigating to an unknown route renders a blank
/// debug screen in production. Providing a custom error page ensures a
/// graceful user experience for unmatched routes.
/// {@endtemplate}
class MissingGoRouterErrorHandler extends DartLintRule {
  /// {@macro missing_go_router_error_handler}
  const MissingGoRouterErrorHandler() : super(code: _code);

  static const _code = LintCode(
    name: 'missing_go_router_error_handler',
    problemMessage:
        'GoRouter should define an error handler for unknown routes.',
    correctionMessage: 'Add an `errorBuilder` or `errorPageBuilder` argument.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final element = node.staticType?.element;
      if (element is! ClassElement || element.name != 'GoRouter') return;

      final hasErrorHandler = node.argumentList.arguments.any((arg) {
        if (arg is! NamedExpression) return false;
        final name = arg.name.label.name;
        return name == 'errorBuilder' || name == 'errorPageBuilder';
      });

      if (!hasErrorHandler) {
        reporter.atNode(node, _code);
      }
    });
  }
}
