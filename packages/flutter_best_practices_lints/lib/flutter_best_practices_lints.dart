/// Analyzer diagnostics for Flutter project structure and widget usage.
///
/// The package registers five opt-in `INFO` diagnostics through Dart's official analyzer plugin host:
///
/// - `single_class_per_file`
/// - `matching_class_and_file_name`
/// - `prefer_widget_class_over_widget_helper`
/// - `avoid_widget_operator_equals`
/// - `prefer_media_query_partial_methods`
///
/// Add the package to the top-level `analysis_options.yaml` for the consuming package or pub workspace:
///
/// ```yaml
/// plugins:
///   flutter_best_practices_lints:
///     version: ^0.6.0
///     diagnostics:
///       matching_class_and_file_name: true
///       single_class_per_file: true
///       prefer_widget_class_over_widget_helper: true
///       avoid_widget_operator_equals: true
///       prefer_media_query_partial_methods: true
/// ```
library;

// 🌎 Project exports:
export 'src/extensions/class_declaration_extension.dart';
export 'src/flutter_best_practices_plugin.dart';
export 'src/rules/avoid_widget_operator_equals.dart';
export 'src/rules/matching_class_and_file_name.dart';
export 'src/rules/prefer_media_query_partial_methods.dart';
export 'src/rules/prefer_widget_class_over_widget_helper.dart';
export 'src/rules/single_class_per_file.dart';
