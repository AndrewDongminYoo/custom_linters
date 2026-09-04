// 📦 Package imports:
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

/// {@template missing_go_route_name_property}
/// Checks that `GoRoute` definitions include a `name` property.
/// {@endtemplate}
class MissingGoRouteNameProperty extends AnalysisRule {
  /// {@macro missing_go_route_name_property}
  MissingGoRouteNameProperty()
    : super(
        name: 'missing_go_route_name_property',
        description: 'Requires a name for each GoRoute definition.',
      );

  static const _code = LintCode(
    'missing_go_route_name_property',
    'GoRoute definition should include a `name` property.',
    correctionMessage: 'Add a `name` property to this GoRoute.',
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

  final MissingGoRouteNameProperty rule;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final element = node.staticType?.element;
    if (element is! ClassElement || element.name != 'GoRoute') return;

    final hasName = node.argumentList.arguments.any(
      (argument) => argument is NamedArgument && argument.name.lexeme == 'name',
    );
    if (!hasName) {
      rule.reportAtNode(node);
    }
  }
}
