/// {@template go_router_linter_package}
/// # go_router_linter
///
/// The `go_router_linter` package provides custom lint rules to improve code
/// quality and maintain consistency when using the `go_router` package in
/// Dart/Flutter projects.
///
/// ## Key Features
///
/// - **Avoid Hardcoded Routes** (`avoid_hardcoded_routes`):
///   Detects hardcoded route strings in `context.go()`, `context.push()` and
///   related methods,
///   as well as in `GoRoute` definitions. Encourages the use of constants or
///   enums.
///
/// - **Ensure `GoRoute` Includes a `name` Property**
///   (`missing_go_route_name_property`):
///   Ensures every `GoRoute` has a `name` property, improving readability and
///   maintainability.
///
/// - **Use `context.go()` Instead of `GoRouter.of(context).go()`**
///   (`use_context_directly_for_go_router`):
///   Suggests the more concise and idiomatic `context.go()` calls.
///
/// ## Structure
///
/// - **Extensions**:
///   - `lint_code_extension.dart`: Provides a `copyWith()` method for creating
///     modified copies of `LintCode` instances.
///   - `route_methods_extension.dart`: Adds a helper extension on `String`
///     to easily identify route-related methods
///     (`go`, `push`, `goNamed`, `pushNamed`, etc.).
///
/// - **Rules**:
///   - `avoid_hardcoded_routes.dart`: Checks for hardcoded route strings in
///     route methods and `GoRoute` definitions.
///   - `missing_go_route_name_property.dart`: Ensures `GoRoute` definitions
///     include a `name`.
///   - `use_context_directly_for_go_router.dart`: Advises using `context.go()`
///     instead of `GoRouter.of(context).go()`.
///
/// - **Plugin Entrypoint**:
///   - `go_router_linter.dart`: Defines the plugin and registers all available
///     lint rules.
///
/// ## Getting Started
///
/// To use these lint rules, add `go_router_linter` as a dev dependency and
/// configure it in your `analysis_options.yaml`:
///
/// ```yaml
/// analyzer:
///   plugins:
///     - custom_lint
///
/// custom_lint:
///   rules:
///     - missing_go_route_name_property
///     - use_context_directly_for_go_router
///     - avoid_hardcoded_routes
/// ```
/// {@endtemplate}
library go_router_linter;

export 'src/extensions/lint_code_extension.dart';
export 'src/extensions/route_methods_extension.dart';
export 'src/go_router_lint_plugin.dart' show createPlugin;
export 'src/rules/avoid_hardcoded_routes.dart';
export 'src/rules/missing_go_route_name_property.dart';
export 'src/rules/use_context_directly_for_go_router.dart';
