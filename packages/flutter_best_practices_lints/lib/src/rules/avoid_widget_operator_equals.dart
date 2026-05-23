// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// {@template avoid_widget_operator_equals}
/// Reports equality overrides on Flutter widget classes.
/// {@endtemplate}
class AvoidWidgetOperatorEquals extends DartLintRule {
  /// {@macro avoid_widget_operator_equals}
  const AvoidWidgetOperatorEquals() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_widget_operator_equals',
    problemMessage: 'Avoid overriding operator == on Widget classes.',
    correctionMessage:
        'Rely on Flutter widget identity and const constructors instead.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      for (final declaration
          in node.declarations.whereType<ClassDeclaration>()) {
        if (!_directlyExtendsFlutterWidget(declaration)) continue;

        for (final member
            in declaration.members.whereType<MethodDeclaration>()) {
          if (member.operatorKeyword != null && member.name.lexeme == '==') {
            reporter.atNode(member, _code);
          }
        }
      }
    });
  }

  bool _directlyExtendsFlutterWidget(ClassDeclaration declaration) {
    final superclass = declaration.extendsClause?.superclass;
    if (superclass == null) return false;

    final element = superclass.type?.element;
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
