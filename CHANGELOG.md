# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

- Migrated both lint packages from `custom_lint` to Dart's official analyzer plugin host.
- Added a standalone consumer harness for exact diagnostics, disabled rules, qualified ignores, timeouts, and repeated analyzer runs.
- Kept publication blocked while the required `flutter analyze` compatibility lane reproduces Flutter issue [#187999](https://github.com/flutter/flutter/issues/187999).

## 1.0.0

- Initial version.
