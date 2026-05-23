// 🌎 Project imports:
import 'package:go_router_linter/go_router_linter.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

import '../lint_test_utils.dart';

void main() {
  group('UseContextDirectlyForGoRouter', () {
    test('reports GoRouter.of(context) helper method calls', () async {
      final errors = await analyzeLintRule(
        const UseContextDirectlyForGoRouter(),
        '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void navigate(BuildContext context) {
  GoRouter.of(context).go('/home');
  GoRouter.of(context).namedLocation('home');
  GoRouter.of(context).canPop();
  GoRouter.of(context).pop();
}
''',
      );

      expect(errors, everyElement('use_context_directly_for_go_router'));
      expect(errors, hasLength(4));
    });

    test('ignores unrelated GoRouter.of(context) access', () async {
      final errors = await analyzeLintRule(
        const UseContextDirectlyForGoRouter(),
        '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void inspect(BuildContext context) {
  GoRouter.of(context).routerDelegate;
  GoRouter.of(context).refresh();
}
''',
      );

      expect(errors, isEmpty);
    });
  });
}
