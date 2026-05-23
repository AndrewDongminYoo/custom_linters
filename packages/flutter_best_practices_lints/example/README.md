# Example App for flutter_best_practices_lints

This example demonstrates how to use the **`flutter_best_practices_lints`** package in a real Flutter application. It highlights rules like:

- **`single_class_per_file`**: Ensures each file contains only one main class.
- **`matching_class_and_file_name`**: Enforces that the class name (PascalCase) matches the file name (snake_case).
- **`prefer_widget_class_over_widget_helper`**: Encourages extracting private
  `Widget _build...` helpers into widget classes.
- **`avoid_widget_operator_equals`**: Discourages equality overrides on Flutter
  widget subclasses.

---

## Purpose

By intentionally including code that violates these rules, this example app shows how lints are reported and what steps you can take to resolve them. It helps you understand how **`flutter_best_practices_lints`** can improve the structure and clarity of your code.

---

## Requirements

```log
• Dart SDK: >=3.5.0
• Flutter: >=3.10.0
```

Make sure you have a valid Flutter environment set up before proceeding.

---

## Getting Started

### 1. Clone the Repository

```sh
git clone https://github.com/AndrewDongminYoo/custom_linters.git
cd custom_linters/packages/flutter_best_practices_lints/example
```

### 2. Install Dependencies

From the `example/` directory, install the Flutter packages:

```sh
flutter pub get
```

### 3. Run the App

To run the example on a connected device or emulator:

```sh
flutter run
```

This launches the Flutter demo app, which includes a counter and demonstrates various Flutter layouts and hot reload functionality.

---

## Linter Demonstration

### Analyzing the Code

To see **`flutter_best_practices_lints`** in action, run:

```sh
dart run custom_lint
```

This command validates that the expected lint diagnostics are emitted. In this
example, you should see:

```log
Analyzing...

No issues found!
```

The example files use `expect_lint` comments, so `custom_lint` succeeds when
the expected lint diagnostics are emitted.

### What Triggers the Lints?

1. **`single_class_per_file`**
   - In `my_home_page.dart`, there's a second class (`MyHomePage2`). This triggers the lint because the file already contains the main `MyHomePage` stateful widget class.
   - **Fix:** Move `MyHomePage2` to a new file or combine the functionality into the main class if appropriate.

2. **`matching_class_and_file_name`**
   <!-- cSpell:ignore MyhomePage -->
   - If you rename `MyHomePage` or the file itself so they no longer match (e.g., file: `my_home_page.dart`, class: `MyhomePage`), you’ll see a lint message advising you to align the two.
   - **Fix:** Ensure the file name is `my_home_page.dart` and the class name is `MyHomePage`.

3. **`prefer_widget_class_over_widget_helper`**
   - In `_MyHomePageState`, `_buildCounterText()` returns a `Widget`.
   - **Fix:** Extract the helper into a dedicated `StatelessWidget`.

4. **`avoid_widget_operator_equals`**
   - `MyHomePage` overrides `operator ==`.
   - **Fix:** Remove the equality override and let Flutter use normal widget
     identity.

By introducing these small “mistakes” in the code, you can see exactly how **`flutter_best_practices_lints`** catches them, providing guidance on how to rectify each situation.

---

## Code Overview

### `main.dart`

- Defines the root `MyApp` widget.
- Sets up the basic Flutter MaterialApp.
- **Lint Trigger:**
  - The `MyApp` class name should match the file name if that rule was enforced here, but currently it's only demonstrating usage.
  - The comment `// expect_lint: matching_class_and_file_name` shows how you might expect a lint if the name doesn’t match.

### `my_home_page.dart`

- Implements `MyHomePage` as a `StatefulWidget`.
- Contains `_MyHomePageState`, which manages the counter logic.
- Also includes a second class, `MyHomePage2`, which demonstrates how `single_class_per_file` will be triggered.
- Includes `_buildCounterText()`, which demonstrates `prefer_widget_class_over_widget_helper`.
- Overrides `operator ==`, which demonstrates `avoid_widget_operator_equals`.
- **Lint Trigger:**
  - `MyHomePage2` violates `single_class_per_file`.
  <!-- cSpell:ignore Myhomepage -->
  - If `MyHomePage` had a mismatched name (e.g., `Myhomepage`), it would violate `matching_class_and_file_name`.

---

## Feedback and Contributions

Feel free to open issues or submit pull requests if you find a bug, want to propose a new rule, or improve this example. Community contributions are always welcome.

---

## License

This example, as well as the main **`flutter_best_practices_lints`** package, is distributed under the MIT License.
Check the [LICENSE](../LICENSE) file for details.
