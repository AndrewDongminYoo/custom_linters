// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

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
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    resolver.getResolvedUnitResult().then((unit) {
      unit.unit.visitChildren(_AvoidHardcodedRoutesVisitor(reporter, context));
    });
  }
}

class _AvoidHardcodedRoutesVisitor extends RecursiveAstVisitor<void> {
  _AvoidHardcodedRoutesVisitor(this.reporter, this.context);

  final ErrorReporter reporter;
  final CustomLintContext context;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    // Check if the target is `context` and the method is `go` or `push`
    final target = node.target;
    if (target is SimpleIdentifier && target.name == 'context') {
      final methodName = node.methodName.name;
      if (methodName == 'go' || methodName == 'push') {
        // Check arguments for hardcoded strings
        for (final argument in node.argumentList.arguments) {
          if (argument is StringLiteral) {
            reporter.atNode(argument, AvoidHardcodedRoutes._code);
          }
        }
      }
    }

    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.staticType?.element;
    // Check if the class being instantiated is GoRoute
    if (element is ClassElement && element.name == 'GoRoute') {
      final arguments = node.argumentList.arguments;

      // Check `path` argument if it is a hardcoded string
      for (final arg in arguments) {
        if (arg is NamedExpression) {
          final paramName = arg.name.label.name;
          // path 또는 name 속성에 대해 검사
          if (paramName == 'path' || paramName == 'name') {
            if (arg.expression is StringLiteral) {
              reporter.atNode(arg.expression, AvoidHardcodedRoutes._code);
            }
          }
        }
      }
    }

    super.visitInstanceCreationExpression(node);
  }
}
