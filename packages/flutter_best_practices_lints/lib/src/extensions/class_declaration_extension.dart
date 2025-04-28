// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';

/// {@template class_declaration_extension}
/// Provides convenient inspection utilities on a [ClassDeclaration]
/// to help custom lint rules determine class characteristics in Flutter code.
/// Utility getters include checks for private Flutter State classes,
/// abstract declarations, interface implementations, superclass extensions,
/// generic type usage, and overall relationships to other classes.
/// {@endtemplate}
extension ClassDeclarationExtension on ClassDeclaration {
  /// {@macro class_declaration_extension}
  ///
  /// Determines if the class is a private Flutter `State` subclass by verifying:
  /// 1. Class name starts with `_` (private).
  /// 2. Class name ends with `State`.
  /// 3. It extends a `State<T>` from Flutter's framework (library URI starts with `package:flutter/`).
  bool get isStateClass {
    final className = name.lexeme;
    // (1) Private classes end with 'State'
    if (!className.startsWith('_') || !className.endsWith('State')) {
      return false;
    }

    // (2) Must have an extends clause
    if (extendsClause == null) return false;

    // (3) Get the superclass AST node
    final superclassNode = extendsClause!.superclass;

    // (4) Resolve its static type element
    final superType = superclassNode.type;
    if (superType == null) return false;
    final superElement = superType.element;
    if (superElement == null) return false;

    // (5) Name must be exactly 'State'
    if (superElement.name != 'State') return false;

    // (6) Confirm it originates from Flutter
    final libraryUri = superElement.library?.source.uri.toString();
    if (libraryUri == null || !libraryUri.startsWith('package:flutter/')) {
      return false;
    }

    return true; // All checks passed
  }

  /// Returns `true` if this class is declared as `abstract`.
  bool get isAbstract => abstractKeyword != null;

  /// Checks if this class implements the interface named [interfaceName].
  /// Returns `true` if an `implements` clause lists the given interface.
  bool implementsInterface(String interfaceName) {
    final clause = implementsClause;
    if (clause == null) return false;
    // Check every implemented interface's identifier
    return clause.interfaces.any((typeName) => typeName.name2.lexeme == interfaceName);
  }

  /// Checks if this class directly extends a base class named [baseClassName].
  bool extendsClass(String baseClassName) {
    if (extendsClause == null) return false;
    // Compare superclass identifier
    return extendsClause!.superclass.name2.lexeme == baseClassName;
  }

  /// Determines if [baseClassName] appears as a generic type argument
  /// in either the extends or implements clauses of this class.
  bool usesGeneric(String baseClassName) {
    // Check extends clause type arguments
    if (extendsClause != null) {
      final typeArgs = extendsClause!.superclass.typeArguments;
      if (typeArgs != null) {
        // Iterate through <...> arguments
        for (final arg in typeArgs.arguments) {
          if (arg is NamedType && arg.name2.lexeme == baseClassName) {
            return true;
          }
        }
      }
    }

    // Check implements clause type arguments
    if (implementsClause != null) {
      for (final interface in implementsClause!.interfaces) {
        final typeArgs = interface.typeArguments;
        if (typeArgs != null) {
          for (final arg in typeArgs.arguments) {
            if (arg is NamedType && arg.name2.lexeme == baseClassName) {
              return true;
            }
          }
        }
      }
    }

    return false;
  }

  /// Returns `true` if this class is related to [className] by either
  /// implementing it, extending it, or using it as a generic type.
  bool isRelatedTo(String className) {
    return implementsInterface(className) || extendsClass(className) || usesGeneric(className);
  }
}
