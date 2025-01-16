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
  /// Specifically, it verifies the following conditions:
  /// 1. The class name starts with an underscore (`_`).
  /// 2. The class name ends with the substring `State`.
  /// 3. The class extends a class whose element name is `State`,
  ///    and its library URI starts with `package:flutter/`.
  ///
  /// This is typically used in Flutter to detect private `State` subclasses.
  bool get isStateClass {
    // (1) Check if the class name follows the naming convention.
    final className = name.lexeme;
    if (!className.startsWith('_') || !className.endsWith('State')) {
      return false;
    }

    // (2) Ensure the class has an extends clause.
    if (extendsClause == null) return false;

    // (3) Retrieve the superclass node.
    final superclassNode = extendsClause!.superclass;

    // (4) Retrieve the static type's element of the superclass.
    final superType = superclassNode.type;
    if (superType == null) return false;
    final superElement = superType.element;
    if (superElement == null) return false;

    // (5) Check that the superclass element's name is exactly 'State'.
    if (superElement.name != 'State') return false;

    // (6) Optionally, confirm that the superclass comes from the Flutter.
    final libraryUri = superElement.library?.source.uri.toString();
    if (libraryUri == null || !libraryUri.startsWith('package:flutter/')) {
      return false;
    }

    return true;
  }

  /// Returns `true` if this [ClassDeclaration] is declared as `abstract`.
  ///
  /// This is determined by checking whether [abstractKeyword] is non-null.
  bool get isAbstract => abstractKeyword != null;
}
