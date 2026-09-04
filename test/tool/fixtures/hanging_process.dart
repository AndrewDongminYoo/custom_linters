// 🐦 Dart imports:
import 'dart:io';

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--child')) {
    stdout.writeln('CHILD_READY_PID:$pid');
    stderr.writeln('CHILD_STDERR_READY');
    await stdout.flush();
    await stderr.flush();
    await Future<void>.delayed(const Duration(days: 1));
  }

  final child = await Process.start(
    Platform.resolvedExecutable,
    [Platform.script.toFilePath(), '--child'],
  );
  stdout
    ..writeln('ROOT_PID:$pid')
    ..writeln('CHILD_PID:${child.pid}');
  stderr.writeln('ROOT_STDERR_READY');
  await stdout.flush();
  await stderr.flush();
  await child.exitCode;
}
