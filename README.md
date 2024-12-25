# Custom Linters

A monorepo for various custom lint rules that can enhance your Flutter and Dart code quality.  
Currently, this repository includes:

- **[go_router_linter](./packages/go_router_linter)**: A set of lint rules for the `go_router` package, helping you maintain consistent and robust route definitions in your Flutter apps.

## Contents

- **packages/**
  - [go_router_linter](./packages/go_router_linter): Contains the rules and tests for `go_router_linter`.
- **analysis_options.yaml**
  - Root-level lint and analyzer settings for shared rules across packages.
- **melos.yaml**
  - Configuration file for managing multiple packages within this monorepo.

## Getting Started

1.  **Clone the repository**:

    ```bash
    git clone https://github.com/YourUserName/custom_linters.git
    cd custom_linters
    ```

2.  Install Melos (optional):

    If you’re using Melos for managing your monorepo:

    ```bash
    dart pub global activate melos
    melos bootstrap
    ```

3.  Navigate to a package:

    For example, to check out the go_router_linter package:

    ```bash
    cd packages/go_router_linter
    ```

4.  Pub commands:

    • Get dependencies: `dart pub get`
    • Run tests: `dart pub test`
    • Analyze code: `dart analyze`

    Or use Melos commands (if configured), for example:

    ```bash
    melos run analyze
    melos run test
    ```

## Contributing

Feel free to open issues or submit pull requests to improve existing lint rules or add new ones.
Any feedback, suggestions, or bug reports are always welcome!

## License

This project is licensed under the BSD-3-Clause License. See the LICENSE file for details.
