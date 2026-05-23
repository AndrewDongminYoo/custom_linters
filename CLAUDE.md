# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Dart/Flutter monorepo containing custom lint packages built on `custom_lint_builder`. It includes two main packages:

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
# Bootstrap all packages (install dependencies, link workspaces)
melos bootstrap

# Run code generation across all packages
melos run generate

# Format all code
melos run format

# Check formatting in CI mode
melos run format:ci

# Analyze all packages
melos analyze

# Run all tests with randomized ordering
melos run test

# Run tests with coverage for CI
melos run test:ci
```

### Per-Package Development

```bash
# Navigate to a specific package
cd packages/go_router_linter
# or
cd packages/flutter_best_practices_lints

# Standard Dart commands
dart pub get
dart analyze
dart test
dart format .
dart fix --apply
```

### Testing Individual Rules

To test a single lint rule, navigate to the package and run tests for that specific file:

```bash
cd packages/go_router_linter
dart test test/src/rules/use_context_directly_for_go_router_test.dart
```

## Architecture

### Custom Lint Plugin Pattern

Both packages follow the `custom_lint_builder` architecture:

1. **Plugin Entry Point**: Each package has a plugin class that implements `PluginBase`
   - `packages/go_router_linter/lib/src/go_router_lint_plugin.dart`
   - `packages/flutter_best_practices_lints/lib/src/flutter_best_practices_plugin.dart`

2. **Lint Rules**: Individual rules extend `DartLintRule` and are registered in the plugin
   - Located in `lib/src/rules/` directories
   - Each rule defines a `LintCode` with name, problem message, and optional correction message
   - Rules implement `run()` method which registers AST node visitors via `context.registry`

3. **Extensions**: Helper utilities for common operations
   - `lib/src/extensions/` contain reusable logic for lint rules
   - Examples: `LintCodeExtension` (copyWith), `RouteMethodsExtension`, `ClassDeclarationExtension`

### Typical Lint Rule Structure

```dart
class MyLintRule extends DartLintRule {
  const MyLintRule() : super(code: _code);

  static const _code = LintCode(
    name: 'my_lint_rule',
    problemMessage: 'Problem description',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    // Register AST visitor (e.g., addMethodInvocation, addClassDeclaration)
    context.registry.addSomeNode((node) {
      // Check condition
      if (/* violation detected */) {
        // Report diagnostic
        reporter.atNode(node, code);
      }
    });
  }
}
```

### Project Structure

- **Root `pubspec.yaml`**: Defines workspace packages and Melos scripts
- **`packages/*/lib/src/rules/`**: Individual lint rule implementations
- **`packages/*/lib/src/extensions/`**: Shared utility extensions
- **`packages/*/test/`**: Tests for rules and extensions
- **`packages/*/example/`**: Example Flutter apps demonstrating lint rules

## Development Workflow

### Adding a New Lint Rule

1. Create rule file in `packages/{package_name}/lib/src/rules/my_new_rule.dart`
2. Implement the `DartLintRule` class
3. Register the rule in the plugin's `getLintRules()` method
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
  1. External packages (commented with `// 📦 Package imports:`) — includes the package under test
  2. Project imports (commented with `// 🌎 Project imports:`) — e.g. `lint_test_utils.dart`
  3. Test-only packages (commented with `// 🧪 Test imports:`) — e.g. `package:test/test.dart`
- Prefer const constructors where possible
- Use template documentation (`/// {@template ...}`)

### Testing

Each package has a shared `test/src/lint_test_utils.dart` helper that drives all rule tests.

**How `analyzeLintRule` works:**

1. Creates a temporary directory under `test/` (`Directory('test').createTempSync('lint_test_')`)
2. Writes the test source string to `<tmpdir>/main.dart`
3. Resolves the file with the real Dart analyzer (`AnalysisContextCollection`)
4. Runs the rule via `rule.testRun(result)` — returns a list of `AnalysisError`s
5. Deletes the temp directory in a `finally` block (guaranteed cleanup)

The function returns `List<String>` of lint code names (e.g. `['prefer_media_query_partial_methods']`).

**Typical test pattern:**

```dart
// 📦 Package imports:
import 'package:my_lint_package/my_lint_package.dart';

// 🌎 Project imports:
import '../lint_test_utils.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

void main() {
  group('MyLintRule', () {
    test('reports the violation', () async {
      final errors = await analyzeLintRule(
        const MyLintRule(),
        '''
import 'package:flutter/widgets.dart';

// ... Dart source that should trigger the lint
''',
      );

      expect(errors, everyElement('my_lint_rule'));
      expect(errors, hasLength(1));
    });

    test('ignores compliant code', () async {
      final errors = await analyzeLintRule(
        const MyLintRule(),
        '''
// ... Dart source that should NOT trigger the lint
''',
      );

      expect(errors, isEmpty);
    });
  });
}
```

**`go_router_linter` only:** `analyzeLintRule` accepts an optional `pubspec` parameter of type `Pubspec` (from `package:pubspec_parse`). Rules that inspect project dependencies (e.g. `avoid_navigator_named_routes_with_go_router`) require a fake pubspec with `go_router` listed to activate.

```dart
import 'package:pubspec_parse/pubspec_parse.dart';

final errors = await analyzeLintRule(
  const AvoidNavigatorNamedRoutesWithGoRouter(),
  source,
  pubspec: Pubspec('test_app', dependencies: {'go_router': HostedDependency()}),
);
```

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

Root-level files (e.g. `CLAUDE.md`, `melos.yaml`) that affect both packages can be committed independently or grouped with whichever package change is most relevant.

## CI/CD

The `.github/workflows/main.yaml` pipeline runs:

1. Semantic PR validation (conventional commits)
2. Spell checking on markdown files
3. Format checking (`melos run format:ci`)
4. Analysis (`melos analyze`)
5. Tests with coverage (`melos run test:ci`)

## Notes

- This repository uses Dart SDK ^3.9.0
- Both packages depend on `analyzer: ^8.4.0` and `custom_lint_builder: ^0.8.1`
- The monorepo is managed via Dart's built-in workspace feature (not just Melos)
- Package versions are managed independently in each package's `pubspec.yaml`

### analyzer 8.x Compatibility

`SimpleIdentifier.staticElement` was **removed** in analyzer 8.x. Do not use it.

To verify that an identifier refers to a specific class from a specific library, use the **return type of the call** instead:

```dart
// ❌ Broken in analyzer 8.x
final classElement = methodTarget.staticElement;  // staticElement not defined
if (classElement is! ClassElement || classElement.name != 'MediaQuery') return;

// ✅ Correct: inspect the return type of the MethodInvocation
final returnElement = invocation.staticType?.element;
final libraryUri = returnElement?.library?.uri.toString();
if (returnElement?.name != 'MediaQueryData' ||
    libraryUri == null ||
    !libraryUri.startsWith('package:flutter/')) {
  return;
}
```

For `InstanceCreationExpression`, use `element?.library?.uri` on the constructor's static element (accessed via the element model of the creation expression itself, not via a `SimpleIdentifier`).
