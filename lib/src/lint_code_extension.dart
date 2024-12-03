// 📦 Package imports:
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// nodoc
extension LintCodeCopyWithExtension on LintCode {
  /// nodoc
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
