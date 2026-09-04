// 📦 Package imports:
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// {@template prefer_media_query_partial_methods}
/// Reports `MediaQuery.of(context).property` accesses that have a dedicated
/// static accessor (e.g. `MediaQuery.sizeOf(context)`).
///
/// The specific accessors subscribe only to the relevant slice of
/// `MediaQueryData`, preventing unnecessary widget rebuilds when other
/// fields change.
/// {@endtemplate}
class PreferMediaQueryPartialMethods extends AnalysisRule {
  /// {@macro prefer_media_query_partial_methods}
  PreferMediaQueryPartialMethods()
    : super(
        name: 'prefer_media_query_partial_methods',
        description: 'Prefers specific MediaQuery accessors.',
      );

  static const _code = LintCode(
    'prefer_media_query_partial_methods',
    'Use the specific MediaQuery accessor to avoid unnecessary rebuilds.',
    correctionMessage: 'Use {0} instead.',
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
  LintCode get diagnosticCode => _code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addPropertyAccess(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule);

  final PreferMediaQueryPartialMethods rule;

  @override
  void visitPropertyAccess(PropertyAccess node) {
    final target = node.target;
    if (target is! MethodInvocation || target.methodName.name != 'of') return;

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

    final replacement = PreferMediaQueryPartialMethods
        ._propertyToReplacement[node.propertyName.name];
    if (replacement == null) return;

    rule.reportAtNode(node, arguments: [replacement]);
  }
}
