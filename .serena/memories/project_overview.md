# Project Overview

- Name: `custom_linters`
- Type: Dart/Flutter monorepo for custom lint plugins.
- Primary purpose: provide reusable custom lint rules for Flutter/Dart projects.
- Platform context: development is on Darwin (macOS).

## Main Packages

1. `packages/go_router_linter`

- Lints for `go_router` usage.
- Notable rules include:
  - `missing_go_route_name_property`
  - `use_context_directly_for_go_router`
  - `avoid_hardcoded_routes`

2. `packages/flutter_best_practices_lints`

- General Flutter code-organization lints.
- Notable rules include:
  - `single_class_per_file`
  - `matching_class_and_file_name`

## Tech Stack

- Language: Dart (`sdk: ^3.9.0`)
- Framework: Flutter (used for examples and test execution in monorepo scripts)
- Lint framework: `custom_lint_builder`
- Workspace management: Dart workspace + Melos
- Static analysis baseline: `very_good_analysis`
- CI: GitHub Actions (`.github/workflows/main.yaml`)
- Additional quality tooling: Trunk (`.trunk/trunk.yaml`)

## Repo-Level Notes

- Root package is not published (`publish_to: none`).
- Package versions are managed per package (`go_router_linter`, `flutter_best_practices_lints`).
- Examples exist under each package to demonstrate lints in real Flutter apps.
