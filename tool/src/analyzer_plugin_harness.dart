// 🐦 Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:io';

const flutterDiagnosticCodes = <String>{
  'single_class_per_file',
  'matching_class_and_file_name',
  'prefer_widget_class_over_widget_helper',
  'avoid_widget_operator_equals',
  'prefer_media_query_partial_methods',
};

const goRouterDiagnosticCodes = <String>{
  'missing_go_route_name_property',
  'use_context_directly_for_go_router',
  'avoid_hardcoded_routes',
  'avoid_navigator_named_routes_with_go_router',
  'missing_go_router_error_handler',
};

enum PluginSelector { flutterBestPracticesLints, goRouterLinter, all }

enum PluginSource { local, hosted }

enum AnalyzerSelector { dart, flutter, all }

enum ProcessFailureKind {
  dependencyResolution,
  pluginLoad,
  diagnosticMismatch,
  parser,
  crash,
  timeout,
}

enum ConsumerScenario { violating, compliant, disabledRule, qualifiedIgnore }

final class HarnessOptions {
  const HarnessOptions({
    required this.plugin,
    required this.source,
    required this.analyzer,
    required this.repeat,
    required this.timeout,
    required this.packageVersions,
    required this.diagnostics,
    required this.negativeControl,
  });

  final PluginSelector plugin;
  final PluginSource source;
  final AnalyzerSelector analyzer;
  final int repeat;
  final Duration timeout;
  final Map<String, String> packageVersions;
  final Set<String> diagnostics;
  final bool negativeControl;
}

final class HarnessSummary {
  const HarnessSummary({
    required this.analyzerRuns,
    required this.resolvedVersions,
  });

  final int analyzerRuns;
  final Map<String, String> resolvedVersions;
}

final class DiagnosticRecord {
  const DiagnosticRecord({
    required this.code,
    required this.severity,
    required this.message,
    required this.path,
    required this.line,
    required this.column,
  });

  final String code;
  final String severity;
  final String message;
  final String path;
  final int line;
  final int column;
}

final class ProcessRunResult {
  const ProcessRunResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.elapsed,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
  final Duration elapsed;
}

final class HarnessFailure implements Exception {
  const HarnessFailure({
    required this.kind,
    required this.message,
    this.exitCode,
    this.stdout = '',
    this.stderr = '',
  });

  final ProcessFailureKind kind;
  final String message;
  final int? exitCode;
  final String stdout;
  final String stderr;

  @override
  String toString() => '$kind: $message';
}

final class HarnessProcessFailure implements Exception {
  const HarnessProcessFailure({
    required this.kind,
    required this.message,
    required this.stdout,
    required this.stderr,
    required this.recordedPids,
    required this.stdoutClosed,
    required this.stderrClosed,
  });

  final ProcessFailureKind kind;
  final String message;
  final String stdout;
  final String stderr;
  final List<int> recordedPids;
  final bool stdoutClosed;
  final bool stderrClosed;

  @override
  String toString() => '$kind: $message';
}

final class AnalyzerProcessRunner {
  const AnalyzerProcessRunner();

  Future<ProcessRunResult> run({
    required String executable,
    required List<String> arguments,
    required String workingDirectory,
    required Duration timeout,
    Map<String, String>? environment,
  }) async {
    final stopwatch = Stopwatch()..start();
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );
    final stdoutFuture = process.stdout.transform(utf8.decoder).join();
    final stderrFuture = process.stderr.transform(utf8.decoder).join();

    try {
      final exitCode = await process.exitCode.timeout(timeout);
      final capturedStdout = await _captureOutput(stdoutFuture);
      final capturedStderr = await _captureOutput(stderrFuture);
      stopwatch.stop();
      return ProcessRunResult(
        exitCode: exitCode,
        stdout: capturedStdout.text,
        stderr: capturedStderr.text,
        elapsed: stopwatch.elapsed,
      );
    } on TimeoutException {
      final descendants = await _descendantPids(process.pid);
      final recordedPids = [process.pid, ...descendants];
      final survivors = await _terminateProcessTree(process, descendants);
      final capturedStdout = await _captureOutput(stdoutFuture);
      final capturedStderr = await _captureOutput(stderrFuture);
      stopwatch.stop();
      throw HarnessProcessFailure(
        kind: ProcessFailureKind.timeout,
        message: survivors.isEmpty
            ? 'Process exceeded ${timeout.inSeconds} seconds.'
            : 'Process exceeded ${timeout.inSeconds} seconds and PIDs '
                  '${survivors.join(', ')} survived cleanup.',
        stdout: capturedStdout.text,
        stderr: capturedStderr.text,
        recordedPids: List.unmodifiable(recordedPids),
        stdoutClosed: capturedStdout.closed,
        stderrClosed: capturedStderr.closed,
      );
    }
  }
}

final class _CapturedOutput {
  const _CapturedOutput({required this.text, required this.closed});

  final String text;
  final bool closed;
}

Future<_CapturedOutput> _captureOutput(Future<String> output) async {
  try {
    return _CapturedOutput(text: await output, closed: true);
  } on Object catch (error) {
    return _CapturedOutput(
      text: 'OUTPUT_STREAM_ERROR: $error',
      closed: false,
    );
  }
}

Future<List<int>> _descendantPids(int parentPid) async {
  if (Platform.isWindows) {
    return _windowsDescendantPids(parentPid);
  }

  final result = await Process.run('pgrep', ['-P', '$parentPid']);
  if (result.exitCode != 0) {
    return const [];
  }
  final children = '${result.stdout}'
      .split(RegExp(r'\s+'))
      .map(int.tryParse)
      .whereType<int>();
  final descendants = <int>[];
  for (final child in children) {
    descendants
      ..addAll(await _descendantPids(child))
      ..add(child);
  }
  return descendants;
}

Future<List<int>> _windowsDescendantPids(int parentPid) async {
  final result = await Process.run('powershell', [
    '-NoProfile',
    '-NonInteractive',
    '-Command',
    '(Get-CimInstance Win32_Process -Filter "ParentProcessId=$parentPid").ProcessId',
  ]);
  if (result.exitCode != 0) {
    return const [];
  }
  final children = '${result.stdout}'
      .split(RegExp(r'\s+'))
      .map(int.tryParse)
      .whereType<int>();
  final descendants = <int>[];
  for (final child in children) {
    descendants
      ..addAll(await _windowsDescendantPids(child))
      ..add(child);
  }
  return descendants;
}

Future<List<int>> _terminateProcessTree(
  Process process,
  List<int> descendants,
) async {
  if (Platform.isWindows) {
    await Process.run('taskkill', ['/PID', '${process.pid}', '/T']);
  } else {
    for (final processId in descendants) {
      _killPid(processId, ProcessSignal.sigterm);
    }
    process.kill();
  }

  var survivors = await _waitForProcessesToExit(
    [process.pid, ...descendants],
    const Duration(seconds: 10),
  );
  if (survivors.isEmpty) {
    await process.exitCode;
    return const [];
  }

  if (Platform.isWindows) {
    await Process.run('taskkill', [
      '/PID',
      '${process.pid}',
      '/T',
      '/F',
    ]);
  } else {
    for (final processId in descendants.where(survivors.contains)) {
      _killPid(processId, ProcessSignal.sigkill);
    }
    process.kill(ProcessSignal.sigkill);
  }

  survivors = await _waitForProcessesToExit(
    survivors,
    const Duration(seconds: 10),
  );
  try {
    await process.exitCode.timeout(const Duration(seconds: 10));
  } on TimeoutException {
    // The surviving root PID is returned below with the timeout failure.
  }
  return survivors;
}

void _killPid(int processId, ProcessSignal signal) {
  try {
    Process.killPid(processId, signal);
  } on ProcessException {
    // The process may have exited between discovery and signaling.
  }
}

Future<List<int>> _waitForProcessesToExit(
  List<int> processIds,
  Duration timeout,
) async {
  final stopwatch = Stopwatch()..start();
  var survivors = List<int>.of(processIds);
  while (stopwatch.elapsed < timeout) {
    survivors = [
      for (final processId in survivors)
        if (await isProcessRunning(processId)) processId,
    ];
    if (survivors.isEmpty) {
      return const [];
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  return survivors;
}

Future<bool> isProcessRunning(int processId) async {
  if (processId <= 0) {
    return false;
  }
  if (Platform.isWindows) {
    final result = await Process.run('tasklist', [
      '/FI',
      'PID eq $processId',
      '/FO',
      'CSV',
      '/NH',
    ]);
    return result.exitCode == 0 &&
        RegExp('"$processId"').hasMatch('${result.stdout}');
  }
  final result = await Process.run('kill', ['-0', '$processId']);
  return result.exitCode == 0;
}

final class ConsumerFixture {
  const ConsumerFixture({
    required this.root,
    required this.pubspecYaml,
    required this.analysisOptionsYaml,
    required this.files,
    required this.expectedDiagnostics,
  });

  final Directory root;
  final String pubspecYaml;
  final String analysisOptionsYaml;
  final Map<String, String> files;
  final List<DiagnosticRecord> expectedDiagnostics;

  Future<void> write() async {
    await root.create(recursive: true);
    await File(_joinPath(root.path, 'pubspec.yaml')).writeAsString(pubspecYaml);
    await File(
      _joinPath(root.path, 'analysis_options.yaml'),
    ).writeAsString(analysisOptionsYaml);
    for (final entry in files.entries) {
      final file = File(_joinPath(root.path, entry.key));
      await file.parent.create(recursive: true);
      await file.writeAsString(entry.value);
    }
  }
}

void assertDiagnosticRecords({
  required List<DiagnosticRecord> actual,
  required List<DiagnosticRecord> expected,
}) {
  final remaining = List<DiagnosticRecord>.of(actual);
  for (final expectedRecord in expected) {
    final matchIndex = remaining.indexWhere(
      (actualRecord) => _sameDiagnostic(actualRecord, expectedRecord),
    );
    if (matchIndex < 0) {
      throw HarnessFailure(
        kind: ProcessFailureKind.diagnosticMismatch,
        message:
            'HARNESS_ASSERTION_FAILED: missing diagnostic '
            '${expectedRecord.code} at ${expectedRecord.path}:'
            '${expectedRecord.line}:${expectedRecord.column}',
      );
    }
    remaining.removeAt(matchIndex);
  }
  if (remaining.isNotEmpty) {
    final record = remaining.first;
    throw HarnessFailure(
      kind: ProcessFailureKind.diagnosticMismatch,
      message:
          'HARNESS_ASSERTION_FAILED: unexpected diagnostic ${record.code} '
          'at ${record.path}:${record.line}:${record.column}',
    );
  }
}

bool _sameDiagnostic(DiagnosticRecord actual, DiagnosticRecord expected) {
  return actual.code == expected.code &&
      actual.severity == expected.severity &&
      actual.message == expected.message &&
      actual.path == expected.path &&
      actual.line == expected.line &&
      actual.column == expected.column;
}

List<DiagnosticRecord> parseDartAnalyzeOutput(String output) {
  return _parseAnalyzerOutput(
    output,
    recordPattern: RegExp(
      r'^\s*(error|warning|info)\s+-\s+(.+):(\d+):(\d+)\s+-\s+'
      r'(.*?)\s+-\s+(\S+)\s*$',
      caseSensitive: false,
    ),
    toRecord: (match) => _recordFromMatch(
      match,
      messageGroup: 5,
      pathGroup: 2,
      lineGroup: 3,
      columnGroup: 4,
      codeGroup: 6,
    ),
  );
}

List<DiagnosticRecord> parseFlutterAnalyzeOutput(String output) {
  return _parseAnalyzerOutput(
    output,
    recordPattern: RegExp(
      r'^\s*(error|warning|info)\s+•\s+(.*?)\s+•\s+'
      r'(.+):(\d+):(\d+)\s+•\s+(\S+)\s*$',
      caseSensitive: false,
    ),
    toRecord: (match) => _recordFromMatch(
      match,
      messageGroup: 2,
      pathGroup: 3,
      lineGroup: 4,
      columnGroup: 5,
      codeGroup: 6,
    ),
  );
}

List<DiagnosticRecord> _parseAnalyzerOutput(
  String output, {
  required RegExp recordPattern,
  required DiagnosticRecord Function(RegExpMatch match) toRecord,
}) {
  final normalized = output.replaceAll(_ansiEscape, '');
  if (normalized.trim().isEmpty) {
    throw const FormatException('Analyzer output is empty.');
  }

  final records = <DiagnosticRecord>[];
  for (final line in normalized.split(RegExp(r'\r?\n'))) {
    final match = recordPattern.firstMatch(line);
    if (match != null) {
      records.add(toRecord(match));
      continue;
    }
    if (_diagnosticLineStart.hasMatch(line)) {
      throw FormatException('Truncated analyzer diagnostic: $line');
    }
  }

  final countMatch = _issueCount.firstMatch(normalized);
  if (countMatch != null) {
    final statedCount = int.parse(countMatch.group(1)!);
    if (statedCount != records.length) {
      throw FormatException(
        'Analyzer stated $statedCount diagnostics but parsed ${records.length}.',
      );
    }
    return records;
  }
  if (normalized.contains('No issues found!') && records.isEmpty) {
    return records;
  }
  throw const FormatException('Analyzer output has no completion summary.');
}

DiagnosticRecord _recordFromMatch(
  RegExpMatch match, {
  required int messageGroup,
  required int pathGroup,
  required int lineGroup,
  required int columnGroup,
  required int codeGroup,
}) {
  final line = int.parse(match.group(lineGroup)!);
  final column = int.parse(match.group(columnGroup)!);
  if (line <= 0 || column <= 0) {
    throw const FormatException(
      'Analyzer diagnostics must use positive line and column values.',
    );
  }
  return DiagnosticRecord(
    code: match.group(codeGroup)!,
    severity: match.group(1)!.toUpperCase(),
    message: match.group(messageGroup)!,
    path: match.group(pathGroup)!,
    line: line,
    column: column,
  );
}

final _ansiEscape = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');
final _diagnosticLineStart = RegExp(
  r'^\s*(error|warning|info)\b',
  caseSensitive: false,
);
final _issueCount = RegExp(r'\b(\d+) issues? found\b');

ConsumerFixture generateConsumerFixture(
  HarnessOptions options, {
  required Directory repositoryRoot,
  required Directory consumerRoot,
  required ConsumerScenario scenario,
}) {
  final repositoryPath = _normalizedPath(repositoryRoot.path);
  final consumerPath = _normalizedPath(consumerRoot.path);
  if (_isWithin(consumerPath, repositoryPath)) {
    throw ArgumentError.value(
      consumerRoot.path,
      'consumerRoot',
      'The standalone consumer must be outside the workspace.',
    );
  }

  final selectedPackages = _packageNames(options.plugin);
  final selectedDiagnostics = options.diagnostics.toList();
  final disabledCode = scenario == ConsumerScenario.disabledRule
      ? selectedDiagnostics.first
      : null;
  final enabledDiagnostics = selectedDiagnostics
      .where((code) => code != disabledCode)
      .toSet();
  final files = <String, String>{};
  final expectedDiagnostics = <DiagnosticRecord>[];

  switch (scenario) {
    case ConsumerScenario.violating:
      for (final code in selectedDiagnostics) {
        final sourceCase = _violatingSource(code);
        final path = 'lib/$code.dart';
        files[path] = sourceCase.source;
        expectedDiagnostics.add(
          _expectedDiagnostic(
            code,
            path,
            sourceCase.source,
            sourceCase.diagnosticNeedle,
            problemMessage: sourceCase.problemMessage,
          ),
        );
      }
    case ConsumerScenario.compliant:
      for (final code in selectedDiagnostics) {
        files['lib/$code.dart'] = _compliantSource(code);
      }
    case ConsumerScenario.disabledRule:
      files['lib/$disabledCode.dart'] = _violatingSource(disabledCode!).source;
    case ConsumerScenario.qualifiedIgnore:
      final code = selectedDiagnostics.first;
      final sourceCase = _qualifiedIgnoreSource(code);
      final path = 'lib/$code.dart';
      files[path] = sourceCase.source;
      expectedDiagnostics.add(
        _expectedDiagnostic(
          code,
          path,
          sourceCase.source,
          sourceCase.diagnosticNeedle,
          occurrence: sourceCase.needleOccurrence,
          problemMessage: sourceCase.problemMessage,
        ),
      );
  }

  return ConsumerFixture(
    root: Directory(consumerPath),
    pubspecYaml: _consumerPubspec(selectedPackages),
    analysisOptionsYaml: _analysisOptions(
      options,
      repositoryPath,
      selectedPackages,
      enabledDiagnostics,
    ),
    files: Map.unmodifiable(files),
    expectedDiagnostics: List.unmodifiable(expectedDiagnostics),
  );
}

Future<HarnessSummary> runAnalyzerPluginHarness(
  HarnessOptions options, {
  required Directory repositoryRoot,
  AnalyzerProcessRunner processRunner = const AnalyzerProcessRunner(),
  void Function(String message) log = print,
}) async {
  final repositoryPath = _normalizedPath(repositoryRoot.path);
  _validateRepository(repositoryPath);
  final invocationRoot = await Directory.systemTemp.createTemp(
    'custom_linters_analyzer_harness_',
  );
  final consumerRoot = Directory(_joinPath(invocationRoot.path, 'consumer'));
  final analyzerState = Directory(
    _joinPath(invocationRoot.path, 'analyzer_state'),
  );
  final pubCache = options.source == PluginSource.hosted
      ? Directory(_joinPath(invocationRoot.path, 'pub_cache'))
      : null;
  await analyzerState.create(recursive: true);
  await pubCache?.create(recursive: true);
  final environment = <String, String>{
    'NO_COLOR': '1',
    'ANALYZER_STATE_LOCATION_OVERRIDE': analyzerState.path,
    if (pubCache != null) 'PUB_CACHE': pubCache.path,
  };

  try {
    final initialFixture = generateConsumerFixture(
      options,
      repositoryRoot: Directory(repositoryPath),
      consumerRoot: consumerRoot,
      scenario: ConsumerScenario.violating,
    );
    await initialFixture.write();
    final resolution = await processRunner.run(
      executable: 'flutter',
      arguments: const ['pub', 'get'],
      workingDirectory: consumerRoot.path,
      environment: environment,
      timeout: options.timeout,
    );
    _logResult(
      log,
      command: 'flutter pub get',
      result: resolution,
    );
    if (resolution.exitCode != 0) {
      throw HarnessFailure(
        kind: ProcessFailureKind.dependencyResolution,
        message: 'Flutter dependency resolution failed.',
        exitCode: resolution.exitCode,
        stdout: resolution.stdout,
        stderr: resolution.stderr,
      );
    }

    final consumerDependencies = await _readDependencyGraph(
      processRunner,
      directory: consumerRoot,
      environment: environment,
      timeout: options.timeout,
    );
    _validateConsumerDependencies(options, consumerDependencies);
    log(
      'HARNESS_HOST: os=${Platform.operatingSystem} '
      'dart=${Platform.version.split(' ').first} '
      'source=${options.source.name}',
    );

    var analyzerRuns = 0;
    Map<String, String>? resolvedVersions;
    for (final analyzer in _selectedAnalyzers(options.analyzer)) {
      for (var repetition = 0; repetition < options.repeat; repetition++) {
        for (final scenario in ConsumerScenario.values) {
          final fixture = generateConsumerFixture(
            options,
            repositoryRoot: Directory(repositoryPath),
            consumerRoot: consumerRoot,
            scenario: scenario,
          );
          await _replaceFixture(fixture);
          final command = _analyzerCommand(analyzer);
          final result = await processRunner.run(
            executable: command.executable,
            arguments: command.arguments,
            workingDirectory: consumerRoot.path,
            environment: environment,
            timeout: options.timeout,
          );
          analyzerRuns++;
          _logResult(
            log,
            command: command.display,
            result: result,
            detail:
                'analyzer=${analyzer.name} repetition=${repetition + 1} '
                'scenario=${scenario.name}',
          );

          final records =
              _parseAnalyzerResult(
                    analyzer,
                    result,
                  )
                  .map((record) => _relativeRecord(record, consumerRoot.path))
                  .toList();
          var expected = fixture.expectedDiagnostics;
          if (options.negativeControl && analyzerRuns == 1) {
            expected = [
              _copyDiagnostic(
                expected.first,
                code: '__negative_control_missing_code__',
              ),
              ...expected.skip(1),
            ];
          }
          assertDiagnosticRecords(actual: records, expected: expected);
          _assertAnalyzerExit(result, scenario);

          resolvedVersions ??= await _verifySyntheticPluginGraph(
            options,
            repositoryPath: repositoryPath,
            analyzerState: analyzerState,
            pubCache: pubCache,
            processRunner: processRunner,
            environment: environment,
            timeout: options.timeout,
          );
          log(
            'HARNESS_DIAGNOSTICS_OK: analyzer=${analyzer.name} '
            'repetition=${repetition + 1} scenario=${scenario.name} '
            'records=${records.length}',
          );
        }
      }
    }

    return HarnessSummary(
      analyzerRuns: analyzerRuns,
      resolvedVersions: Map.unmodifiable(resolvedVersions ?? const {}),
    );
  } finally {
    if (invocationRoot.existsSync()) {
      await invocationRoot.delete(recursive: true);
    }
  }
}

void _validateRepository(String repositoryPath) {
  final manifest = File(_joinPath(repositoryPath, 'pubspec.yaml'));
  final flutterPackage = Directory(
    _joinPath(repositoryPath, 'packages', 'flutter_best_practices_lints'),
  );
  final goRouterPackage = Directory(
    _joinPath(repositoryPath, 'packages', 'go_router_linter'),
  );
  if (!manifest.existsSync() ||
      !flutterPackage.existsSync() ||
      !goRouterPackage.existsSync()) {
    throw ArgumentError.value(
      repositoryPath,
      'repositoryRoot',
      'Expected the custom_linters repository root.',
    );
  }
}

Future<void> _replaceFixture(ConsumerFixture fixture) async {
  final libDirectory = Directory(_joinPath(fixture.root.path, 'lib'));
  if (libDirectory.existsSync()) {
    await libDirectory.delete(recursive: true);
  }
  await fixture.write();
}

final class _AnalyzerCommand {
  const _AnalyzerCommand({
    required this.executable,
    required this.arguments,
    required this.display,
  });

  final String executable;
  final List<String> arguments;
  final String display;
}

_AnalyzerCommand _analyzerCommand(AnalyzerSelector analyzer) =>
    switch (analyzer) {
      AnalyzerSelector.dart => const _AnalyzerCommand(
        executable: 'dart',
        arguments: ['analyze', '--fatal-infos', '--fatal-warnings', '.'],
        display: 'dart analyze --fatal-infos --fatal-warnings .',
      ),
      AnalyzerSelector.flutter => const _AnalyzerCommand(
        executable: 'flutter',
        arguments: ['analyze', '--fatal-infos', '--fatal-warnings', '.'],
        display: 'flutter analyze --fatal-infos --fatal-warnings .',
      ),
      AnalyzerSelector.all => throw StateError(
        'The all selector must be expanded before command creation.',
      ),
    };

List<AnalyzerSelector> _selectedAnalyzers(AnalyzerSelector selector) =>
    switch (selector) {
      AnalyzerSelector.dart => const [AnalyzerSelector.dart],
      AnalyzerSelector.flutter => const [AnalyzerSelector.flutter],
      AnalyzerSelector.all => const [
        AnalyzerSelector.dart,
        AnalyzerSelector.flutter,
      ],
    };

void _logResult(
  void Function(String message) log, {
  required String command,
  required ProcessRunResult result,
  String? detail,
}) {
  final detailPrefix = detail == null ? '' : '$detail ';
  log(
    'HARNESS_PROCESS: command="$command" '
    '$detailPrefix'
    'exit=${result.exitCode} '
    'elapsed_ms=${result.elapsed.inMilliseconds}',
  );
}

List<DiagnosticRecord> _parseAnalyzerResult(
  AnalyzerSelector analyzer,
  ProcessRunResult result,
) {
  final output = '${result.stdout}\n${result.stderr}';
  try {
    return switch (analyzer) {
      AnalyzerSelector.dart => parseDartAnalyzeOutput(output),
      AnalyzerSelector.flutter => parseFlutterAnalyzeOutput(output),
      AnalyzerSelector.all => throw StateError(
        'The all selector must be expanded before parsing.',
      ),
    };
  } on FormatException catch (error) {
    final kind = _looksLikePluginLoadFailure(output)
        ? ProcessFailureKind.pluginLoad
        : result.exitCode != 0
        ? ProcessFailureKind.crash
        : ProcessFailureKind.parser;
    throw HarnessFailure(
      kind: kind,
      message: 'Could not parse complete analyzer output: $error',
      exitCode: result.exitCode,
      stdout: result.stdout,
      stderr: result.stderr,
    );
  }
}

bool _looksLikePluginLoadFailure(String output) {
  final lower = output.toLowerCase();
  return lower.contains('plugin') &&
      (lower.contains('failed to load') ||
          lower.contains('could not load') ||
          lower.contains('plugin error'));
}

void _assertAnalyzerExit(
  ProcessRunResult result,
  ConsumerScenario scenario,
) {
  final shouldSucceed =
      scenario == ConsumerScenario.compliant ||
      scenario == ConsumerScenario.disabledRule;
  if (shouldSucceed && result.exitCode != 0) {
    throw HarnessFailure(
      kind: ProcessFailureKind.diagnosticMismatch,
      message:
          'HARNESS_ASSERTION_FAILED: ${scenario.name} fixture returned '
          '${result.exitCode}',
      exitCode: result.exitCode,
      stdout: result.stdout,
      stderr: result.stderr,
    );
  }
  if (!shouldSucceed && result.exitCode == 0) {
    throw HarnessFailure(
      kind: ProcessFailureKind.diagnosticMismatch,
      message:
          'HARNESS_ASSERTION_FAILED: ${scenario.name} fixture returned zero',
      exitCode: result.exitCode,
      stdout: result.stdout,
      stderr: result.stderr,
    );
  }
}

DiagnosticRecord _relativeRecord(DiagnosticRecord record, String consumerPath) {
  var path = record.path;
  if (_isAbsolutePath(path)) {
    final normalized = _normalizedPath(path);
    if (_isWithin(normalized, consumerPath)) {
      path = normalized.substring(consumerPath.length + 1);
    }
  }
  return _copyDiagnostic(
    record,
    path: path.replaceAll(r'\', '/'),
  );
}

bool _isAbsolutePath(String path) {
  return path.startsWith(Platform.pathSeparator) ||
      RegExp(r'^[A-Za-z]:[\\/]').hasMatch(path);
}

DiagnosticRecord _copyDiagnostic(
  DiagnosticRecord record, {
  String? code,
  String? path,
}) {
  return DiagnosticRecord(
    code: code ?? record.code,
    severity: record.severity,
    message: record.message,
    path: path ?? record.path,
    line: record.line,
    column: record.column,
  );
}

Future<Map<String, String>> _readDependencyGraph(
  AnalyzerProcessRunner processRunner, {
  required Directory directory,
  required Map<String, String> environment,
  required Duration timeout,
}) async {
  final result = await processRunner.run(
    executable: 'dart',
    arguments: const ['pub', 'deps', '--json'],
    workingDirectory: directory.path,
    environment: environment,
    timeout: timeout,
  );
  if (result.exitCode != 0) {
    throw HarnessFailure(
      kind: ProcessFailureKind.dependencyResolution,
      message: 'Could not inspect the dependency graph in ${directory.path}.',
      exitCode: result.exitCode,
      stdout: result.stdout,
      stderr: result.stderr,
    );
  }
  try {
    final json = jsonDecode(result.stdout) as Map<String, Object?>;
    final packages = json['packages']! as List<Object?>;
    return {
      for (final package in packages.cast<Map<String, Object?>>())
        package['name']! as String: package['version']! as String,
    };
  } on Object catch (error) {
    throw HarnessFailure(
      kind: ProcessFailureKind.parser,
      message: 'Could not parse dart pub deps --json output: $error',
      exitCode: result.exitCode,
      stdout: result.stdout,
      stderr: result.stderr,
    );
  }
}

void _validateConsumerDependencies(
  HarnessOptions options,
  Map<String, String> dependencies,
) {
  for (final package in _packageNames(options.plugin)) {
    if (dependencies.containsKey(package)) {
      throw HarnessFailure(
        kind: ProcessFailureKind.dependencyResolution,
        message: '$package must not be a consumer pubspec dependency.',
      );
    }
  }
  if (options.plugin == PluginSelector.goRouterLinter ||
      options.plugin == PluginSelector.all) {
    final version = dependencies['go_router'];
    if (version != '17.5.0') {
      throw HarnessFailure(
        kind: ProcessFailureKind.dependencyResolution,
        message: 'Expected go_router 17.5.0 but resolved $version.',
      );
    }
  }
}

Future<Map<String, String>> _verifySyntheticPluginGraph(
  HarnessOptions options, {
  required String repositoryPath,
  required Directory analyzerState,
  required Directory? pubCache,
  required AnalyzerProcessRunner processRunner,
  required Map<String, String> environment,
  required Duration timeout,
}) async {
  final syntheticPackages = <Directory>[];
  await for (final entity in analyzerState.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File || entity.uri.pathSegments.last != 'pubspec.yaml') {
      continue;
    }
    if ((await entity.readAsString()).contains('name: plugin_entrypoint')) {
      syntheticPackages.add(entity.parent);
    }
  }
  if (syntheticPackages.length != 1) {
    throw HarnessFailure(
      kind: ProcessFailureKind.dependencyResolution,
      message:
          'Expected one synthetic plugin package, found '
          '${syntheticPackages.length}.',
    );
  }

  final syntheticPackage = syntheticPackages.single;
  final packageConfig = File(
    _joinPath(syntheticPackage.path, '.dart_tool', 'package_config.json'),
  );
  if (!packageConfig.existsSync()) {
    throw const HarnessFailure(
      kind: ProcessFailureKind.dependencyResolution,
      message: 'Synthetic plugin package_config.json is missing.',
    );
  }
  final packageRoots = await _readPackageRoots(packageConfig);
  final selectedPackages = _packageNames(options.plugin);
  for (final package in selectedPackages) {
    final actualRoot = packageRoots[package];
    if (actualRoot == null) {
      throw HarnessFailure(
        kind: ProcessFailureKind.dependencyResolution,
        message: 'Synthetic graph does not contain $package.',
      );
    }
    switch (options.source) {
      case PluginSource.local:
        final expectedRoot = _joinPath(repositoryPath, 'packages', package);
        if (_normalizedPath(actualRoot) != _normalizedPath(expectedRoot)) {
          throw HarnessFailure(
            kind: ProcessFailureKind.dependencyResolution,
            message:
                'Expected $package at $expectedRoot but resolved $actualRoot.',
          );
        }
      case PluginSource.hosted:
        if (pubCache == null ||
            !_isWithin(
              _normalizedPath(actualRoot),
              _normalizedPath(pubCache.path),
            )) {
          throw HarnessFailure(
            kind: ProcessFailureKind.dependencyResolution,
            message:
                'Hosted $package did not resolve inside the dedicated PUB_CACHE.',
          );
        }
    }
  }

  final dependencies = await _readDependencyGraph(
    processRunner,
    directory: syntheticPackage,
    environment: environment,
    timeout: timeout,
  );
  for (final package in selectedPackages) {
    final actualVersion = dependencies[package];
    if (options.source == PluginSource.hosted &&
        actualVersion != options.packageVersions[package]) {
      throw HarnessFailure(
        kind: ProcessFailureKind.dependencyResolution,
        message:
            'Expected hosted $package ${options.packageVersions[package]} '
            'but resolved $actualVersion.',
      );
    }
  }
  for (final dependency in const [
    'analysis_server_plugin',
    'analyzer',
    'analyzer_plugin',
  ]) {
    if (!dependencies.containsKey(dependency)) {
      throw HarnessFailure(
        kind: ProcessFailureKind.dependencyResolution,
        message: 'Synthetic graph does not contain $dependency.',
      );
    }
  }
  return dependencies;
}

Future<Map<String, String>> _readPackageRoots(File packageConfig) async {
  try {
    final json =
        jsonDecode(await packageConfig.readAsString()) as Map<String, Object?>;
    final packages = json['packages']! as List<Object?>;
    return {
      for (final package in packages.cast<Map<String, Object?>>())
        package['name']! as String: packageConfig.uri
            .resolve(package['rootUri']! as String)
            .toFilePath(),
    };
  } on Object catch (error) {
    throw HarnessFailure(
      kind: ProcessFailureKind.parser,
      message: 'Could not parse ${packageConfig.path}: $error',
    );
  }
}

String _consumerPubspec(Set<String> selectedPackages) {
  final buffer = StringBuffer()
    ..writeln('name: analyzer_plugin_consumer')
    ..writeln('publish_to: none')
    ..writeln('environment:')
    ..writeln("  sdk: '>=3.10.0 <4.0.0'")
    ..writeln('dependencies:')
    ..writeln('  flutter:')
    ..writeln('    sdk: flutter');
  if (selectedPackages.contains('go_router_linter')) {
    buffer.writeln('  go_router: 17.5.0');
  }
  return buffer.toString();
}

String _analysisOptions(
  HarnessOptions options,
  String repositoryPath,
  Set<String> selectedPackages,
  Set<String> enabledDiagnostics,
) {
  final buffer = StringBuffer()..writeln('plugins:');
  for (final package in selectedPackages) {
    buffer.writeln('  $package:');
    switch (options.source) {
      case PluginSource.local:
        buffer.writeln(
          '    path: ${_joinPath(repositoryPath, 'packages', package)}',
        );
      case PluginSource.hosted:
        buffer.writeln('    version: ${options.packageVersions[package]}');
    }
    final packageDiagnostics = enabledDiagnostics.where(
      (code) => _packageForDiagnostic(code) == package,
    );
    if (packageDiagnostics.isNotEmpty) {
      buffer.writeln('    diagnostics:');
      for (final code in packageDiagnostics) {
        buffer.writeln('      $code: true');
      }
    }
  }
  return buffer.toString();
}

DiagnosticRecord _expectedDiagnostic(
  String code,
  String path,
  String source,
  String needle, {
  int occurrence = 0,
  String? problemMessage,
}) {
  final offset = _indexOfOccurrence(source, needle, occurrence);
  final prefix = source.substring(0, offset);
  final line = '\n'.allMatches(prefix).length + 1;
  final lastNewline = prefix.lastIndexOf('\n');
  final column = offset - lastNewline;
  return DiagnosticRecord(
    code: code,
    severity: 'INFO',
    message: problemMessage ?? _problemMessages[code]!,
    path: path,
    line: line,
    column: column,
  );
}

int _indexOfOccurrence(String source, String needle, int occurrence) {
  var offset = -1;
  for (var index = 0; index <= occurrence; index++) {
    offset = source.indexOf(needle, offset + 1);
    if (offset < 0) {
      throw StateError(
        'Missing fixture marker $needle occurrence $occurrence.',
      );
    }
  }
  return offset;
}

final class _SourceCase {
  const _SourceCase(
    this.source,
    this.diagnosticNeedle, {
    this.needleOccurrence = 0,
    this.problemMessage,
  });

  final String source;
  final String diagnosticNeedle;
  final int needleOccurrence;
  final String? problemMessage;
}

_SourceCase _violatingSource(String code) => switch (code) {
  'single_class_per_file' => const _SourceCase('''
// ignore_for_file: flutter_best_practices_lints/matching_class_and_file_name

class SingleClassPerFile {}
class ExtraClass {}
''', 'class ExtraClass {}'),
  'matching_class_and_file_name' => const _SourceCase(
    'class WrongName {}\n',
    'class WrongName {}',
  ),
  'prefer_widget_class_over_widget_helper' => const _SourceCase('''
import 'package:flutter/widgets.dart';

Widget _buildHeader() => const SizedBox.shrink();
''', 'Widget _buildHeader()'),
  'avoid_widget_operator_equals' => const _SourceCase('''
import 'package:flutter/widgets.dart';

abstract class AvoidWidgetOperatorEquals extends StatelessWidget {
  bool operator ==(Object other) => identical(this, other);
}
''', 'bool operator =='),
  'prefer_media_query_partial_methods' => const _SourceCase('''
import 'package:flutter/widgets.dart';

void readMediaQuery(BuildContext context) {
  MediaQuery.of(context).size;
}
''', 'MediaQuery.of(context).size'),
  'missing_go_route_name_property' => const _SourceCase('''
// ignore_for_file: go_router_linter/avoid_hardcoded_routes

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

GoRoute buildRoute() => GoRoute(
  path: '/home',
  builder: (_, _) => const SizedBox.shrink(),
);
''', 'GoRoute('),
  'use_context_directly_for_go_router' => const _SourceCase('''
// ignore_for_file: go_router_linter/avoid_hardcoded_routes

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void navigate(BuildContext context) {
  GoRouter.of(context).go('/home');
}
''', 'GoRouter.of(context).go'),
  'avoid_hardcoded_routes' => const _SourceCase('''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void navigate(BuildContext context) {
  context.go('/home');
}
''', "'/home'"),
  'avoid_navigator_named_routes_with_go_router' => const _SourceCase('''
// ignore_for_file: go_router_linter/avoid_hardcoded_routes

import 'package:flutter/widgets.dart';

const homeRoute = '/home';

void navigate(BuildContext context) {
  Navigator.pushNamed(context, homeRoute);
}
''', 'Navigator.pushNamed'),
  'missing_go_router_error_handler' => const _SourceCase('''
import 'package:go_router/go_router.dart';

final router = GoRouter(routes: const []);
''', 'GoRouter('),
  _ => throw ArgumentError.value(code, 'code', 'Unknown diagnostic code.'),
};

String _compliantSource(String code) => switch (code) {
  'single_class_per_file' => 'class SingleClassPerFile {}\n',
  'matching_class_and_file_name' => 'class MatchingClassAndFileName {}\n',
  'prefer_widget_class_over_widget_helper' =>
    '''
import 'package:flutter/widgets.dart';

Widget buildHeader() => const SizedBox.shrink();
''',
  'avoid_widget_operator_equals' =>
    '''
import 'package:flutter/widgets.dart';

abstract class AvoidWidgetOperatorEquals extends StatelessWidget {}
''',
  'prefer_media_query_partial_methods' =>
    '''
import 'package:flutter/widgets.dart';

void readMediaQuery(BuildContext context) {
  MediaQuery.sizeOf(context);
}
''',
  'missing_go_route_name_property' =>
    '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

const homeRoute = '/home';

GoRoute buildRoute() => GoRoute(
  path: homeRoute,
  name: 'home',
  builder: (_, _) => const SizedBox.shrink(),
);
''',
  'use_context_directly_for_go_router' =>
    '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

const homeRoute = '/home';

void navigate(BuildContext context) {
  context.go(homeRoute);
}
''',
  'avoid_hardcoded_routes' =>
    '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

const homeRoute = '/home';

void navigate(BuildContext context) {
  context.go(homeRoute);
}
''',
  'avoid_navigator_named_routes_with_go_router' =>
    '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

const homeRoute = '/home';

void navigate(BuildContext context) {
  context.go(homeRoute);
}
''',
  'missing_go_router_error_handler' =>
    '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  routes: const [],
  errorBuilder: (_, _) => const SizedBox.shrink(),
);
''',
  _ => throw ArgumentError.value(code, 'code', 'Unknown diagnostic code.'),
};

_SourceCase _qualifiedIgnoreSource(String code) => switch (code) {
  'single_class_per_file' => const _SourceCase('''
// ignore_for_file: flutter_best_practices_lints/matching_class_and_file_name

class SingleClassPerFile {}
// ignore: flutter_best_practices_lints/single_class_per_file
class IgnoredExtraClass {}
class VisibleExtraClass {}
''', 'class VisibleExtraClass {}'),
  'matching_class_and_file_name' => const _SourceCase(
    '''
// ignore_for_file: flutter_best_practices_lints/single_class_per_file

// ignore: flutter_best_practices_lints/matching_class_and_file_name
class IgnoredWrongName {}
class VisibleWrongName {}
''',
    'class VisibleWrongName {}',
    problemMessage:
        'Class name VisibleWrongName must match the file name "matching_class_and_file_name".',
  ),
  'prefer_widget_class_over_widget_helper' => const _SourceCase('''
import 'package:flutter/widgets.dart';

// ignore: flutter_best_practices_lints/prefer_widget_class_over_widget_helper
Widget _buildIgnored() => const SizedBox.shrink();
Widget _buildVisible() => const SizedBox.shrink();
''', 'Widget _buildVisible()'),
  'avoid_widget_operator_equals' => const _SourceCase(
    '''
// ignore_for_file: flutter_best_practices_lints/single_class_per_file, flutter_best_practices_lints/matching_class_and_file_name

import 'package:flutter/widgets.dart';

abstract class FirstWidget extends StatelessWidget {
  // ignore: flutter_best_practices_lints/avoid_widget_operator_equals
  bool operator ==(Object other) => identical(this, other);
}

abstract class SecondWidget extends StatelessWidget {
  bool operator ==(Object other) => identical(this, other);
}
''',
    'bool operator ==',
    needleOccurrence: 1,
  ),
  'prefer_media_query_partial_methods' => const _SourceCase('''
import 'package:flutter/widgets.dart';

void readMediaQuery(BuildContext context) {
  // ignore: flutter_best_practices_lints/prefer_media_query_partial_methods
  MediaQuery.of(context).size;
  MediaQuery.of(context).padding;
}
''', 'MediaQuery.of(context).padding'),
  'missing_go_route_name_property' => const _SourceCase(
    '''
// ignore_for_file: go_router_linter/avoid_hardcoded_routes

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

final routes = <GoRoute>[
  // ignore: go_router_linter/missing_go_route_name_property
  GoRoute(path: '/ignored', builder: (_, _) => const SizedBox.shrink()),
  GoRoute(path: '/visible', builder: (_, _) => const SizedBox.shrink()),
];
''',
    'GoRoute(',
    needleOccurrence: 1,
  ),
  'use_context_directly_for_go_router' => const _SourceCase('''
// ignore_for_file: go_router_linter/avoid_hardcoded_routes

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void navigate(BuildContext context) {
  // ignore: go_router_linter/use_context_directly_for_go_router
  GoRouter.of(context).go('/ignored');
  GoRouter.of(context).push('/visible');
}
''', 'GoRouter.of(context).push'),
  'avoid_hardcoded_routes' => const _SourceCase('''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void navigate(BuildContext context) {
  // ignore: go_router_linter/avoid_hardcoded_routes
  context.go('/ignored');
  context.push('/visible');
}
''', "'/visible'"),
  'avoid_navigator_named_routes_with_go_router' => const _SourceCase('''
import 'package:flutter/widgets.dart';

void navigate(BuildContext context) {
  // ignore: go_router_linter/avoid_navigator_named_routes_with_go_router
  Navigator.pushNamed(context, '/ignored');
  Navigator.pushReplacementNamed(context, '/visible');
}
''', 'Navigator.pushReplacementNamed'),
  'missing_go_router_error_handler' => const _SourceCase(
    '''
import 'package:go_router/go_router.dart';

final routers = [
  // ignore: go_router_linter/missing_go_router_error_handler
  GoRouter(routes: const []),
  GoRouter(routes: const []),
];
''',
    'GoRouter(',
    needleOccurrence: 1,
  ),
  _ => throw ArgumentError.value(code, 'code', 'Unknown diagnostic code.'),
};

const _problemMessages = <String, String>{
  'single_class_per_file':
      'A file should contain only one public class declaration.',
  'matching_class_and_file_name':
      'Class name WrongName must match the file name '
      '"matching_class_and_file_name".',
  'prefer_widget_class_over_widget_helper':
      'Prefer a widget class over private Widget helper methods.',
  'avoid_widget_operator_equals':
      'Avoid overriding operator == on Widget classes.',
  'prefer_media_query_partial_methods':
      'Use the specific MediaQuery accessor to avoid unnecessary rebuilds.',
  'missing_go_route_name_property':
      'GoRoute definition should include a `name` property.',
  'use_context_directly_for_go_router': 'Use GoRouterHelper extension.',
  'avoid_hardcoded_routes':
      'Avoid hardcoded route paths. Use constants or enums for routes.',
  'avoid_navigator_named_routes_with_go_router':
      'Avoid Navigator named routes in projects that use go_router.',
  'missing_go_router_error_handler':
      'GoRouter should define an error handler for unknown routes.',
};

HarnessOptions parseHarnessOptions(List<String> arguments) {
  String? pluginValue;
  String? sourceValue;
  var analyzer = AnalyzerSelector.all;
  var repeat = 1;
  var timeout = const Duration(seconds: 600);
  var negativeControl = false;
  final packageVersions = <String, String>{};
  final requestedDiagnostics = <String>{};

  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    switch (argument) {
      case '--plugin':
        pluginValue = _singleValue(
          argument,
          pluginValue,
          _nextValue(arguments, ++index, argument),
        );
      case '--source':
        sourceValue = _singleValue(
          argument,
          sourceValue,
          _nextValue(arguments, ++index, argument),
        );
      case '--analyzer':
        final value = _nextValue(arguments, ++index, argument);
        analyzer = switch (value) {
          'dart' => AnalyzerSelector.dart,
          'flutter' => AnalyzerSelector.flutter,
          'all' => AnalyzerSelector.all,
          _ => throw FormatException('Unknown analyzer selector: $value'),
        };
      case '--repeat':
        repeat = _positiveInt(
          _nextValue(arguments, ++index, argument),
          argument,
        );
      case '--timeout-seconds':
        timeout = Duration(
          seconds: _positiveInt(
            _nextValue(arguments, ++index, argument),
            argument,
          ),
        );
      case '--package-version':
        final value = _nextValue(arguments, ++index, argument);
        final separator = value.indexOf('=');
        if (separator <= 0 || separator == value.length - 1) {
          throw const FormatException(
            'Expected --package-version <package>=<exact-version>.',
          );
        }
        final package = value.substring(0, separator);
        final version = value.substring(separator + 1);
        if (packageVersions.containsKey(package)) {
          throw FormatException('Duplicate package version: $package');
        }
        packageVersions[package] = version;
      case '--diagnostic':
        requestedDiagnostics.add(
          _nextValue(arguments, ++index, argument),
        );
      case '--negative-control':
        negativeControl = true;
      default:
        throw FormatException('Unknown argument: $argument');
    }
  }

  final plugin = switch (pluginValue) {
    'flutter_best_practices_lints' => PluginSelector.flutterBestPracticesLints,
    'go_router_linter' => PluginSelector.goRouterLinter,
    'all' => PluginSelector.all,
    null => throw const FormatException('Missing required --plugin.'),
    final value => throw FormatException('Unknown plugin selector: $value'),
  };
  final source = switch (sourceValue) {
    'local' => PluginSource.local,
    'hosted' => PluginSource.hosted,
    null => throw const FormatException('Missing required --source.'),
    final value => throw FormatException('Unknown plugin source: $value'),
  };
  final selectedPackages = _packageNames(plugin);
  final allowedDiagnostics = _diagnosticCodes(plugin);
  final diagnostics = requestedDiagnostics.isEmpty
      ? allowedDiagnostics
      : requestedDiagnostics;

  if (!allowedDiagnostics.containsAll(diagnostics)) {
    final invalid = diagnostics.difference(allowedDiagnostics).join(', ');
    throw FormatException(
      'Diagnostics do not belong to the selected plugin set: $invalid',
    );
  }

  switch (source) {
    case PluginSource.local:
      if (packageVersions.isNotEmpty) {
        throw const FormatException(
          'Local mode does not accept --package-version.',
        );
      }
    case PluginSource.hosted:
      if (packageVersions.keys
          .toSet()
          .difference(selectedPackages)
          .isNotEmpty) {
        throw const FormatException(
          'Hosted versions include an unselected plugin package.',
        );
      }
      for (final package in selectedPackages) {
        final version = packageVersions[package];
        if (version == null) {
          throw FormatException(
            'Hosted mode requires an exact version for $package.',
          );
        }
        if (!_exactVersion.hasMatch(version)) {
          throw FormatException(
            'Hosted mode requires an exact version for $package: $version',
          );
        }
      }
  }

  return HarnessOptions(
    plugin: plugin,
    source: source,
    analyzer: analyzer,
    repeat: repeat,
    timeout: timeout,
    packageVersions: Map.unmodifiable(packageVersions),
    diagnostics: Set.unmodifiable(diagnostics),
    negativeControl: negativeControl,
  );
}

final _exactVersion = RegExp(
  r'^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$',
);

String _nextValue(List<String> arguments, int index, String option) {
  if (index >= arguments.length || arguments[index].startsWith('--')) {
    throw FormatException('Missing value for $option.');
  }
  return arguments[index];
}

String _singleValue(String option, String? current, String next) {
  if (current != null) {
    throw FormatException('Duplicate option: $option');
  }
  return next;
}

int _positiveInt(String value, String option) {
  final result = int.tryParse(value);
  if (result == null || result <= 0) {
    throw FormatException('$option must be a positive integer: $value');
  }
  return result;
}

Set<String> _packageNames(PluginSelector selector) => switch (selector) {
  PluginSelector.flutterBestPracticesLints => {
    'flutter_best_practices_lints',
  },
  PluginSelector.goRouterLinter => {'go_router_linter'},
  PluginSelector.all => {
    'flutter_best_practices_lints',
    'go_router_linter',
  },
};

Set<String> _diagnosticCodes(PluginSelector selector) => switch (selector) {
  PluginSelector.flutterBestPracticesLints => flutterDiagnosticCodes,
  PluginSelector.goRouterLinter => goRouterDiagnosticCodes,
  PluginSelector.all => {
    ...flutterDiagnosticCodes,
    ...goRouterDiagnosticCodes,
  },
};

String _packageForDiagnostic(String code) {
  if (flutterDiagnosticCodes.contains(code)) {
    return 'flutter_best_practices_lints';
  }
  if (goRouterDiagnosticCodes.contains(code)) {
    return 'go_router_linter';
  }
  throw ArgumentError.value(code, 'code', 'Unknown diagnostic code.');
}

String _normalizedPath(String path) {
  final normalized = Directory(path).absolute.uri.normalizePath().toFilePath();
  if (normalized.endsWith(Platform.pathSeparator)) {
    return normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

bool _isWithin(String path, String parent) {
  final normalizedPath = Platform.isWindows ? path.toLowerCase() : path;
  final normalizedParent = Platform.isWindows ? parent.toLowerCase() : parent;
  return normalizedPath == normalizedParent ||
      normalizedPath.startsWith('$normalizedParent${Platform.pathSeparator}');
}

String _joinPath(String root, String first, [String? second]) {
  final prefix = '$root${Platform.pathSeparator}$first';
  return second == null ? prefix : '$prefix${Platform.pathSeparator}$second';
}

String operatingSystemName() => Platform.operatingSystem;
