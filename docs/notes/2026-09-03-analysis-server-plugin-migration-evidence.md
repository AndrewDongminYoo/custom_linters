# Analysis Server Plugin Phase 0 Evidence

## Decision

**Result:** Phase 0 failed on 2026-09-04, and publication remains blocked.
The local Flutter `3.47.2` lane reproduced [Flutter issue #187999](https://github.com/flutter/flutter/issues/187999): `dart analyze` reported the official plugin diagnostic, while `flutter analyze` returned exit code `0` and `No issues found!` for the same positive source.
Task 5 did not start.
No package version, production plugin entrypoint, release documentation, CI workflow, tag, or publication changed.

## Scope Correction

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

## Environment

- Repository commit before the evidence note: `ab60f329a999cf21603b23ccc9a6ba738182e72a`.
- Host: macOS `26.6.2` build `25G83`, arm64.
- Flutter: `3.47.2` stable, framework revision `d3b14c8769`.
- Dart: `3.13.2`.
- Plugin source: absolute local path to the disposable package.
- Selected diagnostic: `prefer_media_query_partial_methods`.

## Resolved Candidate A Unit

```log
analysis_server_plugin=0.3.22
analyzer=14.3.0
analyzer_plugin=0.14.16
analyzer_testing=0.4.1
test_reflective_loader=0.4.0
```

The disposable package used a static `LintCode`, a single `AnalysisRule`, `addPropertyAccess`, `reportAtNode`, a top-level `plugin`, and `registerLintRule`.
It implemented only the approved `MediaQuery.of(context).size` branch and used the static correction template `Use {0} instead.`.

## Rule Test Evidence

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

## Harness Negative Control

The integration negative control ran before the accepted analyzer result.
It stopped after the first analyzer process with exit code `1` and the required prefix:

```log
HARNESS_ASSERTION_FAILED: missing diagnostic __negative_control_missing_code__ at lib/prefer_media_query_partial_methods.dart:4:3
```

The captured analyzer output still contained the real raw diagnostic, which proves that the failure came from the deliberately impossible expectation.

## Dart Analyzer Result

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

## Flutter Analyzer Failure

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

## Gates Not Run After the Hard Failure

- `[PARTIAL]` Flutter `3.44.0`, Linux, and Windows lanes did not run because the current local supported lane already met the specification's stop condition.
- `[PARTIAL]` The IDE smoke test did not run because Phase 0 did not pass its command-line host gate.
- `[PARTIAL]` Hosted-source verification did not run because no package was published or approved for publication.
- `[PARTIAL]` The production timeout was not finalized.
- `[PARTIAL]` The production Flutter package probe commit, compatibility workflow, full Flutter migration, and go_router tranche did not start.

## Required Plan Refinement Before Resumption

The current single-resolution Dart workspace cannot hold Candidate A or B beside any legacy `custom_lint` member.
A resumed implementation must replace the invalid side-by-side transition with one dependency-consistent tranche.
The recommended direction is an atomic current-family migration of all workspace members on a branch, while preserving the release gate that publishes and verifies `flutter_best_practices_lints` before any `go_router_linter` publication.
Do not use an obsolete official-host family or a forced dependency override to mask the incompatibility.
Resume production migration only after the `flutter analyze` omission is fixed or the publication policy is explicitly changed.
