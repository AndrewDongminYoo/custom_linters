// 🐦 Dart imports:
import 'dart:io';

// 🧪 Test imports:
import 'package:test/test.dart';

// 🌎 Project imports:
import '../../tool/src/analyzer_plugin_harness.dart';

void main() {
  group('parseHarnessOptions', () {
    test('parses every plugin, source, and analyzer selector', () {
      for (final (value, expected) in <(String, PluginSelector)>[
        (
          'flutter_best_practices_lints',
          PluginSelector.flutterBestPracticesLints,
        ),
        ('go_router_linter', PluginSelector.goRouterLinter),
        ('all', PluginSelector.all),
      ]) {
        final options = parseHarnessOptions([
          '--plugin',
          value,
          '--source',
          'local',
        ]);

        expect(options.plugin, expected);
        expect(options.source, PluginSource.local);
        expect(options.analyzer, AnalyzerSelector.all);
      }

      for (final (value, expected) in <(String, AnalyzerSelector)>[
        ('dart', AnalyzerSelector.dart),
        ('flutter', AnalyzerSelector.flutter),
        ('all', AnalyzerSelector.all),
      ]) {
        final options = parseHarnessOptions([
          '--plugin',
          'flutter_best_practices_lints',
          '--source',
          'local',
          '--analyzer',
          value,
        ]);

        expect(options.analyzer, expected);
      }
    });

    test('parses positive repeat and timeout values', () {
      final options = parseHarnessOptions([
        '--plugin',
        'flutter_best_practices_lints',
        '--source',
        'local',
        '--repeat',
        '3',
        '--timeout-seconds',
        '120',
      ]);

      expect(options.repeat, 3);
      expect(options.timeout, const Duration(seconds: 120));
    });

    test('parses repeatable exact hosted versions', () {
      final options = parseHarnessOptions([
        '--plugin',
        'all',
        '--source',
        'hosted',
        '--package-version',
        'flutter_best_practices_lints=0.6.0',
        '--package-version',
        'go_router_linter=0.5.0',
      ]);

      expect(options.source, PluginSource.hosted);
      expect(options.packageVersions, {
        'flutter_best_practices_lints': '0.6.0',
        'go_router_linter': '0.5.0',
      });
    });

    test('defaults diagnostics to the selected plugin rules', () {
      final flutterOptions = parseHarnessOptions([
        '--plugin',
        'flutter_best_practices_lints',
        '--source',
        'local',
      ]);
      final allOptions = parseHarnessOptions([
        '--plugin',
        'all',
        '--source',
        'local',
      ]);

      expect(flutterOptions.diagnostics, flutterDiagnosticCodes);
      expect(allOptions.diagnostics, {
        ...flutterDiagnosticCodes,
        ...goRouterDiagnosticCodes,
      });
    });

    test('parses repeatable selected diagnostics and negative control', () {
      final options = parseHarnessOptions([
        '--plugin',
        'flutter_best_practices_lints',
        '--source',
        'local',
        '--diagnostic',
        'single_class_per_file',
        '--diagnostic',
        'prefer_media_query_partial_methods',
        '--negative-control',
      ]);

      expect(options.diagnostics, {
        'single_class_per_file',
        'prefer_media_query_partial_methods',
      });
      expect(options.negativeControl, isTrue);
    });

    test('rejects invalid values and inconsistent modes', () {
      final invalidArguments = <List<String>>[
        ['--plugin', 'unknown', '--source', 'local'],
        ['--plugin', 'all', '--source', 'unknown'],
        ['--plugin', 'all', '--source', 'local', '--analyzer', 'unknown'],
        ['--plugin', 'all', '--source', 'local', '--repeat', '0'],
        ['--plugin', 'all', '--source', 'local', '--timeout-seconds', '0'],
        ['--plugin', 'all', '--source', 'hosted'],
        [
          '--plugin',
          'flutter_best_practices_lints',
          '--source',
          'local',
          '--package-version',
          'flutter_best_practices_lints=0.6.0',
        ],
        [
          '--plugin',
          'flutter_best_practices_lints',
          '--source',
          'hosted',
          '--package-version',
          'flutter_best_practices_lints=^0.6.0',
        ],
        [
          '--plugin',
          'flutter_best_practices_lints',
          '--source',
          'local',
          '--diagnostic',
          'avoid_hardcoded_routes',
        ],
      ];

      for (final arguments in invalidArguments) {
        expect(
          () => parseHarnessOptions(arguments),
          throwsFormatException,
          reason: arguments.join(' '),
        );
      }
    });
  });

  group('consumer fixtures', () {
    late Directory temporaryRoot;

    setUp(() {
      temporaryRoot = Directory.systemTemp.createTempSync(
        'analyzer_plugin_harness_test_',
      );
    });

    tearDown(() {
      if (temporaryRoot.existsSync()) {
        temporaryRoot.deleteSync(recursive: true);
      }
    });

    test(
      'generates absolute local plugin paths without plugin dependencies',
      () {
        final options = parseHarnessOptions([
          '--plugin',
          'all',
          '--source',
          'local',
        ]);
        final fixture = generateConsumerFixture(
          options,
          repositoryRoot: Directory.current.absolute,
          consumerRoot: temporaryRoot,
          scenario: ConsumerScenario.violating,
        );
        final flutterPath = Directory(
          '${Directory.current.path}/packages/flutter_best_practices_lints',
        ).absolute.path;
        final goRouterPath = Directory(
          '${Directory.current.path}/packages/go_router_linter',
        ).absolute.path;

        expect(fixture.analysisOptionsYaml, contains('path: $flutterPath'));
        expect(fixture.analysisOptionsYaml, contains('path: $goRouterPath'));
        expect(fixture.analysisOptionsYaml, isNot(contains('version:')));
        expect(
          fixture.pubspecYaml,
          isNot(contains('flutter_best_practices_lints:')),
        );
        expect(fixture.pubspecYaml, isNot(contains('go_router_linter:')));
        expect(fixture.pubspecYaml, contains('go_router: 17.5.0'));
      },
    );

    test('generates exact hosted versions without plugin paths', () {
      final options = parseHarnessOptions([
        '--plugin',
        'all',
        '--source',
        'hosted',
        '--package-version',
        'flutter_best_practices_lints=0.6.0',
        '--package-version',
        'go_router_linter=0.5.0',
      ]);
      final fixture = generateConsumerFixture(
        options,
        repositoryRoot: Directory.current.absolute,
        consumerRoot: temporaryRoot,
        scenario: ConsumerScenario.violating,
      );

      expect(fixture.analysisOptionsYaml, contains('version: 0.6.0'));
      expect(fixture.analysisOptionsYaml, contains('version: 0.5.0'));
      expect(fixture.analysisOptionsYaml, isNot(contains('path:')));
    });

    test('generates all four isolated scenario shapes', () {
      final options = parseHarnessOptions([
        '--plugin',
        'flutter_best_practices_lints',
        '--source',
        'local',
        '--diagnostic',
        'prefer_media_query_partial_methods',
      ]);

      for (final scenario in ConsumerScenario.values) {
        final fixture = generateConsumerFixture(
          options,
          repositoryRoot: Directory.current.absolute,
          consumerRoot: temporaryRoot,
          scenario: scenario,
        );

        expect(fixture.files, isNotEmpty, reason: scenario.name);
        switch (scenario) {
          case ConsumerScenario.violating:
            expect(fixture.expectedDiagnostics, hasLength(1));
          case ConsumerScenario.compliant:
          case ConsumerScenario.disabledRule:
            expect(fixture.expectedDiagnostics, isEmpty);
          case ConsumerScenario.qualifiedIgnore:
            expect(fixture.expectedDiagnostics, hasLength(1));
            expect(
              fixture.files.values.single,
              contains(
                '// ignore: flutter_best_practices_lints/prefer_media_query_partial_methods',
              ),
            );
        }
      }
    });

    test('omits the disabled rule from diagnostics configuration', () {
      final options = parseHarnessOptions([
        '--plugin',
        'flutter_best_practices_lints',
        '--source',
        'local',
        '--diagnostic',
        'prefer_media_query_partial_methods',
      ]);
      final fixture = generateConsumerFixture(
        options,
        repositoryRoot: Directory.current.absolute,
        consumerRoot: temporaryRoot,
        scenario: ConsumerScenario.disabledRule,
      );

      expect(
        fixture.analysisOptionsYaml,
        isNot(contains('prefer_media_query_partial_methods: true')),
      );
    });

    test('rejects consumer roots inside the workspace', () {
      final options = parseHarnessOptions([
        '--plugin',
        'flutter_best_practices_lints',
        '--source',
        'local',
      ]);

      expect(
        () => generateConsumerFixture(
          options,
          repositoryRoot: Directory.current.absolute,
          consumerRoot: Directory(
            '${Directory.current.path}/packages/'
            'flutter_best_practices_lints/example',
          ),
          scenario: ConsumerScenario.violating,
        ),
        throwsArgumentError,
      );
    });
  });

  group('analyzer output parsers', () {
    test('parses dart analyze POSIX and Windows records', () {
      final records = parseDartAnalyzeOutput(r'''
Analyzing consumer...

   info - lib/main.dart:4:3 - POSIX message. - raw_code
warning - C:\work\consumer\lib\main.dart:12:7 - Windows message. - some_plugin/qualified_code

2 issues found.
''');

      expect(records, hasLength(2));
      _expectRecord(
        records[0],
        code: 'raw_code',
        severity: 'INFO',
        message: 'POSIX message.',
        path: 'lib/main.dart',
        line: 4,
        column: 3,
      );
      _expectRecord(
        records[1],
        code: 'some_plugin/qualified_code',
        severity: 'WARNING',
        message: 'Windows message.',
        path: r'C:\work\consumer\lib\main.dart',
        line: 12,
        column: 7,
      );
    });

    test('parses flutter analyze POSIX and Windows records', () {
      final records = parseFlutterAnalyzeOutput(r'''
Analyzing consumer...

  info • POSIX message. • lib/main.dart:4:3 • raw_code
warning • Windows message. • C:\work\consumer\lib\main.dart:12:7 • some_plugin/qualified_code

2 issues found. (ran in 1.0s)
''');

      expect(records, hasLength(2));
      _expectRecord(
        records[0],
        code: 'raw_code',
        severity: 'INFO',
        message: 'POSIX message.',
        path: 'lib/main.dart',
        line: 4,
        column: 3,
      );
      _expectRecord(
        records[1],
        code: 'some_plugin/qualified_code',
        severity: 'WARNING',
        message: 'Windows message.',
        path: r'C:\work\consumer\lib\main.dart',
        line: 12,
        column: 7,
      );
    });

    test('accepts complete no-issue output', () {
      expect(
        parseDartAnalyzeOutput('Analyzing consumer...\nNo issues found!\n'),
        isEmpty,
      );
      expect(
        parseFlutterAnalyzeOutput(
          'Analyzing consumer...\nNo issues found! (ran in 0.8s)\n',
        ),
        isEmpty,
      );
    });

    test('rejects empty and truncated diagnostic output', () {
      for (final parser in [
        parseDartAnalyzeOutput,
        parseFlutterAnalyzeOutput,
      ]) {
        expect(() => parser(''), throwsFormatException);
      }
      expect(
        () => parseDartAnalyzeOutput(
          'info - lib/main.dart:4:3 - Missing code\n',
        ),
        throwsFormatException,
      );
      expect(
        () => parseFlutterAnalyzeOutput(
          'info • Missing location and code\n',
        ),
        throwsFormatException,
      );
    });

    test('rejects corrupted samples before accepting the originals', () {
      const dartOutput = '''
Analyzing consumer...
info - lib/main.dart:4:3 - Exact message. - raw_code
1 issue found.
''';
      const flutterOutput = '''
Analyzing consumer...
info • Exact message. • lib/main.dart:4:3 • raw_code
1 issue found. (ran in 1.0s)
''';

      expect(
        () => parseDartAnalyzeOutput(
          dartOutput.replaceFirst(' - raw_code', ''),
        ),
        throwsFormatException,
      );
      expect(parseDartAnalyzeOutput(dartOutput), hasLength(1));
      expect(
        () => parseFlutterAnalyzeOutput(
          flutterOutput.replaceFirst(' • raw_code', ''),
        ),
        throwsFormatException,
      );
      expect(parseFlutterAnalyzeOutput(flutterOutput), hasLength(1));
    });
  });

  group('AnalyzerProcessRunner', () {
    test('terminates the complete process tree after a timeout', () async {
      final temporaryRoot = Directory.systemTemp.createTempSync(
        'analyzer_process_runner_test_',
      );
      final workingDirectory = Directory(
        '${temporaryRoot.path}${Platform.pathSeparator}working',
      )..createSync();
      final fixture = File(
        'test/tool/fixtures/hanging_process.dart',
      ).absolute;

      late HarnessProcessFailure failure;
      try {
        final result = await const AnalyzerProcessRunner().run(
          executable: Platform.resolvedExecutable,
          arguments: [fixture.path],
          workingDirectory: workingDirectory.path,
          timeout: const Duration(seconds: 1),
        );
        fail(
          'The hanging process unexpectedly completed with '
          '${result.exitCode}: ${result.stderr}',
        );
      } on HarnessProcessFailure catch (error) {
        failure = error;
      }

      expect(failure.kind, ProcessFailureKind.timeout);
      expect(failure.recordedPids, hasLength(greaterThanOrEqualTo(2)));
      expect(failure.stdout, contains('ROOT_PID:'));
      expect(failure.stdout, contains('CHILD_PID:'));
      expect(failure.stderr, contains('ROOT_STDERR_READY'));
      expect(failure.stdoutClosed, isTrue);
      expect(failure.stderrClosed, isTrue);
      for (final processId in failure.recordedPids) {
        expect(
          await isProcessRunning(processId),
          isFalse,
          reason: 'PID $processId survived timeout cleanup.',
        );
      }

      workingDirectory.deleteSync(recursive: true);
      expect(workingDirectory.existsSync(), isFalse);
      temporaryRoot.deleteSync(recursive: true);
    });
  });

  group('assertDiagnosticRecords', () {
    const actual = [
      DiagnosticRecord(
        code: 'raw_code',
        severity: 'INFO',
        message: 'Exact message.',
        path: 'lib/main.dart',
        line: 4,
        column: 3,
      ),
    ];

    test('accepts exact records', () {
      expect(
        () => assertDiagnosticRecords(actual: actual, expected: actual),
        returnsNormally,
      );
    });

    test('reports the exact negative-control prefix for a missing code', () {
      const expected = [
        DiagnosticRecord(
          code: '__negative_control_missing_code__',
          severity: 'INFO',
          message: 'Exact message.',
          path: 'lib/main.dart',
          line: 4,
          column: 3,
        ),
      ];

      expect(
        () => assertDiagnosticRecords(actual: actual, expected: expected),
        throwsA(
          isA<HarnessFailure>()
              .having(
                (failure) => failure.kind,
                'kind',
                ProcessFailureKind.diagnosticMismatch,
              )
              .having(
                (failure) => failure.message,
                'message',
                startsWith(
                  'HARNESS_ASSERTION_FAILED: missing diagnostic '
                  '__negative_control_missing_code__',
                ),
              ),
        ),
      );
    });
  });
}

void _expectRecord(
  DiagnosticRecord record, {
  required String code,
  required String severity,
  required String message,
  required String path,
  required int line,
  required int column,
}) {
  expect(record.code, code);
  expect(record.severity, severity);
  expect(record.message, message);
  expect(record.path, path);
  expect(record.line, line);
  expect(record.column, column);
}
