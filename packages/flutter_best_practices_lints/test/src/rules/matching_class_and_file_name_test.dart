// 🌎 Project imports:
import 'package:flutter_best_practices_lints/flutter_best_practices_lints.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

import '../lint_test_utils.dart';

const _code = 'matching_class_and_file_name';

void main() {
  group('MatchingClassAndFileName', () {
    test('allows a single class that matches the file name', () async {
      final diagnostics = await analyzeLintRule(
        const MatchingClassAndFileName(),
        'class HomePage {}',
        relativePath: 'lib/home_page.dart',
      );

      expect(diagnostics, isEmpty);
    });

    test('reports a single class that does not match the file name', () async {
      const source = 'class WrongName {}';
      final diagnostics = await analyzeLintRule(
        const MatchingClassAndFileName(),
        source,
        relativePath: 'lib/home_page.dart',
      );

      expect(diagnostics, hasLength(1));
      expectLintDiagnostic(
        diagnostics.single,
        code: _code,
        message: 'Class name WrongName must match the file name "home_page".',
        correctionMessage: 'Rename the class to "HomePage".',
        offset: 0,
        length: source.length,
      );
    });

    test(
      'reports only unrelated classes when a primary class exists',
      () async {
        const source = '''
class HomePage {}
class HomePageChild extends HomePage {}
class Helper {}
''';
        const declaration = 'class Helper {}';
        final diagnostics = await analyzeLintRule(
          const MatchingClassAndFileName(),
          source,
          relativePath: 'lib/home_page.dart',
        );

        expect(diagnostics, hasLength(1));
        expectLintDiagnostic(
          diagnostics.single,
          code: _code,
          message:
              'Class name Helper does not match the file name "home_page".',
          correctionMessage:
              'Either rename it to "HomePage" or separate into a new file.',
          offset: source.indexOf(declaration),
          length: declaration.length,
        );
      },
    );

    test(
      'allows classes that directly extend or implement the primary',
      () async {
        final diagnostics = await analyzeLintRule(
          const MatchingClassAndFileName(),
          '''
abstract class HomePage {}
class HomePageChild extends HomePage {}
class HomePageImplementation implements HomePage {}
''',
          relativePath: 'lib/home_page.dart',
        );

        expect(diagnostics, isEmpty);
      },
    );

    test(
      'allows primary use in extends and implements type arguments',
      () async {
        final diagnostics = await analyzeLintRule(
          const MatchingClassAndFileName(),
          '''
class HomePage {}
abstract class IterableUse extends Iterable<HomePage> {}
abstract class ComparableUse implements Comparable<HomePage> {}
''',
          relativePath: 'lib/home_page.dart',
        );

        expect(diagnostics, isEmpty);
      },
    );

    test('reports every class when no primary class exists', () async {
      const source = '''
class FirstClass {}
class SecondClass {}
''';
      final diagnostics = await analyzeLintRule(
        const MatchingClassAndFileName(),
        source,
        relativePath: 'lib/home_page.dart',
      );

      expect(diagnostics, hasLength(2));
      for (final (index, declaration) in [
        'class FirstClass {}',
        'class SecondClass {}',
      ].indexed) {
        final className = index == 0 ? 'FirstClass' : 'SecondClass';
        expectLintDiagnostic(
          diagnostics[index],
          code: _code,
          message:
              'Class name $className must match the file name "home_page".',
          correctionMessage: 'Rename the class to "HomePage".',
          offset: source.indexOf(declaration),
          length: declaration.length,
        );
      }
    });

    test('reports a private non-State class', () async {
      const source = 'class _HomePage {}';
      final diagnostics = await analyzeLintRule(
        const MatchingClassAndFileName(),
        source,
        relativePath: 'lib/home_page.dart',
      );

      expect(diagnostics, hasLength(1));
      expectLintDiagnostic(
        diagnostics.single,
        code: _code,
        message: 'Class name _HomePage must match the file name "home_page".',
        correctionMessage: 'Rename the class to "HomePage".',
        offset: 0,
        length: source.length,
      );
    });

    test('ignores a private Flutter State class', () async {
      final diagnostics = await analyzeLintRule(
        const MatchingClassAndFileName(),
        '''
import 'package:flutter/widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
''',
        relativePath: 'lib/home_page.dart',
      );

      expect(diagnostics, isEmpty);
    });

    test('reports under the package lib directory', () async {
      const source = 'class WrongName {}';
      final diagnostics = await analyzeLintRule(
        const MatchingClassAndFileName(),
        source,
        relativePath: 'lib/home_page.dart',
      );

      expect(diagnostics, hasLength(1));
      expectLintDiagnostic(
        diagnostics.single,
        code: _code,
        message: 'Class name WrongName must match the file name "home_page".',
        correctionMessage: 'Rename the class to "HomePage".',
        offset: 0,
        length: source.length,
      );
    });

    test(
      'records the legacy false positive for an unrelated lib ancestor',
      () async {
        const source = 'class WrongName {}';
        final diagnostics = await analyzeLintRule(
          const MatchingClassAndFileName(),
          source,
          relativePath: 'fixtures/lib/home_page.dart',
        );

        expect(diagnostics, hasLength(1));
        expectLintDiagnostic(
          diagnostics.single,
          code: _code,
          message: 'Class name WrongName must match the file name "home_page".',
          correctionMessage: 'Rename the class to "HomePage".',
          offset: 0,
          length: source.length,
        );
      },
    );
  });
}
