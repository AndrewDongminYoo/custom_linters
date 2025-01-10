# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.1.0+1 - 2025-01-10

### Added

- **Linter Plugin**: Implemented the initial custom linter plugin with rules for class naming and single class per file.
- **Lint Rules**:
  - `matching_class_and_file_name`
  - `single_class_per_file`
- **Extensions**:
  - `ClassDeclarationExtension` for identifying `_State` classes, etc.
  - `LintCodeExtension` to support a `copyWith()` method for `LintCode`.
- **Analysis Options**: Updated to ignore `directives_ordering` errors and add a path dependency.
- **Example App**: Added a Flutter example application demonstrating how the custom lints work.
- **Core Package**: Created the **Flutter Best Practices Lints** package structure.
- **Refactor**: Renamed the primary linter class and plugin entrypoint for clarity.
- **README & Docs**: Enhanced package documentation with key features, usage instructions, and examples.
  - Detailed lint rules and usage examples in the main README.
  - Expanded example app README with step-by-step usage instructions.
- **Example Lint Trigger**: Added initial tests in the example app to confirm lint detection and reporting behaviors.
