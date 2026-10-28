# Custom Lint Tests and Commits

This guide documents the current official analyzer rule tests and the commit granularity expected in this monorepo.

## Analyzer Rule Tests

Rule tests extend `AnalysisRuleTest` from `analyzer_testing` and use reflective suites from `test_reflective_loader`.
Set the rule in `setUp()` before calling `super.setUp()`, then use `assertDiagnostics()` and `assertNoDiagnostics()` with inline Dart source.
Diagnostic expectations can check offsets, complete messages and correction text.

See `packages/go_router_linter/test/src/rules/avoid_navigator_named_routes_with_go_router_test.dart` for dependency-sensitive rules and `packages/flutter_best_practices_lints/test/src/rules/avoid_widget_operator_equals_test.dart` for synthetic Flutter types.

## Test and Consumer Boundaries

Run package tests through `dart run melos run test:ci` from the workspace root.
The removed temporary-file helper and its SDK-discovery workaround do not apply to the current official test architecture.
Package rule tests do not establish that the analyzer host discovers the plugin.
Run `dart test test/tool/analyzer_plugin_harness_test.dart` and the standalone consumer command from `CLAUDE.md` for that boundary.
The nested workspace examples intentionally omit plugin configuration.

## Pubspec-Dependent Rules

For rules that inspect package dependencies, create the test package's manifest through the analyzer test resource provider.
The `_writePubspec` helper in `avoid_navigator_named_routes_with_go_router_test.dart` creates that fixture, so tests can verify dependency, development-dependency and absent-dependency cases.

## Package-Level Commit Granularity

Keep commits grouped by package.

When a task touches both packages, commit them separately:

1. `packages/go_router_linter/**`
2. `packages/flutter_best_practices_lints/**`
3. Root docs/tooling changes, if any

Use conventional commit scopes that match the package:

```plaintext
feat(go-router-linter): add navigation API lint
feat(flutter-lints): add widget structure lint
docs(repo): document custom lint workflow
test(go-router-linter): stabilize analyzer rule tests
```

This keeps release notes, package version bumps, and review scope clear.
