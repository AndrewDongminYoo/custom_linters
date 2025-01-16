// expect_lint: matching_class_and_file_name
class State {}

// expect_lint: single_class_per_file
class FakeStateClass {}

// expect_lint: single_class_per_file, matching_class_and_file_name
class FakeInheritedClass extends State {}
