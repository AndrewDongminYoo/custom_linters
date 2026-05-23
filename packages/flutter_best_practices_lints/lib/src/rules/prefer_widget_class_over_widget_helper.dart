// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// {@template prefer_widget_class_over_widget_helper}
/// Reports private `Widget _build...` helpers.
/// {@endtemplate}
class PreferWidgetClassOverWidgetHelper extends DartLintRule {
  /// {@macro prefer_widget_class_over_widget_helper}
  const PreferWidgetClassOverWidgetHelper() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_widget_class_over_widget_helper',
    problemMessage: 'Prefer a widget class over private Widget helper methods.',
    correctionMessage:
        'Extract this reusable UI into a StatelessWidget or StatefulWidget.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      for (final declaration in node.declarations) {
        if (declaration is FunctionDeclaration) {
          _checkFunctionDeclaration(declaration, reporter);
        } else if (declaration is ClassDeclaration) {
          for (final member in declaration.members) {
            if (member is MethodDeclaration) {
              _checkMethodDeclaration(member, reporter);
            }
          }
        }
      }
    });
  }

  void _checkFunctionDeclaration(
    FunctionDeclaration node,
    DiagnosticReporter reporter,
  ) {
    if (_isPrivateWidgetBuildHelper(node.name.lexeme, node.returnType)) {
      reporter.atNode(node, _code);
    }
  }

  void _checkMethodDeclaration(
    MethodDeclaration node,
    DiagnosticReporter reporter,
  ) {
    if (node.name.lexeme == 'build') return;

    if (_isPrivateWidgetBuildHelper(node.name.lexeme, node.returnType)) {
      reporter.atNode(node, _code);
    }
  }

  bool _isPrivateWidgetBuildHelper(String name, TypeAnnotation? returnType) {
    return name.startsWith('_build') && _isWidgetReturnType(returnType);
  }

  bool _isWidgetReturnType(TypeAnnotation? returnType) {
    return returnType is NamedType && returnType.name.lexeme == 'Widget';
  }
}
