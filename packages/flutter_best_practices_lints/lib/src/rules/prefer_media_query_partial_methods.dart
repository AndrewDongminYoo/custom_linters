// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/extensions/lint_code_extension.dart';

/// {@template prefer_media_query_partial_methods}
/// Reports `MediaQuery.of(context).property` accesses that have a dedicated
/// static accessor (e.g. `MediaQuery.sizeOf(context)`).
///
/// The specific accessors subscribe only to the relevant slice of
/// `MediaQueryData`, preventing unnecessary widget rebuilds when other
/// fields change.
/// {@endtemplate}
class PreferMediaQueryPartialMethods extends DartLintRule {
  /// {@macro prefer_media_query_partial_methods}
  const PreferMediaQueryPartialMethods() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_media_query_partial_methods',
    problemMessage:
        'Use the specific MediaQuery accessor to avoid unnecessary rebuilds.',
  );

  static const _propertyToReplacement = {
    'size': 'MediaQuery.sizeOf(context)',
    'padding': 'MediaQuery.paddingOf(context)',
    'viewInsets': 'MediaQuery.viewInsetsOf(context)',
    'viewPadding': 'MediaQuery.viewPaddingOf(context)',
    'textScaler': 'MediaQuery.textScalerOf(context)',
    'devicePixelRatio': 'MediaQuery.devicePixelRatioOf(context)',
    'platformBrightness': 'MediaQuery.platformBrightnessOf(context)',
    'orientation': 'MediaQuery.orientationOf(context)',
    'gestureSettings': 'MediaQuery.gestureSettingsOf(context)',
    'displayFeatures': 'MediaQuery.displayFeaturesOf(context)',
    'alwaysUse24HourFormat': 'MediaQuery.alwaysUse24HourFormatOf(context)',
    'accessibleNavigation': 'MediaQuery.accessibleNavigationOf(context)',
    'boldText': 'MediaQuery.boldTextOf(context)',
    'disableAnimations': 'MediaQuery.disableAnimationsOf(context)',
    'highContrast': 'MediaQuery.highContrastOf(context)',
    'invertColors': 'MediaQuery.invertColorsOf(context)',
  };

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPropertyAccess((node) {
      final target = node.target;
      if (target is! MethodInvocation) return;
      if (target.methodName.name != 'of') return;

      final methodTarget = target.target;
      if (methodTarget is! Identifier || methodTarget.name != 'MediaQuery') {
        return;
      }

      final returnElement = target.staticType?.element;
      final libraryUri = returnElement?.library?.uri.toString();
      if (returnElement?.name != 'MediaQueryData' ||
          libraryUri == null ||
          !libraryUri.startsWith('package:flutter/')) {
        return;
      }

      final property = node.propertyName.name;
      final replacement = _propertyToReplacement[property];
      if (replacement == null) return;

      reporter.atNode(
        node,
        _code.copyWith(correctionMessage: 'Use $replacement instead.'),
      );
    });
  }
}
