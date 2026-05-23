// 🐦 Dart imports:
import 'dart:io';

// 📦 Package imports:
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

Future<List<String>> analyzeLintRule(
  DartLintRule rule,
  String source, {
  Pubspec? pubspec,
}) async {
  final directory = Directory('test').createTempSync('lint_test_');

  try {
    final file = File('${directory.path}/main.dart')..writeAsStringSync(source);
    final result = await _resolveFile(file.absolute.path);
    final diagnostics = await rule.testRun(result, pubspec: pubspec);
    return diagnostics
        .map((diagnostic) => diagnostic.diagnosticCode.name)
        .toList();
  } finally {
    directory.deleteSync(recursive: true);
  }
}

Future<ResolvedUnitResult> _resolveFile(String path) async {
  final result = await _analysisContextCollection
      .contextFor(path)
      .currentSession
      .getResolvedUnit(path);
  if (result is ResolvedUnitResult) {
    return result;
  }

  throw StateError('Could not resolve $path: $result');
}

final _analysisContextCollection = AnalysisContextCollection(
  includedPaths: [Directory.current.absolute.path],
  sdkPath: _dartSdkPath(),
);

String? _dartSdkPath() {
  // flutter test runs on the engine Dart executable, so pass analyzer the SDK.
  for (final path in [
    Platform.environment['DART_HOME'],
    _flutterDartSdkPath(),
    File(Platform.resolvedExecutable).parent.parent.path,
  ]) {
    if (_isDartSdk(path)) {
      return path;
    }
  }

  return null;
}

String? _flutterDartSdkPath() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot == null || flutterRoot.isEmpty) {
    return null;
  }

  return _join(flutterRoot, ['bin', 'cache', 'dart-sdk']);
}

bool _isDartSdk(String? path) {
  if (path == null || path.isEmpty) {
    return false;
  }

  return File(_join(path, ['version'])).existsSync() &&
      File(
        _join(path, [
          'lib',
          '_internal',
          'sdk_library_metadata',
          'lib',
          'libraries.dart',
        ]),
      ).existsSync();
}

String _join(String base, List<String> parts) {
  final separator = Platform.pathSeparator;
  final normalizedBase = base.endsWith(separator)
      ? base.substring(0, base.length - 1)
      : base;

  return [normalizedBase, ...parts].join(separator);
}
