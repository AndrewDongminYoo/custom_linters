/// {@template flutter_best_practices_lints_package}
/// # flutter_best_practices_lints
///
/// The `flutter_best_practices_lints` package provides custom lint rules to
/// improve code quality and maintain consistency across Flutter projects.
///
/// ## Key Features
///
/// - **Single Class per File** (`single_class_per_file`):
///   Ensures that each file contains only one primary class declaration,
///   promoting better organization and maintainability.
///
/// - **Matching Class and File Name** (`matching_class_and_file_name`):
///   Ensures that the class name (in PascalCase) matches the file name
///   (in snake_case), improving project clarity and discoverability.
///
/// ## Structure
///
/// - **Extensions**:
///   - `class_declaration_extension.dart`: Provides helper getters to check
///     whether a class is private `State` or abstract.
///   - `lint_code_extension.dart`: Offers a `copyWith()` method to easily
///     create modified copies of `LintCode` instances.
///
/// - **Rules**:
///   - `matching_class_and_file_name.dart`: Checks if a class name matches
///     the file name and excludes classes like `State` or abstract classes.
///   - `single_class_per_file.dart`: Restricts each file to only one primary
///     class definition, ignoring private `State` classes.
///
/// - **Plugin Entrypoint**:
///   - `flutter_best_practices_plugin.dart`: Registers all the available
///     lint rules and integrates them into your project's static analysis.
///
/// ## Getting Started
///
/// To use these lint rules, add `flutter_best_practices_lints` as a dev
/// dependency in your `pubspec.yaml` and configure it in your
/// `analysis_options.yaml`:
///
/// ```yaml
/// analyzer:
///   plugins:
///     - custom_lint
///
/// custom_lint:
///   rules:
///     - matching_class_and_file_name
///     - single_class_per_file
/// ```
/// {@endtemplate}
library flutter_best_practices_lints;

// 🌎 Project exports:
export 'src/extensions/class_declaration_extension.dart';
export 'src/extensions/lint_code_extension.dart';
export 'src/flutter_best_practices_plugin.dart';
export 'src/rules/matching_class_and_file_name.dart';
export 'src/rules/single_class_per_file.dart';
