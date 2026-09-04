# Analysis Server Plugin Migration Evidence

## Current Decision

**Result:** Both official-host release candidates are implemented locally, and publication remains blocked.
On 2026-09-04, the operator approved one dependency-consistent migration of both workspace packages after the Phase 0 failure proved that an intermediate mixed analyzer-family state cannot resolve.
This approval covered implementation only.
It did not authorize push, merge, tag, workflow dispatch, or publication.

The combined standalone consumer passes through `dart analyze` and still fails through `flutter analyze` because [Flutter issue #187999](https://github.com/flutter/flutter/issues/187999) omits official plugin diagnostics.
The project must not publish either release candidate until every required Flutter lane passes and the remaining release gates close.

## Current Release Candidate

| Item                            | Value                |
| ------------------------------- | -------------------- |
| `flutter_best_practices_lints`  | `0.6.0`              |
| `go_router_linter`              | `0.5.0`              |
| Dart SDK constraint             | `>=3.11.0 <4.0.0`    |
| Local Flutter                   | `3.47.2` stable      |
| Local Dart                      | `3.13.2`             |
| Host operating system           | macOS `26.6.2` arm64 |
| `analysis_server_plugin`        | `0.3.22`             |
| `analyzer`                      | `14.3.0`             |
| `analyzer_plugin`               | `0.14.16`            |
| `analyzer_testing`              | `0.4.1`              |
| `test_reflective_loader`        | `0.4.0`              |
| Standalone consumer `go_router` | `17.5.0`             |

The resolved workspace graph contains no `custom_lint`, `custom_lint_builder`, `custom_lint_core`, or `custom_lint_visitor` package.
Both packages expose `lib/main.dart`, use one official `Plugin`, register five `AnalysisRule` instances, and define one static `LintCode` per rule.
The nested workspace examples contain no legacy host configuration and no top-level official `plugins:` block.

## Current Local Verification

The following checks passed on the release-candidate working tree:

- `dart format` reported no changes for package source, tests, examples, root harness source, and root harness tests.
- `dart run melos run format:ci` checked all four workspace packages.
- `dart run melos run analyze` ran serialized `dart analyze .` commands for all four workspace packages with no issues.
- Root `dart analyze .` completed with no issues.
- Package-local `flutter analyze --no-pub .` completed with no issues for both lint packages.
- `flutter_best_practices_lints` completed 45 tests with one pre-existing syntactic-parser skip.
- `go_router_linter` completed 25 tests, including owning-package isolation in both dependency orderings.
- The root harness suite completed 22 tests, including parser corruption controls, timeout process-tree cleanup, fixture isolation, and the exact negative-control prefix.
- `dart doc --validate-links` documented two public libraries in each package with zero warnings and zero errors.
- Scoped Trunk formatting removed generator whitespace, and clean staging plus `rsync --delete` removed stale legacy API pages.
- Scoped Trunk checks passed for the workflow and all changed Markdown documentation.

The initial publication dry runs exited successfully but reported expected dirty-working-tree warnings and references to tracked files that this migration deletes.
After the code and package-documentation commits, `dart pub publish --dry-run` completed for `flutter_best_practices_lints 0.6.0` and `go_router_linter 0.5.0` with `Package has 0 warnings.`
These dry runs close the local package-validation gate but do not authorize or complete publication.

## Current Harness Negative Control

The final negative-control invocation stopped at the first violating analyzer process with exit code `1` and the required synthetic failure:

```log
HARNESS_ASSERTION_FAILED: missing diagnostic __negative_control_missing_code__ at lib/single_class_per_file.dart:4:1
```

The same captured output contained all ten real raw diagnostic codes.

## Current Combined Dart Host Result

This command passed three complete repetitions:

```bash
dart run tool/verify_analyzer_plugins.dart --plugin all --source local --analyzer dart --repeat 3
```

Each repetition ran violating, compliant, disabled-rule, and qualified-ignore scenarios in that order.
The qualified-ignore scenario suppresses one occurrence and preserves a second occurrence for every one of the ten rules.

| Repetition | Scenario         | Exit | Duration | Diagnostics |
| ---------- | ---------------- | ---: | -------: | ----------: |
| 1          | Violating        |    1 | 23.302 s |          10 |
| 1          | Compliant        |    0 |  7.566 s |           0 |
| 1          | Disabled rule    |    0 |  2.554 s |           0 |
| 1          | Qualified ignore |    1 |  8.349 s |          10 |
| 2          | Violating        |    1 |  6.552 s |          10 |
| 2          | Compliant        |    0 |  8.819 s |           0 |
| 2          | Disabled rule    |    0 |  1.803 s |           0 |
| 2          | Qualified ignore |    1 |  6.827 s |          10 |
| 3          | Violating        |    1 |  7.699 s |          10 |
| 3          | Compliant        |    0 |  6.707 s |           0 |
| 3          | Disabled rule    |    0 |  1.614 s |           0 |
| 3          | Qualified ignore |    1 |  7.584 s |          10 |

The slowest successful positive cold process took `23.302` seconds.
The committed timeout is `max(120, ceil(3 * 23.302)) = 120` seconds.

## Current Combined Flutter Host Failure

The release-candidate graph reproduced issue #187999 with this command:

```bash
dart run tool/verify_analyzer_plugins.dart --plugin all --source local --analyzer flutter --repeat 1
```

The first violating process took `21.144` seconds, returned exit code `0`, and omitted the expected `single_class_per_file` diagnostic:

```log
HARNESS_PROCESS: command="flutter analyze --fatal-infos --fatal-warnings ." analyzer=flutter repetition=1 scenario=violating exit=0 elapsed_ms=21144
HARNESS_ASSERTION_FAILED: missing diagnostic single_class_per_file at lib/single_class_per_file.dart:4:1
Analyzing consumer...
No issues found! (ran in 20.2s)
```

This remains a publication blocker and is not a passing gate.

## Current Unexecuted Gates

- `[PARTIAL]` The GitHub Actions compatibility matrix has been authored but not dispatched.
- `[PARTIAL]` Flutter `3.44.0`, Linux, and Windows have not been verified in this local session.
- `[PARTIAL]` The IDE smoke test has not run because the command-line Flutter host gate fails first.
- `[PARTIAL]` Hosted-source verification cannot run because neither release candidate is published.
- `[PARTIAL]` Push, merge, tag, workflow dispatch, and publication were not authorized or executed.

## Phase 0 Scope Correction

The planned production-package side-by-side probe could not resolve in the current Dart workspace.
Candidate A requires analyzer `>=14.3.0 <15.0.0`, while `go_router_linter` still requires analyzer `^8.4.0` and `custom_lint_builder 0.8.1` itself requires analyzer `^8.0.0` plus `analyzer_plugin ^0.13.0`.
The workspace resolver stopped before any production code changed:

```log
Because go_router_linter depends on analyzer ^8.4.0 and flutter_best_practices_lints depends on analyzer ^14.3.0, version solving failed.
```

Candidate B also requires analyzer `14.x`, so it cannot resolve this workspace transition conflict.
The probe therefore used a disposable plugin package under `/tmp/custom_linters_phase0_probe.vuREtC`, outside the workspace, with Candidate A and the same required `lib/main.dart` shape.
This isolated probe proves the official host behavior and publication blocker, but it does not claim that the production package manifest can resolve beside the legacy workspace members.
The production manifest was restored immediately after the failed resolver attempt.
After evidence capture, the 57 MB disposable probe directory was moved to Trash and remains recoverable until Trash is emptied.

The planned `flutter test` command is also incompatible with `test_reflective_loader 0.4.0` because Flutter's test platform does not provide `dart:mirrors`.
The official rule test ran through `dart test`, while the actual Flutter command path remained covered by the standalone `flutter analyze` process.

## Phase 0 Environment

- Repository commit before the evidence note: `ab60f329a999cf21603b23ccc9a6ba738182e72a`.
- Host: macOS `26.6.2` build `25G83`, arm64.
- Flutter: `3.47.2` stable, framework revision `d3b14c8769`.
- Dart: `3.13.2`.
- Plugin source: absolute local path to the disposable package.
- Selected diagnostic: `prefer_media_query_partial_methods`.

## Phase 0 Resolved Candidate A Unit

```log
analysis_server_plugin=0.3.22
analyzer=14.3.0
analyzer_plugin=0.14.16
analyzer_testing=0.4.1
test_reflective_loader=0.4.0
```

The disposable package used a static `LintCode`, a single `AnalysisRule`, `addPropertyAccess`, `reportAtNode`, a top-level `plugin`, and `registerLintRule`.
It implemented only the approved `MediaQuery.of(context).size` branch and used the static correction template `Use {0} instead.`.

## Phase 0 Rule Test Evidence

The initial test failed because the probe rule did not exist.
The same `flutter test` attempt also exposed the unsupported `dart:mirrors` runner combination.
After implementing the rule, the VM test passed both the positive `MediaQuery.of(context).size` case and the negative `MediaQuery.sizeOf(context)` case:

```bash
dart test test/src/phase0/prefer_media_query_partial_methods_probe_test.dart
```

```log
00:00 +2: All tests passed!
```

Static analysis of the disposable package also passed:

```bash
dart analyze .
```

```log
Analyzing ....
No issues found!
```

## Phase 0 Harness Negative Control

The integration negative control ran before the accepted analyzer result.
It stopped after the first analyzer process with exit code `1` and the required prefix:

```log
HARNESS_ASSERTION_FAILED: missing diagnostic __negative_control_missing_code__ at lib/prefer_media_query_partial_methods.dart:4:3
```

The captured analyzer output still contained the real raw diagnostic, which proves that the failure came from the deliberately impossible expectation.

## Phase 0 Dart Analyzer Result

This command passed three complete repetitions:

```bash
dart run tool/verify_analyzer_plugins.dart --plugin flutter_best_practices_lints --diagnostic prefer_media_query_partial_methods --source local --analyzer dart --repeat 3 --timeout-seconds 600
```

Each repetition ran the positive, compliant, disabled-rule, and plugin-qualified-ignore scenarios in that order.
All 12 analyzer processes matched the expected raw code, `INFO` severity, complete rendered problem and correction text, relative file, line, column, and exit status.

| Repetition | Scenario         | Exit | Duration | Diagnostics |
| ---------- | ---------------- | ---: | -------: | ----------: |
| 1          | Violating        |    1 | 19.189 s |           1 |
| 1          | Compliant        |    0 |  3.529 s |           0 |
| 1          | Disabled rule    |    0 |  4.223 s |           0 |
| 1          | Qualified ignore |    1 |  3.898 s |           1 |
| 2          | Violating        |    1 |  5.083 s |           1 |
| 2          | Compliant        |    0 |  4.674 s |           0 |
| 2          | Disabled rule    |    0 |  5.554 s |           0 |
| 2          | Qualified ignore |    1 |  4.211 s |           1 |
| 3          | Violating        |    1 |  3.776 s |           1 |
| 3          | Compliant        |    0 |  3.854 s |           0 |
| 3          | Disabled rule    |    0 |  3.602 s |           0 |
| 3          | Qualified ignore |    1 |  3.688 s |           1 |

The first complete successful cold invocation took `22.882` seconds for its positive process.
The provisional local Dart timeout calculation is `max(120, ceil(3 * 22.882)) = 120` seconds.
This is not the production timeout because no Flutter analyzer lane completed successfully and the required operating-system matrix did not run.

## Phase 0 Flutter Analyzer Failure

This command stopped on the first positive scenario, as required:

```bash
dart run tool/verify_analyzer_plugins.dart --plugin flutter_best_practices_lints --diagnostic prefer_media_query_partial_methods --source local --analyzer flutter --repeat 3 --timeout-seconds 600
```

The analyzer process took `19.292` seconds, returned exit code `0`, and omitted the expected diagnostic:

```log
HARNESS_PROCESS: command="flutter analyze --fatal-infos --fatal-warnings ." analyzer=flutter repetition=1 scenario=violating exit=0 elapsed_ms=19292
HARNESS_ASSERTION_FAILED: missing diagnostic prefer_media_query_partial_methods at lib/prefer_media_query_partial_methods.dart:4:3
Analyzing consumer...
No issues found! (ran in 18.1s)
```

This result fails AC-012 and AC-016.
The local `dart analyze` success prevents classifying the result as a rule implementation, plugin-load, dependency-resolution, parser, crash, or timeout failure.

## Phase 0 Gates Not Run After the Hard Failure

- `[PARTIAL]` Flutter `3.44.0`, Linux, and Windows lanes did not run because the current local supported lane already met the specification's stop condition.
- `[PARTIAL]` The IDE smoke test did not run because Phase 0 did not pass its command-line host gate.
- `[PARTIAL]` Hosted-source verification did not run because no package was published or approved for publication.
- `[PARTIAL]` The production timeout was not finalized.
- `[PARTIAL]` The production Flutter package probe commit, compatibility workflow, full Flutter migration, and go_router tranche did not start.

## Phase 0 Plan Refinement That Enabled Resumption

The current single-resolution Dart workspace cannot hold Candidate A or B beside any legacy `custom_lint` member.
A resumed implementation must replace the invalid side-by-side transition with one dependency-consistent tranche.
The recommended direction is an atomic current-family migration of all workspace members on a branch, while preserving the release gate that publishes and verifies `flutter_best_practices_lints` before any `go_router_linter` publication.
Do not use an obsolete official-host family or a forced dependency override to mask the incompatibility.
The 2026-09-04 approval changed the implementation sequencing policy and allowed the dependency-consistent local migration to proceed.
It did not relax the `flutter analyze` publication blocker.
