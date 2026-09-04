# Official Analyzer Plugin Migration Specification

<!-- cspell:ignore codesigning dogfood Dongmin namespaced pubspec pubspecs rroussel staticElement -->

**Status:** Blocked by Phase 0
**Date:** 2026-09-03
**Account scope:** Personal repository owned by `AndrewDongminYoo`
**Packages:** `flutter_best_practices_lints`, `go_router_linter`
**Migration type:** Breaking host migration with rule-behavior compatibility

## 1. Summary

This specification moves both lint packages from the archived `custom_lint` host to Dart's official `analysis_server_plugin` system.
The migration keeps the package names, diagnostic names, detection behavior except for the package `lib/` boundary correction in Section 10.2, and independent release cadence.
The migration replaces the plugin entrypoint, rule base classes, consumer configuration, and test harness.
The migration preserves the current `INFO` severity of all ten diagnostics.
The official host disables lint rules until a consumer enables them, so the migration cannot preserve legacy default activation.
The migration does not add lint rules, fixes, assists, or rule-specific options.

The work starts with one representative rule in `flutter_best_practices_lints`.
The first spike must prove that the official host works through `dart analyze`, `flutter analyze`, and one IDE on the supported Flutter stable versions.
The project must not publish a migrated package if those host checks fail.
The 2026-09-04 local Phase 0 run failed because Flutter `3.47.2` omitted a diagnostic that `dart analyze` reported from the same Candidate A plugin.
The [Phase 0 evidence](../notes/2026-09-03-analysis-server-plugin-migration-evidence.md) records the exact commands, versions, timings, negative control, and stop decision.
It also records that the planned side-by-side dependency transition cannot resolve inside the current single-resolution Dart workspace.

## 2. Decision

The project will use `analysis_server_plugin` as the only plugin host in each migrated release.
The project will not fork `custom_lint`.
The project will not maintain a dual-host adapter.
The project will not merge the two lint packages.
The project will not replace analyzer integration with a custom command-line tool.

The project will migrate and release `flutter_best_practices_lints` first.
The project will migrate and release `go_router_linter` only after the first package satisfies all release gates.
The legacy package versions will remain available for consumers that cannot move to the official host.

This decision implements the recommendation accepted in ledger record L2.

## 3. Source Basis

### 3.1 Official direction

Dart added the official analyzer plugin system in Dart 3.10 and Flutter 3.38.
The system supports IDE diagnostics, `dart analyze`, and `flutter analyze` according to the [Dart analyzer plugin guide](https://dart.dev/tools/analyzer-plugins).

The official system requires a top-level `plugins:` section in the package or workspace root `analysis_options.yaml`.
It does not load plugin configuration from a nested analysis options file according to the [official plugin usage guide](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/using_plugins.md).

The legacy plugin documentation says that the legacy system will be deprecated in a future release.
The [Dart diagnostic index](https://dart.dev/tools/diagnostics) describes legacy plugins as deprecated and scheduled for removal.
The exact removal release is `[UNCERTAIN]` because the two official pages use different lifecycle wording.
The migration must not depend on a predicted removal date.

The `custom_lint` repository was archived on 2026-03-24 and recommends `analysis_server_plugin` as the replacement.
This state is visible in the [`custom_lint` repository](https://github.com/invertase/dart_custom_lint).

### 3.2 Official API constraints

An official plugin package must provide `lib/main.dart`.
That file must expose a top-level variable named `plugin` whose value extends `Plugin`.
The plugin registers rules through `PluginRegistry` as described in the [official plugin authoring guide](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_a_plugin.md).

Each lint rule must extend `AnalysisRule` or `MultiAnalysisRule`.
Each rule must register a `SimpleAstVisitor` through `RuleVisitorRegistry` as described in the [official rule authoring guide](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_rules.md).

Each diagnostic code must have stable identity.
The preferred implementation is one `static const LintCode` per semantic diagnostic code.
Dynamic text must use diagnostic message arguments instead of creating a new `LintCode` for each report.
`MultiAnalysisRule` is permitted only when one rule reports multiple semantically distinct diagnostic codes.

The official host creates a synthetic package for all enabled plugins and resolves that package with `dart pub upgrade`.
This resolution separates plugin dependencies from the consumer's main package graph, but all enabled plugins must still resolve together.
The `analysis_server_plugin` and `analyzer` versions must move with the Dart SDK compatibility range.

### 3.3 Known upstream risks

The official documentation promises `flutter analyze` support.
However, Flutter issue [#187999](https://github.com/flutter/flutter/issues/187999) is an open and confirmed report that Flutter 3.44.1 omitted official plugin diagnostics that `dart analyze` reported.
This conflict makes a real `flutter analyze` check a release gate rather than a documentation assumption.

Dart issue [#63538](https://github.com/dart-lang/sdk/issues/63538) is an open report of intermittent analysis-server hangs with some `analysis_server_plugin` and `analyzer` combinations.
The report does not establish that every current combination fails.
The integration harness must apply a timeout and must run more than once on each supported CI platform.

Dart issue [#63787](https://github.com/dart-lang/sdk/issues/63787) reports that the language server can signal analysis completion before plugin diagnostics arrive.
This timing explains why a one-shot client can omit diagnostics even when the language server later publishes them.

Dart issue [#63813](https://github.com/dart-lang/sdk/issues/63813) is an open report of intermittent macOS Apple Silicon crashes while a fresh plugin AOT artifact is compiled and loaded.
The integration matrix must include a cold plugin start and warm repeated starts.
The integration harness must not delete or replace the operator's global plugin cache.

Dart issue [#63098](https://github.com/dart-lang/sdk/issues/63098) tracks the absence of arbitrary rule-specific configuration in the official host.
The current rules do not consume rule-specific options, so this limitation does not block this migration.
Adding configurable thresholds or patterns remains out of scope.

## 4. Current Baseline

The baseline records in this section reflect the repository on 2026-09-03 after the dependency constraint edits identified in ledger record L3 were restored.

| Item                           | Current value                                                                      |
| ------------------------------ | ---------------------------------------------------------------------------------- |
| Local Flutter                  | `3.47.2` stable                                                                    |
| Local Dart                     | `3.13.2` stable                                                                    |
| Lockfile Dart range            | `>=3.12.0 <4.0.0`                                                                  |
| Lockfile Flutter floor         | `>=3.44.0`                                                                         |
| `flutter_best_practices_lints` | `0.5.0`                                                                            |
| `go_router_linter`             | `0.4.0`                                                                            |
| Direct analyzer constraint     | `^8.4.0`                                                                           |
| Legacy host constraint         | `custom_lint_builder: ^0.8.1`                                                      |
| Consumer host                  | `custom_lint: ^0.8.1`                                                              |
| Rule count                     | Five rules in each package                                                         |
| Existing unit seam             | Real `AnalysisContextCollection`, `ResolvedUnitResult`, and `DartLintRule.testRun` |
| Existing integration seam      | Two Flutter example packages with intentional lint cases                           |
| Existing CI                    | Flutter stable, serialized `melos run analyze`, and `melos run test:ci`            |
| Current example `go_router`    | `^17.2.3`                                                                          |
| Phase 3 fixture `go_router`    | `17.5.0`                                                                           |

### 4.1 Current consumer configuration

Consumers currently add the lint package and `custom_lint` as development dependencies.
They enable the legacy host under `analyzer.plugins` and configure rules under `custom_lint.rules`.

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - prefer_media_query_partial_methods
```

### 4.2 Current public API impact

Both packages export their rule classes.
Both packages also export a legacy `createPlugin()` entrypoint.
`flutter_best_practices_lints` exports `FlutterBestPracticesPlugin`.
Both packages export `LintCodeCopyWithExtension`.

The official host does not use `createPlugin()`.
The dynamic `LintCode.copyWith` pattern conflicts with the stable diagnostic identity requirement.
The migrated release will therefore remove `createPlugin()` and `LintCodeCopyWithExtension` as documented breaking changes.
Rule class names and zero-argument constructors must remain stable unless an official API requirement makes one impossible.

### 4.3 Current and target diagnostic behavior

All ten current rules inherit `LintRule.enabledByDefault == true` from `custom_lint`.
All ten current rules use the default `LintCode` severity because no rule sets `errorSeverity`.
That default severity is `INFO`.

The official host treats a registered lint rule as disabled until the consumer enables it under `plugins.<package>.diagnostics`.
The migration therefore preserves diagnostic severity but changes default activation.

| Package                        | Rule                                          | Legacy activation  | Legacy severity | Target activation        | Target severity |
| ------------------------------ | --------------------------------------------- | ------------------ | --------------- | ------------------------ | --------------- |
| `flutter_best_practices_lints` | `single_class_per_file`                       | Enabled by default | `INFO`          | Explicit consumer opt-in | `INFO`          |
| `flutter_best_practices_lints` | `matching_class_and_file_name`                | Enabled by default | `INFO`          | Explicit consumer opt-in | `INFO`          |
| `flutter_best_practices_lints` | `prefer_widget_class_over_widget_helper`      | Enabled by default | `INFO`          | Explicit consumer opt-in | `INFO`          |
| `flutter_best_practices_lints` | `avoid_widget_operator_equals`                | Enabled by default | `INFO`          | Explicit consumer opt-in | `INFO`          |
| `flutter_best_practices_lints` | `prefer_media_query_partial_methods`          | Enabled by default | `INFO`          | Explicit consumer opt-in | `INFO`          |
| `go_router_linter`             | `missing_go_route_name_property`              | Enabled by default | `INFO`          | Explicit consumer opt-in | `INFO`          |
| `go_router_linter`             | `use_context_directly_for_go_router`          | Enabled by default | `INFO`          | Explicit consumer opt-in | `INFO`          |
| `go_router_linter`             | `avoid_hardcoded_routes`                      | Enabled by default | `INFO`          | Explicit consumer opt-in | `INFO`          |
| `go_router_linter`             | `avoid_navigator_named_routes_with_go_router` | Enabled by default | `INFO`          | Explicit consumer opt-in | `INFO`          |
| `go_router_linter`             | `missing_go_router_error_handler`             | Enabled by default | `INFO`          | Explicit consumer opt-in | `INFO`          |

The earlier `Lint Rules v2 Design` described `missing_go_router_error_handler` as a warning.
The implementation did not apply that severity.
This specification preserves the implemented `INFO` severity and supersedes that unimplemented warning requirement.

## 5. Problem Statement

The packages currently depend on an archived plugin host whose compatibility surface includes analyzer internals.
Each analyzer major can require source changes in the rule implementation and the host package.
The archived host no longer provides a maintained path for those changes.

Moving to the official host reduces host ownership risk and follows the supported Dart integration path.
It does not remove analyzer version churn.
The repository therefore needs both a host migration and a narrow support policy.

The migration also changes the consumer-facing `analysis_options.yaml` schema.
The project must treat that configuration change as a breaking release even when every diagnostic keeps the same name and behavior.

## 6. Goals

- G-001: Replace `custom_lint_builder` with the official `analysis_server_plugin` host in both packages.
- G-002: Preserve all ten diagnostic names.
- G-003: Preserve the positive and negative behavior of every existing rule except for the package `lib/` boundary correction in Section 10.2.
- G-004: Preserve the implemented `INFO` severity of all ten diagnostics.
- G-005: Preserve package names and independent package versioning.
- G-006: Verify diagnostics through real `dart analyze` and `flutter analyze` consumer processes.
- G-007: Verify one IDE analysis-server session after a required server restart.
- G-008: Define an explicit Flutter, Dart, `analysis_server_plugin`, and `analyzer` compatibility contract.
- G-009: Publish clear consumer migration instructions and breaking-change notes.
- G-010: Keep the implementation small enough to migrate one package at a time.
- G-011: Document and verify the breaking change from legacy default activation to explicit consumer opt-in.

## 7. Non-Goals

- NG-001: Do not add, remove, rename, or redesign lint rules except for the package `lib/` boundary correction in Section 10.2.
- NG-002: Do not add quick fixes or assists.
- NG-003: Do not add arbitrary rule-specific configuration.
- NG-004: Do not merge the packages or create a shared runtime package.
- NG-005: Do not fork or vendor `custom_lint`.
- NG-006: Do not support legacy and official hosts in the same package version.
- NG-007: Do not upgrade unrelated dependencies during the migration.
- NG-008: Do not hand-edit generated API documentation.
- NG-009: Do not promise beta, dev, or master Flutter channel support.
- NG-010: Do not publish a package as part of implementation without separate external-impact approval.
- NG-011: Do not activate an unpublished local plugin from the committed workspace-root analysis options file.

## 8. Consumer Contract

### 8.1 Hosted package configuration

The README for `flutter_best_practices_lints` must show this target configuration for version `0.6.0`.

```yaml
plugins:
  flutter_best_practices_lints:
    version: ^0.6.0
    diagnostics:
      matching_class_and_file_name: true
      single_class_per_file: true
      prefer_widget_class_over_widget_helper: true
      avoid_widget_operator_equals: true
      prefer_media_query_partial_methods: true
```

The README for `go_router_linter` must show this target configuration for version `0.5.0`.

```yaml
plugins:
  go_router_linter:
    version: ^0.5.0
    diagnostics:
      missing_go_route_name_property: true
      use_context_directly_for_go_router: true
      avoid_hardcoded_routes: true
      avoid_navigator_named_routes_with_go_router: true
      missing_go_router_error_handler: true
```

Hosted mode applies only after the selected package version is published.
The hosted fixture must declare a `version`, must not declare a plugin `path`, and must use a dedicated temporary `PUB_CACHE`.
The fixture must first test this contract without adding the plugin package to the consumer's `dev_dependencies`.
If a supported SDK requires a development dependency in practice, the implementation must record the failing output and add only the minimum documented requirement to both hosted and local fixture modes.

### 8.2 Local development configuration

The integration harness must generate an absolute path because the official guide documents absolute local plugin paths.
The harness must not commit a machine-specific path.
Local mode is the required pre-publication verification mode.
It must declare a plugin `path`, must not declare a plugin `version`, and must first resolve without adding the plugin package to the consumer's `dev_dependencies`.

```yaml
plugins:
  flutter_best_practices_lints:
    path: /absolute/path/to/packages/flutter_best_practices_lints
    diagnostics:
      prefer_media_query_partial_methods: true
```

### 8.3 Workspace placement

The `plugins:` block must live in the package or pub-workspace root analysis options file.
Nested example analysis options files are documentation fixtures and cannot be the only activation proof.
The integration harness must create a standalone temporary consumer whose `analysis_options.yaml` is at its root.

The example packages are inner packages in the current pub workspace.
Their committed analysis options files must remove the legacy plugin block and must not add a replacement `plugins:` block because the official system rejects plugin declarations in inner analysis options files.
The examples remain illustrative source packages, while the standalone integration harness becomes the activation proof.

The examples must remove `custom_lint` from `dev_dependencies`.
They must retain a path development dependency on the package under test only if the fresh consumer experiment proves that the official host requires it.
They must remove `expect_lint` comments because those comments belong to the legacy test convention.

### 8.4 Suppression contract

Consumers must use the plugin-qualified diagnostic name in ignore comments.

```dart
// ignore: flutter_best_practices_lints/prefer_media_query_partial_methods
final size = MediaQuery.of(context).size;
```

Each package must include at least one integration test that proves a qualified ignore suppresses the matching diagnostic and does not suppress another diagnostic.

### 8.5 Severity contract

All ten migrated rules must remain lint rules.
All ten rules must retain `INFO` severity.
They must remain disabled until a consumer enables them under the plugin's `diagnostics:` map.
This explicit opt-in requirement is a breaking activation change from the legacy host, where all ten rules are enabled by default.
The migration must not convert `missing_go_router_error_handler` or another rule into a warning.
The migration documentation must list every diagnostic that a consumer must enable.
An integration fixture with no `diagnostics:` entry for a registered rule must prove that the rule is not reported.

## 9. Plugin Architecture

### 9.1 Entrypoint

Each package must add `lib/main.dart`.
The file must define a top-level final variable named `plugin`.
The value must be an instance of a package-specific class that extends `Plugin`.

For `flutter_best_practices_lints`, `plugin` must be an instance of the public `FlutterBestPracticesPlugin` class.
For `go_router_linter`, the package-specific plugin class may remain private because the current public library exports only `createPlugin()` from its legacy entrypoint.

The plugin class must register the package's five rule factories through `PluginRegistry`.
The registration order should match the current order unless the official API imposes a different order.

### 9.2 Rule structure

Each rule must use one rule class and one focused `SimpleAstVisitor` by default.
The rule class owns the diagnostic code, description, and registry calls.
The visitor owns AST inspection and diagnostic reporting.

The implementation must register only the node types that each rule needs.
It must not use a whole-unit recursive visitor when a specific `RuleVisitorRegistry` callback provides the same coverage.

### 9.3 Diagnostic identity and dynamic messages

`matching_class_and_file_name`, `prefer_media_query_partial_methods`, and `use_context_directly_for_go_router` currently create modified `LintCode` objects at report time.
The migrated implementations must replace that pattern with static diagnostic templates and report-time arguments.

The implementation should use one `AnalysisRule` when all reports express the same semantic violation.
The implementation may use `MultiAnalysisRule` only if static templates cannot preserve materially different problem statements without changing their meaning.

Tests must assert the final problem and correction text for each dynamic-message branch.
Tests must also prove that qualified ignore comments work for those branches.

### 9.4 Public exports

The package libraries must continue to export all ten rule classes.
`flutter_best_practices_lints` must continue to export `ClassDeclarationExtension`, and `go_router_linter` must continue to export `RouteMethodExtension`.
`flutter_best_practices_lints` must continue to export a public class named `FlutterBestPracticesPlugin`.
That class must become the official `Plugin` subclass used by `lib/main.dart`; the implementation must not add a legacy compatibility wrapper.
The migration must remove the legacy `createPlugin()` exports.
The migration must remove `LintCodeCopyWithExtension` and its exports because the extension creates non-canonical diagnostic instances.

The changelog must list these removals under a breaking-change heading.
It must also state that `FlutterBestPracticesPlugin` changes superclass and member surface from the legacy `PluginBase` and `getLintRules` API to the official `Plugin` registration API.
The changelog must explain that normal plugin consumers do not call these APIs directly.

### 9.5 No shared migration framework

The two packages may use similar plugin entrypoints and test fixtures.
The implementation must not create a shared package or generic rule base during the first migration.
The project may consider extraction only after both migrations expose repeated code that has the same inputs, outputs, and lifecycle.

## 10. Rule Migration Inventory

| Package                        | Rule                                          | Required migration behavior                                                                                                                                                                                                                                                                                                                                                                                              | Migration risk          |
| ------------------------------ | --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ----------------------- |
| `flutter_best_practices_lints` | `single_class_per_file`                       | Register compilation-unit processing. Preserve public-class counting, one report on each public class after the first, and the exception for exactly two public classes when one is abstract and the other directly extends or implements it. Apply only the intentional package `lib/` boundary correction in Section 10.2.                                                                                             | Medium                  |
| `flutter_best_practices_lints` | `matching_class_and_file_name`                | Obtain the defining file through supported rule-context or AST source APIs. Preserve inclusion of private classes except the current private Flutter `State` exclusion, single-class handling, primary-class selection, and related-class checks for direct extends, implements, or generic use in those clauses. Preserve every current problem and correction branch. Apply only the Section 10.2 boundary correction. | High                    |
| `flutter_best_practices_lints` | `prefer_widget_class_over_widget_helper`      | Register function and method declarations directly. Preserve the syntactic test for a private `_build...` name and a `NamedType` whose final name is exactly `Widget`, including the exclusion of methods named `build`. Do not add Flutter library identity as part of this migration.                                                                                                                                  | Medium                  |
| `flutter_best_practices_lints` | `avoid_widget_operator_equals`                | Register the required declaration processors through the official registry. Preserve the boundary of classes that directly extend `Widget`, `StatelessWidget`, or `StatefulWidget` from a `package:flutter/` library. Do not broaden detection to indirect subclasses.                                                                                                                                                   | Medium                  |
| `flutter_best_practices_lints` | `prefer_media_query_partial_methods`          | Preserve the current property allowlist, the syntactic `MediaQuery.of` target, and the `MediaQueryData` element and Flutter library identity check. Do not add an argument-name or argument-count requirement. Replace dynamic correction codes with one static template and replacement arguments.                                                                                                                      | High and selected spike |
| `go_router_linter`             | `missing_go_route_name_property`              | Register `InstanceCreationExpression` directly. Remove the detached `getResolvedUnitResult()` future and manual recursive traversal. Preserve the current static-type element-name check for `GoRoute` and the presence check for a named `name` argument. Do not add a go_router library-identity requirement in this migration.                                                                                        | Medium                  |
| `go_router_linter`             | `use_context_directly_for_go_router`          | Preserve the exact syntactic `GoRouter.of(<simple identifier>).<route method>` shape and the route-method allowlist. Replace dynamic correction codes with one static template and context and method arguments. Do not add semantic type or library checks in this migration.                                                                                                                                           | High                    |
| `go_router_linter`             | `avoid_hardcoded_routes`                      | Register method invocations and instance creations through the official registry. Preserve the current route-method allowlists, `GoRouter` element-name check, exact `context` target shortcut, supported constructor names and named arguments, redirect-body traversal, and string-literal boundaries. Do not add library-identity checks in this migration.                                                           | Medium                  |
| `go_router_linter`             | `avoid_navigator_named_routes_with_go_router` | Preserve the exact named-Navigator-method allowlist, the syntactic `Navigator` target or `NavigatorState` element-name target without library identity, and activation when the owning package declares `go_router` in dependencies or development dependencies. Read that pubspec through `RuleContext.package`. Add `pubspec_parse` only if no equivalent supported parsed data exists.                                | High                    |
| `go_router_linter`             | `missing_go_router_error_handler`             | Register `InstanceCreationExpression` and preserve the static-type element-name check for `GoRouter` and the presence check for `errorBuilder` or `errorPageBuilder`. Do not add a go_router library-identity requirement. Keep the diagnostic opt-in with `INFO` severity.                                                                                                                                              | Low                     |

### 10.1 Package dependency detection

`avoid_navigator_named_routes_with_go_router` must inspect the pubspec that belongs to the source package under analysis.
It must not inspect the plugin's synthetic package or assume that the analyzer process working directory is the consumer root.

The preferred implementation uses `RuleContext.package.root` to locate the owning `pubspec.yaml`.
It parses that file with `pubspec_parse` if no supported parsed dependency API is available in the selected analyzer version.
If `pubspec_parse` becomes a runtime dependency, the package manifest and lockfile must change in the same commit.

Any cache must use the package root and pubspec modification stamp as its key.
The cache must not share one package's dependency result with another package in the same analysis-server process.
The first correct implementation may omit caching if measured fixture performance remains acceptable.

### 10.2 Intentional package `lib/` boundary correction

The only approved rule-behavior correction is the source-boundary check used by `single_class_per_file` and `matching_class_and_file_name`.
The legacy implementation accepts any absolute path that contains a component named `lib`, including a test or tool file nested below an unrelated ancestor named `lib`.
The migrated implementation must use `RuleContext.isInLibDir` or an equivalent supported package-relative API so that only the analyzed package's top-level `lib/` tree is included.

Characterization tests must prove that a source file under the package's top-level `lib/` tree is included and a source file outside that tree is excluded even when an ancestor directory is named `lib`.
Any other difference from characterized behavior fails the migration gate.

## 11. Compatibility Policy

### 11.1 Compatibility unit

The project must treat the following versions as one compatibility unit:

1. Flutter stable version.
2. Bundled Dart SDK version.
3. `analysis_server_plugin` version range.
4. `analyzer` version range.
5. `analyzer_plugin` version range when the selected official package requires it.
6. Host operating system.
7. The exact `go_router` version used by Phase 3 and combined real-consumer fixtures.

The project must not widen one constraint without testing the complete unit.
The project must not use dependency overrides to claim compatibility.

### 11.2 Supported channels

The package changelog and README must name the oldest tested Flutter stable release and the current tested Flutter stable release.
The package must support only stable Flutter releases.
The project makes no compatibility promise for beta, dev, or master channels.

The initial compatibility probe must test a stable Flutter release whose Dart version satisfies the current lockfile floor and the current local Flutter stable release.
The exact oldest supported release remains a gate result rather than a guessed version.
If the older candidate fails, the minimum version must move to the oldest stable version that passes every host gate.

### 11.3 Constraint policy

Each package must use the narrowest practical analyzer family that passes the supported matrix.
The upper bound must exclude untested analyzer majors.
The lower bound must match the oldest supported Flutter and Dart combination.

When Flutter stable moves to a new analyzer family, maintenance follows this sequence:

1. Add the new stable version to CI.
2. Regenerate the lockfile with the repository's normal bootstrap command.
3. Run rule tests and real consumer tests.
4. Widen the constraint only after all tests pass.
5. Remove the previous minimum only through a documented breaking release when its dependency graph no longer resolves.

### 11.4 Host operating systems

The release matrix must cover macOS, Linux, and Windows for both the minimum-supported and current Flutter stable compatibility units.
Each operating-system lane must run the same local consumer contract before publication and the same hosted consumer contract after publication.
Each compatibility unit must use separate analyzer-command lanes for `dart analyze` and `flutter analyze` so both commands receive independent cold-start evidence.

The first integration run in each analyzer-command lane must start without a restored analyzer plugin AOT cache and is the cold run.
The next two runs must reuse the same temporary consumer and cache and are the warm runs.
Local workstation evidence counts as cold only when the harness proves that the relevant plugin AOT artifact did not exist before the run.
The harness must never delete or replace the operator's global plugin cache or alter its location to manufacture a cold start.

### 11.5 `go_router` consumer dependency

Phase 3 must pin one exact `go_router` version in the generated real-consumer fixture.
The initial migration fixture must use `17.5.0`, which is the version resolved from the existing example constraint `^17.2.3` in the current baseline.
The harness must verify and print that exact resolved version, and CI evidence must record it with the compatibility unit.
Changing the fixture version requires a specification update and the complete Phase 3 matrix.
Documentation may identify `17.5.0` as tested, but it must not imply support for a wider `go_router` range without additional matrix evidence.

## 12. Migration Phases

### 12.1 Phase 0: Host compatibility probe

Phase 0 changes no published package contract.
It contains a legacy characterization gate followed by an official-host spike.

#### 12.1.1 Legacy behavior characterization

Before replacing one package's host API, the implementation must execute that package's current `custom_lint` rules against committed fixtures.
Phase 0 characterizes the five `flutter_best_practices_lints` rules, and Phase 3 begins by characterizing the five `go_router_linter` rules.
Across both phases, every rule must have at least one positive case and one negative case.
The fixtures must record the diagnostic name, `INFO` severity, problem text, correction text when present, and exact source range for each behavior branch listed in Section 10.

Phase 0 must add missing rule-level behavior coverage for `single_class_per_file` and `matching_class_and_file_name`.
Phase 3 must add missing rule-level behavior coverage for `missing_go_route_name_property` before changing its implementation.
Plugin-registration tests do not count as rule characterization.
The boundary fixtures in Section 10.2 must record both the legacy result and the intentionally corrected target result.

The official-host tests must reuse the same source fixtures and expected results except for the approved `lib/` boundary correction.
A rule branch without characterization blocks that rule's migration.

#### 12.1.2 Official-host spike

The spike uses `prefer_media_query_partial_methods` and the local consumer mode.
It may be throwaway or branch-local until the selected API and host combination passes the complete matrix.

The spike must answer these questions:

- Can the selected official package set resolve on the candidate minimum and current stable Flutter versions?
- Can a local absolute-path plugin load in a standalone consumer?
- Does `dart analyze` report the expected raw diagnostic code, `INFO` severity, problem text, file, line, and column?
- Does `flutter analyze` report the same diagnostic?
- Does an IDE report the same diagnostic after an analysis-server restart?
- Does a qualified ignore suppress the diagnostic?
- Can a static diagnostic template preserve the dynamic replacement text?
- Does omitting the rule from `diagnostics:` keep it disabled?
- Do one cold start and two warm starts complete within the integration timeout on macOS, Linux, and Windows?

If `flutter analyze` omits the diagnostic on any supported version, Phase 0 fails.
If either analyzer command fails on any required host operating system, Phase 0 fails.
The project may keep the spike for investigation, but it must not publish the migrated package.

### 12.2 Phase 1: `flutter_best_practices_lints`

Phase 1 migrates all five Flutter rules after Phase 0 passes.
The target release is `0.6.0` because the consumer configuration and exported host APIs change.

Phase 1 must update the following concerns:

- Package manifest and workspace lockfile.
- Official `lib/main.dart` entrypoint.
- Plugin registration.
- The preserved public `FlutterBestPracticesPlugin` export with its documented official-host API shape.
- Five rule implementations.
- Rule unit tests.
- Real consumer integration harness.
- Example configuration and intentional diagnostic comments.
- Package README and library-level documentation.
- Package changelog.
- Generated API documentation through the generator, if generated API documentation remains tracked.

Phase 1 must not modify `go_router_linter` source behavior.

### 12.3 Phase 2: First package release gate

The project must complete every local-mode CI gate, package validation, and documentation gate before requesting publication approval.
Publication is a separate external-impact action.

After publication approval and publication, the hosted-mode matrix must use a fresh temporary consumer with `version: 0.6.0`.
The verification must not use a path dependency or a pre-existing pub cache as the only evidence.
The hosted verification must use a dedicated temporary `PUB_CACHE` so the test proves package retrieval and resolution.
The verification must confirm the published package through both package metadata and analyzer output.

If the published artifact fails, the project must not delete or rewrite history.
The project must prepare a corrective patch or use the distribution channel's supported retraction mechanism after separate approval.

### 12.4 Phase 3: `go_router_linter`

Phase 3 starts only after the first package passes its published-consumer verification.
The target release is `0.5.0`.

Phase 3 repeats the Phase 1 and Phase 2 gates for the five go_router rules.
It begins with the package-scoped legacy characterization required by Section 12.1.1.
It adds explicit coverage for package-level pubspec dependency detection.
Its real consumer must pin `go_router: 17.5.0` and verify that exact resolution.
It also adds local and hosted consumer fixtures that enable both lint plugins together so the synthetic plugin graph is tested as a set.
The hosted go_router verification must select the exact published plugin version `0.5.0`.

## 13. Testing Strategy

### 13.1 Rule-level tests

Rule-level tests must use the official `analyzer_testing` package and `AnalysisRuleTest` where the selected version supports the required Flutter and pubspec seams.
The [official testing guide](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/testing_rules.md) defines `assertDiagnostics`, `assertNoDiagnostics`, and test package stubs as the preferred seam.

Tests must use resolved elements for rules that depend on type or library identity.
Tests must not replace semantic elements with mocks.
Flutter and go_router test stubs must expose only the APIs needed by each rule.
The real consumer layer must cover the actual Flutter and go_router packages.

Each existing positive and negative test case must survive the migration.
Each rule must also satisfy the complete pre-migration characterization gate in Section 12.1.1.
Each characterized behavior branch must retain its exact source-range assertion.
Dynamic-message branches must assert exact problem and correction text.
The two path-sensitive rules must assert the intentional boundary correction in Section 10.2 and no other behavior change.

### 13.2 Consumer integration harness

The repository must add one root Dart script named `tool/verify_analyzer_plugins.dart`.
The script may use only Dart SDK libraries unless an existing dependency is required for YAML generation or process control.
It must accept `--plugin flutter_best_practices_lints`, `--plugin go_router_linter`, or `--plugin all`.
It must accept `--source local` or `--source hosted`, `--repeat`, and `--timeout-seconds`.
It must accept `--analyzer dart`, `--analyzer flutter`, or `--analyzer all`.
The default analyzer selector must be `all`.
Hosted mode must require one repeatable `--package-version <package>=<exact-version>` argument for every selected plugin, while local mode must reject that argument.

Local mode must generate absolute plugin paths and must not add plugin versions.
Hosted mode must generate exact plugin versions, must not add plugin paths, and must create a dedicated temporary `PUB_CACHE`.
Both modes must first resolve without plugin package development dependencies.
If Phase 0 proves that a supported SDK requires those dependencies, both modes must apply the documented minimum requirement and retain the original failing evidence.

For each selected package, the script must:

1. Create one unique consumer root under the operating system temporary directory and reuse it for all repetitions in that invocation.
2. Write a minimal Flutter package and a root `analysis_options.yaml` for the selected source mode.
3. Write separate violating, compliant, disabled-rule, and qualified-ignore fixtures.
4. Give the qualified-ignore fixture a second enabled violation so it proves that the ignore suppresses only its target.
5. Run Flutter dependency resolution and verify the resolved plugin source or version before analysis.
6. Run `dart analyze --fatal-infos --fatal-warnings .` with the selected timeout.
7. Run `flutter analyze --fatal-infos --fatal-warnings .` with the selected timeout.
8. Parse each tool's complete human-readable diagnostic record with a tool-specific parser.
9. Assert the raw rule code, `INFO` severity, exact problem text, file, line, and column for each expected violation.
10. Assert that neither parser requires a plugin-qualified code in display output.
11. Assert a nonzero analyzer exit for the violating case and a zero exit for the compliant and disabled-rule cases.
12. Assert that a qualified ignore removes only its matching diagnostic and leaves the second diagnostic and nonzero exit intact.
13. Verify `go_router` resolves to `17.5.0` in Phase 3 and combined fixtures.
14. Terminate and await every subprocess before removing the temporary consumer and dedicated cache directories in a `finally` block.

Each scenario must run in isolation by replacing the generated source and analysis options before its analyzer subprocess starts.
One scenario's diagnostics must not contribute to another scenario's exit-code assertion.
The violating scenario must be the first analyzer subprocess in each repetition so the cold and warm records compare the same positive case.
The `all` analyzer selector is a local convenience and cannot supply independent cold evidence for the command that runs second.
Release evidence must invoke the `dart` and `flutter` selectors in separate fresh CI lanes.

The script must print the command, source mode, host operating system, SDK versions, plugin source or exact version, exact `go_router` version when present, exit code, elapsed time, and complete captured standard output and error for each failed subprocess.
It must not treat an empty or truncated output stream as success.
It must classify an expected diagnostic exit separately from dependency-resolution failure, plugin-load failure, parser failure, crash, and timeout.

The script must support one package selector so the two package migrations remain independent.
After both packages migrate, it must support a combined selector that enables both plugins in one consumer root.

### 13.3 Negative control

Before the first passing integration result is accepted, the implementer must prove that the integration harness can fail.
The implementer must run the harness once with an intentionally nonexistent expected diagnostic code or with the triggering expression removed from the generated fixture.
The recorded output must show the expected "diagnostic not found" failure.
The implementer must restore the normal expectation before recording the passing result.

This negative-control mutation must remain outside committed product files.

### 13.4 Repetition and timeout

The host integration check must run three consecutive times for each analyzer command on macOS, Linux, and Windows for each supported compatibility unit before release.
The first run must be classified as cold and the next two runs as warm under Section 11.4.
These three runs are required evidence, not retries.

Initial Phase 0 probes must use a hard ceiling of 600 seconds for each analyzer subprocess.
After all candidate compatibility units have one successful cold probe, the committed default timeout must be the greater of 120 seconds or three times the slowest successful cold-probe duration, rounded up to the next whole second and capped at 600 seconds.
A probe that does not complete within 600 seconds fails that compatibility unit.
The harness may accept an explicit lower timeout for the negative control, but release evidence must use the committed default.

A timeout, crash, or missing diagnostic fails the gate.
An automatic retry must not convert an initial crash or timeout into a passing result.

On timeout, the harness must terminate the complete subprocess tree with the platform-appropriate process-group or job-tree mechanism.
It must allow at most ten seconds for graceful termination, force termination when needed, await the root process and every recorded descendant, and drain both output streams.
The invocation fails if a recorded process remains or a stream does not close.

The existing serialized `melos run analyze` behavior must remain during the migration.
Parallel analyzer execution may be considered only after a separate repeated-run experiment proves that it is stable.

### 13.5 IDE smoke test

The release candidate must be opened in one supported Dart or Flutter IDE integration.
The operator must restart the Dart Analysis Server after changing the `plugins:` section.
The operator must confirm that the selected positive fixture displays the raw rule code when the IDE exposes a code, the exact problem text, and the expected source range.
The operator must confirm that the negative and disabled-rule fixtures do not report that diagnostic and that a plugin-qualified ignore suppresses it.
The IDE check must observe the positive plugin diagnostic before it evaluates absence in another fixture and must not treat the first analysis-complete signal as sufficient evidence.
The evidence must record the IDE name and version, host operating system, Flutter and Dart versions, and plugin source or exact version.

The IDE smoke test is manual evidence.
It does not replace either command-line check.

## 14. Verification Commands

The implementation must expose these repository-level commands after the required script exists.

```bash
melos bootstrap
melos run format:ci
melos run analyze
melos run test:ci
dart run tool/verify_analyzer_plugins.dart --plugin flutter_best_practices_lints --source local --repeat 3
dart run tool/verify_analyzer_plugins.dart --plugin go_router_linter --source local --repeat 3
dart run tool/verify_analyzer_plugins.dart --plugin all --source local --repeat 3
dart run tool/verify_analyzer_plugins.dart --plugin flutter_best_practices_lints --source hosted --package-version flutter_best_practices_lints=0.6.0 --repeat 3
dart run tool/verify_analyzer_plugins.dart --plugin go_router_linter --source hosted --package-version go_router_linter=0.5.0 --repeat 3
dart run tool/verify_analyzer_plugins.dart --plugin all --source hosted --package-version flutter_best_practices_lints=0.6.0 --package-version go_router_linter=0.5.0 --repeat 3
```

Local commands are pre-publication gates.
Each hosted command is valid only after every selected exact version is published with separate approval.
The displayed commands use the default `--analyzer all` for local convenience.
CI and release evidence must run each applicable command once with `--analyzer dart` and once with `--analyzer flutter` in separate fresh lanes.
The script's committed `--timeout-seconds` default must be the value selected by Section 13.4.

The package release preparation must also run `dart doc` from the package directory when generated API documentation remains tracked.
The implementation must inspect the generated diff instead of editing `doc/api` manually.

## 15. CI Requirements

The main CI workflow must keep one current Flutter stable lane and add one pinned minimum-supported Flutter stable lane after Phase 0 identifies that version.
It must run those compatibility units on macOS, Linux, and Windows.
Each operating-system and SDK combination must have separate `dart analyze` and `flutter analyze` integration lanes.

Each compatibility lane must run dependency resolution, formatting verification, static analysis, unit tests, and the relevant consumer integration check.
The integration jobs must not run analyzer-plugin smoke tests concurrently on the same runner.
The first integration run in each command-specific lane must use an ephemeral runner with no restored analyzer plugin AOT cache, and the next two runs must reuse the same consumer and cache state.
CI must not restore an analyzer plugin AOT cache before the cold run.

The first package migration may run only its package selector.
The combined selector becomes mandatory after both packages migrate.

The CI job must preserve complete failure output as an artifact or inline log when an analyzer subprocess times out or crashes.
The job must report the host operating system and the Dart, Flutter, `analysis_server_plugin`, analyzer, and `analyzer_plugin` versions that it resolved.
Phase 3 and combined jobs must also report and assert `go_router 17.5.0`.

## 16. Documentation and Release Requirements

Each migrated package README must include these sections:

- Minimum supported Flutter and Dart versions.
- Tested analyzer and `analysis_server_plugin` family.
- Tested macOS, Linux, and Windows matrix.
- Exact tested `go_router` version for `go_router_linter`.
- Hosted `plugins:` configuration.
- Local development configuration with an absolute-path placeholder.
- Explicit diagnostics map for every rule.
- `INFO` severity and the breaking change from legacy default activation to explicit opt-in.
- Raw diagnostic codes in CLI and IDE output versus plugin-qualified codes in ignore comments.
- Plugin-qualified ignore syntax.
- Migration steps from `custom_lint`.
- A statement that rule-specific options are not supported.

Each changelog must include these facts:

- The release uses the official analyzer plugin host.
- The old `analyzer.plugins: custom_lint` configuration no longer works.
- The old `custom_lint.rules` configuration no longer works.
- `createPlugin()` is removed.
- `LintCodeCopyWithExtension` is removed.
- Diagnostic codes remain unchanged.
- All ten diagnostics retain `INFO` severity but change from legacy default activation to explicit opt-in.
- `FlutterBestPracticesPlugin` remains public but changes from the legacy `PluginBase` API to the official `Plugin` API.
- The minimum Flutter and Dart versions changed to the versions proved by CI.
- The tested host operating systems and exact tested `go_router` version.
- Older package versions remain the compatibility path for the legacy host.

The package description and README must not claim `flutter analyze` support until the real release gate passes.
The documentation must distinguish official platform promises from combinations that this repository has tested.

## 17. Rollback and Failure Policy

### 17.1 Before publication

If any host gate fails, the migration remains unpublished.
The legacy package line remains the supported release.
The project may keep a migration branch or draft pull request for later SDK validation.

The project must not add a compatibility shim that restores `custom_lint` in the new release.
The project must not lower the test standard to make the migration pass.

### 17.2 After publication

Publication requires explicit approval because it changes external state.
The project must verify the public package metadata and a fresh hosted consumer immediately after publication.

If the public artifact fails, the project must record the exact package version, SDK versions, and failing output.
The corrective action must be a new patch release or an approved distribution-channel retraction.
The project must not assume that a published version can be erased.

## 18. Acceptance Criteria

### 18.1 Architecture

- AC-001: Neither migrated package depends on `custom_lint`, `custom_lint_core`, or `custom_lint_builder` directly or transitively through project-owned code.
- AC-002: Each migrated package provides `lib/main.dart` with the official top-level `plugin` variable; existing rule-class and named helper-extension exports remain; and `flutter_best_practices_lints` continues to export `FlutterBestPracticesPlugin` as that official `Plugin` subclass.
- AC-003: Each package registers exactly its existing five diagnostic names at `INFO` severity, and an omitted `diagnostics:` entry leaves each rule disabled.
- AC-004: No dual-host adapter or shared migration framework is added.

### 18.2 Rule behavior

- AC-005: Every rule has a pre-migration positive characterization, and every characterized positive case preserves its diagnostic name, `INFO` severity, problem text, correction text when present, and exact range after migration except for the intentional boundary fixture in Section 10.2.
- AC-006: Every rule has a pre-migration negative characterization, and every characterized negative case remains free of that diagnostic.
- AC-007: The three dynamic-message rules use static diagnostic instances and preserve exact branch-specific problem and correction text.
- AC-008: Package and library identity checks use supported analyzer APIs, and only the two path-sensitive rules adopt the intentional package `lib/` boundary correction in Section 10.2.
- AC-009: `avoid_navigator_named_routes_with_go_router` activates only when the owning package declares `go_router` in dependencies or development dependencies.

### 18.3 Consumer behavior

- AC-010: A standalone consumer loads each unpublished package by an absolute local path before publication and each exact hosted version from a dedicated temporary `PUB_CACHE` after publication.
- AC-011: `dart analyze` reports the expected raw code, `INFO` severity, exact problem text, file, line, and column, with exit status enforced by `--fatal-infos`.
- AC-012: `flutter analyze` reports the same raw diagnostic fields on macOS, Linux, and Windows for every supported Flutter compatibility unit.
- AC-013: One recorded IDE session reports the raw rule code when exposed, exact problem text, and source range after an analysis-server restart.
- AC-014: Plugin-qualified ignore comments suppress only the targeted diagnostic, while a second enabled diagnostic remains visible.
- AC-015: Local and hosted combined consumers enable both packages, resolve one compatible synthetic plugin graph, and resolve exactly `go_router 17.5.0`.

### 18.4 Reliability

- AC-016: One cold run followed by two warm runs completes independently for `dart analyze` and `flutter analyze` on macOS, Linux, and Windows for each supported compatibility unit without a crash, timeout, or missing diagnostic.
- AC-017: Every subprocess uses the Phase 0 timeout formula, and timeout cleanup leaves no recorded child process or open output stream.
- AC-018: The integration harness's negative control fails with the expected message before its passing output is accepted.
- AC-019: Analyzer jobs remain serialized during the migration, and no automatic retry converts a failed evidence run into a pass.

### 18.5 Repository and release

- AC-020: Manifest changes and the regenerated lockfile are included together.
- AC-021: Format, analysis, unit-test, integration-test, and documentation-generation gates pass for the package being released.
- AC-022: README and changelog files contain the proven SDK and operating-system matrix, `INFO` severity, explicit-opt-in break, raw-versus-qualified diagnostic identity, exact tested `go_router` version, and public plugin API change.
- AC-023: Generated API documentation comes from `dart doc` rather than manual edits.
- AC-024: Publication and any retraction remain separately approved external actions.
- AC-025: Each published artifact passes its complete fresh hosted-consumer matrix before the next migration starts or the migration is declared complete.

## 19. Fixed Contracts and Evidence-Driven Values

The table distinguishes decisions fixed by this specification from values that Phase 0 must derive.
No row requires a new product decision unless its stated gate cannot pass.

| Setting                                                 | Fixed contract or default                                                                                     | Resolution gate                                            |
| ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| Rule activation                                         | Explicit consumer opt-in for every rule                                                                       | Disabled-rule consumer fixture                             |
| Diagnostic severity                                     | `INFO` for all ten rules                                                                                      | Characterization and analyzer-output assertions            |
| Displayed diagnostic identity                           | Raw rule code in CLI and IDE output; plugin-qualified code only for suppression                               | Tool-specific parsers, IDE smoke test, and ignore fixture  |
| Host operating systems                                  | macOS, Linux, and Windows                                                                                     | Complete Phase 0 and release matrices                      |
| Analyzer command isolation                              | Separate `dart analyze` and `flutter analyze` lanes                                                           | Independent cold-start evidence for both commands          |
| Repetition shape                                        | One cold run followed by two warm runs per analyzer command                                                   | Cache-state evidence and three-run output                  |
| Analyzer subprocess timeout                             | Greater of 120 seconds or three times the slowest successful cold probe, rounded up and capped at 600 seconds | Phase 0 timing records and timeout negative control        |
| Exact tested `go_router` version                        | `17.5.0`                                                                                                      | Phase 3 and combined consumer resolution output            |
| Oldest supported Flutter stable release                 | Oldest candidate that satisfies the current lockfile floor                                                    | Phase 0 matrix                                             |
| Exact `analysis_server_plugin` and analyzer constraints | Narrowest compatible family                                                                                   | Dependency resolution plus all test layers                 |
| Dynamic diagnostic representation                       | One `AnalysisRule` with static templates and arguments                                                        | Spike message and suppression tests                        |
| Pubspec access for the dependency-aware rule            | `RuleContext.package.root` plus `pubspec_parse` only when no supported parsed dependency API exists           | go_router unit and multi-package consumer tests            |
| Consumer development dependency                         | Not required by default                                                                                       | Local and hosted fresh-consumer resolution without it      |
| `flutter analyze` readiness                             | Required and unproven until tested                                                                            | Real consumer output on every supported compatibility unit |

## 20. Interview Ledger

| ID  | Status  | Resolved requirement or decision                                                                                                                                                            | Source                                                                       |
| --- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| L1  | Current | Investigate whether Flutter and analyzer changes make the current plugin host unsustainable, and use official documentation as the primary evidence.                                        | Operator request on 2026-09-03                                               |
| L2  | Current | Document the recommended migration to the official analyzer plugin system as a detailed specification.                                                                                      | Operator request on 2026-09-03 after reviewing the recommendation            |
| L3  | Current | Restore the five dependency constraint edits before documenting the migration baseline.                                                                                                     | Operator authorization on 2026-09-03                                         |
| L4  | Current | Treat the exact legacy removal release as unknown and do not use it as the migration trigger.                                                                                               | Official documentation conflict identified during the accepted investigation |
| L5  | Current | Apply all eight refinement findings for activation, severity, diagnostic identity, Windows, characterization, process reliability, public API, fixture modes, and exact go_router coverage. | Operator approval on 2026-09-03                                              |

## 21. Traceability

| Ledger record | Specification coverage        | Verification coverage                                                         |
| ------------- | ----------------------------- | ----------------------------------------------------------------------------- |
| L1            | Sections 3, 5, and 11         | AC-011 through AC-019                                                         |
| L2            | Sections 2 and 6 through 19   | AC-001 through AC-025                                                         |
| L3            | Section 4 and NG-007          | Clean diff for the five restored manifests                                    |
| L4            | Sections 3.1 and 19           | Phase 0 gates use observed compatibility rather than a predicted removal date |
| L5            | Sections 4.3 and 8 through 22 | AC-002 through AC-019, AC-022, and AC-025                                     |

## 22. Oracle Precedent

Both Oracle lookups used the personal `custom_linters` project scope.
The original drafting lookup used the current local wiki checkout because the Oracle MCP was unavailable and was therefore marked `[PARTIAL]`.

- The repository previously migrated away from the removed analyzer 8 `staticElement` API by using supported element-model paths.
  This precedent confirms that the migration should preserve semantic type and library checks through supported analyzer APIs rather than replacing analyzer integration.
  Source: [`analyzer-8-static-element-removal.md`](../../../llm-wiki-dongminyu/wiki/concepts/analyzer-8-static-element-removal.md) `[OUT_OF_SCOPE path: sibling repository]`.
- The repository uses real `AnalysisContextCollection` and `ResolvedUnitResult` objects instead of mocked analyzer hosts.
  This precedent requires real resolved elements at the rule-test seam and a real consumer process at the host seam.
  Source: [`dart-analyzer.md`](../../../llm-wiki-dongminyu/wiki/entities/dart-analyzer.md) `[OUT_OF_SCOPE path: sibling repository]`.
- The repository previously upgraded `analyzer` and `custom_lint_builder` as one compatibility unit.
  This precedent confirms the compatibility-unit policy in Section 11.
  Source: [`dart-analyzer.md`](../../../llm-wiki-dongminyu/wiki/entities/dart-analyzer.md) `[OUT_OF_SCOPE path: sibling repository]`.
- The existing changelog history does not consistently record migration scope, dates, and breaking consumer actions.
  This precedent adds the explicit changelog requirements in Section 16.
  Source: [`custom_linters--changelog.md`](../../../llm-wiki-dongminyu/wiki/sources/custom_linters--changelog.md) `[OUT_OF_SCOPE path: sibling repository]`.
- Direct precedent for choosing the official host over `custom_lint`: `[no precedent found]`.
- Direct precedent for a stable-SDK support lifetime: `[no precedent found]`.

The refinement lookup completed normally and searched specifically for breaking activation, diagnostic severity, public plugin-class compatibility, operating-system coverage, cold and warm cache behavior, and repeated analyzer starts.
It returned no candidate precedent pages for either topic.

- Breaking activation, severity, and public plugin-class compatibility: `[no precedent found]`.
  This specification therefore establishes the explicit opt-in, `INFO`, and `FlutterBestPracticesPlugin` contracts from current repository behavior and official-host constraints.
- Operating-system, cold and warm cache, and repetition policy: `[no precedent found]`.
  This specification therefore establishes the macOS, Linux, and Windows matrix and the one-cold-plus-two-warm gate as new project precedent based on the cited upstream failures.

## 23. References

- [Dart analyzer plugins](https://dart.dev/tools/analyzer-plugins)
- [Dart static analysis configuration](https://dart.dev/tools/analysis)
- [Official plugin usage guide](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/using_plugins.md)
- [Official plugin authoring guide](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_a_plugin.md)
- [Official rule authoring guide](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_rules.md)
- [Official rule testing guide](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/testing_rules.md)
- [`analysis_server_plugin` changelog](https://pub.dev/packages/analysis_server_plugin/changelog)
- [`analyzer` package documentation](https://pub.dev/packages/analyzer)
- [`custom_lint` archived repository](https://github.com/invertase/dart_custom_lint)
- [Flutter issue #187999](https://github.com/flutter/flutter/issues/187999)
- [Dart issue #63538](https://github.com/dart-lang/sdk/issues/63538)
- [Dart issue #63787](https://github.com/dart-lang/sdk/issues/63787)
- [Dart issue #63813](https://github.com/dart-lang/sdk/issues/63813)
- [Dart issue #63098](https://github.com/dart-lang/sdk/issues/63098)
- [Earlier Lint Rules v2 design](2026-05-23-lint-rules-v2-design.md)
- [Current Flutter plugin entrypoint](../../packages/flutter_best_practices_lints/lib/src/flutter_best_practices_plugin.dart)
- [Current go_router plugin entrypoint](../../packages/go_router_linter/lib/src/go_router_lint_plugin.dart)
- [Current Flutter rule implementations](../../packages/flutter_best_practices_lints/lib/src/rules)
- [Current go_router rule implementations](../../packages/go_router_linter/lib/src/rules)
- [Current Flutter rule test seam](../../packages/flutter_best_practices_lints/test/src/lint_test_utils.dart)
- [Current go_router rule test seam](../../packages/go_router_linter/test/src/lint_test_utils.dart)
