// 📦 Package imports:
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// {@template prefer_widget_class_over_widget_helper}
/// Reports private `Widget _build...` helpers.
/// {@endtemplate}
class PreferWidgetClassOverWidgetHelper extends AnalysisRule {
  /// {@macro prefer_widget_class_over_widget_helper}
  PreferWidgetClassOverWidgetHelper()
    : super(
        name: 'prefer_widget_class_over_widget_helper',
        description: 'Prefers widget classes over private Widget helpers.',
      );

  static const _code = LintCode(
    'prefer_widget_class_over_widget_helper',
    'Prefer a widget class over private Widget helper methods.',
    correctionMessage:
        'Extract this reusable UI into a StatelessWidget or StatefulWidget.',
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
      ..addFunctionDeclaration(this, visitor)
      ..addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final PreferWidgetClassOverWidgetHelper rule;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.parent is! CompilationUnit) return;

    if (_isPrivateWidgetBuildHelper(node.name.lexeme, node.returnType)) {
      rule.reportAtNode(node);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.parent?.parent is! ClassDeclaration) return;
    if (node.name.lexeme == 'build') return;

    if (_isPrivateWidgetBuildHelper(node.name.lexeme, node.returnType)) {
      rule.reportAtNode(node);
    }
  }

  bool _isPrivateWidgetBuildHelper(String name, TypeAnnotation? returnType) {
    return name.startsWith('_build') &&
        returnType is NamedType &&
        returnType.name.lexeme == 'Widget';
  }
}
