# Lint Package Modernization Plan

## Summary

Update both packages with small, default-enabled rules that follow current official Flutter/go_router guidance without duplicating `flutter_lints`. Current baseline tests pass with `dart test` in both packages.

Use official docs as the source of truth: `go_router` current docs are at 17.2.3, include BuildContext helper APIs such as `go`, `goNamed`, `namedLocation`, `push`, `replace`, `canPop`, and `pop`, and document named/type-safe routing as first-class navigation patterns. Flutter docs already recommend `flutter_lints`, so this package should avoid reimplementing const/key/style rules. 

## Key Changes

- **go_router_linter**
  - Strengthen `use_context_directly_for_go_router` so it only reports real `GoRouter.of(context).<helper>()` calls and supports `namedLocation`, `canPop`, and `pop`; do not report unrelated `GoRouter.of(context)` property/method access.
  - Strengthen `avoid_hardcoded_routes` by splitting route APIs into location/name methods and reporting only the first route identifier argument. Add `namedLocation` and redirect callback return strings to the checked surface.
  - Add default-enabled `avoid_navigator_named_routes_with_go_router` to flag `Navigator.pushNamed`, `pushReplacementNamed`, `popAndPushNamed`, and restorable named-route variants when the analyzed project depends on `go_router`. Flutter docs discourage named routes for most apps, and go_router docs note Navigator-pushed pages are not deep-linkable page-backed routes. 

- **flutter_best_practices_lints**
  - Add default-enabled `prefer_widget_class_over_widget_helper` for private `Widget _build...(...)` helper functions/methods, excluding the actual `build` override. This follows Flutter’s guidance to prefer reusable `StatelessWidget`s over UI helper functions. 
  - Add default-enabled `avoid_widget_operator_equals` to flag `operator ==` overrides inside Flutter `Widget`, `StatelessWidget`, or `StatefulWidget` subclasses. Flutter performance docs call this a performance pitfall except for narrow leaf-widget cases, so v1 should keep the rule simple and conservative. 
  - Do not add duplicate rules for `const`, widget keys, child ordering, `SizedBox`, or standard analyzer style checks; those belong to `flutter_lints`/Dart lints. 

## Public Interfaces

- Export new rule classes from each package entrypoint.
- Register new rules in each `PluginBase.getLintRules`.
- Update README, package dartdoc comments, examples, and `analysis_options.yaml` snippets with the new lint codes.
- Update CHANGELOGs and bump minor versions only, without publishing:
  - `go_router_linter`: `0.2.0` -> `0.3.0`
  - `flutter_best_practices_lints`: `0.3.0` -> `0.4.0`

## Test Plan

- Add behavior tests using `DartLintRule.testAnalyzeAndRun` with temporary Dart files for each new/strengthened rule.
- Cover positive and negative cases:
  - `GoRouter.of(context).go(...)` reports; `GoRouter.of(context).routerDelegate` does not.
  - `context.namedLocation('route')`, `redirect: (...) => '/login'`, and `GoRoute(path/name: '...')` report under `avoid_hardcoded_routes`.
  - `Navigator.pushNamed` reports only when `go_router` is present in the simulated pubspec.
  - `_buildHeader()` returning `Widget` reports; `@override Widget build(...)` does not.
  - `operator ==` in a widget subclass reports; non-widget model classes do not.
- Verification commands:
  - `dart test` in `packages/go_router_linter`
  - `dart test` in `packages/flutter_best_practices_lints`
  - `dart analyze .` in both packages
  - `dart run custom_lint` in both example apps

## Assumptions

- New rules are default-enabled, per your choice and the existing package behavior.
- Scope stays surgical: no dependency upgrades, broad formatter churn, generated API docs refresh, or publishing step in this task.
- The implementation should prioritize low false-positive rules over broad “best practice” coverage.
