# Custom Lint Tests and Commits

This guide documents the test helper pattern used by the custom lint packages
and the commit granularity expected in this monorepo.

## Temporary File Rule Tests

Use `test/src/lint_test_utils.dart` for rule behavior tests instead of wiring a
full example app for every case.

The shared `analyzeLintRule` helper should:

1. Create a temporary directory under `test/`.
2. Write the inline Dart source to `main.dart`.
3. Resolve the file with `AnalysisContextCollection`.
4. Run the lint with `DartLintRule.testRun`.
5. Delete the temporary directory in a `finally` block.

This keeps rule tests small while still exercising resolved analyzer behavior.

## Flutter Test SDK Handling

Do not call analyzer's `resolveFile` directly from these helpers.

Under `flutter test`, `Platform.resolvedExecutable` can point at Flutter's
engine Dart executable. Analyzer may then infer an invalid SDK path such as
`bin/cache/artifacts/engine`, which fails in CI with missing
`libraries.dart` or `engine/version` files.

Instead, create an `AnalysisContextCollection` with an explicit SDK path:

1. Prefer `DART_HOME` when present in CI.
2. Fall back to `FLUTTER_ROOT/bin/cache/dart-sdk`.
3. Fall back to `Platform.resolvedExecutable` only if it points to a valid SDK.

Also reuse the `AnalysisContextCollection` per test isolate. Creating a new
analysis context for every inline source can exceed the default 30-second test
timeout when `melos run test:ci` runs both packages in parallel.

## Pubspec-Dependent Rules

For rules that inspect package dependencies, pass a fake `Pubspec` into
`analyzeLintRule`.

Example: `go_router_linter` uses this for
`avoid_navigator_named_routes_with_go_router`, so tests can verify that
`Navigator.pushNamed` is reported only when `go_router` is present.

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
