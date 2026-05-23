# Example App for go_router_linter

This example app demonstrates the use of the go_router_linter package to ensure consistent and idiomatic usage of navigation methods in Flutter applications using the go_router package. It uses a sample app inspired by the official go_router example.

Purpose

The app showcases how go_router_linter detects and provides actionable feedback when non-idiomatic navigation patterns (e.g., GoRouter.of(context).go('/home') or Navigator.pushNamed(context, '/details')) are used. It highlights the benefits of replacing such patterns with concise alternatives like context.go('/home') or context.goNamed(AppRouteNames.details).

Getting Started

Requirements

```log
•	Dart SDK: >=3.5.0
•	Flutter: >=3.10.0
•	go_router package installed
```

Clone the Repository

To run the example, clone the repository and navigate to the example directory:

```sh
git clone https://github.com/andrewdongminyu/go_router_linter.git
cd go_router_linter/example
```

Install Dependencies

Run the following command to install the necessary dependencies:

```sh
flutter pub get
```

Run the App

Launch the app using the Flutter CLI:

```sh
flutter run
```

The app should start, and you can interact with its navigation features.

Linter Demonstration

To see the go_router_linter in action:

1. Open the main.dart file.

2. Inspect the intentional lint examples marked with `expect_lint`, such as:

```dart
GoRouter.of(context).go('/details');
```

3. Run the linter. The command succeeds when the expected lints are emitted:

```sh
$ dart run custom_lint
Building package executable... (2.0s)
Built custom_lint:custom_lint.
Analyzing...

No issues found!
```

4. Replace the intentionally bad code with the idiomatic version:

```dart
context.go('/details');
```

Remove the matching `expect_lint` comment after fixing the code. The example
then stays clean while showing the intended migration path.

Code Overview

The example app demonstrates basic navigation between two routes:

1. Home Page: The default landing page with navigation buttons.
2. Details Page: Accessed via /details.

main.dart

The main.dart file defines the app’s navigation using GoRouter. For details, see the official go_router example here.

Feedback

If you encounter any issues or have suggestions for improving the go_router_linter or this example app, feel free to open an issue on the GitHub repository.

This example app is designed to demonstrate how go_router_linter can integrate into real-world Flutter projects to enforce consistent navigation patterns.
