# Flutter Best Practices Lints

`flutter_best_practices_lints` provides opt-in analyzer diagnostics for Flutter project structure and widget usage.
Version `0.6.0` migrates the package from `custom_lint` to Dart's official analyzer plugin host.

## Requirements

- Dart `>=3.11.0 <4.0.0`.
- A stable Flutter SDK that includes a compatible Dart SDK.
- A top-level `analysis_options.yaml` in the consuming package or pub workspace.

The only locally tested Flutter stable release is `3.47.2`, so it is both the oldest tested and current tested release.
The minimum supported Flutter stable release is not established until the complete matrix passes.
The tested dependency family resolves `analysis_server_plugin 0.3.22`, `analyzer 14.3.0`, and `analyzer_plugin 0.14.16`.
Beta, dev, and master Flutter channels are unsupported.

The `0.6.0` release candidate is unpublished while Flutter issue [#187999](https://github.com/flutter/flutter/issues/187999) reproduces in the required `flutter analyze` lane.

## Compatibility evidence

The release matrix below separates local evidence from lanes that have not run.
`Blocked #187999` means that the command completed without reporting the expected plugin diagnostics.

| Operating system   | Flutter stable | Bundled Dart | Resolved official family                                                      | `dart analyze` | `flutter analyze` |
| ------------------ | -------------- | ------------ | ----------------------------------------------------------------------------- | -------------- | ----------------- |
| macOS 26.6.2 arm64 | 3.47.2         | 3.13.2       | `analysis_server_plugin 0.3.22`, `analyzer 14.3.0`, `analyzer_plugin 0.14.16` | Passed locally | Blocked #187999   |
| macOS              | 3.44.0         | Not recorded | Not resolved                                                                  | Not run        | Not run           |
| Linux              | 3.47.2         | Not recorded | Not resolved                                                                  | Not run        | Not run           |
| Linux              | 3.44.0         | Not recorded | Not resolved                                                                  | Not run        | Not run           |
| Windows            | 3.47.2         | Not recorded | Not resolved                                                                  | Not run        | Not run           |
| Windows            | 3.44.0         | Not recorded | Not resolved                                                                  | Not run        | Not run           |

The GitHub Actions matrix defines the unverified lanes, but it has not been dispatched.
No row other than the macOS `dart analyze` row is release evidence.

## Installation

Add the package as a development dependency:

```yaml
dev_dependencies:
  flutter_best_practices_lints: ^0.6.0
```

Add the plugin to the top-level `analysis_options.yaml` and enable each diagnostic explicitly:

```yaml
plugins:
  flutter_best_practices_lints:
    version: ^0.6.0
    diagnostics:
      matching_class_and_file_name: true
      single_class_per_file: true
      prefer_widget_class_over_widget_helper: true
      avoid_widget_operator_equals: true
      prefer_media_query_partial_methods: true
```

For local development, replace `version` with an absolute package path:

```yaml
plugins:
  flutter_best_practices_lints:
    path: /absolute/path/to/custom_linters/packages/flutter_best_practices_lints
    diagnostics:
      matching_class_and_file_name: true
      single_class_per_file: true
      prefer_widget_class_over_widget_helper: true
      avoid_widget_operator_equals: true
      prefer_media_query_partial_methods: true
```

The official host does not load a `plugins:` block from an inner package's nested analysis options file.
Place the block at the consumer package root or pub-workspace root.

All diagnostics use `INFO` severity and remain disabled until listed under `diagnostics:`.
Analyzer output shows the raw diagnostic code.
Use the plugin-qualified form only in suppression comments:

```dart
// ignore: flutter_best_practices_lints/prefer_media_query_partial_methods
final size = MediaQuery.of(context).size;
```

The package does not define rule-specific options.

## Rules

### `single_class_per_file`

Reports each additional public class in a `lib/` source file.
It preserves the direct abstract relationship and private Flutter `State` exceptions.

```dart
class FirstClass {}

class SecondClass {}
```

### `matching_class_and_file_name`

Checks that a primary class name matches its snake-case file name.
It preserves private-class, abstract-class, related-class, and private Flutter `State` handling.

```dart
// File: my_home_page.dart
class MyHomePage {}
```

### `prefer_widget_class_over_widget_helper`

Reports private `_build...` functions and methods whose declared return type is `Widget`.

```dart
Widget _buildHeader() => const Text('Header');
```

Extract the helper into a `StatelessWidget` or `StatefulWidget`.

### `avoid_widget_operator_equals`

Reports `operator ==` overrides declared on direct Flutter `Widget`, `StatelessWidget`, or `StatefulWidget` subclasses.

```dart
class MyButton extends StatelessWidget {
  const MyButton({super.key});

  @override
  bool operator ==(Object other) => other is MyButton;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
```

Remove the equality override and rely on normal widget identity.

### `prefer_media_query_partial_methods`

Reports supported `MediaQuery.of(context).property` expressions that have a dedicated static accessor.

```dart
final size = MediaQuery.of(context).size;
final padding = MediaQuery.of(context).padding;
```

Use the dedicated accessors:

```dart
final size = MediaQuery.sizeOf(context);
final padding = MediaQuery.paddingOf(context);
```

Supported accessors are `sizeOf`, `paddingOf`, `viewInsetsOf`, `viewPaddingOf`, `textScalerOf`, `devicePixelRatioOf`, `platformBrightnessOf`, `orientationOf`, `gestureSettingsOf`, `displayFeaturesOf`, `alwaysUse24HourFormatOf`, `accessibleNavigationOf`, `boldTextOf`, `disableAnimationsOf`, `highContrastOf`, and `invertColorsOf`.

## Development

Run the rule tests with the Dart VM because `test_reflective_loader` uses `dart:mirrors`:

```bash
dart test
dart analyze .
```

The workspace example intentionally does not enable `plugins:`.
Use the repository's standalone consumer harness for a real host check:

```bash
dart run tool/verify_analyzer_plugins.dart --plugin flutter_best_practices_lints --source local --analyzer dart --repeat 3
```

## License

This package is licensed under the MIT License.
See [LICENSE](https://github.com/AndrewDongminYoo/custom_linters/blob/main/packages/flutter_best_practices_lints/LICENSE).
