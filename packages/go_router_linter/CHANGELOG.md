# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.5.0 - Unreleased

### Changed

- **Breaking:** Replaced the `custom_lint` host with Dart's official `analysis_server_plugin` host.
- **Breaking:** Replaced the legacy `analyzer.plugins` and `custom_lint.rules` configuration with a top-level `plugins:` block.
- **Breaking:** Diagnostics now require explicit activation under the plugin's `diagnostics:` map.
- **Breaking:** Raised the minimum Dart SDK to `3.11.0` and moved to `analyzer >=14.3.0 <15.0.0` with `analysis_server_plugin >=0.3.22 <0.4.0`.
- **Breaking:** Removed the legacy `createPlugin()` entrypoint and `LintCodeCopyWithExtension` API.
- Moved `pubspec_parse` to runtime dependencies so `avoid_navigator_named_routes_with_go_router` can inspect the owning package's manifest.
- Preserved the five raw diagnostic codes, `INFO` severity, public rule class names, zero-argument constructors, and characterized rule behavior.
- Replaced legacy rule tests with `AnalysisRuleTest` coverage and added a standalone consumer harness for the real analyzer host.

### Compatibility evidence

The only locally tested Flutter stable release is `3.47.2`, so it is both the oldest tested and current tested release.
The minimum supported Flutter stable release is not established.
The tested dependency family resolves `analysis_server_plugin 0.3.22`, `analyzer 14.3.0`, and `analyzer_plugin 0.14.16`.
The standalone consumer pins and resolves `go_router 17.5.0`.
This tested version does not imply compatibility with a wider `go_router` range.

| Operating system   | Flutter stable | Bundled Dart | `dart analyze` | `flutter analyze` |
| ------------------ | -------------- | ------------ | -------------- | ----------------- |
| macOS 26.6.2 arm64 | 3.47.2         | 3.13.2       | Passed locally | Blocked #187999   |
| macOS              | 3.44.0         | Not recorded | Not run        | Not run           |
| Linux              | 3.47.2         | Not recorded | Not run        | Not run           |
| Linux              | 3.44.0         | Not recorded | Not run        | Not run           |
| Windows            | 3.47.2         | Not recorded | Not run        | Not run           |
| Windows            | 3.44.0         | Not recorded | Not run        | Not run           |

Publication remains blocked while Flutter issue [#187999](https://github.com/flutter/flutter/issues/187999) reproduces and while the remaining operating-system and SDK lanes are unverified.
The GitHub Actions matrix has been authored but not dispatched.
Consumers that need the legacy host must stay on `0.4.x`.

## 0.4.0 - 2026-05-23

### Added

- Added `missing_go_router_error_handler` to warn when `GoRouter` is constructed without an `errorBuilder` or `errorPageBuilder`.
- Extended `avoid_hardcoded_routes` to report hardcoded `initialLocation` strings in `GoRouter` constructors.

## 0.3.0 - 2026-05-23

### Added

- Added `avoid_navigator_named_routes_with_go_router` to discourage
  `Navigator.*Named` APIs when the analyzed project depends on `go_router`.
- Added behavior tests for strengthened and new go_router lint rules.

### Changed

- Expanded `use_context_directly_for_go_router` to cover current GoRouterHelper
  methods such as `namedLocation`, `canPop`, and `pop`, while ignoring unrelated
  `GoRouter.of(context)` access.
- Updated `avoid_hardcoded_routes` to check route identifier arguments only and
  to report hardcoded redirect callback return strings.
- Updated README, examples, and package docs for the current rule set.

## 0.2.0 - 2026-02-09

### Changed

- **Breaking**: Upgraded minimum Dart SDK to ^3.9.0
- Updated `analyzer` dependency to ^8.4.0
- Updated `custom_lint_builder` dependency to ^0.8.1
- Configured workspace resolution for monorepo support

### Fixed

- Suppressed `discarded_futures` lint warning

## 0.1.9 - 2025-01-10

### Changed

- update dependencies for `go_router_linter` and `melos`
- remove overridden dependencies

## 0.1.8 - 2024-12-24

### Changed

- fix: 📌 force upgrade the version of `analyzer` by adding a `dependency_overrides` section

## 0.1.7 - 2024-12-24

### Changed

- fix: ⬆️ upgrade dart pub dependencies

## 0.1.6 - 2024-12-18

### Added

- test: 🧪 add an extension method test case
- docs: 📝 update HTML documents generated with `dart doc`

### Changed

- refactor: ♻️ change folder structure and adding document comments

## 0.1.5 - 2024-12-11

### Added

- added a rule to prevent hardcoded strings from being used as URLs in go_router

### Fixed

- 📝 updating documentation for new lint rules

### Changed

- upgrade example flutter project dependencies
- upgrade test package
- separate directories for dart files by purpose
- ⚡️ modify rule to prevent hardcoded URLs from being used even when using GoRouter
- ⚡️ added string helper methods to support other routing functions

## 0.1.4 - 2024-12-03

### Added

- added new linter: declare `name` attribute when using GoRoute

## 0.1.3+1 - 2024-11-21

### Added

- add example application

### Fixed

- fixed tests

## 0.1.2+1 - 2024-11-21

### Added

- add documentation and format source codes

## 0.1.0+1 - 2024-11-19

### Added

- add GoRouter.of(context) usage restriction lint
