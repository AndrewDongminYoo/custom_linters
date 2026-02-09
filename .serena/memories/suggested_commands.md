# Suggested Commands

## Core Monorepo Commands (run at repo root)

```bash
# install/link workspace packages
melos bootstrap

# format + auto-fix all packages
melos run format

# format check for CI
melos run format:ci

# analyze all packages
melos analyze

# run tests
melos run test

# run tests with coverage/concurrency settings for CI
melos run test:ci

# generate build_runner outputs where applicable
melos run generate
```

## Per-Package Commands

```bash
cd packages/go_router_linter
# or
cd packages/flutter_best_practices_lints

dart pub get
dart analyze
dart test
dart format .
dart fix --apply
```

## Example App Entrypoints

```bash
# go_router_linter example
cd packages/go_router_linter/example
flutter pub get
flutter run
dart run custom_lint

# flutter_best_practices_lints example
cd packages/flutter_best_practices_lints/example
flutter pub get
flutter run
dart run custom_lint
```

## CI-Equivalent Local Check Sequence

```bash
melos bootstrap
melos run format:ci
melos analyze
melos run test:ci
```

## Trunk (if installed)

```bash
trunk fmt --all
trunk check --fix --all
trunk check --all
```

## Useful Darwin/macOS Shell Commands

```bash
# filesystem/navigation
ls -la
cd <dir>
find . -name "*.dart"
rg "pattern" .

# git
git status
git diff
git add -p
git commit -m "<message>"

# macOS helpers
open .
pbcopy < file.txt
sed -i '' 's/old/new/g' file.txt
```

Notes:

- Prefer `rg` over `grep` for speed when searching.
- Some scripts/CI steps assume `flutter` is available, even for lint package tests.
