// 📦 Package imports:
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/error/error.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

/// {@template avoid_navigator_named_routes_with_go_router}
/// Reports Navigator named-route APIs in packages that use go_router.
/// {@endtemplate}
class AvoidNavigatorNamedRoutesWithGoRouter extends AnalysisRule {
  /// {@macro avoid_navigator_named_routes_with_go_router}
  AvoidNavigatorNamedRoutesWithGoRouter()
    : super(
        name: 'avoid_navigator_named_routes_with_go_router',
        description: 'Avoids Navigator named routes when go_router is used.',
      );

  static const _code = LintCode(
    'avoid_navigator_named_routes_with_go_router',
    'Avoid Navigator named routes in projects that use go_router.',
    correctionMessage:
        'Use go_router navigation APIs so routes stay declarative and deep-linkable.',
  );

  @override
  LintCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!_packageUsesGoRouter(context)) return;

    registry.addMethodInvocation(this, _Visitor(this));
  }

  bool _packageUsesGoRouter(RuleContext context) {
    final package = context.package;
    if (package == null) return false;

    final pubspecFile = package.root.getFile('pubspec.yaml');
    if (!pubspecFile.exists) return false;

    late final String contents;
    try {
      contents = pubspecFile.readAsStringSync();
    } on FileSystemException {
      return false;
    }

    late final Pubspec pubspec;
    try {
      pubspec = Pubspec.parse(
        contents,
        sourceUrl: Uri.file(pubspecFile.path),
      );
    } on Object {
      return false;
    }

    return pubspec.dependencies.containsKey('go_router') ||
        pubspec.devDependencies.containsKey('go_router');
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final AvoidNavigatorNamedRoutesWithGoRouter rule;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (!_namedNavigatorMethods.contains(node.methodName.name)) return;

    final target = node.target;
    final isNavigatorStaticCall =
        target is Identifier && target.name == 'Navigator';
    final isNavigatorStateCall =
        target?.staticType?.element?.name == 'NavigatorState';
    if (isNavigatorStaticCall || isNavigatorStateCall) {
      rule.reportAtNode(node);
    }
  }
}

const _namedNavigatorMethods = {
  'pushNamed',
  'pushReplacementNamed',
  'popAndPushNamed',
  'pushNamedAndRemoveUntil',
  'restorablePushNamed',
  'restorablePushReplacementNamed',
  'restorablePopAndPushNamed',
  'restorablePushNamedAndRemoveUntil',
};
