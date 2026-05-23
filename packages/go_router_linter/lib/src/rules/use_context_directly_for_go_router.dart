// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

// 🌎 Project imports:
import 'package:go_router_linter/src/extensions/lint_code_extension.dart';
import 'package:go_router_linter/src/extensions/route_methods_extension.dart';

/// {@template use_context_directly_for_go_router}
/// A custom lint rule that checks for the use of `GoRouter.of(context).go()`
/// instead of `context.go()`.
///
/// This lint rule is part of the `go_router_linter` plugin, which provides
/// a set of custom lints for the Go Router library.
/// The purpose of this lint is to encourage the use of the more concise
/// and idiomatic `context.go()` method instead of
/// the longer `GoRouter.of(context).go()` form.
/// {@endtemplate}
class UseContextDirectlyForGoRouter extends DartLintRule {
  /// {@macro use_context_directly_for_go_router}
  const UseContextDirectlyForGoRouter() : super(code: _code);

  /// Metadata about the warning that will show up in the IDE.
  static const LintCode _code = LintCode(
    name: 'use_context_directly_for_go_router',
    problemMessage: 'Use GoRouterHelper extension.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'of' &&
          node.target is Identifier &&
          (node.target! as Identifier).name == 'GoRouter' &&
          node.argumentList.arguments.length == 1 &&
          node.argumentList.arguments.first is SimpleIdentifier) {
        final parent = node.parent;
        if (parent is! MethodInvocation || parent.target != node) {
          return;
        }

        final name = parent.methodName.name;
        if (!name.isRouteMethod) {
          return;
        }

        final contextName =
            (node.argumentList.arguments.first as SimpleIdentifier).name;
        final message =
            'Use $contextName.$name instead of GoRouter.of($contextName).$name.';
        reporter.atNode(parent, code.copyWith(correctionMessage: message));
      }
    });
  }
}
