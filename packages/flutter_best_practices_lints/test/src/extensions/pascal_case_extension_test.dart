// 📦 Package imports:
import 'package:test/test.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/extensions/pascal_case_extension.dart';

void main() {
  group('String.toPascalCase()', () {
    test('converts single word to pascal case', () {
      expect('hello'.toPascalCase(), equals('Hello'));
      expect('WORLD'.toPascalCase(), equals('World'));
    });

    test('converts multiple words with spaces to pascal case', () {
      expect('hello world'.toPascalCase(), equals('HelloWorld'));
      expect('  hello   world  '.toPascalCase(), equals('HelloWorld'));
    });

    test('handles special characters and converts to pascal case', () {
      expect('hello@world'.toPascalCase(), equals('HelloWorld'));
      expect(r'hello#world$test'.toPascalCase(), equals('HelloWorldTest'));
      expect('hello!!!world???test'.toPascalCase(), equals('HelloWorldTest'));
    });

    test('handles numbers correctly', () {
      expect('hello123world'.toPascalCase(), equals('Hello123world'));
      expect('123hello'.toPascalCase(), equals('123hello'));
      expect('hello 123 world'.toPascalCase(), equals('Hello123World'));
    });

    test('handles empty and whitespace strings', () {
      expect(''.toPascalCase(), equals(''));
      expect('   '.toPascalCase(), equals(''));
      expect('\t\n'.toPascalCase(), equals(''));
    });

    test('handles mixed case input', () {
      expect('hElLo WoRlD'.toPascalCase(), equals('HelloWorld'));
      expect('JSON parser'.toPascalCase(), equals('JsonParser'));
      expect('XML Http Request'.toPascalCase(), equals('XmlHttpRequest'));
    });

    test('handles consecutive special characters', () {
      expect(r'hello@#$%world'.toPascalCase(), equals('HelloWorld'));
      expect('hello...world---test'.toPascalCase(), equals('HelloWorldTest'));
    });
  });
}
