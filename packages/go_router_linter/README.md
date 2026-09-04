# Go Router Linter

`go_router_linter` provides opt-in analyzer diagnostics for route definitions and navigation calls that use `go_router`.
Version `0.5.0` migrates the package from `custom_lint` to Dart's official analyzer plugin host.

## Requirements

- Dart `>=3.11.0 <4.0.0`.
- A stable Flutter SDK that includes a compatible Dart SDK.
- A top-level `analysis_options.yaml` in the consuming package or pub workspace.

The only locally tested Flutter stable release is `3.47.2`, so it is both the oldest tested and current tested release.
The minimum supported Flutter stable release is not established until the complete matrix passes.
The tested dependency family resolves `analysis_server_plugin 0.3.22`, `analyzer 14.3.0`, and `analyzer_plugin 0.14.16`.
Beta, dev, and master Flutter channels are unsupported.

The standalone migration consumer pins `go_router 17.5.0`.
This evidence does not imply compatibility with a wider `go_router` range.
The `0.5.0` release candidate is unpublished while Flutter issue [#187999](https://github.com/flutter/flutter/issues/187999) reproduces in the required `flutter analyze` lane.

## Compatibility evidence

The release matrix below separates local evidence from lanes that have not run.
`Blocked #187999` means that the command completed without reporting the expected plugin diagnostics.

| Operating system   | Flutter stable | Bundled Dart | Resolved official family                                                      | `go_router`  | `dart analyze` | `flutter analyze` |
| ------------------ | -------------- | ------------ | ----------------------------------------------------------------------------- | ------------ | -------------- | ----------------- |
| macOS 26.6.2 arm64 | 3.47.2         | 3.13.2       | `analysis_server_plugin 0.3.22`, `analyzer 14.3.0`, `analyzer_plugin 0.14.16` | 17.5.0       | Passed locally | Blocked #187999   |
| macOS              | 3.44.0         | Not recorded | Not resolved                                                                  | Not resolved | Not run        | Not run           |
| Linux              | 3.47.2         | Not recorded | Not resolved                                                                  | Not resolved | Not run        | Not run           |
| Linux              | 3.44.0         | Not recorded | Not resolved                                                                  | Not resolved | Not run        | Not run           |
| Windows            | 3.47.2         | Not recorded | Not resolved                                                                  | Not resolved | Not run        | Not run           |
| Windows            | 3.44.0         | Not recorded | Not resolved                                                                  | Not resolved | Not run        | Not run           |

The GitHub Actions matrix defines the unverified lanes, but it has not been dispatched.
No row other than the macOS `dart analyze` row is release evidence.

## Installation

Add the package as a development dependency:

```yaml
dev_dependencies:
  go_router_linter: ^0.5.0
```

Add the plugin to the top-level `analysis_options.yaml` and enable each diagnostic explicitly:

```yaml
plugins:
  go_router_linter:
    version: ^0.5.0
    diagnostics:
      missing_go_route_name_property: true
      use_context_directly_for_go_router: true
      avoid_hardcoded_routes: true
      avoid_navigator_named_routes_with_go_router: true
      missing_go_router_error_handler: true
```

For local development, replace `version` with an absolute package path:

```yaml
plugins:
  go_router_linter:
    path: /absolute/path/to/custom_linters/packages/go_router_linter
    diagnostics:
      missing_go_route_name_property: true
      use_context_directly_for_go_router: true
      avoid_hardcoded_routes: true
      avoid_navigator_named_routes_with_go_router: true
      missing_go_router_error_handler: true
```

The official host does not load a `plugins:` block from an inner package's nested analysis options file.
Place the block at the consumer package root or pub-workspace root.

All diagnostics use `INFO` severity and remain disabled until listed under `diagnostics:`.
Analyzer output shows the raw diagnostic code.
Use the plugin-qualified form only in suppression comments:

```dart
// ignore: go_router_linter/avoid_hardcoded_routes
context.go('/home');
```

The package does not define rule-specific options.

## Rules

### `missing_go_route_name_property`

Reports a `GoRoute` that does not include a `name` argument.

```dart
GoRoute(
  path: AppRoutes.homePath,
  builder: (context, state) => const HomePage(),
);
```

### `use_context_directly_for_go_router`

Reports supported `GoRouter.of(context)` route-method calls and recommends the corresponding `BuildContext` extension.

```dart
GoRouter.of(context).go(AppRoutes.homePath);
```

Use `context.go(AppRoutes.homePath)` instead.

### `avoid_hardcoded_routes`

Reports hardcoded route strings in supported `BuildContext` and `GoRouter` methods, `GoRoute` definitions, redirects, and `GoRouter.initialLocation`.

```dart
context.go('/profile');
```

Use a constant, enum, or variable instead.

### `avoid_navigator_named_routes_with_go_router`

Reports supported `Navigator.*Named` and `NavigatorState.*Named` calls when the owning package declares `go_router` in `dependencies` or `dev_dependencies`.
The rule reads the owning package's pubspec and does not use the process working directory or a cross-package cache.

```dart
Navigator.pushNamed(context, AppRoutes.detailsPath);
```

Use a `go_router` navigation API instead.

### `missing_go_router_error_handler`

Reports a `GoRouter` that defines neither `errorBuilder` nor `errorPageBuilder`.

```dart
final router = GoRouter(routes: const []);
```

Add an error handler that renders an appropriate fallback.

## Development

Run the rule tests with the Dart VM because `test_reflective_loader` uses `dart:mirrors`:

```bash
dart test
dart analyze .
```

The workspace example intentionally does not enable `plugins:`.
Use the repository's standalone consumer harness for a real host check:

```bash
dart run tool/verify_analyzer_plugins.dart --plugin go_router_linter --source local --analyzer dart --repeat 3
```

## License

This package is licensed under the MIT License.
See [LICENSE](https://github.com/AndrewDongminYoo/custom_linters/blob/main/LICENSE).
