# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Dart/Flutter monorepo containing custom lint packages built on `custom_lint_builder`. It includes two main packages:

1. **go_router_linter**: Custom lint rules for the `go_router` package
   - Enforces `name` property in `GoRoute` definitions
   - Suggests using `context.go()` over `GoRouter.of(context).go()`
   - Detects hardcoded route strings

2. **flutter_best_practices_lints**: General Flutter best practice rules
   - Enforces single class per file
   - Ensures class names match file names (PascalCase ↔ snake_case)

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
- Import ordering:
  1. Dart/Flutter packages (commented with `// 🎯`)
  2. External packages (commented with `// 📦`)
  3. Project imports (commented with `// 🌎`)
- Prefer const constructors where possible
- Use template documentation (`/// {@template ...}`)

### Testing

Tests use the `custom_lint_builder` testing utilities. The typical pattern:

```dart
void main() {
  test('lint rule detects issue', () async {
    // Arrange: Define test code as string
    final code = '''
// test code here
''';

    // Act & Assert: Use custom_lint testing framework
    // (exact pattern varies by package)
  });
}
```

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
