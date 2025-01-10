# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
