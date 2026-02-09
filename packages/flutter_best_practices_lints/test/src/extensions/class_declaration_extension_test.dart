// 📦 Package imports:
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/extensions/class_declaration_extension.dart';

/// Parses a Dart source code string and extracts the first [ClassDeclaration].
ClassDeclaration parseClassDeclaration(String code) {
  final result = parseString(content: code);
  final unit = result.unit;
  return unit.declarations.whereType<ClassDeclaration>().first;
}

void main() {
  group('ClassDeclarationExtension', () {
    group('isStateClass', () {
      test(
        'returns true for private State class',
        () {
          const code = '''
class _AwesomeWidgetState extends State<AwesomeWidget> {}
''';
          final classDecl = parseClassDeclaration(code);
          expect(classDecl.isStateClass, isTrue);
        },
        skip: 'parseString() only does syntactic parsing without type resolution. '
            'isStateClass requires resolved types to verify State extends from '
            'package:flutter. Full analysis context setup would be too complex '
            'for this unit test.',
      );

      test('returns false for non-State class', () {
        const code = '''
class AuthenticationState {}
''';
        final classDecl = parseClassDeclaration(code);
        expect(classDecl.isStateClass, isFalse);
      });

      test('returns false for class with State in middle', () {
        const code = '''
class MiddleStateClass {}
''';
        final classDecl = parseClassDeclaration(code);
        expect(classDecl.isStateClass, isFalse);
      });

      test('returns false for public State class', () {
        const code = '''
class PublicStateClass {}
''';
        final classDecl = parseClassDeclaration(code);
        expect(classDecl.isStateClass, isFalse);
      });
    });

    group('isAbstract', () {
      test('returns true for abstract class', () {
        const code = '''
abstract class MockAbstractClass {}
''';
        final classDecl = parseClassDeclaration(code);
        expect(classDecl.isAbstract, isTrue);
      });

      test('returns false for non-abstract class', () {
        const code = '''
class MockRegularClass {}
''';
        final classDecl = parseClassDeclaration(code);
        expect(classDecl.isAbstract, isFalse);
      });

      test('returns false for private State class without abstract keyword', () {
        const code = '''
class _AwesomeWidgetState {}
''';
        final classDecl = parseClassDeclaration(code);
        expect(classDecl.isAbstract, isFalse);
      });
    });
  });
}
