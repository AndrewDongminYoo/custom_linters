// 📦 Package imports:
import 'package:custom_lint_builder/custom_lint_builder.dart';

// 🌎 Project imports:
import 'package:go_router_linter/src/extensions/lint_code_extension.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

void main() {
  group('LintCodeCopyWithExtension', () {
    test('copyWith updates fields correctly', () {
      const original = LintCode(
        name: 'original_name',
        problemMessage: 'original problem',
        correctionMessage: 'original correction',
        uniqueName: 'original_unique',
        url: 'http://original.com',
      );

      final copied = original.copyWith(
        name: 'new_name',
        problemMessage: 'new problem',
        correctionMessage: 'new correction',
        uniqueName: 'new_unique',
        url: 'http://new.com',
      );

      expect(copied.name, 'new_name');
      expect(copied.problemMessage, 'new problem');
      expect(copied.correctionMessage, 'new correction');
      expect(copied.uniqueName, 'new_unique');
      expect(copied.url, 'http://new.com');
    });

    test('copyWith leaves fields unchanged if null', () {
      const original = LintCode(
        name: 'original_name',
        problemMessage: 'original problem',
        correctionMessage: 'original correction',
        uniqueName: 'original_unique',
        url: 'http://original.com',
      );

      final copied = original.copyWith();

      expect(copied.name, original.name);
      expect(copied.problemMessage, original.problemMessage);
      expect(copied.correctionMessage, original.correctionMessage);
      expect(copied.uniqueName, original.uniqueName);
      expect(copied.url, original.url);
    });
  });
}
