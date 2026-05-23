// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

// 🌎 Project imports:
import 'package:go_router_linter/src/extensions/route_methods_extension.dart';

/// {@template avoid_hardcoded_routes}
/// A lint rule that checks for hardcoded route strings.
///
/// A lint rule that detects hardcoded route paths or names in
/// `context.go`,  `context.push`, or when defining GoRoute instances,
/// and suggests using constants instead.
/// {@endtemplate}
class AvoidHardcodedRoutes extends DartLintRule {
  /// {@macro avoid_hardcoded_routes}
  const AvoidHardcodedRoutes() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_hardcoded_routes',
    problemMessage:
        'Avoid hardcoded route paths. Use constants or enums for routes.',
    correctionMessage:
        'Use a constant, enum, or a variable instead of a hardcoded string.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    final visitor = _AvoidHardcodedRoutesVisitor(reporter);
    context.registry.addMethodInvocation(visitor.checkMethodInvocation);
    context.registry.addInstanceCreationExpression(
      visitor.checkInstanceCreationExpression,
    );
  }
}

class _AvoidHardcodedRoutesVisitor {
  _AvoidHardcodedRoutesVisitor(this.reporter);

  final DiagnosticReporter reporter;

  void checkMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (methodName.isLocationRouteMethod || methodName.isNamedRouteMethod) {
      // Verify that the call target is a GoRouter
      // Example: GoRouter.of(context).go('/details')
      final target = node.target;
      final targetType = target?.staticType;
      final isGoRouterCall =
          targetType != null && targetType.element?.name == 'GoRouter';

      // Check for existing context.go(), context.push()
      final isContextExtension =
          target is SimpleIdentifier && target.name == 'context';

      if (isGoRouterCall || isContextExtension) {
        final routeArgument = node.argumentList.arguments
            .where((argument) => argument is! NamedExpression)
            .firstOrNull;

        if (routeArgument is StringLiteral) {
          reporter.atNode(routeArgument, AvoidHardcodedRoutes._code);
        }
      }
    }
  }

  void checkInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.staticType?.element;
    if (element is ClassElement &&
        {
          'GoRoute',
          'GoRouter',
          'ShellRoute',
          'StatefulShellRoute',
        }.contains(element.name)) {
      final arguments = node.argumentList.arguments;

      // Check `path` argument if it is a hardcoded string
      for (final arg in arguments) {
        if (arg is NamedExpression) {
          final paramName = arg.name.label.name;
          // Inspect against the path or name property
          if (paramName == 'path' || paramName == 'name') {
            if (arg.expression is StringLiteral) {
              reporter.atNode(arg.expression, AvoidHardcodedRoutes._code);
            }
          } else if (paramName == 'initialLocation' &&
              element.name == 'GoRouter') {
            if (arg.expression is StringLiteral) {
              reporter.atNode(arg.expression, AvoidHardcodedRoutes._code);
            }
          } else if (paramName == 'redirect') {
            _reportRedirectStrings(arg.expression);
          }
        }
      }
    }
  }

  void _reportRedirectStrings(Expression expression) {
    if (expression is! FunctionExpression) return;

    final body = expression.body;
    if (body is ExpressionFunctionBody) {
      final redirectExpression = body.expression;
      if (redirectExpression is StringLiteral) {
        reporter.atNode(redirectExpression, AvoidHardcodedRoutes._code);
      }
      return;
    }

    if (body is BlockFunctionBody) {
      body.visitChildren(_RedirectStringVisitor(reporter));
    }
  }
}

class _RedirectStringVisitor extends RecursiveAstVisitor<void> {
  _RedirectStringVisitor(this.reporter);

  final DiagnosticReporter reporter;

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (expression is StringLiteral) {
      reporter.atNode(expression, AvoidHardcodedRoutes._code);
    }

    super.visitReturnStatement(node);
  }
}
