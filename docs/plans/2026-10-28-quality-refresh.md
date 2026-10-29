# Quality Tooling Refresh Plan

## Work

1. Preserve the reviewed inherited SDK-floor edits and verify repository, account and Oracle evidence.
   Verify: exact root, origin, current status and inherited baseline receipt.
2. Update compatible dependency constraints, existing quality configuration and CI SDK alignment.
   Verify: primary package metadata, official Flutter tag and effective Trunk configuration.
3. Regenerate the existing lockfile and run the declared gates after the root grants the single heavy-job slot.
   Verify: Flutter Pub resolution, enforced lockfile, analysis, tests and standalone plugin diagnostics.
4. Prove the security and spelling readers with temporary negative controls, then run the full no-fix Trunk scan.
   Verify: intentional violations fail with the expected reader output and clean reruns pass.
5. Correct verified documentation drift and review the scoped candidate.
   Verify: documented paths, symbols, commands, internal links and `git diff --check`.
6. Commit locally through the root and prepare visible evidence before requesting publication approval.
   Verify: explicit staged paths, independent review and the final local receipt.

## Resource Boundary

Preparation may read metadata and edit the owned manifests, quality configuration, workflow and documentation.
Package resolution, analyzer runs, tests, consumer harness execution and full scans wait for the root's explicit heavy-job slot.
Run heavy jobs sequentially and recheck machine load before starting.
Do not update the global SDK, touch device state or run broad `dart fix` commands.

## Declared Gates

- `flutter pub upgrade`
- `flutter pub get --enforce-lockfile`
- `dart run melos bootstrap`
- `dart run melos run analyze`
- `dart analyze .`
- `dart run melos run test:ci`
- `dart test test/tool/analyzer_plugin_harness_test.dart`
- `dart run tool/verify_analyzer_plugins.dart --plugin all --source local --analyzer dart --repeat 3`
- `dart format --output=none --set-exit-if-changed tool test/tool packages/flutter_best_practices_lints/lib packages/flutter_best_practices_lints/test packages/flutter_best_practices_lints/example/lib packages/go_router_linter/lib packages/go_router_linter/test packages/go_router_linter/example/lib`
- Configured CSpell and offline TruffleHog negative and positive controls on explicitly owned temporary content
- `python3 -B .trunk/configs/tests/test_trufflehog_to_sarif.py`
- Direct OSV scan of the generated `pubspec.lock` when a scanner advisory needs diagnosis
- `trunk check --all --no-fix --jobs=2`
- `git diff --check`

## Preparation Checkpoint

The inherited SDK floor is preserved.
Melos is the only direct dependency with a newer stable release in the metadata read.
Existing linter pins already match the supplied latest-version matrix.
The current local changes add CSpell `10.4.0`, raise its Trunk-only Node runtime, preserve offline TruffleHog scanning, align CI with Flutter `3.47.8` and the root CSpell configuration, and correct stale active architecture and test guidance.
The generated lockfile now refreshes Melos, crypto and vector_math.
Keep platform at `3.1.6` because Melos `8.10.0` requires `<3.2.0`, and material_color_utilities at `0.13.0` because the installed Flutter SDK pins it exactly.
Do not force either dependency past its consumer constraint.

## Execution Checkpoint

The frozen workspace install, bootstrap, package and root analysis, package tests and harness unit tests passed.
Analysis reports informational diagnostics in unchanged source; a successful exit does not mean zero diagnostics.
The standalone consumer harness rejected its intentional missing-code control before passing all declared Dart analyzer repetitions and scenarios.
Actual encoded and literal controls were blocked by configured Trunk scanning, while clean content passed.
The local reader and its regression tests are included in the scanner sandbox and primary CI job.
Checkov `3.4.0` was published during execution and verified against official PyPI metadata before updating its pin.
The remaining full quality scan, knowledge audit and independent review must pass before a publication request.
