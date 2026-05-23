# Lint Rules v2 Design

**Date:** 2026-05-23
**Packages:** `flutter_best_practices_lints`, `go_router_linter`
**Scope:** 3 new lint rules; 1 existing rule extended

## Summary

Add 3 new default-enabled lint rules and extend 1 existing rule to cover recently
identified best-practice gaps. All rules produce low false-positive rates and are
grounded in official Flutter and go_router documentation.

## Rules

### 1. `prefer_media_query_partial_methods` (flutter_best_practices_lints — new)

**Problem:** `MediaQuery.of(context)` subscribes the widget to every
`MediaQueryData` field. Flutter 3.10 introduced dedicated static accessors
(`MediaQuery.sizeOf`, `MediaQuery.paddingOf`, etc.) that subscribe only to the
specific value, reducing unnecessary rebuilds.

**Detection:** `PropertyAccess` node where:
- The target is a `MethodInvocation` with method name `of` on `MediaQuery`
- The accessed property has a corresponding dedicated static accessor

**Covered property → replacement mapping:**

| Property | Replacement |
|---|---|
| `size` | `MediaQuery.sizeOf(context)` |
| `padding` | `MediaQuery.paddingOf(context)` |
| `viewInsets` | `MediaQuery.viewInsetsOf(context)` |
| `viewPadding` | `MediaQuery.viewPaddingOf(context)` |
| `textScaler` | `MediaQuery.textScalerOf(context)` |
| `devicePixelRatio` | `MediaQuery.devicePixelRatioOf(context)` |
| `platformBrightness` | `MediaQuery.platformBrightnessOf(context)` |
| `orientation` | `MediaQuery.orientationOf(context)` |
| `gestureSettings` | `MediaQuery.gestureSettingsOf(context)` |
| `displayFeatures` | `MediaQuery.displayFeaturesOf(context)` |
| `alwaysUse24HourFormat` | `MediaQuery.alwaysUse24HourFormatOf(context)` |
| `accessibleNavigation` | `MediaQuery.accessibleNavigationOf(context)` |
| `boldText` | `MediaQuery.boldTextOf(context)` |
| `disableAnimations` | `MediaQuery.disableAnimationsOf(context)` |
| `highContrast` | `MediaQuery.highContrastOf(context)` |
| `invertColors` | `MediaQuery.invertColorsOf(context)` |

**Correction message:** Dynamic per property, e.g.
`Use MediaQuery.sizeOf(context) instead.`

**Excluded:** Indirect access via variable (`final mq = MediaQuery.of(context); mq.size`)
is out of scope to avoid false positives.

**Tests:**
- Reports `MediaQuery.of(ctx).size`
- Reports `MediaQuery.of(ctx).padding`
- Does not report `MediaQuery.sizeOf(ctx)`
- Does not report `MediaQuery.of(ctx).copyWith(...)` (not in the mapping)

---

### 2. `missing_go_router_error_handler` (go_router_linter — new)

**Problem:** `GoRouter` without `errorBuilder` or `errorPageBuilder` silently
renders a blank/debug screen when an unknown route is pushed. Production apps
should always define a custom error screen.

**Detection:** `InstanceCreationExpression` where:
- The static type element name is `GoRouter`
- Neither `errorBuilder` nor `errorPageBuilder` appears in the argument list

**LintCode severity:** warning

**Tests:**
- Reports `GoRouter(routes: [...])`
- Does not report `GoRouter(routes: [...], errorBuilder: (_, __) => const NotFoundPage())`
- Does not report `GoRouter(routes: [...], errorPageBuilder: ...)`

---

### 3. `avoid_hardcoded_routes` extension — `initialLocation` (go_router_linter)

**Problem:** `GoRouter(initialLocation: '/home')` is an existing gap in the
`avoid_hardcoded_routes` rule. Hardcoded `initialLocation` strings bypass the
same constants/enums enforcement already applied to `path` and `name`.

**Change:** In `_AvoidHardcodedRoutesVisitor.checkInstanceCreationExpression`,
add `initialLocation` to the set of checked named parameters when the enclosing
class is `GoRouter`.

**Tests:**
- Reports `GoRouter(initialLocation: '/home')`
- Does not report `GoRouter(initialLocation: AppRoutes.home)`

---

## Public Interface Changes

- Export `PreferMediaQueryPartialMethods` from
  `flutter_best_practices_lints.dart`
- Register `PreferMediaQueryPartialMethods` in `FlutterBestPracticesPlugin`
- Export `MissingGoRouterErrorHandler` from `go_router_linter.dart`
- Register `MissingGoRouterErrorHandler` in `_GoRouterLintPlugin`
- No API break — all existing rules retain their signatures

## Version Bumps

- `flutter_best_practices_lints`: `0.4.0` → `0.5.0`
- `go_router_linter`: `0.3.0` → `0.4.0`

## Verification Commands

```plaintext
dart test packages/flutter_best_practices_lints
dart test packages/go_router_linter
melos analyze
dart run custom_lint  (in each example app)
```
