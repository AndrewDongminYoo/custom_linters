// Example showing expected lint violations for:
// - matching_class_and_file_name
// - single_class_per_file

/// A minimal abstract fake State class
/// to simulate Flutter `State<T>` behavior in tests.
abstract class State<T> {
  /// The current configured widget instance of type [T].
  /// Stored privately and updated by the framework before initState.
  T get widget => _widget!;
  T? _widget;
}

// This file intentionally violates our lints for demonstration:
// - Two public classes: FakeStateClass and FakeInheritedState
// - Class names do not match file name

class FakeStateClass {}

class FakeInheritedState extends State<FakeStateClass> {}
