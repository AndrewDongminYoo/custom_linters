// 📦 Package imports:
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

// 🌎 Project imports:
import 'package:go_router_linter/src/extensions/route_methods_extension.dart';

/// {@template use_context_directly_for_go_router}
/// Reports `GoRouter.of(context).method()` calls when the equivalent
/// `BuildContext` helper is available.
/// {@endtemplate}
class UseContextDirectlyForGoRouter extends AnalysisRule {
  /// {@macro use_context_directly_for_go_router}
  UseContextDirectlyForGoRouter()
    : super(
        name: 'use_context_directly_for_go_router',
        description: 'Prefers BuildContext go_router helpers.',
      );

  static const _code = LintCode(
    'use_context_directly_for_go_router',
    'Use GoRouterHelper extension.',
    correctionMessage: 'Use {0}.{1} instead of GoRouter.of({0}).{1}.',
  );

  @override
  LintCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addMethodInvocation(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final UseContextDirectlyForGoRouter rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final methodName = node.methodName.name;
    if (!methodName.isRouteMethod) return;

    final target = node.target;
    if (target is! MethodInvocation || target.methodName.name != 'of') return;

    final goRouterTarget = target.target;
    if (goRouterTarget is! Identifier || goRouterTarget.name != 'GoRouter') {
      return;
    }

    final arguments = target.argumentList.arguments;
    if (arguments.length != 1 || arguments.single is! SimpleIdentifier) return;

    final contextName = (arguments.single as SimpleIdentifier).name;
    rule.reportAtNode(node, arguments: [contextName, methodName]);
  }
}
