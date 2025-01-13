/// {@macro pascal_case_extension}
extension PascalCaseExtension on String {
  /// {@template pascal_case_extension}
  /// Converts the string to PascalCase.
  ///
  /// The transformation is performed in the following steps:
  /// 1. If the string is empty or consists only of whitespace, an empty
  ///    string is returned.
  /// 2. All characters that are not alphanumeric are replaced with a single
  ///    space. For example: "word1@#$%word2" becomes "word1 word2".
  /// 3. The string is split on whitespace (multiple spaces count as one),
  ///    and non-empty words are extracted.
  /// 4. If no words are found, an empty string is returned.
  /// 5. Each word is transformed so that only the first letter is in
  ///    uppercase and the remainder is in lowercase. The words are then
  ///    concatenated.
  /// {@endtemplate}
  String toPascalCase() {
    // 1. If the trimmed string is empty, return an empty string.
    if (trim().isEmpty) {
      return '';
    }

    // 2. Replace all non-alphanumeric characters with a single space.
    //    E.g.: "word1@#$%word2" becomes "word1 word2".
    final replaced = replaceAll(RegExp('[^a-zA-Z0-9]+'), ' ');

    // 3. Split the string on whitespace (treating multiple spaces as one)
    //    and extract only non-empty words.
    final words = replaced
        .split(RegExp(r'\s+')) // multiple spaces treated as one.
        .where((w) => w.isNotEmpty)
        .toList();

    // 4. If no words are found, return an empty string.
    if (words.isEmpty) {
      return '';
    }

    // 5. For each word, convert the first letter to uppercase and the rest
    //    to lowercase, then concatenate them.
    final buffer = StringBuffer();
    for (final word in words) {
      final lower = word.toLowerCase();
      // Capitalize only the first letter, the rest remain in lowercase.
      final capitalized = lower[0].toUpperCase() + lower.substring(1);
      buffer.write(capitalized);
    }

    return buffer.toString();
  }
}
