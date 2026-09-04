// 🌎 Project imports:
import 'package:flutter_best_practices_lints/flutter_best_practices_lints.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

import '../lint_test_utils.dart';

const _code = 'single_class_per_file';
const _message = 'A file should contain only one public class declaration.';
const _correction = 'Split the classes into separate files.';

void main() {
  group('SingleClassPerFile', () {
    test('allows one public class and any number of private classes', () async {
      final diagnostics = await analyzeLintRule(
        const SingleClassPerFile(),
        '''
class PublicClass {}
class _PrivateClass {}
class _AnotherPrivateClass {}
''',
      );

      expect(diagnostics, isEmpty);
    });

    test('reports each public class after the first', () async {
      const source = '''
class FirstClass {}
class SecondClass {}
class ThirdClass {}
''';
      final diagnostics = await analyzeLintRule(
        const SingleClassPerFile(),
        source,
      );

      expect(diagnostics, hasLength(2));
      for (final (index, declaration) in [
        'class SecondClass {}',
        'class ThirdClass {}',
      ].indexed) {
        expectLintDiagnostic(
          diagnostics[index],
          code: _code,
          message: _message,
          correctionMessage: _correction,
          offset: source.indexOf(declaration),
          length: declaration.length,
        );
      }
    });

    test(
      'reports a direct relationship when neither class is abstract',
      () async {
        const source = '''
class BaseClass {}
class ChildClass extends BaseClass {}
''';
        const declaration = 'class ChildClass extends BaseClass {}';
        final diagnostics = await analyzeLintRule(
          const SingleClassPerFile(),
          source,
        );

        expect(diagnostics, hasLength(1));
        expectLintDiagnostic(
          diagnostics.single,
          code: _code,
          message: _message,
          correctionMessage: _correction,
          offset: source.indexOf(declaration),
          length: declaration.length,
        );
      },
    );

    test('allows an abstract class with its direct subclass', () async {
      final diagnostics = await analyzeLintRule(
        const SingleClassPerFile(),
        '''
abstract class BaseClass {}
class ChildClass extends BaseClass {}
''',
      );

      expect(diagnostics, isEmpty);
    });

    test('allows an abstract class with its direct implementation', () async {
      final diagnostics = await analyzeLintRule(
        const SingleClassPerFile(),
        '''
abstract class Contract {}
class Implementation implements Contract {}
''',
      );

      expect(diagnostics, isEmpty);
    });

    test('reports a non-direct relationship through a private class', () async {
      const source = '''
abstract class BaseClass {}
class _MiddleClass extends BaseClass {}
class ChildClass extends _MiddleClass {}
''';
      const declaration = 'class ChildClass extends _MiddleClass {}';
      final diagnostics = await analyzeLintRule(
        const SingleClassPerFile(),
        source,
      );

      expect(diagnostics, hasLength(1));
      expectLintDiagnostic(
        diagnostics.single,
        code: _code,
        message: _message,
        correctionMessage: _correction,
        offset: source.indexOf(declaration),
        length: declaration.length,
      );
    });

    test('reports under the package lib directory', () async {
      const source = '''
class FirstClass {}
class SecondClass {}
''';
      const declaration = 'class SecondClass {}';
      final diagnostics = await analyzeLintRule(
        const SingleClassPerFile(),
        source,
        relativePath: 'lib/feature/main.dart',
      );

      expect(diagnostics, hasLength(1));
      expectLintDiagnostic(
        diagnostics.single,
        code: _code,
        message: _message,
        correctionMessage: _correction,
        offset: source.indexOf(declaration),
        length: declaration.length,
      );
    });

    test(
      'records the legacy false positive for an unrelated lib ancestor',
      () async {
        const source = '''
class FirstClass {}
class SecondClass {}
''';
        const declaration = 'class SecondClass {}';
        final diagnostics = await analyzeLintRule(
          const SingleClassPerFile(),
          source,
          relativePath: 'fixtures/lib/main.dart',
        );

        expect(diagnostics, hasLength(1));
        expectLintDiagnostic(
          diagnostics.single,
          code: _code,
          message: _message,
          correctionMessage: _correction,
          offset: source.indexOf(declaration),
          length: declaration.length,
        );
      },
    );
  });
}
