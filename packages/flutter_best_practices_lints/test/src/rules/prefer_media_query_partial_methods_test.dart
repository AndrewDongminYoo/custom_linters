// 📦 Package imports:
import 'package:flutter_best_practices_lints/flutter_best_practices_lints.dart';
import 'package:test/test.dart';

// 🌎 Project imports:
import '../lint_test_utils.dart';

void main() {
  group('PreferMediaQueryPartialMethods', () {
    test('reports MediaQuery.of(context).property calls', () async {
      final errors = await analyzeLintRule(
        const PreferMediaQueryPartialMethods(),
        '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    return SizedBox(width: size.width, height: padding.top);
  }
}
''',
      );

      expect(errors, everyElement('prefer_media_query_partial_methods'));
      expect(errors, hasLength(2));
    });

    test('ignores dedicated MediaQuery static accessors', () async {
      final errors = await analyzeLintRule(
        const PreferMediaQueryPartialMethods(),
        '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    return SizedBox(width: size.width, height: padding.top);
  }
}
''',
      );

      expect(errors, isEmpty);
    });

    test('ignores MediaQuery.of().copyWith (no direct replacement)', () async {
      final errors = await analyzeLintRule(
        const PreferMediaQueryPartialMethods(),
        '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: const SizedBox.shrink(),
    );
  }
}
''',
      );

      expect(errors, isEmpty);
    });
  });
}
