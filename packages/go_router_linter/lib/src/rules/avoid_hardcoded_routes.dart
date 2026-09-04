// 📦 Package imports:
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

// 🌎 Project imports:
import 'package:go_router_linter/src/extensions/route_methods_extension.dart';

/// {@template avoid_hardcoded_routes}
/// Detects hardcoded route paths and names in go_router APIs.
/// {@endtemplate}
class AvoidHardcodedRoutes extends AnalysisRule {
  /// {@macro avoid_hardcoded_routes}
  AvoidHardcodedRoutes()
    : super(
        name: 'avoid_hardcoded_routes',
        description: 'Avoids hardcoded route paths and names.',
      );

  static const _code = LintCode(
    'avoid_hardcoded_routes',
    'Avoid hardcoded route paths. Use constants or enums for routes.',
    correctionMessage:
        'Use a constant, enum, or a variable instead of a hardcoded string.',
  );

  @override
  LintCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this);
    registry
      ..addMethodInvocation(this, visitor)
      ..addInstanceCreationExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidHardcodedRoutes rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (!methodName.isLocationRouteMethod && !methodName.isNamedRouteMethod) {
      return;
    }

    final target = node.target;
    final targetElement = target?.staticType?.element;
    final isGoRouterCall = targetElement?.name == 'GoRouter';
    final isContextExtension =
        target is SimpleIdentifier && target.name == 'context';
    if (!isGoRouterCall && !isContextExtension) return;

    final arguments = node.argumentList.arguments;
    final routeArgument = arguments.whereType<Expression>().firstOrNull;
    if (routeArgument is StringLiteral) {
      rule.reportAtNode(routeArgument);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.staticType?.element;
    if (element is! ClassElement ||
        !{'GoRoute', 'GoRouter', 'ShellRoute', 'StatefulShellRoute'}.contains(
          element.name,
        )) {
      return;
    }

    for (final argument in node.argumentList.arguments) {
      if (argument is! NamedArgument) continue;

      final parameterName = argument.name.lexeme;
      final expression = _argumentExpression(argument);
      if (parameterName == 'path' || parameterName == 'name') {
        if (expression is StringLiteral) {
          rule.reportAtNode(expression);
        }
      } else if (parameterName == 'initialLocation' &&
          element.name == 'GoRouter') {
        if (expression is StringLiteral) {
          rule.reportAtNode(expression);
        }
      } else if (parameterName == 'redirect') {
        _reportRedirectStrings(expression);
      }
    }
  }

  Expression _argumentExpression(NamedArgument argument) {
    return argument.argumentExpression;
  }

  void _reportRedirectStrings(Expression expression) {
    if (expression is! FunctionExpression) return;

    final body = expression.body;
    if (body is ExpressionFunctionBody) {
      final redirectExpression = body.expression;
      if (redirectExpression is StringLiteral) {
        rule.reportAtNode(redirectExpression);
      }
      return;
    }

    if (body is BlockFunctionBody) {
      body.visitChildren(_RedirectStringVisitor(rule));
    }
  }
}

class _RedirectStringVisitor extends RecursiveAstVisitor<void> {
  _RedirectStringVisitor(this.rule);

  final AvoidHardcodedRoutes rule;

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expression = node.expression;
    if (expression is StringLiteral) {
      rule.reportAtNode(expression);
    }

    super.visitReturnStatement(node);
  }
}
