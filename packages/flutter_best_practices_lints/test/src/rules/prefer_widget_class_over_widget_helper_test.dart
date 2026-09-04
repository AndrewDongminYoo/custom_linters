// 🌎 Project imports:
import 'package:flutter_best_practices_lints/flutter_best_practices_lints.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

import '../lint_test_utils.dart';

void main() {
  group('PreferWidgetClassOverWidgetHelper', () {
    test('reports private Widget helper functions and methods', () async {
      const source = '''
import 'package:flutter/widgets.dart';

Widget _buildHeader() => const SizedBox.shrink();

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildBody() => const SizedBox.shrink();

  @override
  Widget build(BuildContext context) => _buildBody();
}
''';
      final errors = await analyzeLintRule(
        const PreferWidgetClassOverWidgetHelper(),
        source,
      );

      expect(errors, hasLength(2));
      const function = 'Widget _buildHeader() => const SizedBox.shrink();';
      const method = 'Widget _buildBody() => const SizedBox.shrink();';
      for (final (index, declaration) in [function, method].indexed) {
        expectLintDiagnostic(
          errors[index],
          code: 'prefer_widget_class_over_widget_helper',
          message: 'Prefer a widget class over private Widget helper methods.',
          correctionMessage:
              'Extract this reusable UI into a StatelessWidget or StatefulWidget.',
          offset: source.indexOf(declaration),
          length: declaration.length,
        );
      }
    });

    test(
      'uses the _build prefix and final return type name syntactically',
      () async {
        const source = '''
class Widget {}

Widget _builder() => Widget();
Widget? _buildNullable() => null;
''';
        final diagnostics = await analyzeLintRule(
          const PreferWidgetClassOverWidgetHelper(),
          source,
        );

        expect(diagnostics, hasLength(2));
        for (final (index, declaration) in [
          'Widget _builder() => Widget();',
          'Widget? _buildNullable() => null;',
        ].indexed) {
          expectLintDiagnostic(
            diagnostics[index],
            code: 'prefer_widget_class_over_widget_helper',
            message:
                'Prefer a widget class over private Widget helper methods.',
            correctionMessage:
                'Extract this reusable UI into a StatelessWidget or StatefulWidget.',
            offset: source.indexOf(declaration),
            length: declaration.length,
          );
        }
      },
    );

    test('ignores other names and non-Widget return types', () async {
      final diagnostics = await analyzeLintRule(
        const PreferWidgetClassOverWidgetHelper(),
        '''
class Widget {}

Object _buildObject() => Object();
Future<Widget> _buildAsync() async => Widget();
Widget _header() => Widget();
Widget buildHeader() => Widget();
''',
      );

      expect(diagnostics, isEmpty);
    });

    test('ignores the build override', () async {
      final errors = await analyzeLintRule(
        const PreferWidgetClassOverWidgetHelper(),
        '''
import 'package:flutter/widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
''',
      );

      expect(errors, isEmpty);
    });
  });
}
