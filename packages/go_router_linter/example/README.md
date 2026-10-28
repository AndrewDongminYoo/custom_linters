# Go Router Linter Example

This Flutter app contains source patterns used to demonstrate the five `go_router_linter` diagnostics with the `go_router` dependency declared in its `pubspec.yaml`.
It is an inner package in this repository's pub workspace, so its committed `analysis_options.yaml` intentionally does not contain a top-level `plugins:` block.

## Requirements

- Dart `>=3.13.7 <4.0.0`.
- A compatible stable Flutter SDK.
- `go_router ^18.1.1`, as declared in this example.

## Run the App

```bash
flutter pub get
flutter run
```

## Verify the Plugin Host

Run the standalone consumer harness from the repository root.
The harness creates a temporary consumer outside the workspace, adds the official plugin configuration at that consumer's root, and checks violating, compliant, disabled, and plugin-qualified-ignore scenarios.
That consumer independently pins `go_router 17.5.0`; its evidence does not establish a wider supported version range.

```bash
dart run tool/verify_analyzer_plugins.dart --plugin go_router_linter --source local --analyzer dart --repeat 3
```

The demonstration source covers `missing_go_route_name_property`, `use_context_directly_for_go_router`, `avoid_hardcoded_routes`, `avoid_navigator_named_routes_with_go_router`, and `missing_go_router_error_handler`.

## License

This example is distributed under the package's MIT License.
See [LICENSE](../LICENSE).
