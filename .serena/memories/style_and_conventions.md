# Style and Conventions

## Baseline

- Analyzer config includes `package:very_good_analysis/analysis_options.yaml`.
- Some analyzer rules are explicitly ignored at project/package level:
  - `directives_ordering`
  - `document_ignores`
  - `lines_longer_than_80_chars`

## Code Organization

- Lint rules are implemented as separate files under `lib/src/rules/`.
- Shared helper logic goes under `lib/src/extensions/`.
- Plugin file registers all lint rules via `getLintRules(CustomLintConfigs configs)`.

## Naming Patterns

- Lint code identifiers use `snake_case` (e.g. `single_class_per_file`).
- Class names use `PascalCase`.
- File names use `snake_case.dart`.
- Tests commonly mirror source path names under `test/src/...`.

## Import Conventions (observed)

- Imports are grouped with comment headers in many files:
  - package imports
  - project imports
- Keep imports explicit and predictable by module responsibility.

## Documentation/Comments

- Public APIs and plugin entrypoints are documented with `///` doc comments.
- Rule docs in README files include behavior, lint code, and good/bad examples.

## Monorepo Conventions

- Use Melos scripts from root for cross-package operations.
- Keep package READMEs and CHANGELOGs updated when rules/behavior change.
