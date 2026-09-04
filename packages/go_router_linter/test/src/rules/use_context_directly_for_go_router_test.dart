// 🌎 Project imports:
import 'package:go_router_linter/go_router_linter.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

import '../lint_test_utils.dart';

void main() {
  group('UseContextDirectlyForGoRouter', () {
    test('reports every GoRouter.of(context) route method call', () async {
      const source = '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void navigate(BuildContext context) {
  GoRouter.of(context).go('/home');
  GoRouter.of(context).push('/home');
  GoRouter.of(context).pushReplacement('/home');
  GoRouter.of(context).replace('/home');
  GoRouter.of(context).goNamed('home');
  GoRouter.of(context).namedLocation('home');
  GoRouter.of(context).pushNamed('home');
  GoRouter.of(context).pushReplacementNamed('home');
  GoRouter.of(context).replaceNamed('home');
  GoRouter.of(context).canPop();
  GoRouter.of(context).pop();
}
''';
      final errors = await analyzeLintRule(
        const UseContextDirectlyForGoRouter(),
        source,
      );

      const expectations = {
        "GoRouter.of(context).go('/home')": 'go',
        "GoRouter.of(context).push('/home')": 'push',
        "GoRouter.of(context).pushReplacement('/home')": 'pushReplacement',
        "GoRouter.of(context).replace('/home')": 'replace',
        "GoRouter.of(context).goNamed('home')": 'goNamed',
        "GoRouter.of(context).namedLocation('home')": 'namedLocation',
        "GoRouter.of(context).pushNamed('home')": 'pushNamed',
        "GoRouter.of(context).pushReplacementNamed('home')":
            'pushReplacementNamed',
        "GoRouter.of(context).replaceNamed('home')": 'replaceNamed',
        'GoRouter.of(context).canPop()': 'canPop',
        'GoRouter.of(context).pop()': 'pop',
      };
      expect(errors, hasLength(expectations.length));
      for (final MapEntry(key: invocation, value: method)
          in expectations.entries) {
        final offset = source.indexOf(invocation);
        final diagnostic = errors.singleWhere(
          (error) => error.offset == offset,
        );
        expectLintDiagnostic(
          diagnostic,
          code: 'use_context_directly_for_go_router',
          message: 'Use GoRouterHelper extension.',
          correctionMessage:
              'Use context.$method instead of GoRouter.of(context).$method.',
          offset: offset,
          length: invocation.length,
        );
      }
    });

    test(
      'preserves the simple-identifier and direct-parent boundaries',
      () async {
        final errors = await analyzeLintRule(
          const UseContextDirectlyForGoRouter(),
          '''
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class Scope {
  const Scope(this.context);

  final BuildContext context;
}

BuildContext getContext() => throw UnimplementedError();

void inspect(BuildContext context, Scope scope) {
  GoRouter.of(context).routerDelegate;
  GoRouter.of(context).refresh();
  GoRouter.of(scope.context).go('/home');
  GoRouter.of(getContext()).go('/home');
  (GoRouter.of(context)).go('/home');
}
''',
        );

        expect(errors, isEmpty);
      },
    );
  });
}
