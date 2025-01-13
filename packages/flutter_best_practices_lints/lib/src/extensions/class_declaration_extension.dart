// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';

/// {@template class_declaration_extension}
/// An extension on [ClassDeclaration] that provides utility getters
/// to determine whether the class is a private `State`-related class
/// (common in Flutter) or an abstract class.
/// {@endtemplate}
extension ClassDeclarationExtension on ClassDeclaration {
  /// {@macro class_declaration_extension}
  ///
  /// Checks if this [ClassDeclaration] is considered a `State` class.
  /// Specifically, it verifies two conditions:
  /// 1. The class name starts with an underscore (`_`).
  /// 2. The class name ends with the substring `State`.
  /// 3. The class extends `State` class.
  ///
  /// This is typically used in Flutter to detect private `State` subclasses.
  bool get isStateClass {
    final className = name.lexeme;
    return className.startsWith('_') &&
        className.endsWith('State') &&
        extendsClause != null;
  }

  /// Returns `true` if this [ClassDeclaration] is declared as `abstract`.
  ///
  /// This is determined by checking whether [abstractKeyword] is non-null.
  bool get isAbstract => abstractKeyword != null;
}
