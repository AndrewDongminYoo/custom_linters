# Lint Rules v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 3 new default-enabled lint rules and extend 1 existing rule across `flutter_best_practices_lints` and `go_router_linter`.

**Architecture:** Each rule is a `DartLintRule` subclass in its package's `lib/src/rules/` directory. New rules are registered in the package's `PluginBase.getLintRules` and exported from the library entrypoint. The existing `avoid_hardcoded_routes` rule gets a minimal one-path extension. TDD throughout: write the failing test first, then the implementation.

**Tech Stack:** Dart ^3.9.0, `custom_lint_builder ^0.8.1`, `analyzer ^8.4.0`, `test` package

---

## File Map

**flutter_best_practices_lints**
- Create: `packages/flutter_best_practices_lints/lib/src/rules/prefer_media_query_partial_methods.dart`
- Create: `packages/flutter_best_practices_lints/test/src/rules/prefer_media_query_partial_methods_test.dart`
- Modify: `packages/flutter_best_practices_lints/lib/flutter_best_practices_lints.dart` — add export
- Modify: `packages/flutter_best_practices_lints/lib/src/flutter_best_practices_plugin.dart` — register rule
- Modify: `packages/flutter_best_practices_lints/pubspec.yaml` — bump version 0.4.0 → 0.5.0
- Modify: `packages/flutter_best_practices_lints/CHANGELOG.md` — add 0.5.0 entry

**go_router_linter**
- Create: `packages/go_router_linter/lib/src/rules/missing_go_router_error_handler.dart`
- Create: `packages/go_router_linter/test/src/rules/missing_go_router_error_handler_test.dart`
- Modify: `packages/go_router_linter/lib/go_router_linter.dart` — add export
- Modify: `packages/go_router_linter/lib/src/go_router_lint_plugin.dart` — register rule
- Modify: `packages/go_router_linter/lib/src/rules/avoid_hardcoded_routes.dart` — add `initialLocation` check
- Modify: `packages/go_router_linter/test/src/rules/avoid_hardcoded_routes_test.dart` — add `initialLocation` test
- Modify: `packages/go_router_linter/pubspec.yaml` — bump version 0.3.0 → 0.4.0
- Modify: `packages/go_router_linter/CHANGELOG.md` — add 0.4.0 entry

---

## Task 1: `prefer_media_query_partial_methods` — Test

**Files:**
- Create: `packages/flutter_best_practices_lints/test/src/rules/prefer_media_query_partial_methods_test.dart`

- [ ] **Step 1.1: Create the failing test file**

```dart
// 📦 Package imports:
import 'package:flutter_best_practices_lints/flutter_best_practices_lints.dart';
import 'package:test/test.dart';

// 🌎 Project imports:
import '../lint_test_utils.dart';

void main() {
  group('PreferMediaQueryPartialMethods', () {
    test('reports MediaQuery.of(context).property calls', () async {
      final errors = await analyzeLintRule(
        const PreferMediaQueryPartialMethods(),
        '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    return SizedBox(width: size.width, height: padding.top);
  }
}
''',
      );

      expect(errors, everyElement('prefer_media_query_partial_methods'));
      expect(errors, hasLength(2));
    });

    test('ignores dedicated MediaQuery static accessors', () async {
      final errors = await analyzeLintRule(
        const PreferMediaQueryPartialMethods(),
        '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    return SizedBox(width: size.width, height: padding.top);
  }
}
''',
      );

      expect(errors, isEmpty);
    });

    test('ignores MediaQuery.of().copyWith (no direct replacement)', () async {
      final errors = await analyzeLintRule(
        const PreferMediaQueryPartialMethods(),
        '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: const SizedBox.shrink(),
    );
  }
}
''',
      );

      expect(errors, isEmpty);
    });
  });
}
```

- [ ] **Step 1.2: Run to confirm FAIL**

```bash
cd packages/flutter_best_practices_lints && dart test test/src/rules/prefer_media_query_partial_methods_test.dart
```

Expected output contains: `Error: Getter 'PreferMediaQueryPartialMethods' isn't defined`

---

## Task 2: `prefer_media_query_partial_methods` — Implementation

**Files:**
- Create: `packages/flutter_best_practices_lints/lib/src/rules/prefer_media_query_partial_methods.dart`
- Modify: `packages/flutter_best_practices_lints/lib/flutter_best_practices_lints.dart`
- Modify: `packages/flutter_best_practices_lints/lib/src/flutter_best_practices_plugin.dart`

- [ ] **Step 2.1: Create the rule implementation**

```dart
// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/extensions/lint_code_extension.dart';

/// {@template prefer_media_query_partial_methods}
/// Reports `MediaQuery.of(context).property` accesses that have a dedicated
/// static accessor (e.g. `MediaQuery.sizeOf(context)`).
///
/// The specific accessors subscribe only to the relevant slice of
/// `MediaQueryData`, preventing unnecessary widget rebuilds when other
/// fields change.
/// {@endtemplate}
class PreferMediaQueryPartialMethods extends DartLintRule {
  /// {@macro prefer_media_query_partial_methods}
  const PreferMediaQueryPartialMethods() : super(code: _code);

  static const _code = LintCode(
    name: 'prefer_media_query_partial_methods',
    problemMessage:
        'Use the specific MediaQuery accessor to avoid unnecessary rebuilds.',
  );

  static const _propertyToReplacement = {
    'size': 'MediaQuery.sizeOf(context)',
    'padding': 'MediaQuery.paddingOf(context)',
    'viewInsets': 'MediaQuery.viewInsetsOf(context)',
    'viewPadding': 'MediaQuery.viewPaddingOf(context)',
    'textScaler': 'MediaQuery.textScalerOf(context)',
    'devicePixelRatio': 'MediaQuery.devicePixelRatioOf(context)',
    'platformBrightness': 'MediaQuery.platformBrightnessOf(context)',
    'orientation': 'MediaQuery.orientationOf(context)',
    'gestureSettings': 'MediaQuery.gestureSettingsOf(context)',
    'displayFeatures': 'MediaQuery.displayFeaturesOf(context)',
    'alwaysUse24HourFormat': 'MediaQuery.alwaysUse24HourFormatOf(context)',
    'accessibleNavigation': 'MediaQuery.accessibleNavigationOf(context)',
    'boldText': 'MediaQuery.boldTextOf(context)',
    'disableAnimations': 'MediaQuery.disableAnimationsOf(context)',
    'highContrast': 'MediaQuery.highContrastOf(context)',
    'invertColors': 'MediaQuery.invertColorsOf(context)',
  };

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPropertyAccess((node) {
      final target = node.target;
      if (target is! MethodInvocation) return;
      if (target.methodName.name != 'of') return;

      final methodTarget = target.target;
      if (methodTarget is! Identifier || methodTarget.name != 'MediaQuery') {
        return;
      }

      final property = node.propertyName.name;
      final replacement = _propertyToReplacement[property];
      if (replacement == null) return;

      reporter.atNode(
        node,
        _code.copyWith(correctionMessage: 'Use $replacement instead.'),
      );
    });
  }
}
```

- [ ] **Step 2.2: Export from package entrypoint**

In `packages/flutter_best_practices_lints/lib/flutter_best_practices_lints.dart`, add the export after the existing rule exports (after `single_class_per_file.dart`):

```dart
export 'src/rules/prefer_media_query_partial_methods.dart';
```

- [ ] **Step 2.3: Register in plugin**

In `packages/flutter_best_practices_lints/lib/src/flutter_best_practices_plugin.dart`, add the import and register the rule:

```dart
// 📦 Package imports:
import 'package:custom_lint_builder/custom_lint_builder.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/rules/avoid_widget_operator_equals.dart';
import 'package:flutter_best_practices_lints/src/rules/matching_class_and_file_name.dart';
import 'package:flutter_best_practices_lints/src/rules/prefer_media_query_partial_methods.dart';
import 'package:flutter_best_practices_lints/src/rules/prefer_widget_class_over_widget_helper.dart';
import 'package:flutter_best_practices_lints/src/rules/single_class_per_file.dart';

/// This is the entrypoint of our custom linter
PluginBase createPlugin() => FlutterBestPracticesPlugin();

/// A plugin class is used to list all the assists/lints defined by a plugin.
class FlutterBestPracticesPlugin extends PluginBase {
  /// We list all the custom warnings/infos/errors
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => <LintRule>[
    const SingleClassPerFile(),
    const MatchingClassAndFileName(),
    const PreferWidgetClassOverWidgetHelper(),
    const AvoidWidgetOperatorEquals(),
    const PreferMediaQueryPartialMethods(),
  ];
}
```

- [ ] **Step 2.4: Run tests to confirm PASS**

```bash
cd packages/flutter_best_practices_lints && dart test test/src/rules/prefer_media_query_partial_methods_test.dart
```

Expected output: `All tests passed!`

- [ ] **Step 2.5: Run full package test suite**

```bash
cd packages/flutter_best_practices_lints && dart test
```

Expected output: `All tests passed!`

- [ ] **Step 2.6: Commit**

```bash
git add packages/flutter_best_practices_lints/lib/src/rules/prefer_media_query_partial_methods.dart \
        packages/flutter_best_practices_lints/lib/flutter_best_practices_lints.dart \
        packages/flutter_best_practices_lints/lib/src/flutter_best_practices_plugin.dart \
        packages/flutter_best_practices_lints/test/src/rules/prefer_media_query_partial_methods_test.dart
git commit -m "feat(flutter-lints): add prefer_media_query_partial_methods rule"
```

---

## Task 3: `missing_go_router_error_handler` — Test

**Files:**
- Create: `packages/go_router_linter/test/src/rules/missing_go_router_error_handler_test.dart`

- [ ] **Step 3.1: Create the failing test file**

```dart
// 📦 Package imports:
import 'package:go_router_linter/go_router_linter.dart';
import 'package:test/test.dart';

// 🌎 Project imports:
import '../lint_test_utils.dart';

void main() {
  group('MissingGoRouterErrorHandler', () {
    test('reports GoRouter without error handler', () async {
      final errors = await analyzeLintRule(
        const MissingGoRouterErrorHandler(),
        '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const SizedBox.shrink(),
    ),
  ],
);
''',
      );

      expect(errors, everyElement('missing_go_router_error_handler'));
      expect(errors, hasLength(1));
    });

    test('ignores GoRouter with errorBuilder', () async {
      final errors = await analyzeLintRule(
        const MissingGoRouterErrorHandler(),
        '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [],
  errorBuilder: (context, state) => const SizedBox.shrink(),
);
''',
      );

      expect(errors, isEmpty);
    });

    test('ignores GoRouter with errorPageBuilder', () async {
      final errors = await analyzeLintRule(
        const MissingGoRouterErrorHandler(),
        '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: [],
  errorPageBuilder: (context, state) =>
      const NoTransitionPage(child: SizedBox.shrink()),
);
''',
      );

      expect(errors, isEmpty);
    });
  });
}
```

- [ ] **Step 3.2: Run to confirm FAIL**

```bash
cd packages/go_router_linter && dart test test/src/rules/missing_go_router_error_handler_test.dart
```

Expected output contains: `Error: Getter 'MissingGoRouterErrorHandler' isn't defined`

---

## Task 4: `missing_go_router_error_handler` — Implementation

**Files:**
- Create: `packages/go_router_linter/lib/src/rules/missing_go_router_error_handler.dart`
- Modify: `packages/go_router_linter/lib/go_router_linter.dart`
- Modify: `packages/go_router_linter/lib/src/go_router_lint_plugin.dart`

- [ ] **Step 4.1: Create the rule implementation**

```dart
// 📦 Package imports:
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// {@template missing_go_router_error_handler}
/// Reports `GoRouter` constructor calls that define no `errorBuilder` or
/// `errorPageBuilder`.
///
/// Without an error handler, navigating to an unknown route renders a blank
/// debug screen in production. Providing a custom error page ensures a
/// graceful user experience for unmatched routes.
/// {@endtemplate}
class MissingGoRouterErrorHandler extends DartLintRule {
  /// {@macro missing_go_router_error_handler}
  const MissingGoRouterErrorHandler() : super(code: _code);

  static const _code = LintCode(
    name: 'missing_go_router_error_handler',
    problemMessage:
        'GoRouter should define an error handler for unknown routes.',
    correctionMessage:
        'Add an `errorBuilder` or `errorPageBuilder` argument.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final element = node.staticType?.element;
      if (element is! ClassElement || element.name != 'GoRouter') return;

      final hasErrorHandler = node.argumentList.arguments.any((arg) {
        if (arg is! NamedExpression) return false;
        final name = arg.name.label.name;
        return name == 'errorBuilder' || name == 'errorPageBuilder';
      });

      if (!hasErrorHandler) {
        reporter.atNode(node, _code);
      }
    });
  }
}
```

- [ ] **Step 4.2: Export from package entrypoint**

In `packages/go_router_linter/lib/go_router_linter.dart`, add the export after the existing rule exports:

```dart
export 'src/rules/missing_go_router_error_handler.dart';
```

- [ ] **Step 4.3: Register in plugin**

In `packages/go_router_linter/lib/src/go_router_lint_plugin.dart`, replace the full file content:

```dart
// 📦 Package imports:
import 'package:custom_lint_builder/custom_lint_builder.dart';

// 🌎 Project imports:
import 'package:go_router_linter/src/rules/avoid_hardcoded_routes.dart';
import 'package:go_router_linter/src/rules/avoid_navigator_named_routes_with_go_router.dart';
import 'package:go_router_linter/src/rules/missing_go_router_error_handler.dart';
import 'package:go_router_linter/src/rules/missing_go_route_name_property.dart';
import 'package:go_router_linter/src/rules/use_context_directly_for_go_router.dart';

/// This is the entrypoint of our custom linter
PluginBase createPlugin() => _GoRouterLintPlugin();

/// A plugin class is used to list all the assists/lints defined by a plugin.
class _GoRouterLintPlugin extends PluginBase {
  /// We list all the custom warnings/infos/errors
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => <LintRule>[
    const UseContextDirectlyForGoRouter(),
    const MissingGoRouteNameProperty(),
    const AvoidHardcodedRoutes(),
    const AvoidNavigatorNamedRoutesWithGoRouter(),
    const MissingGoRouterErrorHandler(),
  ];
}
```

- [ ] **Step 4.4: Run tests to confirm PASS**

```bash
cd packages/go_router_linter && dart test test/src/rules/missing_go_router_error_handler_test.dart
```

Expected output: `All tests passed!`

- [ ] **Step 4.5: Run full package test suite**

```bash
cd packages/go_router_linter && dart test
```

Expected output: `All tests passed!`

- [ ] **Step 4.6: Commit**

```bash
git add packages/go_router_linter/lib/src/rules/missing_go_router_error_handler.dart \
        packages/go_router_linter/lib/go_router_linter.dart \
        packages/go_router_linter/lib/src/go_router_lint_plugin.dart \
        packages/go_router_linter/test/src/rules/missing_go_router_error_handler_test.dart
git commit -m "feat(go-router-linter): add missing_go_router_error_handler rule"
```

---

## Task 5: `avoid_hardcoded_routes` — `initialLocation` Extension

**Files:**
- Modify: `packages/go_router_linter/lib/src/rules/avoid_hardcoded_routes.dart`
- Modify: `packages/go_router_linter/test/src/rules/avoid_hardcoded_routes_test.dart`

- [ ] **Step 5.1: Add the failing test case**

In `packages/go_router_linter/test/src/rules/avoid_hardcoded_routes_test.dart`, add a new test inside the `group`:

```dart
test('reports hardcoded initialLocation in GoRouter', () async {
  final errors = await analyzeLintRule(
    const AvoidHardcodedRoutes(),
    '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/home',
  routes: [],
);
''',
  );

  expect(errors, everyElement('avoid_hardcoded_routes'));
  expect(errors, hasLength(1));
});

test('ignores constant initialLocation in GoRouter', () async {
  final errors = await analyzeLintRule(
    const AvoidHardcodedRoutes(),
    '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

const homeRoute = '/home';

final router = GoRouter(
  initialLocation: homeRoute,
  routes: [],
);
''',
  );

  expect(errors, isEmpty);
});
```

- [ ] **Step 5.2: Run to confirm FAIL**

```bash
cd packages/go_router_linter && dart test test/src/rules/avoid_hardcoded_routes_test.dart
```

Expected: the `initialLocation` test fails; the existing tests still pass.

- [ ] **Step 5.3: Extend `checkInstanceCreationExpression`**

In `packages/go_router_linter/lib/src/rules/avoid_hardcoded_routes.dart`, find the `for` loop inside `checkInstanceCreationExpression` and replace the `if (paramName == 'path' || paramName == 'name')` branch:

```dart
for (final arg in arguments) {
  if (arg is NamedExpression) {
    final paramName = arg.name.label.name;
    if (paramName == 'path' || paramName == 'name') {
      if (arg.expression is StringLiteral) {
        reporter.atNode(arg.expression, AvoidHardcodedRoutes._code);
      }
    } else if (paramName == 'initialLocation' &&
        element.name == 'GoRouter') {
      if (arg.expression is StringLiteral) {
        reporter.atNode(arg.expression, AvoidHardcodedRoutes._code);
      }
    } else if (paramName == 'redirect') {
      _reportRedirectStrings(arg.expression);
    }
  }
}
```

- [ ] **Step 5.4: Run tests to confirm PASS**

```bash
cd packages/go_router_linter && dart test test/src/rules/avoid_hardcoded_routes_test.dart
```

Expected output: `All tests passed!`

- [ ] **Step 5.5: Run full package test suite**

```bash
cd packages/go_router_linter && dart test
```

Expected output: `All tests passed!`

- [ ] **Step 5.6: Commit**

```bash
git add packages/go_router_linter/lib/src/rules/avoid_hardcoded_routes.dart \
        packages/go_router_linter/test/src/rules/avoid_hardcoded_routes_test.dart
git commit -m "feat(go-router-linter): extend avoid_hardcoded_routes to check initialLocation"
```

---

## Task 6: Version Bumps and CHANGELOGs

**Files:**
- Modify: `packages/flutter_best_practices_lints/pubspec.yaml`
- Modify: `packages/flutter_best_practices_lints/CHANGELOG.md`
- Modify: `packages/go_router_linter/pubspec.yaml`
- Modify: `packages/go_router_linter/CHANGELOG.md`

- [ ] **Step 6.1: Bump `flutter_best_practices_lints` to 0.5.0**

In `packages/flutter_best_practices_lints/pubspec.yaml`, change:
```yaml
version: 0.4.0
```
to:
```yaml
version: 0.5.0
```

- [ ] **Step 6.2: Update `flutter_best_practices_lints` CHANGELOG**

Prepend to `packages/flutter_best_practices_lints/CHANGELOG.md`:

```markdown
## 0.5.0 - 2026-05-23

### Added

- Added `prefer_media_query_partial_methods` to encourage `MediaQuery.sizeOf(context)` and sibling accessors over `MediaQuery.of(context).size` to reduce unnecessary widget rebuilds (Flutter 3.10+).

```

- [ ] **Step 6.3: Bump `go_router_linter` to 0.4.0**

In `packages/go_router_linter/pubspec.yaml`, change:
```yaml
version: 0.3.0
```
to:
```yaml
version: 0.4.0
```

- [ ] **Step 6.4: Update `go_router_linter` CHANGELOG**

Prepend to `packages/go_router_linter/CHANGELOG.md`:

```markdown
## 0.4.0 - 2026-05-23

### Added

- Added `missing_go_router_error_handler` to warn when `GoRouter` is constructed without an `errorBuilder` or `errorPageBuilder`.
- Extended `avoid_hardcoded_routes` to report hardcoded `initialLocation` strings in `GoRouter` constructors.

```

- [ ] **Step 6.5: Verify full monorepo analysis**

```bash
melos analyze
```

Expected output: `No issues found!`

- [ ] **Step 6.6: Commit version bumps**

```bash
git add packages/flutter_best_practices_lints/pubspec.yaml \
        packages/flutter_best_practices_lints/CHANGELOG.md \
        packages/go_router_linter/pubspec.yaml \
        packages/go_router_linter/CHANGELOG.md
git commit -m "chore: bump versions for lint rules v2 release"
```
