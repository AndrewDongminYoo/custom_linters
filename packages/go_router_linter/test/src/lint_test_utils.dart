// 🐦 Dart imports:
import 'dart:io';

// 📦 Package imports:
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:pubspec_parse/pubspec_parse.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

Future<List<Diagnostic>> analyzeLintRule(
  DartLintRule rule,
  String source, {
  Pubspec? pubspec,
  String relativePath = 'lib/main.dart',
}) async {
  final directory = Directory('test').createTempSync('lint_test_');

  try {
    final file = File(
      _join(directory.path, relativePath.split('/')),
    );
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(source);
    final result = await _resolveFile(file.absolute.path);
    return await rule.testRun(result, pubspec: pubspec);
  } finally {
    directory.deleteSync(recursive: true);
  }
}

void expectLintDiagnostic(
  Diagnostic diagnostic, {
  required String code,
  required String message,
  required String? correctionMessage,
  required int offset,
  required int length,
}) {
  expect(diagnostic.diagnosticCode.name, code);
  expect(diagnostic.diagnosticCode.severity, DiagnosticSeverity.INFO);
  expect(diagnostic.message, message);
  expect(diagnostic.correctionMessage, correctionMessage);
  expect(diagnostic.offset, offset);
  expect(diagnostic.length, length);
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
