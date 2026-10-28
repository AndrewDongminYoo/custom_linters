# Quality Tooling Refresh

## Approved Scope

Refresh supported dependencies and existing quality tooling.
Preserve public APIs, generated artifacts and repository-specific boundaries.
Keep published package versions and the official `analysis_server_plugin` architecture unchanged.
The five existing Dart SDK constraints of `^3.13.7` and matching root lockfile floor were inherited, reviewed changes with unknown authorship.
Preserve and disclose that baseline.
Allow native Dart formatting on the two files rejected by the declared format gates, with canonical analyzer AST equality and negative controls before accepting those changes.

## Dependency and Runtime Baseline

- Refresh Melos from `^8.9.0` to `^8.10.0` and regenerate the existing root `pubspec.lock` with Flutter Pub.
- Pub.dev metadata already reports the existing direct versions of `analysis_server_plugin`, `analyzer`, `analyzer_testing`, `test`, `test_reflective_loader`, `very_good_analysis`, `pubspec_parse`, `go_router` and `flutter_lints` as latest stable.
- Flutter `3.47.8` includes Dart `3.13.7` in the installed SDK metadata.
  The official `flutter/flutter` tag points to the same framework revision, `737ba8f885dc774b53b442759999a312c9461e4e`.
- Use Trunk-managed Node `22.23.4` because CSpell `10.4.0` requires Node `>=22.18.0` and the prior runtime was `22.16.0`.
- Preserve current linter pins and refresh Checkov to `3.4.0`, published during execution.
  Keep Pinact `4.1.1!` with both `lint` and `upgrade` commands.
- Use the existing root `cspell.json` for local and hosted Markdown checks.
- Keep TruffleHog credential verification and self-update disabled with `--no-verification --no-update`.
  Use the local filesystem SARIF reader, include it through `direct_configs`, and run its independent standard-library tests in CI.
- Preserve platform `3.1.6` under Melos's `<3.2.0` range and material_color_utilities `0.13.0` under Flutter's exact pin.

## Acceptance

- Pinact remains locked to `4.1.1` with `lint` and `upgrade`.
- The full no-fix Trunk scan and declared project gates pass.
- Changed manifests have package-manager-generated lockfiles under repository policy.
- Advisory dispositions have specific evidence and affected knowledge claims are reconciled.
- Package analysis and unit tests pass with the generated dependency graph.
- The standalone harness reports the expected diagnostic code, severity, complete message, path, line and column for violating fixtures.
- The standalone harness also verifies compliant code, a disabled rule and a package-qualified ignore across three Dart analyzer repetitions.
- Temporary negative controls make the configured CSpell and offline secret-scanner readers fail before their positive checks are trusted.
- Package and example README SDK requirements match the inherited manifest floor; historical migration tables remain clearly identified as historical evidence.
- Flutter analyzer and other-OS release compatibility remain unverified by the local Dart analyzer gate.

## Relevant Oracle Precedent

The personal `custom_linters` retrieval used source commit `9670d54de3076c5239713f54900c7a855bd18478` with freshness marked unverified.
`wiki/entities/custom-linters.md` records that official plugin discovery can silently miss diagnostics, nested examples intentionally omit plugins, and an independent consumer harness covers diagnostic matching, disabled rules, qualified ignores, timeouts and repetitions.
This confirms that package analysis alone cannot prove registration and that the existing disposable consumer harness remains a required gate.
The same source records a prior gap between disabled local CSpell and hosted spelling checks, which motivates a shared configured reader with real negative and positive controls.

`wiki/entities/dart-analyzer.md`, `raw/sources/custom_linters/CLAUDE.md` and `wiki/concepts/custom-lint-builder-rule-pattern.md` contain historical analyzer API and `custom_lint_builder` guidance.
Current manifests and source supersede that historical architecture, so the refresh corrects active documentation without restoring it.
The old serial AOT workaround is retired.
No SDK-floor-specific precedent was found by the scoped retrieval.

## Verification Sources

- [Pub.dev package metadata](https://pub.dev/api/packages/melos) identifies the Melos release and its SDK constraint.
- [Official Flutter tag](https://api.github.com/repos/flutter/flutter/git/ref/tags/3.47.8) identifies the framework revision.
- [Official Node release index](https://nodejs.org/dist/index.json) identifies the latest Node 22 patch.
- [CSpell package metadata](https://registry.npmjs.org/cspell/latest) identifies its Node requirement.

The installed SDK metadata was read from `<flutter-sdk>/bin/cache/flutter.version.json`.
The Flutter wrapper has not been run at the preparation checkpoint.

## Publication

Push and PR creation require explicit repository-specific approval.
After approval, continue the requested hosted gates, merge, cleanup and memory recording.
