// 📦 Package imports:
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/rules/avoid_widget_operator_equals.dart';
import 'package:flutter_best_practices_lints/src/rules/matching_class_and_file_name.dart';
import 'package:flutter_best_practices_lints/src/rules/prefer_media_query_partial_methods.dart';
import 'package:flutter_best_practices_lints/src/rules/prefer_widget_class_over_widget_helper.dart';
import 'package:flutter_best_practices_lints/src/rules/single_class_per_file.dart';

/// Registers the Flutter best-practice analysis rules.
class FlutterBestPracticesPlugin extends Plugin {
  @override
  String get name => 'flutter_best_practices_lints';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerLintRule(SingleClassPerFile())
      ..registerLintRule(MatchingClassAndFileName())
      ..registerLintRule(PreferWidgetClassOverWidgetHelper())
      ..registerLintRule(AvoidWidgetOperatorEquals())
      ..registerLintRule(PreferMediaQueryPartialMethods());
  }
}
