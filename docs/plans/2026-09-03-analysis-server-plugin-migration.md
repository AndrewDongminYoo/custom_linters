# Official Analyzer Plugin Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

<!-- cspell:ignore Pubspec dartdoc dongminyu ests lockfiles oneline pathspec pgrep pubspec staticElement taskkill toplevel worktree worktrees -->

**Goal:** Migrate `flutter_best_practices_lints` and then `go_router_linter` from `custom_lint` to the official analyzer plugin host without changing characterized rule behavior, except for the approved package-relative `lib/` boundary correction.

**Architecture:** Use one official `Plugin` entrypoint and five independent `AnalysisRule` implementations in each package. Keep rule logic package-local. Verify the host through a root Dart harness that creates standalone consumers outside the workspace. Treat the Flutter package publication and fresh hosted-consumer result as a hard checkpoint before any go_router implementation work starts.

**Tech Stack:** Dart, Flutter, Melos, `analysis_server_plugin`, `analyzer`, `analyzer_testing`, `test_reflective_loader`, `test`, `pubspec_parse`, GitHub Actions on macOS, Linux, and Windows

**Spec:** [`docs/specs/2026-09-03-analysis-server-plugin-migration.md`](../specs/2026-09-03-analysis-server-plugin-migration.md)

## Execution Status

Phase 0 failed on 2026-09-04 because Flutter `3.47.2` reproduced issue #187999 while the equivalent `dart analyze` matrix passed.
Stop before Task 5 and use the recorded [Phase 0 evidence](../notes/2026-09-03-analysis-server-plugin-migration-evidence.md) before resuming this plan.
The evidence also proves that Task 3's production-package side-by-side dependency step cannot resolve in the current single-resolution Dart workspace and that its official `AnalysisRuleTest` must run with `dart test` instead of `flutter test`.
Treat the affected Task 3 steps as superseded until the dependency-consistent transition is refined and approved.

## Global Constraints

- Implement the Flutter package first.
- Do not change `go_router_linter` source behavior until `flutter_best_practices_lints 0.6.0` passes the complete fresh hosted-consumer matrix.
- Do not publish either package without separate approval immediately before the publication command.
- Treat a retraction as another separately approved external action.
- Keep workspace example packages free of a top-level `plugins:` section.
- Do not add a dual-host adapter to a release candidate.
- Do not add a shared rule base, shared plugin package, or generic migration framework.
- Keep `melos run analyze` serialized with `--concurrency=1`.
- Preserve raw diagnostic codes in analyzer and IDE output.
- Use plugin-qualified codes only in suppression comments.
- Keep every diagnostic at `INFO` severity and disabled until the consumer explicitly enables it.
- Preserve every public rule class and zero-argument constructor.
- Preserve `ClassDeclarationExtension`, `RouteMethodExtension`, and the public `FlutterBestPracticesPlugin` name.
- Remove `createPlugin()` and `LintCodeCopyWithExtension` in the breaking releases.
- Do not cache parsed pubspec data in the first `go_router_linter` implementation.
- Do not claim `flutter analyze` support or publish while [Flutter issue #187999](https://github.com/flutter/flutter/issues/187999) reproduces in a required compatibility lane.
- Do not use dependency overrides as compatibility evidence.
- Do not retry a failed cold or warm evidence run.
- Do not delete or rewrite a published version.

## Oracle Precedent Applied

- The supported analyzer element-model migration confirms the use of public `Element.library` and `LibraryElement.uri` APIs instead of removed analyzer APIs. Source: [`analyzer-8-static-element-removal.md`](../../../llm-wiki-dongminyu/wiki/concepts/analyzer-8-static-element-removal.md) `[OUT_OF_SCOPE path: sibling personal repository]`.
- The real analyzer test precedent confirms `AnalysisRuleTest` with resolved elements plus a real standalone consumer process. Source: [`dart-analyzer.md`](../../../llm-wiki-dongminyu/wiki/entities/dart-analyzer.md) `[OUT_OF_SCOPE path: sibling personal repository]`.
- The prior compatibility-unit precedent confirms that Flutter, Dart, analyzer, and plugin-host versions move through one tested matrix. Source: [`dart-analyzer.md`](../../../llm-wiki-dongminyu/wiki/entities/dart-analyzer.md) `[OUT_OF_SCOPE path: sibling personal repository]`.
- The changelog precedent confirms that each breaking release must state the removed host API and exact consumer migration. Source: [`custom_linters--changelog.md`](../../../llm-wiki-dongminyu/wiki/sources/custom_linters--changelog.md) `[OUT_OF_SCOPE path: sibling personal repository]`.
- Package-first publication gating followed by a second package migration: `[no precedent found]`.
- Legacy characterization followed by staged local and hosted consumer validation: `[no precedent found]`.

The planning Oracle lookup supplied no source pages for the last two topics and reported freshness as `UNVERIFIED`.
Treat those two execution patterns as new project precedent, not historical authority.

## Commit and Ownership Policy

The repository versions and tags the two packages independently.
Keep their implementation and release-history commits separate.

- A commit may touch `packages/flutter_best_practices_lints/**` and the root lockfile that its manifest change regenerates.
- A commit may touch `packages/go_router_linter/**` and the root lockfile that its manifest change regenerates.
- No commit may touch both package directories.
- Root harness, CI, and migration-evidence changes use separate repository-level commits.
- Stage explicit paths.
- Do not use `git add -A`, `git add .`, or `git commit -- <pathspec>`.
- Do not push the probe, implementation, release, or tag without explicit approval.

## Phase 0 Dependency Candidates

Start with candidate A because it is the current official package family identified during specification refinement.
The versions remain candidates until the complete matrix passes.

| Candidate | `analysis_server_plugin` | `analyzer`         | `analyzer_testing` | `test_reflective_loader` | Use condition                                                         |
| --------- | ------------------------ | ------------------ | ------------------ | ------------------------ | --------------------------------------------------------------------- |
| A         | `>=0.3.22 <0.4.0`        | `>=14.3.0 <15.0.0` | `^0.4.1`           | `^0.4.0`                 | Test first on Flutter `3.44.0` and `3.47.2`                           |
| B         | `>=0.3.20 <0.4.0`        | `>=14.1.0 <15.0.0` | `^0.3.4`           | `^0.4.0`                 | Test only if candidate A fails dependency resolution on the older SDK |

Use one candidate family in the package manifest and root lockfile.
Do not select different dependency families per operating system or Flutter lane.
If neither candidate resolves and passes on both Flutter versions, stop Phase 0 and update the specification with the observed incompatibility before changing the support floor or trying a third family.
If Flutter `3.44.0` resolves but fails a host gate while `3.47.2` passes, test stable Flutter releases between those versions in ascending order and record each result.
The oldest complete pass becomes the minimum supported stable release.

## Rule Registration Map

Use the narrowest official registry callback that preserves current behavior.

| Rule                                          | Registry callback                                         | Visitor node                                        | Required preservation                                                                                                        |
| --------------------------------------------- | --------------------------------------------------------- | --------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `single_class_per_file`                       | `addCompilationUnit`                                      | `CompilationUnit`                                   | Count public classes and report every public class after the first, with the direct abstract relationship exception          |
| `matching_class_and_file_name`                | `addCompilationUnit`                                      | `CompilationUnit`                                   | Preserve primary-class selection, private-class handling, private Flutter `State` exclusion, and direct related-class checks |
| `prefer_widget_class_over_widget_helper`      | `addFunctionDeclaration` and `addMethodDeclaration`       | `FunctionDeclaration` and `MethodDeclaration`       | Preserve the private `_build...` syntax check, final return-type name `Widget`, and `build` exclusion                        |
| `avoid_widget_operator_equals`                | `addClassDeclaration`                                     | `ClassDeclaration`                                  | Preserve direct Flutter `Widget`, `StatelessWidget`, and `StatefulWidget` checks without indirect-subclass expansion         |
| `prefer_media_query_partial_methods`          | `addPropertyAccess`                                       | `PropertyAccess`                                    | Preserve the allowlist, syntactic `MediaQuery.of` target, and Flutter `MediaQueryData` library identity                      |
| `missing_go_route_name_property`              | `addInstanceCreationExpression`                           | `InstanceCreationExpression`                        | Preserve the `GoRoute` element-name and named `name` argument checks                                                         |
| `use_context_directly_for_go_router`          | `addMethodInvocation`                                     | `MethodInvocation`                                  | Preserve the exact nested invocation shape and route-method allowlist                                                        |
| `avoid_hardcoded_routes`                      | `addMethodInvocation` and `addInstanceCreationExpression` | `MethodInvocation` and `InstanceCreationExpression` | Preserve method, constructor, named-argument, redirect-body, and string-literal boundaries                                   |
| `avoid_navigator_named_routes_with_go_router` | `addMethodInvocation`                                     | `MethodInvocation`                                  | Preserve the named-Navigator allowlist and activate only for an owning package that declares `go_router`                     |
| `missing_go_router_error_handler`             | `addInstanceCreationExpression`                           | `InstanceCreationExpression`                        | Preserve the `GoRouter` element-name and `errorBuilder` or `errorPageBuilder` presence check                                 |

## Static Diagnostic Templates

Every rule owns a `static const LintCode`.
Use report-time `arguments` for the three currently dynamic diagnostics.

| Rule                                 | Static template                                                                                                                                                  |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `matching_class_and_file_name`       | Problem: `Class name {0} {1} the file name "{2}".` Correction: `{3}`. Pass `must match` or `does not match` and the exact characterized correction as arguments. |
| `prefer_media_query_partial_methods` | Problem: `Use the specific MediaQuery accessor to avoid unnecessary rebuilds.` Correction: `Use {0} instead.`                                                    |
| `use_context_directly_for_go_router` | Problem: `Use GoRouterHelper extension.` Correction: `Use {0}.{1} instead of GoRouter.of({0}).{1}.`                                                              |

Use anchored regular expressions in `analyzer_testing` expectations when an API accepts only message patterns.
This makes a pattern check enforce the complete message instead of a substring.

## File Map

### Repository-level files

- Modify: `.gitignore`
- Modify: `pubspec.yaml`
- Track and regenerate: `pubspec.lock`
- Modify: `.github/workflows/main.yaml`
- Create: `tool/verify_analyzer_plugins.dart`
- Create: `tool/src/analyzer_plugin_harness.dart`
- Create: `test/tool/analyzer_plugin_harness_test.dart`
- Create: `test/tool/fixtures/hanging_process.dart`
- Create: `docs/notes/2026-09-03-analysis-server-plugin-migration-evidence.md`

### `flutter_best_practices_lints`

- Create: `packages/flutter_best_practices_lints/lib/main.dart`
- Create temporarily, then delete before the release candidate: `packages/flutter_best_practices_lints/lib/src/phase0/prefer_media_query_partial_methods_probe.dart`
- Create temporarily, then delete before the release candidate: `packages/flutter_best_practices_lints/test/src/phase0/prefer_media_query_partial_methods_probe_test.dart`
- Create: `packages/flutter_best_practices_lints/test/src/rules/single_class_per_file_test.dart`
- Create: `packages/flutter_best_practices_lints/test/src/rules/matching_class_and_file_name_test.dart`
- Modify: `packages/flutter_best_practices_lints/pubspec.yaml`
- Modify: `packages/flutter_best_practices_lints/lib/flutter_best_practices_lints.dart`
- Modify: `packages/flutter_best_practices_lints/lib/src/flutter_best_practices_plugin.dart`
- Modify: `packages/flutter_best_practices_lints/lib/src/rules/single_class_per_file.dart`
- Modify: `packages/flutter_best_practices_lints/lib/src/rules/matching_class_and_file_name.dart`
- Modify: `packages/flutter_best_practices_lints/lib/src/rules/prefer_widget_class_over_widget_helper.dart`
- Modify: `packages/flutter_best_practices_lints/lib/src/rules/avoid_widget_operator_equals.dart`
- Modify: `packages/flutter_best_practices_lints/lib/src/rules/prefer_media_query_partial_methods.dart`
- Modify: `packages/flutter_best_practices_lints/test/src/lint_test_utils.dart`
- Modify: `packages/flutter_best_practices_lints/test/src/flutter_best_practices_plugin_test.dart`
- Modify: `packages/flutter_best_practices_lints/test/src/rules/prefer_widget_class_over_widget_helper_test.dart`
- Modify: `packages/flutter_best_practices_lints/test/src/rules/avoid_widget_operator_equals_test.dart`
- Modify: `packages/flutter_best_practices_lints/test/src/rules/prefer_media_query_partial_methods_test.dart`
- Delete: `packages/flutter_best_practices_lints/lib/src/extensions/lint_code_extension.dart`
- Modify: `packages/flutter_best_practices_lints/README.md`
- Modify: `packages/flutter_best_practices_lints/CHANGELOG.md`
- Modify: `packages/flutter_best_practices_lints/example/README.md`
- Modify: `packages/flutter_best_practices_lints/example/analysis_options.yaml`
- Modify: `packages/flutter_best_practices_lints/example/lib/main.dart`
- Modify: `packages/flutter_best_practices_lints/example/pubspec.yaml`
- Regenerate: `packages/flutter_best_practices_lints/doc/api/**`

### `go_router_linter`

- Create: `packages/go_router_linter/lib/main.dart`
- Create: `packages/go_router_linter/test/src/rules/missing_go_route_name_property_test.dart`
- Modify: `packages/go_router_linter/pubspec.yaml`
- Modify: `packages/go_router_linter/lib/go_router_linter.dart`
- Delete: `packages/go_router_linter/lib/src/go_router_lint_plugin.dart`
- Modify: `packages/go_router_linter/lib/src/rules/missing_go_route_name_property.dart`
- Modify: `packages/go_router_linter/lib/src/rules/use_context_directly_for_go_router.dart`
- Modify: `packages/go_router_linter/lib/src/rules/avoid_hardcoded_routes.dart`
- Modify: `packages/go_router_linter/lib/src/rules/avoid_navigator_named_routes_with_go_router.dart`
- Modify: `packages/go_router_linter/lib/src/rules/missing_go_router_error_handler.dart`
- Modify: `packages/go_router_linter/test/src/lint_test_utils.dart`
- Modify: `packages/go_router_linter/test/src/go_router_lint_plugin_test.dart`
- Modify: `packages/go_router_linter/test/src/rules/use_context_directly_for_go_router_test.dart`
- Modify: `packages/go_router_linter/test/src/rules/avoid_hardcoded_routes_test.dart`
- Modify: `packages/go_router_linter/test/src/rules/avoid_navigator_named_routes_with_go_router_test.dart`
- Modify: `packages/go_router_linter/test/src/rules/missing_go_router_error_handler_test.dart`
- Delete: `packages/go_router_linter/lib/src/extensions/lint_code_extension.dart`
- Delete: `packages/go_router_linter/test/src/extensions/lint_code_extension_test.dart`
- Modify: `packages/go_router_linter/README.md`
- Modify: `packages/go_router_linter/CHANGELOG.md`
- Modify: `packages/go_router_linter/example/README.md`
- Modify: `packages/go_router_linter/example/analysis_options.yaml`
- Modify: `packages/go_router_linter/example/lib/main.dart`
- Modify: `packages/go_router_linter/example/pubspec.yaml`
- Regenerate: `packages/go_router_linter/doc/api/**`

---

## Task 0: Preserve the Planning Baseline and Start Isolated Work

**Files:**

- Verify: `docs/specs/2026-09-03-analysis-server-plugin-migration.md`
- Verify: `docs/plans/2026-09-03-analysis-server-plugin-migration.md`

- [ ] **Step 0.1: Re-read the repository and Git state**

```bash
git rev-parse --show-toplevel
git status --short
git log -5 --oneline
```

Expected repository root: `/Users/dongminyu/Development/01_personal/custom_linters`.
Stop if source or manifest edits appear before implementation starts.

- [ ] **Step 0.2: Verify the two planning artifacts before preserving them**

```bash
trunk check docs/specs/2026-09-03-analysis-server-plugin-migration.md docs/plans/2026-09-03-analysis-server-plugin-migration.md
rg -n 'T(BD)|TO(DO)|FIX(ME)|similar to T(ask)|add t(ests)' docs/plans/2026-09-03-analysis-server-plugin-migration.md
```

The placeholder scan must return no matches.

- [ ] **Step 0.3: Preserve the approved documents in one documentation commit when implementation is authorized**

```bash
git add docs/specs/2026-09-03-analysis-server-plugin-migration.md docs/plans/2026-09-03-analysis-server-plugin-migration.md
git diff --cached --check
git diff --cached --name-only
git commit -m "docs: specify analyzer plugin migration"
```

Do not include any other path.

- [ ] **Step 0.4: Create an isolated implementation worktree**

Use `superpowers:using-git-worktrees` before this step.
Re-read the current log and status before the worktree command.

```bash
git worktree add ../custom_linters-flutter-analysis-plugin -b feat/flutter-analysis-server-plugin
```

- [ ] **Step 0.5: Capture a clean baseline in the implementation worktree**

```bash
melos bootstrap
melos run format:ci
melos run analyze
melos run test:ci
```

Record failures before changing code.
Do not treat a pre-existing failure as migration success.

## Task 1: Characterize All Five Flutter Rules on the Legacy Host

**Files:**

- Modify: `packages/flutter_best_practices_lints/test/src/lint_test_utils.dart`
- Create: `packages/flutter_best_practices_lints/test/src/rules/single_class_per_file_test.dart`
- Create: `packages/flutter_best_practices_lints/test/src/rules/matching_class_and_file_name_test.dart`
- Modify: `packages/flutter_best_practices_lints/test/src/rules/prefer_widget_class_over_widget_helper_test.dart`
- Modify: `packages/flutter_best_practices_lints/test/src/rules/avoid_widget_operator_equals_test.dart`
- Modify: `packages/flutter_best_practices_lints/test/src/rules/prefer_media_query_partial_methods_test.dart`

- [ ] **Step 1.1: Make the legacy helper expose full diagnostics and configurable source placement**

Change `analyzeLintRule` to return `Future<List<AnalysisError>>` instead of diagnostic names.
Add a `relativePath` argument with the default `lib/main.dart`.
Create parent directories under the existing temporary root before writing the source.
Keep real `AnalysisContextCollection`, `ResolvedUnitResult`, and `DartLintRule.testRun` objects.

Assert these fields in every positive case:

- `diagnosticCode.name`
- `diagnosticCode.severity`
- `message`
- `correctionMessage`
- `offset`
- `length`

- [ ] **Step 1.2: Add complete characterization for `single_class_per_file`**

Cover one public class, private classes, two unrelated public classes, three public classes, direct `extends`, direct `implements`, the abstract-pair exception, and a non-direct relationship.
Assert one diagnostic for every public class after the first.
Add one file under the package-relative `lib/` shape and one file outside it under an unrelated ancestor directory named `lib`.
Record the legacy false positive for the ancestor case as the only expectation that will change later.

- [ ] **Step 1.3: Add complete characterization for `matching_class_and_file_name`**

Cover a matching single class, a mismatching single class, a matching primary class with unrelated extra classes, direct `extends`, direct `implements`, generic use in those clauses, no primary class, private classes, and the private Flutter `State` exclusion.
Assert each current message branch and correction branch exactly.
Add the same package-relative and unrelated-ancestor boundary pair used in Step 1.2.

- [ ] **Step 1.4: Strengthen the three existing rule test files**

For `prefer_widget_class_over_widget_helper`, preserve top-level functions, methods, the `_build...` prefix, the exact final return-type name `Widget`, the `build` exclusion, and non-matching return types.
For `avoid_widget_operator_equals`, preserve direct Flutter widget subclasses, non-Flutter types with the same names, indirect subclasses, and classes without `operator ==`.
For `prefer_media_query_partial_methods`, cover every current property-to-accessor mapping, the `MediaQuery.of` syntax boundary, an arbitrary argument expression, non-Flutter `MediaQueryData`, unsupported properties, and already-specific accessors.

- [ ] **Step 1.5: Prove that the new characterization assertions can fail**

Temporarily increase one expected diagnostic length by one.
Run the owning test and confirm that the failure identifies the range mismatch.
Restore the correct length and rerun the same test.

```bash
(cd packages/flutter_best_practices_lints && flutter test test/src/rules)
```

- [ ] **Step 1.6: Verify and commit only the Flutter characterization**

```bash
dart format packages/flutter_best_practices_lints/test/src/lint_test_utils.dart packages/flutter_best_practices_lints/test/src/rules
(cd packages/flutter_best_practices_lints && flutter test test)
git diff --check -- packages/flutter_best_practices_lints/test
git add packages/flutter_best_practices_lints/test/src/lint_test_utils.dart packages/flutter_best_practices_lints/test/src/rules
git diff --cached --name-only
git commit -m "test(flutter-lints): characterize legacy diagnostics"
```

## Task 2: Add the Standalone Consumer Harness

**Files:**

- Modify: `.gitignore`
- Modify: `pubspec.yaml`
- Track and regenerate: `pubspec.lock`
- Create: `tool/verify_analyzer_plugins.dart`
- Create: `tool/src/analyzer_plugin_harness.dart`
- Create: `test/tool/analyzer_plugin_harness_test.dart`
- Create: `test/tool/fixtures/hanging_process.dart`

- [ ] **Step 2.1: Make the workspace lockfile trackable**

Add `!/pubspec.lock` after the existing `pubspec.lock` ignore rule.
Do not unignore package-level lockfiles.
Add `test: ^1.31.1` to the root development dependencies so the root harness library has a package-local unit-test target.
Do not add an argument parser, YAML writer, or process-control dependency.

- [ ] **Step 2.2: Write failing option and fixture-generation tests**

Test all three plugin selectors, both source modes, all three analyzer selectors, positive repeat values, positive timeout values, and repeatable exact hosted versions.
Test an optional repeatable `--diagnostic <raw-code>` selector.
Default it to all five rules for one package and all ten rules for the combined selector.
Reject a raw code that does not belong to the selected plugin set.
Assert that hosted mode rejects missing versions.
Assert that local mode rejects versions.
Assert that hosted versions reject ranges such as `^0.6.0`.
Assert that generated local configuration contains absolute `path:` values and no `version:` values.
Assert that generated hosted configuration contains exact `version:` values and no `path:` values.
Assert that workspace examples are never used as generated consumer roots.

- [ ] **Step 2.3: Implement a thin CLI and a testable harness library**

Use these concrete types and responsibilities:

```dart
enum PluginSelector { flutterBestPracticesLints, goRouterLinter, all }

enum PluginSource { local, hosted }

enum AnalyzerSelector { dart, flutter, all }

enum ProcessFailureKind {
  dependencyResolution,
  pluginLoad,
  diagnosticMismatch,
  parser,
  crash,
  timeout,
}

final class HarnessOptions {
  const HarnessOptions({
    required this.plugin,
    required this.source,
    required this.analyzer,
    required this.repeat,
    required this.timeout,
    required this.packageVersions,
    required this.diagnostics,
    required this.negativeControl,
  });
}

final class DiagnosticRecord {
  const DiagnosticRecord({
    required this.code,
    required this.severity,
    required this.message,
    required this.path,
    required this.line,
    required this.column,
  });
}

HarnessOptions parseHarnessOptions(List<String> arguments);
List<DiagnosticRecord> parseDartAnalyzeOutput(String output);
List<DiagnosticRecord> parseFlutterAnalyzeOutput(String output);
```

Keep `tool/verify_analyzer_plugins.dart` limited to argument parsing, calling the library, mapping typed failures to a nonzero exit, and printing the final summary.
Keep consumer creation, dependency checks, process control, output parsing, and assertions in `tool/src/analyzer_plugin_harness.dart`.

- [ ] **Step 2.4: Generate four isolated scenarios per selected plugin set**

Use one unique operating-system temporary consumer root per harness invocation.
Reuse that consumer root for all repetitions in the invocation.
Replace source and `analysis_options.yaml` before each analyzer subprocess.
Generate these scenarios for the selected diagnostics:

1. A violating fixture with all selected positive diagnostics.
2. A compliant fixture with no selected diagnostics.
3. A disabled-rule fixture that omits one rule from `diagnostics:`.
4. A qualified-ignore fixture that suppresses one plugin-qualified diagnostic and leaves a second enabled violation visible.

The violating scenario must run first in every repetition.
Treat the qualified-ignore fixture as a scenario class that runs each characterized dynamic-message branch in isolation.
Pair every suppressed dynamic branch with a second unsuppressed violation in the same file.
The second violation may use the same raw diagnostic code during the one-rule Phase 0 probe.
Do not add either plugin package to the generated consumer's development dependencies.
Add `go_router: 17.5.0` only for go_router and combined consumers.

- [ ] **Step 2.5: Verify dependency provenance before analysis**

Run Flutter dependency resolution in the generated consumer.
Read `.dart_tool/package_config.json` to verify each selected local plugin resolves to the expected absolute repository path.
In hosted mode, set a dedicated temporary `PUB_CACHE` and inspect `dart pub deps --json` to verify each exact plugin version.
Inspect the same dependency graph for `go_router 17.5.0` when present.
Classify any mismatch as `dependencyResolution` and stop before analysis.
Print the host operating system, Flutter and Dart versions, resolved `analysis_server_plugin`, analyzer, and `analyzer_plugin` versions, plugin source or exact version, and exact go_router version when present.

- [ ] **Step 2.6: Implement separate human-output parsers**

Parse the complete default human output from `dart analyze --fatal-infos --fatal-warnings .` and `flutter analyze --fatal-infos --fatal-warnings .` with separate functions.
Test each parser with POSIX paths and Windows drive-letter paths.
Do not normalize a plugin-qualified display code into a raw code.
Reject truncated records and any record without severity, message, path, line, column, and code.
Assert the raw code, `INFO`, exact problem text, normalized relative path, line, and column.
Assert nonzero exit for violating and qualified-ignore scenarios.
Assert zero exit for compliant and disabled-rule scenarios.

- [ ] **Step 2.7: Implement an explicit integration negative control**

Add `--negative-control` as a harness-only verification flag.
When enabled, replace one expected raw code with `__negative_control_missing_code__` and stop after the first analyzer subprocess.
The command must exit nonzero and print this exact prefix:

```log
HARNESS_ASSERTION_FAILED: missing diagnostic __negative_control_missing_code__
```

CI must run this command first, assert the nonzero exit and exact prefix, and only then trust the normal harness run.

- [ ] **Step 2.8: Implement bounded process-tree cleanup**

Start every analyzer through `Process.start` with complete stdout and stderr capture.
On Unix, discover descendants recursively with `pgrep -P`, send `SIGTERM` deepest-first, terminate the root, wait at most ten seconds, and send `SIGKILL` to recorded survivors.
On Windows, call `taskkill /PID <pid> /T`, wait at most ten seconds, and call `taskkill /PID <pid> /T /F` for survivors.
Await the root exit and every recorded descendant.
Drain both output streams before deleting the temporary consumer or dedicated cache.
Place consumer and cache deletion in a `finally` block that runs after all process and stream awaits.
Use an initial default timeout of 600 seconds until Task 4 commits the measured default.

- [ ] **Step 2.9: Test parser failure and timeout cleanup before accepting success**

The hanging-process fixture must start a child process, print both process identifiers, and hold both processes open.
The unit test must run it with a one-second timeout.
Assert a typed timeout, both recorded processes gone, stdout closed, stderr closed, and the temporary directory removable.
Corrupt one valid analyzer-output sample and prove that each parser rejects it before accepting the unmodified sample.

```bash
dart test test/tool/analyzer_plugin_harness_test.dart
```

- [ ] **Step 2.10: Regenerate the lockfile and commit repository infrastructure**

```bash
melos bootstrap
dart format tool test/tool
dart test test/tool/analyzer_plugin_harness_test.dart
git check-ignore -v pubspec.lock
git diff --check -- .gitignore pubspec.yaml pubspec.lock tool test/tool
git add .gitignore pubspec.yaml pubspec.lock tool/verify_analyzer_plugins.dart tool/src/analyzer_plugin_harness.dart test/tool/analyzer_plugin_harness_test.dart test/tool/fixtures/hanging_process.dart
git diff --cached --name-only
git commit -m "test(harness): add analyzer plugin verifier"
```

`git check-ignore -v pubspec.lock` must report that the negation rule makes the root lockfile visible.

## Task 3: Build and Run the Flutter Official-Host Probe

**Files:**

- Modify: `packages/flutter_best_practices_lints/pubspec.yaml`
- Create: `packages/flutter_best_practices_lints/lib/main.dart`
- Create: `packages/flutter_best_practices_lints/lib/src/phase0/prefer_media_query_partial_methods_probe.dart`
- Create: `packages/flutter_best_practices_lints/test/src/phase0/prefer_media_query_partial_methods_probe_test.dart`
- Modify: `pubspec.lock`

- [ ] **Step 3.1: Add candidate A beside the legacy host for the branch-only probe**

Keep `custom_lint_builder` only because the other four production rules still compile during the probe.
Add candidate A's official runtime and test dependencies.
Regenerate the root lockfile with `melos bootstrap`.
Record the resolved `analysis_server_plugin`, `analyzer`, and `analyzer_plugin` versions from `dart pub deps --json`.

- [ ] **Step 3.2: Write the failing official rule test**

Extend `AnalysisRuleTest`.
Set `rule = Phase0PreferMediaQueryPartialMethodsProbe()` before `super.setUp()`.
Use `assertDiagnostics` with `lint(offset, length, messageContainsAll: [anchoredProblem], correctionContains: anchoredCorrection)`.
Cover a positive `MediaQuery.of(context).size`, an already-correct `MediaQuery.sizeOf(context)`, a disabled integration case, and the exact static correction template.

- [ ] **Step 3.3: Implement the disposable probe rule and official entrypoint**

Implement only the characterized `size` branch in the disposable probe file.
Define one `static const LintCode` with the production diagnostic name and static `{0}` correction template.
Use `addPropertyAccess` and `reportAtNode(..., arguments: ['MediaQuery.sizeOf(context)'])`.
Create `lib/main.dart` with a private Phase 0 `Plugin` subclass.
Register the probe with `registerLintRule` so omission from `diagnostics:` leaves it disabled.
Do not export the probe.
Do not change the workspace example configuration.

- [ ] **Step 3.4: Verify the probe locally on Flutter `3.47.2`**

```bash
flutter --version
(cd packages/flutter_best_practices_lints && flutter test test/src/phase0/prefer_media_query_partial_methods_probe_test.dart)
dart run tool/verify_analyzer_plugins.dart --plugin flutter_best_practices_lints --diagnostic prefer_media_query_partial_methods --source local --analyzer dart --repeat 3 --timeout-seconds 600
dart run tool/verify_analyzer_plugins.dart --plugin flutter_best_practices_lints --diagnostic prefer_media_query_partial_methods --source local --analyzer flutter --repeat 3 --timeout-seconds 600
```

The two analyzer selectors must use separate harness invocations.
Stop immediately if either command omits the diagnostic, crashes, or times out.

- [ ] **Step 3.5: Commit the branch-only package probe**

```bash
git add packages/flutter_best_practices_lints/pubspec.yaml packages/flutter_best_practices_lints/lib/main.dart packages/flutter_best_practices_lints/lib/src/phase0/prefer_media_query_partial_methods_probe.dart packages/flutter_best_practices_lints/test/src/phase0/prefer_media_query_partial_methods_probe_test.dart pubspec.lock
git diff --cached --name-only
git commit -m "test(flutter-lints): probe official analyzer host"
```

This commit is not a release candidate.
It must never be tagged or published.

## Task 4: Add the Compatibility Matrix and Freeze Phase 0 Results

**Files:**

- Modify: `.github/workflows/main.yaml`
- Modify: `tool/src/analyzer_plugin_harness.dart`
- Create: `docs/notes/2026-09-03-analysis-server-plugin-migration-evidence.md`

- [ ] **Step 4.1: Add the Phase 0 CI matrix**

Keep one current quality lane.
Add `workflow_dispatch` inputs for `source`, `flutter_best_practices_lints_version`, and `go_router_linter_version` so an approved publication can run the same matrix in hosted mode.
Reject hosted dispatch when a selected package version input is empty or is not exact.
Add a matrix with these independent dimensions:

```yaml
os: [macos-latest, ubuntu-latest, windows-latest]
flutter: [3.44.0, 3.47.2]
analyzer: [dart, flutter]
```

Set `fail-fast: false`.
Each lane must resolve dependencies, verify formatting, run serialized analysis, run unit tests, print the compatibility unit, and invoke the Flutter local consumer harness with its one analyzer selector and `--repeat 3`.
The Phase 0 invocation must pass `--diagnostic prefer_media_query_partial_methods`.
Do not restore an analyzer-plugin AOT cache before the first run.
Upload complete harness logs on failure.

- [ ] **Step 4.2: Add the negative-control job step**

Run the negative control before the normal matrix accepts harness output.
Capture its output without converting a normal zero exit into success.
Require a nonzero exit and the exact `HARNESS_ASSERTION_FAILED` prefix.
Fail the job if the negative control returns zero or the prefix is absent.

- [ ] **Step 4.3: Verify workflow structure locally**

```bash
trunk check .github/workflows/main.yaml
rg -n 'concurrency=1|macos-latest|ubuntu-latest|windows-latest|3\.44\.0|3\.47\.2|--analyzer|--repeat 3|negative-control' .github/workflows/main.yaml
```

- [ ] **Step 4.4: Commit CI separately**

```bash
git add .github/workflows/main.yaml
git diff --cached --name-only
git commit -m "ci: add analyzer plugin compatibility matrix"
```

- [ ] **Step 4.5: Stop for push approval and run the complete remote matrix**

Push is an external-impact action.
Request explicit approval before pushing the probe branch.
Do not infer approval from authorization to implement this plan.

- [ ] **Step 4.6: Apply the candidate fallback only for a dependency-resolution failure**

If candidate A fails dependency resolution on the older Flutter lane, replace the package constraints with candidate B, regenerate `pubspec.lock`, and rerun every operating-system and analyzer lane.
Do not use candidate B to mask a missing diagnostic, crash, timeout, parser failure, or `flutter analyze` omission.
If candidate B also fails resolution, stop with both exact resolver outputs.
When candidate B passes, commit only the Flutter manifest and root lockfile before recording evidence.

```bash
git add packages/flutter_best_practices_lints/pubspec.yaml pubspec.lock
git diff --cached --name-only
git commit -m "test(flutter-lints): select compatible analyzer family"
```

- [ ] **Step 4.7: Calculate and commit the production timeout**

Collect the first successful cold duration from every required lane.
Select the greatest duration.
Calculate `max(120, ceil(3 * slowestColdSeconds))` and cap the result at 600.
Replace the harness's 600-second default with that integer.
Keep the explicit lower timeout available for timeout tests.
If the computed value is 600, leave the source unchanged and record that the initial ceiling became the measured default.
Run the following commit block only when the source changed.

```bash
dart format tool/src/analyzer_plugin_harness.dart
dart test test/tool/analyzer_plugin_harness_test.dart
git add tool/src/analyzer_plugin_harness.dart
git diff --cached --name-only
git commit -m "test(harness): set measured analyzer timeout"
```

- [ ] **Step 4.8: Perform the IDE probe**

Open the standalone positive consumer in one supported Dart or Flutter IDE integration.
Restart the Dart Analysis Server after changing `plugins:`.
Observe the positive diagnostic first.
Then verify the disabled fixture, compliant fixture, and qualified-ignore fixture.
Record the IDE name and version, operating system, Flutter and Dart versions, plugin source, raw code when exposed, exact problem text, and source range.

- [ ] **Step 4.9: Record the Phase 0 evidence and decision**

Write the selected dependency family, resolved transitive versions, every matrix result, cold and warm durations, timeout calculation, negative-control result, and IDE result in the evidence note.
If any `flutter analyze` lane reproduces issue #187999, mark Phase 0 failed and stop before Task 5.

```bash
git add docs/notes/2026-09-03-analysis-server-plugin-migration-evidence.md
git diff --cached --name-only
git commit -m "docs: record analyzer plugin phase zero evidence"
```

## Task 5: Migrate `flutter_best_practices_lints` Atomically

Start this task only after every Phase 0 gate passes.

**Files:**

- Modify: `packages/flutter_best_practices_lints/pubspec.yaml`
- Modify: `packages/flutter_best_practices_lints/lib/main.dart`
- Modify: `packages/flutter_best_practices_lints/lib/flutter_best_practices_lints.dart`
- Modify: `packages/flutter_best_practices_lints/lib/src/flutter_best_practices_plugin.dart`
- Modify: `packages/flutter_best_practices_lints/lib/src/rules/single_class_per_file.dart`
- Modify: `packages/flutter_best_practices_lints/lib/src/rules/matching_class_and_file_name.dart`
- Modify: `packages/flutter_best_practices_lints/lib/src/rules/prefer_widget_class_over_widget_helper.dart`
- Modify: `packages/flutter_best_practices_lints/lib/src/rules/avoid_widget_operator_equals.dart`
- Modify: `packages/flutter_best_practices_lints/lib/src/rules/prefer_media_query_partial_methods.dart`
- Delete: `packages/flutter_best_practices_lints/lib/src/extensions/lint_code_extension.dart`
- Delete: `packages/flutter_best_practices_lints/lib/src/phase0/prefer_media_query_partial_methods_probe.dart`
- Delete: `packages/flutter_best_practices_lints/test/src/phase0/prefer_media_query_partial_methods_probe_test.dart`
- Modify: `packages/flutter_best_practices_lints/test/src/flutter_best_practices_plugin_test.dart`
- Modify: `packages/flutter_best_practices_lints/test/src/rules/single_class_per_file_test.dart`
- Modify: `packages/flutter_best_practices_lints/test/src/rules/matching_class_and_file_name_test.dart`
- Modify: `packages/flutter_best_practices_lints/test/src/rules/prefer_widget_class_over_widget_helper_test.dart`
- Modify: `packages/flutter_best_practices_lints/test/src/rules/avoid_widget_operator_equals_test.dart`
- Modify: `packages/flutter_best_practices_lints/test/src/rules/prefer_media_query_partial_methods_test.dart`
- Modify: `pubspec.lock`

- [ ] **Step 5.1: Port the characterized tests to `AnalysisRuleTest` before changing production rules**

Set each concrete rule in `setUp` before calling `super.setUp()`.
Use the same source strings, offsets, lengths, exact messages, and exact corrections from Task 1.
Use anchored message and correction patterns.
Keep fixture data for every dynamic-message branch available to the standalone harness's qualified-ignore scenario class.
Use package stubs only for the Flutter declarations needed by the rule.
Use resolved elements for Flutter library checks.
Change only the two unrelated-ancestor expectations to no diagnostic.

Run the tests and record the expected compile or assertion failures against the legacy rule classes.

- [ ] **Step 5.2: Replace the plugin shell**

Make `FlutterBestPracticesPlugin` extend official `Plugin`.
Return `flutter_best_practices_lints` from `name`.
Register exactly five rule instances with `registry.registerLintRule` in the existing order.
Set the top-level `plugin` in `lib/main.dart` to `FlutterBestPracticesPlugin()`.
Remove `createPlugin()` and its export.
Keep the public `FlutterBestPracticesPlugin` export.
Replace legacy configuration in the library-level documentation with a minimal official-host example so the release-candidate library contains no legacy host symbols.

- [ ] **Step 5.3: Migrate the five rules**

Make every class extend `AnalysisRule`.
Keep one focused `SimpleAstVisitor<void>` per rule.
Use the Rule Registration Map in this plan.
Use `element.library?.uri` for Flutter package identity.
Use `RuleContext.isInLibDir` for only `single_class_per_file` and `matching_class_and_file_name`.
Use the Static Diagnostic Templates for all dynamic messages.
Do not add semantic Flutter identity to `prefer_widget_class_over_widget_helper`.
Do not broaden direct-subclass logic in `avoid_widget_operator_equals`.

- [ ] **Step 5.4: Remove the legacy dependencies and dynamic-code extension**

Remove `custom_lint_builder` and `path` from the package manifest.
Keep the selected official runtime constraints.
Keep the selected `analyzer_testing`, `test_reflective_loader`, and `test` development dependencies.
Delete `LintCodeCopyWithExtension` and remove its export.
Regenerate the root lockfile.

- [ ] **Step 5.5: Replace the plugin test**

Assert that `package:flutter_best_practices_lints/main.dart` exposes a top-level official plugin.
Assert that the object is a `FlutterBestPracticesPlugin` and that its name is `flutter_best_practices_lints`.
Leave exact five-rule registration to the standalone consumer and an official registry test only if the selected public API exposes a stable recording seam.
Do not mock analyzer internals.

- [ ] **Step 5.6: Verify the package migration**

```bash
melos bootstrap
dart format packages/flutter_best_practices_lints/lib packages/flutter_best_practices_lints/test
(cd packages/flutter_best_practices_lints && flutter test test)
(cd packages/flutter_best_practices_lints && dart analyze .)
rg -n 'package:custom_lint|extends PluginBase|extends DartLintRule|PluginBase createPlugin|show createPlugin|LintCodeCopyWithExtension|\.copyWith\(' packages/flutter_best_practices_lints/lib packages/flutter_best_practices_lints/pubspec.yaml
dart run tool/verify_analyzer_plugins.dart --plugin flutter_best_practices_lints --source local --analyzer dart --repeat 3
dart run tool/verify_analyzer_plugins.dart --plugin flutter_best_practices_lints --source local --analyzer flutter --repeat 3
```

The legacy-symbol scan must return no matches.

- [ ] **Step 5.7: Commit the atomic Flutter host migration**

```bash
git add packages/flutter_best_practices_lints/lib packages/flutter_best_practices_lints/test packages/flutter_best_practices_lints/pubspec.yaml pubspec.lock
git diff --cached --name-only
git commit -m "feat(flutter-lints): migrate to official analyzer plugin"
```

## Task 6: Prepare the Flutter Package Release Contract

**Files:**

- Modify: `packages/flutter_best_practices_lints/pubspec.yaml`
- Modify: `packages/flutter_best_practices_lints/README.md`
- Modify: `packages/flutter_best_practices_lints/CHANGELOG.md`
- Modify: `packages/flutter_best_practices_lints/lib/flutter_best_practices_lints.dart`
- Modify: `packages/flutter_best_practices_lints/example/README.md`
- Modify: `packages/flutter_best_practices_lints/example/analysis_options.yaml`
- Modify: `packages/flutter_best_practices_lints/example/lib/main.dart`
- Modify: `packages/flutter_best_practices_lints/example/pubspec.yaml`
- Regenerate: `packages/flutter_best_practices_lints/doc/api/**`
- Modify: `pubspec.lock`

- [ ] **Step 6.1: Set version `0.6.0` and update the consumer-facing manifest**

Set the package version to `0.6.0`.
Update the SDK floor only to the minimum proved in Task 4.
Keep the analyzer upper bound below major 15.
Remove the example's `custom_lint` dependency.
Do not add the lint package as an example development dependency unless Phase 0 preserved evidence that the official host requires it.
Regenerate the root lockfile.

- [ ] **Step 6.2: Replace legacy configuration in documentation**

Document hosted `plugins:` configuration with version `0.6.0`.
Document local configuration with an absolute path placeholder.
List all five rule codes and show explicit `true` activation.
Document `INFO`, explicit opt-in, raw displayed codes, plugin-qualified ignore syntax, no rule-specific options, tested stable SDKs, and tested operating systems.
Explain that `analyzer.plugins: custom_lint` and `custom_lint.rules` no longer configure version `0.6.0`.

- [ ] **Step 6.3: Keep the workspace example host-neutral**

Remove legacy custom-lint configuration and `expect_lint`-style assumptions that depend on the old host.
Do not add top-level `plugins:` configuration to the example.
Keep illustrative violating source only when it still compiles under normal workspace analysis.
Explain in the example README that host behavior is verified by the standalone root harness.

- [ ] **Step 6.4: Write the breaking changelog entry**

Record the official host, removed legacy configuration, removed `createPlugin()`, removed `LintCodeCopyWithExtension`, unchanged raw codes, retained `INFO`, new explicit opt-in, public `FlutterBestPracticesPlugin` superclass and member-surface change, tested matrix, and legacy-version compatibility path.
Do not call the migration non-breaking.

- [ ] **Step 6.5: Generate API documentation**

Run the package generator.
Inspect generated changes instead of editing generated HTML by hand.

```bash
cd packages/flutter_best_practices_lints
./dartdoc.sh
cd ../..
git diff --stat -- packages/flutter_best_practices_lints/doc/api
git diff --check -- packages/flutter_best_practices_lints
```

- [ ] **Step 6.6: Verify and commit Flutter release documentation**

```bash
trunk check packages/flutter_best_practices_lints/README.md packages/flutter_best_practices_lints/CHANGELOG.md packages/flutter_best_practices_lints/example/README.md packages/flutter_best_practices_lints/lib/flutter_best_practices_lints.dart
melos bootstrap
melos run format:ci
melos run analyze
(cd packages/flutter_best_practices_lints && flutter test test)
git add packages/flutter_best_practices_lints/pubspec.yaml packages/flutter_best_practices_lints/README.md packages/flutter_best_practices_lints/CHANGELOG.md packages/flutter_best_practices_lints/lib/flutter_best_practices_lints.dart packages/flutter_best_practices_lints/example packages/flutter_best_practices_lints/doc/api pubspec.lock
git diff --cached --name-only
git commit -m "docs(flutter-lints): document official plugin migration"
```

## Task 7: Gate and Publish `flutter_best_practices_lints 0.6.0`

**Files:**

- Modify after evidence exists: `docs/notes/2026-09-03-analysis-server-plugin-migration-evidence.md`

- [ ] **Step 7.1: Run all local release gates**

```bash
melos bootstrap
melos run format:ci
melos run analyze
melos run test:ci
dart run tool/verify_analyzer_plugins.dart --plugin flutter_best_practices_lints --source local --analyzer dart --repeat 3
dart run tool/verify_analyzer_plugins.dart --plugin flutter_best_practices_lints --source local --analyzer flutter --repeat 3
cd packages/flutter_best_practices_lints
dart pub publish --dry-run
dart doc
cd ../..
```

Run the same two separate analyzer commands in every remote compatibility lane.
The local `--analyzer all` convenience command is not release evidence.

- [ ] **Step 7.2: Repeat the IDE smoke test on the release candidate**

Restart the Dart Analysis Server.
Observe a positive diagnostic before checking absence.
Verify exact problem text and range, raw code when exposed, disabled behavior, compliant behavior, and targeted qualified suppression.
Append the release-candidate evidence.

- [ ] **Step 7.3: Check the publication blocker**

If any required `flutter analyze` lane omits the plugin diagnostic, stop.
Keep the package unpublished and keep `go_router_linter` unchanged.
Record the exact Flutter, Dart, host-package, analyzer, analyzer-plugin, operating-system, and command output.

- [ ] **Step 7.4: Commit release evidence separately**

```bash
git add docs/notes/2026-09-03-analysis-server-plugin-migration-evidence.md
git diff --cached --name-only
git commit -m "docs: record flutter plugin release evidence"
```

- [ ] **Step 7.5: Stop for Flutter branch integration approval**

Present the exact branch SHA, all required lane results, dry-run result, and IDE evidence.
Request approval before pushing the latest release commits, opening or updating a pull request, or merging the Flutter tranche.
These actions do not authorize publication.

- [ ] **Step 7.6: Revalidate the exact merged Flutter head**

After the approved merge, fetch and verify that the release checkout matches `origin/main`.
Rerun the local package gate and the complete local-mode CI matrix at that exact SHA.
Confirm that `.github/workflows/main.yaml` with hosted `workflow_dispatch` support is present on the default branch.

```bash
git fetch origin
git rev-parse HEAD
git rev-parse origin/main
git status --short
```

- [ ] **Step 7.7: Stop for publication approval**

Present the exact merged SHA, all revalidated lane results, public package version `0.6.0`, and the exact publication command.
Request explicit approval for `dart pub publish`.
Name the later hosted `workflow_dispatch` as a separate external action and request approval for it before dispatch unless the operator explicitly approves both named actions together.

- [ ] **Step 7.8: Publish only after approval**

```bash
cd packages/flutter_best_practices_lints
dart pub publish
```

Do not combine publication approval with any later retraction or go_router publication.

- [ ] **Step 7.9: Verify the public artifact and complete hosted matrix**

Verify pub.dev metadata for exactly `0.6.0`.
Run each hosted lane with a fresh temporary consumer and dedicated temporary `PUB_CACHE`.

```bash
dart run tool/verify_analyzer_plugins.dart --plugin flutter_best_practices_lints --source hosted --package-version flutter_best_practices_lints=0.6.0 --analyzer dart --repeat 3
dart run tool/verify_analyzer_plugins.dart --plugin flutter_best_practices_lints --source hosted --package-version flutter_best_practices_lints=0.6.0 --analyzer flutter --repeat 3
```

Do not start Task 8 until macOS, Linux, and Windows pass on every supported stable compatibility unit.
If a hosted lane fails, stop and prepare a patch-release proposal or separately approved retraction request.

- [ ] **Step 7.10: Tag the verified Flutter release after separate approval**

Confirm that `flutter_best_practices_lints@0.6.0` does not exist locally or remotely.
Request approval to create and push the lightweight package tag at the exact merged and published SHA.
After approval, create the tag, push only that tag, and re-query the remote tag target.

```bash
git tag --list flutter_best_practices_lints@0.6.0
git ls-remote --tags origin refs/tags/flutter_best_practices_lints@0.6.0
```

Both commands must produce no tag before approval.

```bash
flutter_release_sha="$(git rev-parse origin/main)"
test "$flutter_release_sha" = "$(git rev-parse HEAD)"
git tag flutter_best_practices_lints@0.6.0 "$flutter_release_sha"
git push origin refs/tags/flutter_best_practices_lints@0.6.0
git ls-remote --tags origin refs/tags/flutter_best_practices_lints@0.6.0
```

## Task 8: Characterize All Five go_router Rules on the Legacy Host

Start only after Task 7.10 passes.

**Files:**

- Modify: `packages/go_router_linter/test/src/lint_test_utils.dart`
- Create: `packages/go_router_linter/test/src/rules/missing_go_route_name_property_test.dart`
- Modify: `packages/go_router_linter/test/src/rules/use_context_directly_for_go_router_test.dart`
- Modify: `packages/go_router_linter/test/src/rules/avoid_hardcoded_routes_test.dart`
- Modify: `packages/go_router_linter/test/src/rules/avoid_navigator_named_routes_with_go_router_test.dart`
- Modify: `packages/go_router_linter/test/src/rules/missing_go_router_error_handler_test.dart`

- [ ] **Step 8.1: Start the go_router tranche from the revalidated default branch**

Re-read the local and remote log and confirm that the Flutter hosted evidence is complete.
Use `superpowers:using-git-worktrees` to create a separate branch from the latest `origin/main`.

```bash
git fetch origin
git worktree add ../custom_linters-go-router-analysis-plugin -b feat/go-router-analysis-server-plugin origin/main
```

Do not carry an uncommitted Flutter worktree into the go_router tranche.

- [ ] **Step 8.2: Make the go_router legacy helper expose full diagnostics**

Return `Future<List<AnalysisError>>`.
Retain the existing `Pubspec?` input for legacy dependency characterization.
Add configurable source placement.
Assert code, severity, exact message, exact correction, offset, and length.

- [ ] **Step 8.3: Add missing `missing_go_route_name_property` coverage**

Cover a `GoRoute` without `name`, a `GoRoute` with `name`, a non-GoRoute constructor with the same argument shape, and the current static-type element-name boundary.

- [ ] **Step 8.4: Complete the four existing rule characterizations**

For `use_context_directly_for_go_router`, cover every route method, the simple-identifier context boundary, nested invocation shape, exact problem text, and every dynamic correction branch.
For `avoid_hardcoded_routes`, cover each method allowlist, `context` shortcut, `GoRouter` element-name path, supported constructor and named-argument path, redirect return strings, interpolation and non-string boundaries.
For `avoid_navigator_named_routes_with_go_router`, cover dependencies, development dependencies, no `go_router`, each Navigator method, syntactic `Navigator`, `NavigatorState` element name, and unrelated targets.
For `missing_go_router_error_handler`, cover neither handler, `errorBuilder`, `errorPageBuilder`, both handlers, and non-GoRouter constructors.

- [ ] **Step 8.5: Prove characterization failure and then pass**

Temporarily alter one exact correction or range.
Run the owning test and observe the mismatch.
Restore the expected value.

```bash
(cd packages/go_router_linter && flutter test test/src/rules)
```

- [ ] **Step 8.6: Commit only go_router characterization**

```bash
dart format packages/go_router_linter/test/src/lint_test_utils.dart packages/go_router_linter/test/src/rules
(cd packages/go_router_linter && flutter test test)
git add packages/go_router_linter/test/src/lint_test_utils.dart packages/go_router_linter/test/src/rules
git diff --cached --name-only
git commit -m "test(go-router-linter): characterize legacy diagnostics"
```

## Task 9: Migrate `go_router_linter` Atomically

**Files:**

- Modify: `packages/go_router_linter/pubspec.yaml`
- Create: `packages/go_router_linter/lib/main.dart`
- Modify: `packages/go_router_linter/lib/go_router_linter.dart`
- Delete: `packages/go_router_linter/lib/src/go_router_lint_plugin.dart`
- Modify: `packages/go_router_linter/lib/src/rules/missing_go_route_name_property.dart`
- Modify: `packages/go_router_linter/lib/src/rules/use_context_directly_for_go_router.dart`
- Modify: `packages/go_router_linter/lib/src/rules/avoid_hardcoded_routes.dart`
- Modify: `packages/go_router_linter/lib/src/rules/avoid_navigator_named_routes_with_go_router.dart`
- Modify: `packages/go_router_linter/lib/src/rules/missing_go_router_error_handler.dart`
- Delete: `packages/go_router_linter/lib/src/extensions/lint_code_extension.dart`
- Delete: `packages/go_router_linter/test/src/extensions/lint_code_extension_test.dart`
- Modify: `packages/go_router_linter/test/src/go_router_lint_plugin_test.dart`
- Modify: `packages/go_router_linter/test/src/rules/missing_go_route_name_property_test.dart`
- Modify: `packages/go_router_linter/test/src/rules/use_context_directly_for_go_router_test.dart`
- Modify: `packages/go_router_linter/test/src/rules/avoid_hardcoded_routes_test.dart`
- Modify: `packages/go_router_linter/test/src/rules/avoid_navigator_named_routes_with_go_router_test.dart`
- Modify: `packages/go_router_linter/test/src/rules/missing_go_router_error_handler_test.dart`
- Modify: `pubspec.lock`

- [ ] **Step 9.1: Port the same characterized sources to `AnalysisRuleTest`**

Use the selected official test dependency family.
Set each rule before `super.setUp()`.
Use anchored exact message and correction patterns.
Keep fixture data for every `use_context_directly_for_go_router` message branch available to the standalone harness's qualified-ignore scenario class.
Use minimal go_router and Flutter test package stubs.
Keep actual resolved elements for all semantic checks.

- [ ] **Step 9.2: Add the official private plugin entrypoint**

Define `final plugin = _GoRouterLintPlugin();` in `lib/main.dart`.
Keep `_GoRouterLintPlugin` in that library so no new plugin class becomes part of the package's public API.
Return `go_router_linter` from `name`.
Register exactly five lint rules in the existing order.
Delete the legacy plugin file and remove `createPlugin()` from the public library.
Replace legacy configuration in the library-level documentation with a minimal official-host example so the release-candidate library contains no legacy host symbols.

- [ ] **Step 9.3: Migrate the five rules with the narrow registry callbacks**

Use the Rule Registration Map.
Replace the detached resolved-unit future and recursive traversal in `missing_go_route_name_property` with `addInstanceCreationExpression`.
Use the Static Diagnostic Templates for `use_context_directly_for_go_router`.
Preserve every characterized syntax and semantic boundary.
Do not add go_router library identity checks.

- [ ] **Step 9.4: Implement package-owned dependency detection without caching**

Use `context.package?.root.getChildAssumingFile('pubspec.yaml')`.
Return inactive when there is no owning package, no pubspec file, an unreadable file, or no `go_router` entry.
Parse the owning file with `pubspec_parse` and activate for either `dependencies` or `devDependencies`.
Move the existing `pubspec_parse: ^1.5.0` constraint from a development dependency to a runtime dependency.
Do not inspect the process working directory.
Do not cache the result.

- [ ] **Step 9.5: Remove the legacy host dependencies and helpers**

Remove `custom_lint_builder`.
Add the exact official dependency family proved by the Flutter package.
Add matching official test dependencies.
Delete `LintCodeCopyWithExtension` and its test.
Regenerate the root lockfile.

- [ ] **Step 9.6: Test owning-package isolation**

Create one analyzer-testing package that declares `go_router` and one that does not.
Analyze both in the same test process.
Assert that the first reports and the second does not.
Repeat in reverse order.
This proves there is no working-directory lookup or cross-package state leak.

- [ ] **Step 9.7: Verify and commit the go_router migration**

```bash
melos bootstrap
dart format packages/go_router_linter/lib packages/go_router_linter/test
(cd packages/go_router_linter && flutter test test)
(cd packages/go_router_linter && dart analyze .)
rg -n 'package:custom_lint|extends PluginBase|extends DartLintRule|PluginBase createPlugin|show createPlugin|LintCodeCopyWithExtension|\.copyWith\(' packages/go_router_linter/lib packages/go_router_linter/pubspec.yaml
dart run tool/verify_analyzer_plugins.dart --plugin go_router_linter --source local --analyzer dart --repeat 3
dart run tool/verify_analyzer_plugins.dart --plugin go_router_linter --source local --analyzer flutter --repeat 3
git add packages/go_router_linter/lib packages/go_router_linter/test packages/go_router_linter/pubspec.yaml pubspec.lock
git diff --cached --name-only
git commit -m "feat(go-router-linter): migrate to official analyzer plugin"
```

The legacy-symbol scan must return no matches.

## Task 10: Prepare the go_router Package Release Contract

**Files:**

- Modify: `packages/go_router_linter/pubspec.yaml`
- Modify: `packages/go_router_linter/README.md`
- Modify: `packages/go_router_linter/CHANGELOG.md`
- Modify: `packages/go_router_linter/lib/go_router_linter.dart`
- Modify: `packages/go_router_linter/example/README.md`
- Modify: `packages/go_router_linter/example/analysis_options.yaml`
- Modify: `packages/go_router_linter/example/lib/main.dart`
- Modify: `packages/go_router_linter/example/pubspec.yaml`
- Regenerate: `packages/go_router_linter/doc/api/**`
- Modify: `pubspec.lock`

- [ ] **Step 10.1: Set version `0.5.0` and exact tested go_router dependency**

Set the linter version to `0.5.0`.
Use the same proved SDK and official analyzer-family constraints as the Flutter package.
Remove the example's `custom_lint` dependency.
Set the example's `go_router` dependency to exact `17.5.0`.
Regenerate the root lockfile.

- [ ] **Step 10.2: Update README, library documentation, and example documentation**

Document the hosted and local official configuration.
List all five diagnostics as explicit opt-ins.
Document `INFO`, raw display codes, qualified suppression, no rule-specific options, supported stable SDK matrix, all tested operating systems, and exact tested `go_router 17.5.0`.
Do not imply a wider go_router compatibility promise.
Keep the workspace example free of top-level `plugins:`.

- [ ] **Step 10.3: Write the `0.5.0` breaking changelog entry**

Record the official host, legacy configuration removal, `createPlugin()` removal, `LintCodeCopyWithExtension` removal, unchanged raw codes, retained `INFO`, explicit opt-in, tested matrix, exact go_router version, and legacy-version compatibility path.

- [ ] **Step 10.4: Generate API documentation**

```bash
cd packages/go_router_linter
dart doc
cd ../..
git diff --stat -- packages/go_router_linter/doc/api
git diff --check -- packages/go_router_linter
```

- [ ] **Step 10.5: Verify and commit only go_router release documentation**

```bash
trunk check packages/go_router_linter/README.md packages/go_router_linter/CHANGELOG.md packages/go_router_linter/example/README.md packages/go_router_linter/lib/go_router_linter.dart
melos bootstrap
melos run format:ci
melos run analyze
(cd packages/go_router_linter && flutter test test)
git add packages/go_router_linter/pubspec.yaml packages/go_router_linter/README.md packages/go_router_linter/CHANGELOG.md packages/go_router_linter/lib/go_router_linter.dart packages/go_router_linter/example packages/go_router_linter/doc/api pubspec.lock
git diff --cached --name-only
git commit -m "docs(go-router-linter): document official plugin migration"
```

## Task 11: Enable Combined Consumer Verification

**Files:**

- Modify: `.github/workflows/main.yaml`
- Modify if tests expose a gap: `tool/src/analyzer_plugin_harness.dart`
- Modify: `test/tool/analyzer_plugin_harness_test.dart`

- [ ] **Step 11.1: Add failing combined-fixture tests**

Assert one generated consumer contains both plugin blocks.
Assert their diagnostics remain in separate plugin namespaces.
Assert the dependency graph contains one compatible analyzer plugin family and exact `go_router 17.5.0`.
Assert a qualified ignore for one package cannot hide the other package's diagnostic.

- [ ] **Step 11.2: Complete `--plugin all` behavior**

Reuse one consumer root and one synthetic plugin graph.
Generate at least one positive rule from each package.
Keep disabled, compliant, and targeted-ignore scenarios isolated.
Print both plugin sources or exact versions.

- [ ] **Step 11.3: Change the local CI selector from Flutter-only to combined**

Keep the same operating-system, Flutter-version, and analyzer-selector dimensions.
Keep each analyzer command in a fresh lane.
Keep one cold and two warm runs.
Print and assert `go_router 17.5.0`.

- [ ] **Step 11.4: Verify and commit repository-level combined coverage**

```bash
dart format tool test/tool
dart test test/tool/analyzer_plugin_harness_test.dart
trunk check .github/workflows/main.yaml
dart run tool/verify_analyzer_plugins.dart --plugin all --source local --analyzer dart --repeat 3
dart run tool/verify_analyzer_plugins.dart --plugin all --source local --analyzer flutter --repeat 3
git add .github/workflows/main.yaml tool/src/analyzer_plugin_harness.dart test/tool/analyzer_plugin_harness_test.dart
git diff --cached --name-only
git commit -m "ci: verify combined analyzer plugins"
```

- [ ] **Step 11.5: Stop for push approval and require the complete combined remote matrix**

Do not use a Flutter-only pass as evidence for the combined graph.
Do not proceed to publication if any one of the twelve command-specific lanes fails.

## Task 12: Gate and Publish `go_router_linter 0.5.0`

**Files:**

- Modify after evidence exists: `docs/notes/2026-09-03-analysis-server-plugin-migration-evidence.md`

- [ ] **Step 12.1: Run package and combined local gates**

```bash
melos bootstrap
melos run format:ci
melos run analyze
melos run test:ci
dart run tool/verify_analyzer_plugins.dart --plugin go_router_linter --source local --analyzer dart --repeat 3
dart run tool/verify_analyzer_plugins.dart --plugin go_router_linter --source local --analyzer flutter --repeat 3
dart run tool/verify_analyzer_plugins.dart --plugin all --source local --analyzer dart --repeat 3
dart run tool/verify_analyzer_plugins.dart --plugin all --source local --analyzer flutter --repeat 3
cd packages/go_router_linter
dart pub publish --dry-run
dart doc
cd ../..
```

- [ ] **Step 12.2: Run the go_router IDE smoke fixture**

Restart the Dart Analysis Server.
Observe a positive go_router diagnostic first.
Then verify compliant, disabled, and qualified-ignore behavior.
Record the IDE and complete compatibility unit.

- [ ] **Step 12.3: Commit go_router release evidence**

```bash
git add docs/notes/2026-09-03-analysis-server-plugin-migration-evidence.md
git diff --cached --name-only
git commit -m "docs: record go router plugin release evidence"
```

- [ ] **Step 12.4: Stop for go_router branch integration approval**

Present the exact branch SHA, package dry-run, go_router-only matrix, combined matrix, and IDE result.
Request approval before pushing the latest release commits, opening or updating a pull request, or merging the go_router tranche.
These actions do not authorize publication.

- [ ] **Step 12.5: Revalidate the exact merged go_router head**

After the approved merge, fetch and verify that the release checkout matches `origin/main`.
Rerun the package, go_router-only, and combined local gates at that exact SHA.

```bash
git fetch origin
git rev-parse HEAD
git rev-parse origin/main
git status --short
```

- [ ] **Step 12.6: Stop for separate publication approval**

Present the exact merged SHA, revalidated package and matrix results, public package version `0.5.0`, and exact publication command.
Request explicit approval for this publication.
Name the later hosted `workflow_dispatch` as a separate external action and request approval for it before dispatch unless the operator explicitly approves both named actions together.

- [ ] **Step 12.7: Publish only after approval**

```bash
cd packages/go_router_linter
dart pub publish
```

- [ ] **Step 12.8: Verify go_router-only and combined hosted consumers**

Use a new dedicated temporary `PUB_CACHE` in every harness invocation.

```bash
dart run tool/verify_analyzer_plugins.dart --plugin go_router_linter --source hosted --package-version go_router_linter=0.5.0 --analyzer dart --repeat 3
dart run tool/verify_analyzer_plugins.dart --plugin go_router_linter --source hosted --package-version go_router_linter=0.5.0 --analyzer flutter --repeat 3
dart run tool/verify_analyzer_plugins.dart --plugin all --source hosted --package-version flutter_best_practices_lints=0.6.0 --package-version go_router_linter=0.5.0 --analyzer dart --repeat 3
dart run tool/verify_analyzer_plugins.dart --plugin all --source hosted --package-version flutter_best_practices_lints=0.6.0 --package-version go_router_linter=0.5.0 --analyzer flutter --repeat 3
```

Run all four command shapes on macOS, Linux, and Windows for every supported stable compatibility unit.
Verify public metadata for exact version `0.5.0`.
If a hosted lane fails, stop and prepare a patch-release proposal or separately approved retraction request.

- [ ] **Step 12.9: Tag the verified go_router release after separate approval**

Confirm that `go_router_linter@0.5.0` does not exist locally or remotely.
Request approval to create and push the lightweight package tag at the exact merged and published SHA.
After approval, create the tag, push only that tag, and re-query the remote tag target.

```bash
git tag --list go_router_linter@0.5.0
git ls-remote --tags origin refs/tags/go_router_linter@0.5.0
```

Both commands must produce no tag before approval.

```bash
go_router_release_sha="$(git rev-parse origin/main)"
test "$go_router_release_sha" = "$(git rev-parse HEAD)"
git tag go_router_linter@0.5.0 "$go_router_release_sha"
git push origin refs/tags/go_router_linter@0.5.0
git ls-remote --tags origin refs/tags/go_router_linter@0.5.0
```

## Task 13: Run the Final Repository and Acceptance Audit

**Files:**

- Verify all changed paths.
- Modify only if a gate exposes a migration defect within this specification.

- [ ] **Step 13.1: Prove legacy host removal and example isolation**

```bash
rg -n 'package:custom_lint|extends PluginBase|extends DartLintRule|PluginBase createPlugin|show createPlugin|LintCodeCopyWithExtension' packages/flutter_best_practices_lints/lib packages/flutter_best_practices_lints/pubspec.yaml packages/go_router_linter/lib packages/go_router_linter/pubspec.yaml
rg -n '^plugins:' packages/flutter_best_practices_lints/example/analysis_options.yaml packages/go_router_linter/example/analysis_options.yaml
```

Both scans must return no matches.

- [ ] **Step 13.2: Prove official entrypoints and static diagnostics**

```bash
rg -n '^final plugin =|extends Plugin|registerLintRule' packages/flutter_best_practices_lints/lib/main.dart packages/flutter_best_practices_lints/lib/src/flutter_best_practices_plugin.dart packages/go_router_linter/lib/main.dart
rg -n 'static const .*LintCode' packages/flutter_best_practices_lints/lib/src/rules packages/go_router_linter/lib/src/rules
```

Review the output and count exactly five registered rule names in each package and ten static lint codes overall.
Do not infer counts from truncated output.

- [ ] **Step 13.3: Run the full repository gate**

```bash
melos bootstrap
melos run format:ci
melos run analyze
melos run test:ci
trunk check
```

State what each command inspected.
Do not use these passes as substitutes for hosted consumer or IDE evidence.

- [ ] **Step 13.4: Verify generated documentation provenance**

Rerun `dart doc` in each package.
Confirm a clean diff for `doc/api/**` after regeneration.
Fail if manual generated-file edits remain.

- [ ] **Step 13.5: Audit Git scope and commit grouping**

```bash
git status --short
git diff --check
git log --oneline --name-only --decorate -20
```

Confirm that no commit mixes both package directories.
Confirm that every package manifest change has the regenerated root lockfile in the same commit.
Confirm that no coverage or temporary-consumer artifact is tracked.

- [ ] **Step 13.6: Close every acceptance criterion with direct evidence**

Use the matrix below.
Record each criterion as passed, failed, or blocked.
Do not mark the migration complete while any criterion is failed, blocked, or supported only by local-path evidence.

## Acceptance-Criteria Traceability

| Criterion | Implementation tasks        | Required closing evidence                                                          |
| --------- | --------------------------- | ---------------------------------------------------------------------------------- |
| AC-001    | Tasks 5 and 9               | Legacy dependency and symbol scans plus resolved graph                             |
| AC-002    | Tasks 5 and 9               | Entrypoint tests, public export tests, and source inspection                       |
| AC-003    | Tasks 3, 5, 9, and 11       | Registration source, severity assertions, and disabled fixtures                    |
| AC-004    | Tasks 5, 9, and 13          | Final source tree contains neither adapter nor shared framework                    |
| AC-005    | Tasks 1, 5, 8, and 9        | Pre-migration and official tests share sources and exact expectations              |
| AC-006    | Tasks 1, 5, 8, and 9        | Characterized negatives remain clean                                               |
| AC-007    | Tasks 5 and 9               | Static-code source scan and exact dynamic-message tests                            |
| AC-008    | Tasks 5 and 9               | Public analyzer API use and two explicit boundary tests                            |
| AC-009    | Tasks 8 and 9               | Dependency, development-dependency, absent-dependency, and package-isolation tests |
| AC-010    | Tasks 2, 7, and 12          | Absolute local path and dedicated hosted `PUB_CACHE` logs                          |
| AC-011    | Tasks 2, 4, 7, 11, and 12   | Parsed `dart analyze` records and enforced exit status                             |
| AC-012    | Tasks 4, 7, 11, and 12      | Parsed `flutter analyze` records from every matrix lane                            |
| AC-013    | Tasks 4, 7, and 12          | Recorded IDE sessions after analysis-server restarts                               |
| AC-014    | Tasks 2, 4, 7, 11, and 12   | Qualified-ignore scenario keeps its second diagnostic visible                      |
| AC-015    | Tasks 11 and 12             | Combined graph and exact `go_router 17.5.0` resolution                             |
| AC-016    | Tasks 4, 7, 11, and 12      | One cold and two warm results for each command-specific lane                       |
| AC-017    | Tasks 2 and 4               | Timeout unit test, process-tree check, and measured default                        |
| AC-018    | Tasks 2 and 4               | Expected negative-control failure before normal runs                               |
| AC-019    | Tasks 4, 7, 11, and 12      | Serialized jobs and absence of retry logic                                         |
| AC-020    | Tasks 2, 3, 5, 6, 9, and 10 | Commit inspection shows each manifest with root lockfile                           |
| AC-021    | Tasks 7, 12, and 13         | Format, analysis, tests, integration, dry-run, and doc logs                        |
| AC-022    | Tasks 6 and 10              | README and changelog content review against the specification                      |
| AC-023    | Tasks 6, 10, and 13         | Regeneration produces a clean documentation diff                                   |
| AC-024    | Tasks 7 and 12              | Separate approval records for publication and any retraction                       |
| AC-025    | Tasks 7 and 12              | Complete fresh hosted matrix before the next phase or completion                   |

## Stop Conditions

Stop and report the exact evidence when any of these conditions occurs:

1. The official dependency family cannot resolve on a required stable Flutter version.
2. `dart analyze` or `flutter analyze` omits an expected diagnostic.
3. A command crashes, times out, leaves a descendant process, or leaves an output stream open.
4. The negative control unexpectedly passes.
5. A characterized behavior changes outside the two approved package-relative `lib/` fixtures.
6. A qualified ignore hides the second enabled diagnostic.
7. The combined consumer resolves a conflicting plugin graph or any `go_router` version other than `17.5.0`.
8. A publication dry run fails.
9. A published artifact fails fresh hosted verification.
10. The implementation would require a compatibility shim, shared framework, dependency override, wider public API break, or lower test standard.

## Final Handoff

Report the exact final commit SHA.
Report local, CI, IDE, package metadata, and hosted-consumer evidence separately.
Name any unexecuted external action.
Name the exact supported Flutter and Dart versions that the matrix proved.
Name the exact resolved `analysis_server_plugin`, `analyzer`, `analyzer_plugin`, and `go_router` versions.
If the migration remains blocked by issue #187999, report it as unpublished and leave `go_router_linter` on the legacy host.
