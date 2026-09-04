// ignore_for_file: non_constant_identifier_names

// 📦 Package imports:
import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/rules/prefer_media_query_partial_methods.dart';

const _message =
    'Use the specific MediaQuery accessor to avoid unnecessary rebuilds.';
const _replacements = <(String, String)>[
  ('size', 'MediaQuery.sizeOf(context)'),
  ('padding', 'MediaQuery.paddingOf(context)'),
  ('viewInsets', 'MediaQuery.viewInsetsOf(context)'),
  ('viewPadding', 'MediaQuery.viewPaddingOf(context)'),
  ('textScaler', 'MediaQuery.textScalerOf(context)'),
  ('devicePixelRatio', 'MediaQuery.devicePixelRatioOf(context)'),
  ('platformBrightness', 'MediaQuery.platformBrightnessOf(context)'),
  ('orientation', 'MediaQuery.orientationOf(context)'),
  ('gestureSettings', 'MediaQuery.gestureSettingsOf(context)'),
  ('displayFeatures', 'MediaQuery.displayFeaturesOf(context)'),
  ('alwaysUse24HourFormat', 'MediaQuery.alwaysUse24HourFormatOf(context)'),
  ('accessibleNavigation', 'MediaQuery.accessibleNavigationOf(context)'),
  ('boldText', 'MediaQuery.boldTextOf(context)'),
  ('disableAnimations', 'MediaQuery.disableAnimationsOf(context)'),
  ('highContrast', 'MediaQuery.highContrastOf(context)'),
  ('invertColors', 'MediaQuery.invertColorsOf(context)'),
];

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PreferMediaQueryPartialMethodsTest);
  });
}

@reflectiveTest
class PreferMediaQueryPartialMethodsTest extends AnalysisRuleTest {
  @override
  void setUp() {
    newPackage('flutter').addFile('lib/widgets.dart', _flutterWidgetsStub);
    rule = PreferMediaQueryPartialMethods();
    super.setUp();
  }

  Future<void> test_reportsEverySupportedPropertyMapping() async {
    final accesses = [
      for (final (property, _) in _replacements)
        'MediaQuery.of(context).$property',
    ];
    final source =
        '''
import 'package:flutter/widgets.dart';

void readMediaQuery(BuildContext context) {
${accesses.map((access) => '  $access;').join('\n')}
}
''';

    await assertDiagnostics(source, [
      for (final (index, replacement) in _replacements.indexed)
        lint(
          source.indexOf(accesses[index]),
          accesses[index].length,
          messageContainsAll: [_exact(_message)],
          correctionContains: _exact('Use ${replacement.$2} instead.'),
        ),
    ]);
  }

  Future<void> test_acceptsArbitraryArgumentExpression() async {
    const source = '''
import 'package:flutter/widgets.dart';

void readMediaQuery(
  BuildContext first,
  BuildContext second,
  bool condition,
) {
  MediaQuery.of(condition ? first : second).size;
}
''';
    const access = 'MediaQuery.of(condition ? first : second).size';

    await assertDiagnostics(source, [
      lint(
        source.indexOf(access),
        access.length,
        messageContainsAll: [_exact(_message)],
        correctionContains: _exact('Use MediaQuery.sizeOf(context) instead.'),
      ),
    ]);
  }

  Future<void> test_ignoresNonFlutterMediaQueryData() async {
    await assertNoDiagnostics('''
class MediaQueryData {
  Object get size => Object();
}

class MediaQuery {
  static MediaQueryData of(Object context) => MediaQueryData();
}

void readMediaQuery(Object context) {
  MediaQuery.of(context).size;
}
''');
  }

  Future<void> test_ignoresUnsupportedQualifiedAndDedicatedAccessors() async {
    await assertNoDiagnostics('''
import 'package:flutter/widgets.dart' as widgets;

void readMediaQuery(widgets.BuildContext context) {
  widgets.MediaQuery.of(context).size;
  widgets.MediaQuery.of(context).navigationMode;
  widgets.MediaQuery.of(context).copyWith();
  widgets.MediaQuery.sizeOf(context);
}
''');
  }
}

RegExp _exact(String value) => RegExp('^${RegExp.escape(value)}\$');

const _flutterWidgetsStub = '''
class BuildContext {}

class MediaQueryData {
  Object get size => Object();
  Object get padding => Object();
  Object get viewInsets => Object();
  Object get viewPadding => Object();
  Object get textScaler => Object();
  Object get devicePixelRatio => Object();
  Object get platformBrightness => Object();
  Object get orientation => Object();
  Object get gestureSettings => Object();
  Object get displayFeatures => Object();
  Object get alwaysUse24HourFormat => Object();
  Object get accessibleNavigation => Object();
  Object get boldText => Object();
  Object get disableAnimations => Object();
  Object get highContrast => Object();
  Object get invertColors => Object();
  Object get navigationMode => Object();
  MediaQueryData copyWith() => this;
}

class MediaQuery {
  static MediaQueryData of(Object context) => MediaQueryData();
  static Object sizeOf(Object context) => Object();
}
''';
