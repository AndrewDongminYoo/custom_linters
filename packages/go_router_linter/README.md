# Go Router Linter

`go_router_linter` is a custom linting package designed to enhance code quality and consistency when using the `go_router` package in Dart and Flutter applications. It encourages best practices by identifying and suggesting improvements for common patterns.

## Features

### Current Rules

#### 1. Ensure `GoRoute` Includes a `name` Property

- **Lint Code:** `missing_go_route_name_property`
- **What it does:** Detects `GoRoute` definitions missing the `name` property and suggests adding it for better readability and routing consistency.

**Example:**

```dart
// Bad
GoRoute(
  path: '/home',
  builder: (context, state) => HomePage(),
);

// Good
GoRoute(
  path: '/home',
  name: 'home',
  builder: (context, state) => HomePage(),
);
```

#### 2. Use `context.go()` Instead of `GoRouter.of(context).go()`

- **Lint Code:** `use_context_directly_for_go_router`
- **What it does:** Detects instances where `GoRouter.of(context).go()` is used and suggests replacing it with the more concise `context.go()`.

**Example:**

```dart
// Bad
GoRouter.of(context).go('/home');

// Good
context.go('/home');
```

#### 3. Avoid Hardcoded Routes

- **Lint Code:** `avoid_hardcoded_routes`
- **What it does:** Detects when hardcoded route strings are used directly in:
  - `context.go()`, `context.push()`, `context.goNamed()`, `context.pushNamed()`, etc.
  - `GoRouter.of(context).go()`, `GoRouter.of(context).push()`, `GoRouter.of(context).goNamed()`, `GoRouter.of(context).pushNamed()`, etc.
  - `GoRoute` definitions (`path` and `name` properties)
  - `redirect` callback return strings
  - `GoRouter` constructor's `initialLocation` argument

  and suggests using constants or enums instead.

**Examples:**

```dart
// Bad: Hardcoded string in go()
context.go('/profile');

// Good: Use a constant or enum
context.go(AppRoutes.profile);
```

```dart
// Bad: Hardcoded string in GoRoute definition
GoRoute(
  path: '/details',
  name: 'details',
  builder: (context, state) => DetailsPage(),
);

// Good: Use a constant or enum
GoRoute(
  path: AppRoutes.detailsPath,
  name: DetailsPage.name,
  builder: (context, state) => DetailsPage(),
);
```

```dart
// Bad: Hardcoded initialLocation
GoRouter(initialLocation: '/home', routes: [...]);

// Good: Use a constant
GoRouter(initialLocation: AppRoutes.home, routes: [...]);
```

#### 4. Avoid Navigator Named Routes With GoRouter

- **Lint Code:** `avoid_navigator_named_routes_with_go_router`
- **What it does:** Detects `Navigator.*Named` APIs in projects that depend on
  `go_router`, and suggests using go_router navigation APIs instead.

**Example:**

```dart
// Bad
Navigator.pushNamed(context, '/details');

// Good
context.goNamed(AppRouteNames.details);
```

#### 5. Missing GoRouter Error Handler

- **Lint Code:** `missing_go_router_error_handler`
- **What it does:** Warns when a `GoRouter` is constructed without either an
  `errorBuilder` or an `errorPageBuilder`. Without one of these, navigation
  errors (e.g. unknown routes, guard redirects that produce no match) surface
  as a blank screen instead of a meaningful error UI.

**Example:**

```dart
// Bad: no error handler
final router = GoRouter(routes: [...]);

// Good: provide errorBuilder
final router = GoRouter(
  routes: [...],
  errorBuilder: (context, state) => ErrorPage(state.error),
);

// Also good: provide errorPageBuilder
final router = GoRouter(
  routes: [...],
  errorPageBuilder: (context, state) => NoTransitionPage(
    child: ErrorPage(state.error),
  ),
);
```

## Installation

To integrate `go_router_linter` into your project, follow these steps:

### 1. Add Dependency

In your `pubspec.yaml` file, include `go_router_linter` under `dev_dependencies`:

```yaml
dev_dependencies:
  go_router_linter: ^0.4.0
```

### 2. Update `analysis_options.yaml`

Enable the custom lint rules by adding the following to your `analysis_options.yaml` file:

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - missing_go_route_name_property
    - use_context_directly_for_go_router
    - avoid_hardcoded_routes
    - avoid_navigator_named_routes_with_go_router
    - missing_go_router_error_handler
```

## Usage

After setting up, the linter will automatically analyze your code and provide warnings or suggestions based on the defined rules.

### Missing `name` Property

If a `GoRoute` definition does not include the `name` property:

```dart
GoRoute(
  path: '/profile',
  builder: (context, state) => ProfilePage(),
);
```

The linter will produce the following suggestion:

> GoRoute definition should include a `name` property.

### Using `GoRouter.of(context).go()`

If `GoRouter.of(context).go()` is detected:

```dart
GoRouter.of(context).go('/home');
```

The linter will suggest replacing it with:

```dart
context.go('/home');
```

### Avoiding Hardcoded Routes

If a hardcoded route string is detected in `context.go('/profile')`:

> Avoid hardcoded route paths. Use constants or enums for routes.

If a hardcoded route string is detected in a `GoRoute` definition:

> Avoid hardcoded route paths. Use constants or enums for routes.

### Avoiding Navigator Named Routes With GoRouter

If a `Navigator.*Named` API is detected in a project that depends on
`go_router`:

```dart
Navigator.pushNamed(context, '/details');
```

The linter will suggest using go_router navigation APIs instead:

```dart
context.goNamed(AppRouteNames.details);
```

### Missing GoRouter Error Handler

If a `GoRouter` constructor is missing both `errorBuilder` and
`errorPageBuilder`:

```dart
final router = GoRouter(routes: [...]);
```

The linter will warn:

> GoRouter should define an errorBuilder or errorPageBuilder.

## Contributing

Contributions are welcome! If you have ideas for new lint rules or improvements, please open an issue or submit a pull request on our [GitHub repository](https://github.com/AndrewDongminYoo/custom_linters).

## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/AndrewDongminYoo/custom_linters/blob/main/LICENSE) file for details.

## Acknowledgements

Special thanks to the Dart and Flutter communities for their continuous support and contributions.
