// 🌎 Project imports:
import 'package:flutter_best_practices_lints/flutter_best_practices_lints.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

import '../lint_test_utils.dart';

void main() {
  group('PreferWidgetClassOverWidgetHelper', () {
    test('reports private Widget helper functions and methods', () async {
      final errors = await analyzeLintRule(
        const PreferWidgetClassOverWidgetHelper(),
        '''
import 'package:flutter/widgets.dart';

Widget _buildHeader() => const SizedBox.shrink();

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildBody() => const SizedBox.shrink();

  @override
  Widget build(BuildContext context) => _buildBody();
}
''',
      );

      expect(errors, everyElement('prefer_widget_class_over_widget_helper'));
      expect(errors, hasLength(2));
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
