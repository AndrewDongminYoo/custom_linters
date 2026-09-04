// 📦 Package imports:
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// {@template avoid_widget_operator_equals}
/// Reports equality overrides on Flutter widget classes.
/// {@endtemplate}
class AvoidWidgetOperatorEquals extends AnalysisRule {
  /// {@macro avoid_widget_operator_equals}
  AvoidWidgetOperatorEquals()
    : super(
        name: 'avoid_widget_operator_equals',
        description: 'Avoids equality overrides on Flutter widget classes.',
      );

  static const _code = LintCode(
    'avoid_widget_operator_equals',
    'Avoid overriding operator == on Widget classes.',
    correctionMessage:
        'Rely on Flutter widget identity and const constructors instead.',
  );

  @override
  LintCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addClassDeclaration(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidWidgetOperatorEquals rule;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (!_directlyExtendsFlutterWidget(node)) return;

    for (final member in node.body.members.whereType<MethodDeclaration>()) {
      if (member.operatorKeyword != null && member.name.lexeme == '==') {
        rule.reportAtNode(member);
      }
    }
  }

  bool _directlyExtendsFlutterWidget(ClassDeclaration declaration) {
    final superclass = declaration.extendsClause?.superclass;
    if (superclass == null) return false;

    final element = superclass.element;
    final libraryUri = element?.library?.uri.toString();
    return {
          'Widget',
          'StatelessWidget',
          'StatefulWidget',
        }.contains(element?.name) &&
        libraryUri != null &&
        libraryUri.startsWith('package:flutter/');
  }
}
