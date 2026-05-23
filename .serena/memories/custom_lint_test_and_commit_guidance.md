# Custom lint test and commit guidance

For this repo, rule behavior tests should use the package-local `test/src/lint_test_utils.dart` pattern: write inline Dart source to a temporary `test/lint_test_*` file, resolve it with analyzer, then run `DartLintRule.testRun`. Under `flutter test`, do not rely on analyzer `resolveFile` default SDK detection; pass an explicit SDK path (`DART_HOME`, then `FLUTTER_ROOT/bin/cache/dart-sdk`) and reuse the `AnalysisContextCollection` per test isolate to avoid CI SDK-path failures and 30s timeouts.

Commit changes by package. Keep `packages/go_router_linter/**` and `packages/flutter_best_practices_lints/**` in separate conventional commits; put root docs/tooling changes in their own commit when they affect both packages.

Detailed repo guide: `docs/guides/custom-lint-tests-and-commits.md`.