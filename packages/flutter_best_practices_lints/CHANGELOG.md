# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 0.1.2+1 - 2025-01-16

### Changed

- **Module Paths & Run Configurations**: Updated run configurations and module paths for clarity and consistency, preventing unnecessary inspection of directories such as `test`.
- **isStateClass Logic Improvement**: Enhanced the check in `ClassDeclarationExtension` to validate that the target class actually extends Flutter’s `State` class by confirming the superclass element and its library URI.
- **State Class Adjustment**: Modified the sample `State` class to behave like a typical Flutter widget by changing it to an abstract class.

### Added

- **Example Classes for `State`**: Added additional example classes to demonstrate how the lint rules target `State` classes.

### Documentation

- **isStateClass Docs Update**: Updated documentation for the `isStateClass` getter to clarify its logic and usage.

## 0.1.1+1 - 2025-01-16

### Added

- **PascalCase Extension**: Added an extension for string transformation (converting snake_case to PascalCase) and updated the lint rule to utilize this extension.
- **Enhanced ClassDeclarationExtension**: Extended the extension to include a check for State class inheritance and added corresponding unit tests.
- **Documentation Assets**: Added static assets and additional documentation files for Flutter Best Practices Lints.
- **Example App**: Updated run configurations and added the Flutter Best Practices Lints example app.

### Changed

- **Dependency Updates**: Downgraded the analyzer and custom_lint_builder dependencies for compatibility.
- **Code Formatting**: Reformatted code in the PascalCaseExtension for improved readability.
- **README Updates**: Revised the README to include the new Flutter Best Practices Lints package and enhanced instructions.
- **Clarified Docs**: Clarified documentation for the MatchingClassAndFileName rule.

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
