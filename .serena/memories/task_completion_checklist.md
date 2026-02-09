# Task Completion Checklist

Use this checklist before finalizing code changes.

## Minimum Validation

1. Ensure dependencies/workspace are ready:

- `melos bootstrap`

2. Verify formatting:

- `melos run format:ci`

3. Run analyzer:

- `melos analyze`

4. Run tests:

- `melos run test` (or `melos run test:ci` when coverage/concurrency parity is desired)

## Scope-Specific Validation

- If only one package changed, also run targeted checks in that package:
  - `dart analyze`
  - `dart test`

- If rule behavior changed, update docs/examples as needed:
  - package `README.md`
  - package `CHANGELOG.md`
  - example app snippets where relevant

## CI Alignment

Current CI workflow (`.github/workflows/main.yaml`) verifies:

- formatting (`melos run format:ci`)
- analysis (`melos analyze`)
- tests (`melos run test:ci`)

Local completion should be aligned with these checks before submitting PRs.
