// ignore_for_file: non_constant_identifier_names

// 📦 Package imports:
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/rules/prefer_widget_class_over_widget_helper.dart';

const _message = 'Prefer a widget class over private Widget helper methods.';
const _correction =
    'Extract this reusable UI into a StatelessWidget or StatefulWidget.';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferWidgetClassOverWidgetHelperTest);
  });
}

@reflectiveTest
class PreferWidgetClassOverWidgetHelperTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = PreferWidgetClassOverWidgetHelper();
    super.setUp();
  }

  Future<void> test_reportsPrivateWidgetFunctionsAndMethods() async {
    const source = '''
class Widget {}

Widget _buildHeader() => Widget();

class HomePage {
  Widget _buildBody() => Widget();
  Widget build() => _buildBody();
}
''';
    const function = 'Widget _buildHeader() => Widget();';
    const method = 'Widget _buildBody() => Widget();';

    await assertDiagnostics(source, [
      lint(
        source.indexOf(function),
        function.length,
        messageContainsAll: [_exact(_message)],
        correctionContains: _exact(_correction),
      ),
      lint(
        source.indexOf(method),
        method.length,
        messageContainsAll: [_exact(_message)],
        correctionContains: _exact(_correction),
      ),
    ]);
  }

  Future<void> test_usesBuildPrefixAndFinalReturnTypeName() async {
    const source = '''
class Widget {}

Widget _builder() => Widget();
Widget? _buildNullable() => null;
''';
    const builder = 'Widget _builder() => Widget();';
    const nullable = 'Widget? _buildNullable() => null;';

    await assertDiagnostics(source, [
      lint(
        source.indexOf(builder),
        builder.length,
        messageContainsAll: [_exact(_message)],
        correctionContains: _exact(_correction),
      ),
      lint(
        source.indexOf(nullable),
        nullable.length,
        messageContainsAll: [_exact(_message)],
        correctionContains: _exact(_correction),
      ),
    ]);
  }

  Future<void> test_ignoresOtherNamesAndReturnTypes() async {
    await assertNoDiagnostics('''
class Widget {}

Object _buildObject() => Object();
Future<Widget> _buildAsync() async => Widget();
Widget _header() => Widget();
Widget buildHeader() => Widget();
''');
  }

  Future<void> test_ignoresBuildMethod() async {
    await assertNoDiagnostics('''
class Widget {}

class HomePage {
  Widget build() => Widget();
}
''');
  }

  Future<void> test_ignoresMethodsOutsideClasses() async {
    await assertNoDiagnostics('''
class Widget {}

extension WidgetExtension on Widget {
  Widget _buildExtension() => Widget();
}

mixin WidgetMixin {
  Widget _buildMixin() => Widget();
}

enum WidgetEnum {
  value;

  Widget _buildEnum() => Widget();
}

extension type WidgetExtensionType(Object value) {
  Widget _buildExtensionType() => Widget();
}
''');
  }

  Future<void> test_ignoresLocalFunctions() async {
    await assertNoDiagnostics('''
class Widget {}

void enclosing() {
  Widget _buildLocal() => Widget();
  _buildLocal();
}
''');
  }
}

RegExp _exact(String value) => RegExp('^${RegExp.escape(value)}\$');
