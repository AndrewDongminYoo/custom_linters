# Custom Linters

A monorepo for analyzer plugins that improve Flutter and Dart code quality.
Currently, this repository includes:

- **[go_router_linter](./packages/go_router_linter)**: A set of lint rules for the `go_router` package, helping you maintain consistent and robust route definitions and navigation calls in your Flutter apps.
- **[flutter_best_practices_lints](./packages/flutter_best_practices_lints)**: A collection of lint rules that enforce focused Flutter structure and widget best practices, such as matching class names to file names, keeping one main class per file, preferring widget classes over private widget helpers, and avoiding widget equality overrides.

## Contents

- **`packages/`**
  - [go_router_linter](./packages/go_router_linter): Contains the rules and tests for the `go_router_linter`.
  - [flutter_best_practices_lints](./packages/flutter_best_practices_lints): Contains the rules, tests, and example app for enforcing best practices in Flutter projects.
- **`analysis_options.yaml`**
  - Root-level lint and analyzer settings for shared rules across packages.
- **`melos.yaml`**
  - Configuration file for managing multiple packages within this monorepo.

## Getting Started

1. **Clone the repository**:

   ```bash
   git clone https://github.com/AndrewDongminYoo/custom_linters.git
   cd custom_linters
   ```

2. **Bootstrap the workspace**:

   ```bash
   dart pub get
   dart run melos bootstrap
   ```

3. **Navigate to a package**:
   - **For `go_router_linter`**:

     ```bash
     cd packages/go_router_linter
     ```

   - **For `flutter_best_practices_lints`**:

     ```bash
     cd packages/flutter_best_practices_lints
     ```

4. **Pub commands**:
   - Get dependencies: `dart pub get`
   - Run tests: `dart test`
   - Analyze code: `dart analyze`

   Or use Melos commands (if configured), for example:

   ```bash
   dart run melos run analyze
   dart run melos run test
   ```

Each package README documents its top-level official `plugins:` configuration.
The nested example packages intentionally do not enable plugins because they are members of this pub workspace.

## Contributing

Feel free to open issues or submit pull requests to improve existing lint rules or add new ones.
Any feedback, suggestions, or bug reports are always welcome!

## License

This project is licensed under the BSD-3-Clause License. See the [LICENSE](./LICENSE) file for details.
