// 📦 Package imports:
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// {@template lint_code_copy_with_ext}
/// An extension that provides a method for creating modified copies of a
/// [LintCode].
///
/// This allows you to selectively replace certain properties of a `LintCode`
/// instance without having to manually instantiate a new `LintCode` object
/// each time.
/// {@endtemplate}
extension LintCodeCopyWithExtension on LintCode {
  /// {@macro lint_code_copy_with_ext}
  ///
  /// Creates a copy of the current [LintCode] with updated fields.
  /// Any field left as `null` remains unchanged from the original instance.
  ///
  /// - [name]: The new name for the `LintCode`.
  /// - [problemMessage]: The new problem message associated with the `LintCode`
  /// - [correctionMessage]: The new correction message for this `LintCode`.
  /// - [uniqueName]: The new unique name for disambiguation.
  /// - [url]: The updated URL linking to further documentation or details.
  LintCode copyWith({
    String? name,
    String? problemMessage,
    String? correctionMessage,
    String? uniqueName,
    String? url,
  }) {
    return LintCode(
      name: name ?? this.name,
      problemMessage: problemMessage ?? this.problemMessage,
      correctionMessage: correctionMessage ?? this.correctionMessage,
      uniqueName: uniqueName ?? this.uniqueName,
      url: url ?? this.url,
    );
  }
}
