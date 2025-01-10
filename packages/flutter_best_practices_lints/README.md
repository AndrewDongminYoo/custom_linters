# Flutter Best Practices Lints

`flutter_best_practices_lints` is a custom linting package designed to enhance code quality and maintain consistency in Flutter applications. By enforcing best practices in file structure and class naming, it helps keep your project organized, readable, and easy to navigate.

## Features

### Current Rules

#### 1. Single Class per File

- **Lint Code:** `single_class_per_file`
- **What it does:** Ensures that each file contains only one class declaration.
  - Excludes Flutter `State` classes (i.e., classes ending with `State` and prefixed with `_`).
  - Encourages better separation of concerns and organization.

<details>
<summary>Example</summary>

**Bad (multiple classes in one file):**

```dart
class MyFirstClass {}

class MySecondClass {}
```

**Good (each class in its own file):**

```dart
// my_first_class.dart
class MyFirstClass {}

// my_second_class.dart
class MySecondClass {}
```

</details>

#### 2. Matching Class and File Name

- **Lint Code:** `matching_class_and_file_name`
- **What it does:** Checks that the main class name (in PascalCase) matches the file name (in snake_case).
  - Excludes private `State` classes (e.g., `_MyHomePageState`) and abstract classes.
  - Helps keep your codebase consistent and files easy to discover.

<details>
<summary>Example</summary>

**File:** `my_home_page.dart`
**Bad (mismatched class name):**

```dart
class MyHomepage {}  // Should be `MyHomePage`
```

**Good (matching file and class name):**

```dart
class MyHomePage {}
```

</details>

## Installation

To integrate `flutter_best_practices_lints` into your project, follow these steps:

### 1. Add the Dependency

In your `pubspec.yaml`, include `flutter_best_practices_lints` under `dev_dependencies`:

```yaml
dev_dependencies:
  flutter_best_practices_lints: ^0.1.0
```

_(Note: Replace `^0.1.0` with the actual version you're using.)_

### 2. Update `analysis_options.yaml`

Enable the custom lint rules by adding or updating your `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    - custom_lint

custom_lint:
  rules:
    - matching_class_and_file_name
    - single_class_per_file
```

## Usage

After configuring your project, the linter automatically checks your files and provides warnings or suggestions based on the defined rules.

- When you have multiple classes in the same file, it will suggest splitting them.
- When a class name doesn't match the file name (in `snake_case` → `PascalCase` format), it prompts you to rename either the class or the file.

### Example Lint Warnings

**Multiple classes warning:**

```log
lib/multiple_classes.dart:10:1 • A file should contain only one class declaration. • single_class_per_file • INFO
```

**Mismatched class and file name warning:**

```log
lib/widgets/my_widget.dart:7:7 • Class name Mywidget must match the file name "my_widget" • matching_class_and_file_name • INFO
```

## Contributing

Contributions are welcome! If you have ideas for new lint rules, improvements, or bug fixes, feel free to open an issue or submit a pull request on our [GitHub repository](https://github.com/AndrewDongminYoo/custom_linters).

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to the Dart and Flutter communities for their ongoing support and for sharing best practices.
- Inspired by other linting tools like [`go_router_linter`](https://pub.dev/packages/go_router_linter) and [`custom_lint`](https://pub.dev/packages/custom_lint).
