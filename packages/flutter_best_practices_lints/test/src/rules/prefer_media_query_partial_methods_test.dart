// 🌎 Project imports:
import 'package:flutter_best_practices_lints/flutter_best_practices_lints.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

import '../lint_test_utils.dart';

const _code = 'prefer_media_query_partial_methods';
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
  group('PreferMediaQueryPartialMethods', () {
    test('reports every supported MediaQuery property mapping', () async {
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
      final diagnostics = await analyzeLintRule(
        const PreferMediaQueryPartialMethods(),
        source,
      );

      expect(diagnostics, hasLength(_replacements.length));
      for (final (index, replacement) in _replacements.indexed) {
        final access = accesses[index];
        expectLintDiagnostic(
          diagnostics[index],
          code: _code,
          message: _message,
          correctionMessage: 'Use ${replacement.$2} instead.',
          offset: source.indexOf(access),
          length: access.length,
        );
      }
    });

    test('accepts an arbitrary MediaQuery.of argument expression', () async {
      const source = '''
import 'package:flutter/widgets.dart';

void readMediaQuery(BuildContext first, BuildContext second) {
  MediaQuery.of(first.mounted ? first : second).size;
}
''';
      const access = 'MediaQuery.of(first.mounted ? first : second).size';
      final diagnostics = await analyzeLintRule(
        const PreferMediaQueryPartialMethods(),
        source,
      );

      expect(diagnostics, hasLength(1));
      expectLintDiagnostic(
        diagnostics.single,
        code: _code,
        message: _message,
        correctionMessage: 'Use MediaQuery.sizeOf(context) instead.',
        offset: source.indexOf(access),
        length: access.length,
      );
    });

    test('ignores non-Flutter MediaQueryData', () async {
      final diagnostics = await analyzeLintRule(
        const PreferMediaQueryPartialMethods(),
        '''
class MediaQueryData {
  Object get size => Object();
}

class MediaQuery {
  static MediaQueryData of(Object context) => MediaQueryData();
}

void readMediaQuery(Object context) {
  MediaQuery.of(context).size;
}
''',
      );

      expect(diagnostics, isEmpty);
    });

    test('ignores unsupported, qualified, and dedicated accessors', () async {
      final diagnostics = await analyzeLintRule(
        const PreferMediaQueryPartialMethods(),
        '''
import 'package:flutter/widgets.dart' as widgets;

void readMediaQuery(widgets.BuildContext context) {
  widgets.MediaQuery.of(context).size;
  widgets.MediaQuery.of(context).navigationMode;
  widgets.MediaQuery.of(context).copyWith();
  widgets.MediaQuery.sizeOf(context);
}
''',
      );

      expect(diagnostics, isEmpty);
    });
  });
}
