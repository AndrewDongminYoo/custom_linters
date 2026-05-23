// 🌎 Project imports:
import 'package:go_router_linter/go_router_linter.dart';

// 📦 Package imports:
import 'package:pubspec_parse/pubspec_parse.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

import '../lint_test_utils.dart';

void main() {
  group('AvoidNavigatorNamedRoutesWithGoRouter', () {
    test(
      'reports Navigator named route calls when go_router is present',
      () async {
        final errors = await analyzeLintRule(
          const AvoidNavigatorNamedRoutesWithGoRouter(),
          '''
import 'package:flutter/widgets.dart';

void navigate(BuildContext context) {
  Navigator.pushNamed(context, '/details');
  Navigator.pushReplacementNamed(context, '/details');
  Navigator.popAndPushNamed(context, '/details');
  Navigator.restorablePushNamed(context, '/details');
}
''',
          pubspec: Pubspec.parse('''
name: test_project
dependencies:
  go_router: any
'''),
        );

        expect(
          errors,
          everyElement('avoid_navigator_named_routes_with_go_router'),
        );
        expect(errors, hasLength(4));
      },
    );

    test('ignores Navigator named route calls without go_router', () async {
      final errors = await analyzeLintRule(
        const AvoidNavigatorNamedRoutesWithGoRouter(),
        '''
import 'package:flutter/widgets.dart';

void navigate(BuildContext context) {
  Navigator.pushNamed(context, '/details');
}
''',
      );

      expect(errors, isEmpty);
    });
  });
}
