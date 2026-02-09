# Codebase Structure

## Top Level

- `pubspec.yaml`: workspace definition and Melos scripts.
- `analysis_options.yaml`: shared analysis options (includes `very_good_analysis`).
- `README.md`: monorepo purpose and quick-start commands.
- `.github/workflows/main.yaml`: CI pipeline.
- `.trunk/trunk.yaml`: Trunk lint/check configuration.
- `packages/`: all lint packages and their examples.

## Package Layout (common)

Each lint package follows a similar structure:

- `lib/`
  - package entry file (`<package_name>.dart`)
  - `src/<plugin_file>.dart`: plugin registration (`PluginBase` implementation)
  - `src/rules/`: individual `DartLintRule` implementations
  - `src/extensions/`: helper extensions/utilities used by rules
- `test/`
  - package and extension tests
- `example/`
  - runnable Flutter app showing lint behavior
- `README.md`, `CHANGELOG.md`, `pubspec.yaml`

## Important Concrete Paths

- `packages/go_router_linter/lib/src/go_router_lint_plugin.dart`
- `packages/flutter_best_practices_lints/lib/src/flutter_best_practices_plugin.dart`
- `packages/go_router_linter/lib/src/rules/`
- `packages/flutter_best_practices_lints/lib/src/rules/`
- `packages/go_router_linter/test/`
- `packages/flutter_best_practices_lints/test/`

## Generated/Tooling Artifacts (seen in repo)

- `.dart_tool/` directories exist at root and package levels.
- `doc/api/` directories are present for package docs output.
