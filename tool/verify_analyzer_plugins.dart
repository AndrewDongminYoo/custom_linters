// 🐦 Dart imports:
import 'dart:io';

// 🌎 Project imports:
import 'src/analyzer_plugin_harness.dart';

Future<void> main(List<String> arguments) async {
  try {
    final options = parseHarnessOptions(arguments);
    final summary = await runAnalyzerPluginHarness(
      options,
      repositoryRoot: Directory.current.absolute,
      log: stdout.writeln,
    );
    stdout.writeln(
      'HARNESS_OK: analyzer_runs=${summary.analyzerRuns} '
      'resolved=${summary.resolvedVersions}',
    );
  } on FormatException catch (error) {
    stderr.writeln('HARNESS_ARGUMENT_ERROR: ${error.message}');
    exitCode = 64;
  } on HarnessProcessFailure catch (error) {
    stderr
      ..writeln('HARNESS_PROCESS_FAILED: ${error.kind.name}: ${error.message}')
      ..writeln('RECORDED_PIDS: ${error.recordedPids.join(', ')}')
      ..writeln('STDOUT:')
      ..write(error.stdout)
      ..writeln('STDERR:')
      ..write(error.stderr);
    exitCode = 1;
  } on HarnessFailure catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln('FAILURE_KIND: ${error.kind.name}')
      ..writeln('EXIT_CODE: ${error.exitCode ?? 'unavailable'}')
      ..writeln('STDOUT:')
      ..write(error.stdout)
      ..writeln('STDERR:')
      ..write(error.stderr);
    exitCode = 1;
  } on Object catch (error, stackTrace) {
    stderr
      ..writeln('HARNESS_UNEXPECTED_FAILURE: $error')
      ..writeln(stackTrace);
    exitCode = 1;
  }
}
