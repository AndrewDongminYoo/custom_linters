// 🌎 Project imports:
import 'package:flutter_best_practices_lints/flutter_best_practices_lints.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

import '../lint_test_utils.dart';

void main() {
  group('AvoidWidgetOperatorEquals', () {
    test('reports equality overrides in widget subclasses', () async {
      final errors = await analyzeLintRule(
        const AvoidWidgetOperatorEquals(),
        '''
import 'package:flutter/widgets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();

  @override
  bool operator ==(Object other) => identical(this, other);
}
''',
      );

      expect(errors, everyElement('avoid_widget_operator_equals'));
      expect(errors, hasLength(1));
    });

    test('ignores equality overrides in non-widget classes', () async {
      final errors = await analyzeLintRule(
        const AvoidWidgetOperatorEquals(),
        '''
class ValueObject {
  @override
  bool operator ==(Object other) => other is ValueObject;
}
''',
      );

      expect(errors, isEmpty);
    });
  });
}
