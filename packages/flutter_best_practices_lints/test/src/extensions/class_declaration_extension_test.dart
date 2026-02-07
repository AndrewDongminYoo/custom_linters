// ignore_for_file: directives_ordering

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/extensions/class_declaration_extension.dart';

void main() {
  group('ClassDeclarationExtension', () {
    group('isStateClass', () {
      test(
        'returns true for private State class',
        () {
          final unit = parseString(
            content: "import 'package:flutter/widgets.dart';\n\nclass _AwesomeWidgetState extends State<int> {}\n",
          ).unit;
          final classDecl = unit.declarations.whereType<ClassDeclaration>().single;

          expect(classDecl.isStateClass, isTrue);
        },
      );

      test('returns false for non-State class', () {
        // No `extends` clause.
        final mockNonStateClass = parseString(
          content: 'class AuthenticationState {}',
        ).unit.declarations.whereType<ClassDeclaration>().single;

        expect(mockNonStateClass.isStateClass, isFalse);
      });

      test('returns false for class with State in middle', () {
        final middleStateClass = parseString(
          content: 'class MidleStateClass {}',
        ).unit.declarations.whereType<ClassDeclaration>().single;

        expect(middleStateClass.isStateClass, isFalse);
      });

      test('returns false for public State class', () {
        final publicStateClass = parseString(
          content: 'class PublicStateClass {}',
        ).unit.declarations.whereType<ClassDeclaration>().single;

        expect(publicStateClass.isStateClass, isFalse);
      });
    });

    group('isAbstract', () {
      test('returns true for abstract class', () {
        final mockAbstractClass = parseString(
          content: 'abstract class MockAbstractClass {}',
        ).unit.declarations.whereType<ClassDeclaration>().single;

        expect(mockAbstractClass.isAbstract, isTrue);
      });

      test('returns false for non-abstract class', () {
        final mockRegularClass = parseString(
          content: 'class MockRegularClass {}',
        ).unit.declarations.whereType<ClassDeclaration>().single;

        expect(mockRegularClass.isAbstract, isFalse);
      });

      test('returns false for private State class without abstract keyword', () {
        final mockStateClass = parseString(
          content: 'class _AwesomeWidgetState {}',
        ).unit.declarations.whereType<ClassDeclaration>().single;

        expect(mockStateClass.isAbstract, isFalse);
      });
    });
  });
}
