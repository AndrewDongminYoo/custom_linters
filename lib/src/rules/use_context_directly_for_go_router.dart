// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

// 🌎 Project imports:
import 'package:go_router_linter/src/helpers/lint_code_extension.dart';

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
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((MethodInvocation node) {
      if (node.methodName.name == 'of' &&
          node.target is Identifier &&
          (node.target! as Identifier).name == 'GoRouter' &&
          node.argumentList.arguments.length == 1 &&
          node.argumentList.arguments.first is SimpleIdentifier) {
        // Ensure the parent is a MethodInvocation
        if (node.parent is MethodInvocation) {
          final parent = node.parent! as MethodInvocation;
          if (parent.methodName.name.isNotEmpty) {
            // Get the method name (e.g., `go`, `push`)
            final name = parent.methodName.name;
            // Generate a dynamic problem message
            final message =
                'Use context.$name instead of GoRouter.of(context).$name.';
            reporter.atNode(parent, code.copyWith(problemMessage: message));
          }
        }
      }
    });
  }
}
