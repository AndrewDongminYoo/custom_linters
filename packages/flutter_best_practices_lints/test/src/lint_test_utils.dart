// 🐦 Dart imports:
import 'dart:io';

// 📦 Package imports:
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

Future<List<String>> analyzeLintRule(
  DartLintRule rule,
  String source,
) async {
  final directory = Directory('test').createTempSync('lint_test_');

  try {
    final file = File('${directory.path}/main.dart')..writeAsStringSync(source);
    final result = await resolveFile(path: file.absolute.path);
    final diagnostics = await rule.testRun(result as ResolvedUnitResult);
    return diagnostics
        .map((diagnostic) => diagnostic.diagnosticCode.name)
        .toList();
  } finally {
    directory.deleteSync(recursive: true);
  }
}
