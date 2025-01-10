// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/extensions/class_declaration_extension.dart';

/// {@template single_class_per_file}
/// A custom lint rule that ensures a file contains only one class declaration.
///
/// This rule is part of the `flutter_best_practices_lints` plugin.
/// Having multiple classes in a single file can make code organization hard.
/// By restricting a file to a single main class, you encourage better
/// project structure and maintainability.
///
/// - Excludes classes recognized as Flutter `State` classes
///   (for example, `_MyWidgetState`).
/// {@endtemplate}
class SingleClassPerFile extends DartLintRule {
  /// {@macro single_class_per_file}
  const SingleClassPerFile()
      : super(
          code: const LintCode(
            name: 'single_class_per_file',
            problemMessage: 'A file should contain only one class declaration.',
            correctionMessage: 'Split the classes into separate files.',
          ),
        );

  /// {@macro single_class_per_file}
  ///
  /// This method collects all class declarations in a file (except those
  /// recognized as Flutter `State` subclasses) and checks if more than
  /// one class remains. If multiple classes are found, a lint diagnostic
  /// is raised for each class beyond the first.
  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((CompilationUnit node) {
      final classDeclarations = node.declarations
          .whereType<ClassDeclaration>()
          .where((element) => !element.isStateClass);

      // If there's more than one class (excluding State classes),
      // report a lint diagnostic.
      if (classDeclarations.length > 1) {
        for (var i = 1; i < classDeclarations.length; i++) {
          final decl = classDeclarations.elementAt(i);
          reporter.atNode(decl, code);
        }
      }
    });
  }
}
