// ignore_for_file: non_constant_identifier_names

// 📦 Package imports:
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/rules/matching_class_and_file_name.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MatchingClassAndFileNameTest);
  });
}

@reflectiveTest
class MatchingClassAndFileNameTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile('lib/widgets.dart', '''
abstract class Widget {}
abstract class StatefulWidget extends Widget {}
abstract class State<T extends StatefulWidget> {}
''');
    rule = MatchingClassAndFileName();
    super.setUp();
  }

  Future<void> test_allowsMatchingSingleClass() async {
    final path = _writeHomePage('class HomePage {}');
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_reportsMismatchingSingleClass() async {
    const source = 'class WrongName {}';

    final path = _writeHomePage(source);
    await assertDiagnosticsInFile(path, [
      lint(
        0,
        source.length,
        messageContainsAll: [
          _exact('Class name WrongName must match the file name "home_page".'),
        ],
        correctionContains: _exact('Rename the class to "HomePage".'),
      ),
    ]);
  }

  Future<void> test_reportsOnlyUnrelatedClassWhenPrimaryExists() async {
    const source = '''
class HomePage {}
class HomePageChild extends HomePage {}
class Helper {}
''';
    const helper = 'class Helper {}';

    final path = _writeHomePage(source);
    await assertDiagnosticsInFile(path, [
      lint(
        source.indexOf(helper),
        helper.length,
        messageContainsAll: [
          _exact(
            'Class name Helper does not match the file name "home_page".',
          ),
        ],
        correctionContains: _exact(
          'Either rename it to "HomePage" or separate into a new file.',
        ),
      ),
    ]);
  }

  Future<void> test_allowsDirectExtendsAndImplementsRelationships() async {
    final path = _writeHomePage('''
abstract class HomePage {}
class HomePageChild extends HomePage {}
class HomePageImplementation implements HomePage {}
''');
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_allowsPrimaryInClauseTypeArguments() async {
    final path = _writeHomePage('''
class HomePage {}
abstract class IterableUse extends Iterable<HomePage> {}
abstract class ComparableUse implements Comparable<HomePage> {}
''');
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_reportsEveryClassWhenNoPrimaryExists() async {
    const source = '''
class FirstClass {}
class SecondClass {}
''';
    const first = 'class FirstClass {}';
    const second = 'class SecondClass {}';

    final path = _writeHomePage(source);
    await assertDiagnosticsInFile(path, [
      lint(
        source.indexOf(first),
        first.length,
        messageContainsAll: [
          _exact(
            'Class name FirstClass must match the file name "home_page".',
          ),
        ],
        correctionContains: _exact('Rename the class to "HomePage".'),
      ),
      lint(
        source.indexOf(second),
        second.length,
        messageContainsAll: [
          _exact(
            'Class name SecondClass must match the file name "home_page".',
          ),
        ],
        correctionContains: _exact('Rename the class to "HomePage".'),
      ),
    ]);
  }

  Future<void> test_reportsPrivateNonStateClass() async {
    const source = 'class _HomePage {}';

    final path = _writeHomePage(source);
    await assertDiagnosticsInFile(path, [
      lint(
        0,
        source.length,
        messageContainsAll: [
          _exact('Class name _HomePage must match the file name "home_page".'),
        ],
        correctionContains: _exact('Rename the class to "HomePage".'),
      ),
    ]);
  }

  Future<void> test_ignoresPrivateFlutterStateClass() async {
    final path = _writeHomePage('''
import 'package:flutter/widgets.dart';

class HomePage extends StatefulWidget {}
class _HomePageState extends State<HomePage> {}
''');
    await assertNoDiagnosticsInFile(path);
  }

  Future<void> test_ignoresUnrelatedLibAncestor() async {
    final path = '$testPackageRootPath/fixtures/lib/home_page.dart';
    newFile(path, 'class WrongName {}');

    await assertNoDiagnosticsInFile(path);
  }

  String _writeHomePage(String source) {
    final path = '$testPackageLibPath/home_page.dart';
    newFile(path, source);
    return path;
  }
}

RegExp _exact(String value) => RegExp('^${RegExp.escape(value)}\$');
