// 📦 Package imports:
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

/// {@template missing_go_router_error_handler}
/// Reports `GoRouter` constructor calls that define no `errorBuilder` or
/// `errorPageBuilder`.
/// {@endtemplate}
class MissingGoRouterErrorHandler extends AnalysisRule {
  /// {@macro missing_go_router_error_handler}
  MissingGoRouterErrorHandler()
    : super(
        name: 'missing_go_router_error_handler',
        description: 'Requires an error handler for each GoRouter.',
      );

  static const _code = LintCode(
    'missing_go_router_error_handler',
    'GoRouter should define an error handler for unknown routes.',
    correctionMessage: 'Add an `errorBuilder` or `errorPageBuilder` argument.',
  );

  @override
  LintCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addInstanceCreationExpression(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final MissingGoRouterErrorHandler rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.staticType?.element;
    if (element is! ClassElement || element.name != 'GoRouter') return;

    final hasErrorHandler = node.argumentList.arguments.any((argument) {
      if (argument is! NamedArgument) return false;
      return argument.name.lexeme == 'errorBuilder' ||
          argument.name.lexeme == 'errorPageBuilder';
    });
    if (!hasErrorHandler) {
      rule.reportAtNode(node);
    }
  }
}
