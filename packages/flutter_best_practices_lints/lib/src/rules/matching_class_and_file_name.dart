// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as path;

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/extensions/class_declaration_extension.dart';
import 'package:flutter_best_practices_lints/src/extensions/lint_code_extension.dart';
import 'package:flutter_best_practices_lints/src/extensions/pascal_case_extension.dart';

/// {@template matching_class_and_file_name}
/// Ensures that public class names in PascalCase correspond to their
/// snake_case file names, helping maintain consistency between files
/// and the primary class they contain.
///
/// - Single public class: name must match file name.
/// - Multiple public classes: at least one must match, and any others
///   not related to the primary class will trigger a warning.
/// {@endtemplate}
class MatchingClassAndFileName extends DartLintRule {
  /// {@macro matching_class_and_file_name}
  const MatchingClassAndFileName() : super(code: _code);

  /// Metadata about the diagnostic that appears in the IDE.
  ///
  /// The initial [LintCode.problemMessage] is general,
  /// but it may be overwritten dynamically in [run]
  /// when the class name does not match the file name.
  static const _code = LintCode(
    name: 'matching_class_and_file_name',
    problemMessage: 'Class name (PascalCase) must match the file name (snake_case).',
  );

  /// {@macro matching_class_and_file_name}
  ///
  /// Registers a callback to inspect each Dart compilation unit.
  /// It computes the expected class name from the file name,
  /// then validates each non-State, non-private class declaration.
  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    // Only apply to files under 'lib/' directory
    final filePath = resolver.path;

    // If the file path is not included in the lib folder,
    // it will not be checked.
    if (!path.split(filePath).contains('lib')) return;

    context.registry.addCompilationUnit((CompilationUnit node) {
      final fullPath = node.declaredElement!.source.fullName;
      final fileName = path.basenameWithoutExtension(fullPath);
      final expectedClassName = fileName.toPascalCase();

      // Collect all class declarations excluding private State classes
      final classDeclarations =
          node.declarations.whereType<ClassDeclaration>().where((cls) => !cls.isStateClass).toList();

      if (classDeclarations.isEmpty) return; // Nothing to check

      // Identify classes matching the expected primary name
      final primaryClasses = classDeclarations.where((cls) => cls.name.lexeme == expectedClassName).toList();

      // Single public class case
      if (classDeclarations.length == 1) {
        final mainClass = classDeclarations.first;
        if (mainClass.name.lexeme != expectedClassName) {
          // Report mismatch with correction recommendation
          reporter.atNode(
            mainClass,
            _code.copyWith(
              problemMessage: 'Class name ${mainClass.name.lexeme} must match the file name "$fileName".',
              correctionMessage: 'Rename the class to "$expectedClassName".',
            ),
          );
        }
        return;
      }

      // Multiple public classes
      if (primaryClasses.isNotEmpty) {
        // Warn on any classes not matching and not related to primary
        for (final cls in classDeclarations.where((c) => c.name.lexeme != expectedClassName)) {
          final isRelated = primaryClasses.any((primary) => cls.isRelatedTo(primary.name.lexeme));
          if (!isRelated) {
            reporter.atNode(
              cls,
              _code.copyWith(
                problemMessage: 'Class name ${cls.name.lexeme} does not match the file name "$fileName".',
                correctionMessage: 'Either rename it to "$expectedClassName" or separate into a new file.',
              ),
            );
          }
        }
      } else {
        // No primary class at all: warn on every class
        for (final cls in classDeclarations) {
          reporter.atNode(
            cls,
            _code.copyWith(
              problemMessage: 'Class name ${cls.name.lexeme} must match the file name "$fileName".',
              correctionMessage: 'Rename the class to "$expectedClassName".',
            ),
          );
        }
      }
    });
  }
}
