// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/error/error.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/extensions/class_declaration_extension.dart';

/// {@template single_class_per_file}
/// Validates that each Dart file declares only one public class,
/// except when exactly two public classes exist and one is abstract
/// while the other extends or implements it (common for interface+impl),
/// or when a StatefulWidget and its private State coexist.
/// {@endtemplate}
class SingleClassPerFile extends AnalysisRule {
  /// {@macro single_class_per_file}
  SingleClassPerFile()
    : super(
        name: 'single_class_per_file',
        description: 'Enforces one public class declaration per file.',
      );

  static const _code = LintCode(
    'single_class_per_file',
    'A file should contain only one public class declaration.',
    correctionMessage: 'Split the classes into separate files.',
  );

  @override
  LintCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isInLibDir) return;

    registry.addCompilationUnit(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final SingleClassPerFile rule;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final allClasses = node.declarations.whereType<ClassDeclaration>().toList();
    final publicClasses = allClasses
        .where(
          (declaration) =>
              !declaration.namePart.typeName.lexeme.startsWith('_'),
        )
        .toList();

    if (publicClasses.length <= 1) return;

    if (publicClasses.length == 2) {
      final first = publicClasses[0];
      final second = publicClasses[1];
      final firstName = first.namePart.typeName.lexeme;
      final secondName = second.namePart.typeName.lexeme;
      final firstUsedBySecond =
          second.implementsInterface(firstName) ||
          second.extendsClass(firstName);
      final secondUsedByFirst =
          first.implementsInterface(secondName) ||
          first.extendsClass(secondName);

      if ((first.isAbstract && firstUsedBySecond) ||
          (second.isAbstract && secondUsedByFirst)) {
        return;
      }
    }

    for (var index = 1; index < publicClasses.length; index++) {
      rule.reportAtNode(publicClasses[index]);
    }
  }
}
