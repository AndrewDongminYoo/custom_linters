// 📦 Package imports:
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/extensions/class_declaration_extension.dart';
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
class MatchingClassAndFileName extends AnalysisRule {
  /// {@macro matching_class_and_file_name}
  MatchingClassAndFileName()
    : super(
        name: 'matching_class_and_file_name',
        description: 'Matches the primary class name to its file name.',
      );

  static const _code = LintCode(
    'matching_class_and_file_name',
    'Class name {0} {1} the file name "{2}".',
    correctionMessage: '{3}',
  );

  @override
  LintCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    if (!context.isInLibDir) return;

    registry.addCompilationUnit(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final MatchingClassAndFileName rule;
  final RuleContext context;

  @override
  void visitCompilationUnit(CompilationUnit node) {
    final shortName =
        context.currentUnit?.file.shortName ??
        context.definingUnit.file.shortName;
    final fileName = shortName.endsWith('.dart')
        ? shortName.substring(0, shortName.length - '.dart'.length)
        : shortName;
    final expectedClassName = fileName.toPascalCase();
    final classDeclarations = node.declarations
        .whereType<ClassDeclaration>()
        .where((declaration) => !declaration.isStateClass)
        .toList();

    if (classDeclarations.isEmpty) return;

    final primaryClasses = classDeclarations
        .where(
          (declaration) =>
              declaration.namePart.typeName.lexeme == expectedClassName,
        )
        .toList();

    if (classDeclarations.length == 1) {
      final declaration = classDeclarations.single;
      final className = declaration.namePart.typeName.lexeme;
      if (className != expectedClassName) {
        _reportMustMatch(
          declaration,
          className: className,
          fileName: fileName,
          expectedClassName: expectedClassName,
        );
      }
      return;
    }

    if (primaryClasses.isEmpty) {
      for (final declaration in classDeclarations) {
        _reportMustMatch(
          declaration,
          className: declaration.namePart.typeName.lexeme,
          fileName: fileName,
          expectedClassName: expectedClassName,
        );
      }
      return;
    }

    for (final declaration in classDeclarations) {
      final className = declaration.namePart.typeName.lexeme;
      if (className == expectedClassName) continue;

      final isRelated = primaryClasses.any(
        (primary) => declaration.isRelatedTo(primary.namePart.typeName.lexeme),
      );
      if (!isRelated) {
        rule.reportAtNode(
          declaration,
          arguments: [
            className,
            'does not match',
            fileName,
            'Either rename it to "$expectedClassName" or separate into a new file.',
          ],
        );
      }
    }
  }

  void _reportMustMatch(
    ClassDeclaration declaration, {
    required String className,
    required String fileName,
    required String expectedClassName,
  }) {
    rule.reportAtNode(
      declaration,
      arguments: [
        className,
        'must match',
        fileName,
        'Rename the class to "$expectedClassName".',
      ],
    );
  }
}
