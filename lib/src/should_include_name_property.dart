// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// {@template should_include_name_property}
/// A lint rule that checks if GoRoute definitions include a `name` property.
/// 
/// This rule is part of the custom lint rules for the GoRouter package.
/// It ensures that all GoRoute definitions have a `name` property set,
/// which is required for proper routing functionality.
/// {@endtemplate}
class ShouldIncludeNameProperty extends DartLintRule {
  /// {@macro should_include_name_property}
  const ShouldIncludeNameProperty() : super(code: _code);

  static const _code = LintCode(
    name: 'missing_go_route_name',
    problemMessage: 'GoRoute definition should include a `name` property.',
    correctionMessage: 'Add a `name` property to this GoRoute.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    resolver.getResolvedUnitResult().then((unit) {
      unit.unit.visitChildren(_GoRouteVisitor(reporter, context));
    });
  }
}

class _GoRouteVisitor extends RecursiveAstVisitor<void> {
  _GoRouteVisitor(this.reporter, this.context);

  final ErrorReporter reporter;
  final CustomLintContext context;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.staticType?.element;

    // Check if the class being instantiated is GoRoute
    if (element is ClassElement && element.name == 'GoRoute') {
      final arguments = node.argumentList.arguments;

      // Check if any of the arguments has the name 'name'
      final hasNameProperty = arguments.any((arg) {
        if (arg is NamedExpression) {
          return arg.name.label.name == 'name';
        }
        return false;
      });

      // If name property is missing, report an error
      if (!hasNameProperty) {
        reporter.atNode(node, ShouldIncludeNameProperty._code);
      }
    }

    super.visitInstanceCreationExpression(node);
  }
}
