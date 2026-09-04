// ignore_for_file: non_constant_identifier_names

// 📦 Package imports:
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/rules/avoid_widget_operator_equals.dart';

const _message = 'Avoid overriding operator == on Widget classes.';
const _correction =
    'Rely on Flutter widget identity and const constructors instead.';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidWidgetOperatorEqualsTest);
  });
}

@reflectiveTest
class AvoidWidgetOperatorEqualsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile('lib/widgets.dart', '''
abstract class Widget {}
abstract class StatelessWidget extends Widget {}
abstract class StatefulWidget extends Widget {}
''');
    rule = AvoidWidgetOperatorEquals();
    super.setUp();
  }

  Future<void> test_reportsDirectFlutterWidgetSubclasses() async {
    const source = '''
import 'package:flutter/widgets.dart';

abstract class DirectWidget extends Widget {
  bool operator ==(Object other) => other is DirectWidget;
}

abstract class DirectStatelessWidget extends StatelessWidget {
  bool operator ==(Object other) => other is DirectStatelessWidget;
}

abstract class DirectStatefulWidget extends StatefulWidget {
  bool operator ==(Object other) => other is DirectStatefulWidget;
}
''';
    const declarations = [
      'bool operator ==(Object other) => other is DirectWidget;',
      'bool operator ==(Object other) => other is DirectStatelessWidget;',
      'bool operator ==(Object other) => other is DirectStatefulWidget;',
    ];

    await assertDiagnostics(source, [
      for (final declaration in declarations)
        lint(
          source.indexOf(declaration),
          declaration.length,
          messageContainsAll: [_exact(_message)],
          correctionContains: _exact(_correction),
        ),
    ]);
  }

  Future<void> test_ignoresSameNamedClassesOutsideFlutter() async {
    await assertNoDiagnostics('''
class Widget {}
class StatelessWidget {}
class StatefulWidget {}

class LocalWidget extends Widget {
  bool operator ==(Object other) => other is LocalWidget;
}

class LocalStatelessWidget extends StatelessWidget {
  bool operator ==(Object other) => other is LocalStatelessWidget;
}

class LocalStatefulWidget extends StatefulWidget {
  bool operator ==(Object other) => other is LocalStatefulWidget;
}
''');
  }

  Future<void> test_ignoresIndirectFlutterWidgetSubclasses() async {
    await assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

abstract class BaseWidget extends StatelessWidget {}

class IndirectWidget extends BaseWidget {
  bool operator ==(Object other) => other is IndirectWidget;
}
''');
  }

  Future<void> test_ignoresClassesWithoutEqualityOverride() async {
    await assertNoDiagnostics('''
import 'package:flutter/widgets.dart';

abstract class PlainWidget extends Widget {}
abstract class PlainStatelessWidget extends StatelessWidget {}
abstract class PlainStatefulWidget extends StatefulWidget {}
''');
  }
}

RegExp _exact(String value) => RegExp('^${RegExp.escape(value)}\$');
