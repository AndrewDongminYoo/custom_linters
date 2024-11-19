# Go Router Linter

`go_router_linter` is a custom linting package designed to enhance code quality and consistency when using the `go_router` package in Dart and Flutter applications. It encourages best practices by identifying and suggesting improvements for common patterns.

## Features

- **Lint Rule: Use `context.go()` Instead of `GoRouter.of(context).go()`**
  - Detects instances where `GoRouter.of(context).go()` is used and suggests replacing it with the more concise `context.go()`.

## Installation

To integrate `go_router_linter` into your project, follow these steps:

1. **Add Dependency**

   In your `pubspec.yaml` file, include `go_router_linter` under `dev_dependencies`:

   ```yaml
   dev_dependencies:
     go_router_linter: ^0.1.0
   ```

2. **Update `analysis_options.yaml`**

   Enable the custom lint rule by adding the following to your `analysis_options.yaml` file:

   ```yaml
   analyzer:
     plugins:
       - custom_lint

   custom_lint:
     rules:
       - use_context_directly_for_go_router
   ```

## Usage

After setting up, the linter will automatically analyze your code and provide warnings or suggestions based on the defined rules. For example, if `GoRouter.of(context).go()` is detected, the linter will recommend using `context.go()` instead.

## Contributing

Contributions are welcome! If you have ideas for new lint rules or improvements, please open an issue or submit a pull request on our [GitHub repository](https://github.com/AndrewDongminYoo/custom_linters).

## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/AndrewDongminYoo/custom_linters/blob/main/LICENSE) file for details.

## Acknowledgements

Special thanks to the Dart and Flutter communities for their continuous support and contributions.
