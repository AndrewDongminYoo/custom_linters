// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as path;

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/extensions/class_declaration_extension.dart';
import 'package:flutter_best_practices_lints/src/extensions/lint_code_extension.dart';

/// {@template matching_class_and_file_name}
/// A custom lint rule that checks whether the main class name (in PascalCase)
/// matches the file name (in snake_case).
///
/// This rule is part of the `flutter_best_practices_lints` plugin.
/// It ensures that each file's primary class is in sync with its file name,
/// improving project structure and clarity.
///
/// - Excludes classes that are recognized as Flutter `State` classes
///   (for example, `_MyWidgetState`).
/// - Excludes abstract classes.
/// {@endtemplate}
class MatchingClassAndFileName extends DartLintRule {
  /// {@macro matching_class_and_file_name}
  const MatchingClassAndFileName() : super(code: _code);

  /// Metadata about the diagnostic that appears in the IDE.
  ///
  /// The initial [problemMessage] is general, but it may be overwritten
  /// dynamically in [run] when the class name does not match the file name.
  static const _code = LintCode(
    name: 'matching_class_and_file_name',
    problemMessage:
        'Class name (PascalCase) must match the file name (snake_case).',
  );

  /// {@macro matching_class_and_file_name}
  ///
  /// This method retrieves the current file path, derives the expected class
  /// name from the file name, and compares it against each non-abstract,
  /// non-State class. If a mismatch is found, a lint diagnostic is reported.
  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((CompilationUnit node) {
      final filePath = node.declaredElement!.source.fullName;
      final fileName = path.basenameWithoutExtension(filePath);

      String snakeToPascal(String snakeCase) {
        return snakeCase.split('_').map((segment) {
          if (segment.isEmpty) return '';
          return segment[0].toUpperCase() + segment.substring(1);
        }).join();
      }

      final expectedClassName = snakeToPascal(fileName);

      // Filter out classes that are recognized as Flutter State classes
      // or declared abstract.
      final classDeclarations = node.declarations
          .whereType<ClassDeclaration>()
          .where((ClassDeclaration classDecl) {
        return !classDecl.isStateClass && !classDecl.isAbstract;
      });

      for (final classDecl in classDeclarations) {
        final className = classDecl.name.lexeme;
        if (className != expectedClassName) {
          // Dynamically override the problem/correction message
          reporter.atNode(
            classDecl,
            code.copyWith(
              problemMessage:
                  'Class name $className must match the file name "$fileName"',
              correctionMessage: 'Rename the class to "$expectedClassName".\n'
                  'Alternatively, separate the classes into different files.',
            ),
          );
        }
      }
    });
  }
}
