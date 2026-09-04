// ignore_for_file: non_constant_identifier_names

// 📦 Package imports:
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/rules/single_class_per_file.dart';

const _message = 'A file should contain only one public class declaration.';
const _correction = 'Split the classes into separate files.';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SingleClassPerFileTest);
  });
}

@reflectiveTest
class SingleClassPerFileTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = SingleClassPerFile();
    super.setUp();
  }

  Future<void> test_allowsOnePublicClassAndPrivateClasses() async {
    await assertNoDiagnostics('''
class PublicClass {}
class _PrivateClass {}
class _AnotherPrivateClass {}
''');
  }

  Future<void> test_reportsEachPublicClassAfterFirst() async {
    const source = '''
class FirstClass {}
class SecondClass {}
class ThirdClass {}
''';
    const second = 'class SecondClass {}';
    const third = 'class ThirdClass {}';

    await assertDiagnostics(source, [
      lint(
        source.indexOf(second),
        second.length,
        messageContainsAll: [_exact(_message)],
        correctionContains: _exact(_correction),
      ),
      lint(
        source.indexOf(third),
        third.length,
        messageContainsAll: [_exact(_message)],
        correctionContains: _exact(_correction),
      ),
    ]);
  }

  Future<void> test_reportsDirectRelationshipWhenNeitherIsAbstract() async {
    const source = '''
class BaseClass {}
class ChildClass extends BaseClass {}
''';
    const declaration = 'class ChildClass extends BaseClass {}';

    await assertDiagnostics(source, [
      lint(
        source.indexOf(declaration),
        declaration.length,
        messageContainsAll: [_exact(_message)],
        correctionContains: _exact(_correction),
      ),
    ]);
  }

  Future<void> test_allowsAbstractClassWithDirectSubclass() async {
    await assertNoDiagnostics('''
abstract class BaseClass {}
class ChildClass extends BaseClass {}
''');
  }

  Future<void> test_allowsAbstractClassWithDirectImplementation() async {
    await assertNoDiagnostics('''
abstract class Contract {}
class Implementation implements Contract {}
''');
  }

  Future<void> test_reportsNonDirectRelationshipThroughPrivateClass() async {
    const source = '''
abstract class BaseClass {}
class _MiddleClass extends BaseClass {}
class ChildClass extends _MiddleClass {}
''';
    const declaration = 'class ChildClass extends _MiddleClass {}';

    await assertDiagnostics(source, [
      lint(
        source.indexOf(declaration),
        declaration.length,
        messageContainsAll: [_exact(_message)],
        correctionContains: _exact(_correction),
      ),
    ]);
  }

  Future<void> test_reportsInsidePackageLibDirectory() async {
    const source = '''
class FirstClass {}
class SecondClass {}
''';
    const declaration = 'class SecondClass {}';

    await assertDiagnostics(source, [
      lint(
        source.indexOf(declaration),
        declaration.length,
        messageContainsAll: [_exact(_message)],
        correctionContains: _exact(_correction),
      ),
    ]);
  }

  Future<void> test_ignoresUnrelatedLibAncestor() async {
    final path = '$testPackageRootPath/fixtures/lib/main.dart';
    newFile(
      path,
      '''
class FirstClass {}
class SecondClass {}
''',
    );

    await assertNoDiagnosticsInFile(path);
  }
}

RegExp _exact(String value) => RegExp('^${RegExp.escape(value)}\$');
