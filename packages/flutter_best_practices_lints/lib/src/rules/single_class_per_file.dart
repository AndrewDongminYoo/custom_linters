// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as path;

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/extensions/class_declaration_extension.dart';

/// {@template single_class_per_file}
/// Validates that each Dart file declares only one public class,
/// except when exactly two public classes exist and one is abstract
/// while the other extends or implements it (common for interface+impl),
/// or when a StatefulWidget and its private State coexist.
/// {@endtemplate}
class SingleClassPerFile extends DartLintRule {
  /// {@macro single_class_per_file}
  const SingleClassPerFile()
      : super(
          code: const LintCode(
            name: 'single_class_per_file',
            problemMessage: 'A file should contain only one public class declaration.',
            correctionMessage: 'Split the classes into separate files.',
          ),
        );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    // Only enforce for 'lib/' sources
    final filePath = resolver.path;
    if (!path.split(filePath).contains('lib')) return;

    context.registry.addCompilationUnit((CompilationUnit node) {
      final allClasses = node.declarations.whereType<ClassDeclaration>().toList();
      // Public classes do not start with '_'
      final publicClasses = allClasses.where((cls) => !cls.name.lexeme.startsWith('_')).toList();

      if (publicClasses.length <= 1) return; // Zero or one public class is fine

      // Allow exactly two if one is abstract and the other extends/implements it
      if (publicClasses.length == 2) {
        final first = publicClasses[0];
        final second = publicClasses[1];
        final firstIsAbstract = first.isAbstract;
        final secondIsAbstract = second.isAbstract;
        final firstUsedBySecond =
            second.implementsInterface(first.name.lexeme) || second.extendsClass(first.name.lexeme);
        final secondUsedByFirst =
            first.implementsInterface(second.name.lexeme) || first.extendsClass(second.name.lexeme);

        // If one class is an abstract definition and the other builds on it, allow both
        if ((firstIsAbstract && firstUsedBySecond) || (secondIsAbstract && secondUsedByFirst)) {
          return;
        }
      }

      // For any extra public classes beyond allowed, issue lint
      for (var i = 1; i < publicClasses.length; i++) {
        reporter.atNode(publicClasses[i], code);
      }
    });
  }
}
