abstract class State<T> {
  /// The current configuration.
  ///
  /// A [State] object's configuration is the corresponding `StatefulWidget`
  /// instance. This property is initialized by the framework before calling
  /// `initState`. If the parent updates this location in the tree to a new
  /// widget with the same `runtimeType` and `Widget.key` as the current
  /// configuration, the framework will update this property to refer to the new
  /// widget and then call `didUpdateWidget`, passing the old configuration as
  /// an argument.
  T get widget => _widget!;
  T? _widget;
}

// expect_lint: single_class_per_file
class FakeStateClass {}

// expect_lint: single_class_per_file, matching_class_and_file_name
class FakeInheritedState extends State {}
