# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Dart/Flutter monorepo containing official analyzer plugins built on `analysis_server_plugin`.
It includes two main packages:

1. **go_router_linter** (`packages/go_router_linter/`) — lint rules for the `go_router` package
   - `missing_go_route_name_property`: enforces `name` property in `GoRoute`
   - `use_context_directly_for_go_router`: prefers `context.go()` over `GoRouter.of(context).go()`
   - `avoid_hardcoded_routes`: bans hardcoded strings in navigation calls, `GoRoute` definitions, `redirect` returns, and `GoRouter(initialLocation:)`
   - `avoid_navigator_named_routes_with_go_router`: bans `Navigator.*Named` APIs when `go_router` is a dependency
   - `missing_go_router_error_handler`: requires `errorBuilder` or `errorPageBuilder` on every `GoRouter`

2. **flutter_best_practices_lints** (`packages/flutter_best_practices_lints/`) — general Flutter best-practice rules
   - `single_class_per_file`: one primary class per file (allows paired `State` classes)
   - `matching_class_and_file_name`: PascalCase class name must match snake_case file name
   - `prefer_widget_class_over_widget_helper`: bans private `Widget _build...` helper functions
   - `avoid_widget_operator_equals`: bans `operator ==` overrides on widget subclasses
   - `prefer_media_query_partial_methods`: prefers `MediaQuery.sizeOf(context)` and sibling accessors over `MediaQuery.of(context).size` (Flutter 3.10+)

## Essential Commands

### Monorepo Management (Melos)

```bash
# Install the locked Flutter workspace dependencies
flutter pub get --enforce-lockfile
dart run melos bootstrap

# Run code generation across all packages
dart run melos run generate

# Format only the Dart files changed by the task
dart format path/to/changed.dart

# Check formatting in CI mode
dart run melos run format:ci

# Analyze all packages
dart run melos run analyze
dart analyze .

# Run all tests with randomized ordering
dart run melos run test

# Run the declared CI tests
dart run melos run test:ci
dart test test/tool/analyzer_plugin_harness_test.dart

# Verify real plugin discovery in standalone consumers
dart run tool/verify_analyzer_plugins.dart --plugin all --source local --analyzer dart --repeat 3

# Run the independent offline secret-reader regression tests
python3 -B .trunk/configs/tests/test_trufflehog_to_sarif.py
```

### Per-Package Development

```bash
# Navigate to a specific package
cd packages/go_router_linter
# or
cd packages/flutter_best_practices_lints

# Standard Dart commands after workspace dependency installation
dart analyze
dart test
dart format path/to/changed.dart
```

### Testing Individual Rules

To test a single lint rule, navigate to the package and run tests for that specific file:

```bash
cd packages/go_router_linter
dart test test/src/rules/use_context_directly_for_go_router_test.dart
```

## Architecture

### Custom Lint Plugin Pattern

Both packages use the official analyzer plugin architecture:

1. **Plugin Entry Point**: Each package exports a top-level `plugin` from `lib/main.dart`.

- `packages/go_router_linter/lib/main.dart` creates its private `Plugin` subclass.
- `packages/flutter_best_practices_lints/lib/main.dart` creates `FlutterBestPracticesPlugin` from `lib/src/flutter_best_practices_plugin.dart`.

2. **Lint Rules**: Individual rules extend `AnalysisRule` and are registered with `PluginRegistry.registerLintRule()`.

- Rules live in `lib/src/rules/` and expose their `LintCode` through `diagnosticCode`.
- `registerNodeProcessors()` connects a `SimpleAstVisitor` through `RuleVisitorRegistry`.
- Visitors report diagnostics with `rule.reportAtNode()`.

3. **Extensions**: `lib/src/extensions/` contains helpers for route methods, class declarations and naming.

### Typical Lint Rule Structure

Use `packages/go_router_linter/lib/src/rules/missing_go_route_name_property.dart` as a concrete example of `AnalysisRule`, `LintCode`, `registerNodeProcessors()` and its visitor.
Preserve the package-qualified diagnostic names used by consumers and the standalone harness.

### Project Structure

- **Root `pubspec.yaml`**: Defines workspace packages and Melos scripts
- **`packages/*/lib/src/rules/`**: Individual lint rule implementations
- **`packages/*/lib/src/extensions/`**: Shared utility extensions
- **`packages/*/test/`**: Tests for rules and extensions
- **`packages/*/example/`**: Example Flutter apps demonstrating lint rules

## Development Workflow

### Adding a New Lint Rule

1. Create rule file in `packages/{package_name}/lib/src/rules/my_new_rule.dart`
2. Implement an `AnalysisRule` subclass and its diagnostic code
3. Register the rule in the plugin's `register()` method
4. Export the rule in `lib/src/rules.dart` if needed
5. Write tests in `packages/{package_name}/test/src/rules/my_new_rule_test.dart`
6. Update the package README with the new rule documentation

### Code Style

- Uses `very_good_analysis` for consistent code style
- Import ordering in **lib files**:
  1. Dart SDK imports (commented with `// 🐦 Dart imports:`)
  2. External packages (commented with `// 📦 Package imports:`)
  3. Project imports (commented with `// 🌎 Project imports:`)
- Import ordering in **test files**:
  1. Analyzer and test framework packages (commented with `// 📦 Package imports:`)
  2. The project's rule under test (commented with `// 🌎 Project imports:`)
- Prefer const constructors where possible
- Use template documentation (`/// {@template ...}`)

### Testing

Rule tests use `AnalysisRuleTest` from `analyzer_testing` and reflective suites from `test_reflective_loader`.
They set `rule` in `setUp()` and use `assertDiagnostics()` or `assertNoDiagnostics()` to check the rule.
Diagnostic expectations cover source offsets and messages where relevant.
See `packages/go_router_linter/test/src/rules/missing_go_route_name_property_test.dart` for the current pattern.

The root `test/tool/analyzer_plugin_harness_test.dart` tests fixture generation, output parsing, diagnostic matching and process cleanup.
`tool/verify_analyzer_plugins.dart` separately runs disposable consumers outside the workspace with top-level `plugins:` configuration.
It checks violating, compliant, disabled-rule and qualified-ignore scenarios and compares exact diagnostic code, severity, message, path, line and column.
An analyzer exit code alone does not establish that the plugin loaded.

Nested example packages intentionally omit `plugins:` because they are workspace members.
Do not enable plugins there to substitute for the standalone consumer gate.
The harness uses a fixed `go_router` consumer version independently of the workspace example dependency.

## Git Workflow

### Commit Granularity in This Monorepo

Each package is versioned and tagged independently. **Commits must be grouped per package** — do not mix changes from `flutter_best_practices_lints` and `go_router_linter` in a single commit.

When a session touches both packages, stage and commit them separately:

```bash
# 1. Commit flutter_best_practices_lints changes first
git add packages/flutter_best_practices_lints/
git commit -m "feat(flutter-lints): ..."

# 2. Then commit go_router_linter changes
git add packages/go_router_linter/
git commit -m "feat(go-router-linter): ..."
```

Root-level files (e.g. `CLAUDE.md`, `pubspec.yaml`) that affect both packages can be committed independently or grouped with whichever package change is most relevant.

## CI/CD

The `.github/workflows/main.yaml` pipeline runs:

1. Semantic PR validation (conventional commits)
2. Spell checking on Markdown files with the root `cspell.json`
3. Format checking (`dart run melos run format:ci` and the root harness paths)
4. Analysis (`dart run melos run analyze` and `dart analyze .`)
5. Tests (`dart run melos run test:ci` and the root harness unit tests)
6. Standalone Dart analyzer plugin checks with three repetitions

CI uses Flutter `3.47.8`, which includes Dart `3.13.7`.
The manual compatibility job runs the same SDK on macOS, Linux and Windows with both the Dart and Flutter analyzer commands.
Local Trunk uses CSpell `10.4.0` for Markdown and the root `cspell.json`, matching CI's configuration and file scope.
TruffleHog performs a filesystem scan with `--no-verification --no-update` and uses `.trunk/configs/trufflehog_to_sarif.py` to retain decoded findings without printing secret values.
CI runs the standalone Python reader tests before Flutter setup.

## Notes

- This repository requires Dart SDK `^3.13.7`
- Both packages depend on `analyzer: ^14.6.0` and `analysis_server_plugin: ^0.3.25`
- The monorepo is managed via Dart's built-in workspace feature (not just Melos)
- Package versions are managed independently in each package's `pubspec.yaml`

### Analyzer API Compatibility

Use the APIs from the currently resolved `analyzer` package and existing rule implementations.
After an analyzer or plugin dependency change, run the package rule tests and standalone consumer harness before declaring compatibility.
