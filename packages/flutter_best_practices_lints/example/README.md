# Flutter Best Practices Lints Example

This Flutter app contains source patterns used to demonstrate the five `flutter_best_practices_lints` diagnostics.
It is an inner package in this repository's pub workspace, so its committed `analysis_options.yaml` intentionally does not contain a top-level `plugins:` block.

## Requirements

- Dart `>=3.11.0 <4.0.0`.
- A compatible stable Flutter SDK.

## Run the App

```bash
flutter pub get
flutter run
```

## Verify the Plugin Host

Run the standalone consumer harness from the repository root.
The harness creates a temporary consumer outside the workspace, adds the official plugin configuration at that consumer's root, and checks violating, compliant, disabled, and plugin-qualified-ignore scenarios.

```bash
dart run tool/verify_analyzer_plugins.dart --plugin flutter_best_practices_lints --source local --analyzer dart --repeat 3
```

The demonstration source covers `single_class_per_file`, `matching_class_and_file_name`, `prefer_widget_class_over_widget_helper`, `avoid_widget_operator_equals`, and `prefer_media_query_partial_methods`.

## License

This example is distributed under the package's MIT License.
See [LICENSE](../LICENSE).
