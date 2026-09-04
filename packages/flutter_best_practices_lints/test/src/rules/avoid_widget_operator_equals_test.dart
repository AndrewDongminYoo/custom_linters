// 🌎 Project imports:
import 'package:flutter_best_practices_lints/flutter_best_practices_lints.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

import '../lint_test_utils.dart';

void main() {
  group('AvoidWidgetOperatorEquals', () {
    test(
      'reports equality overrides in direct Flutter widget subclasses',
      () async {
        const source = '''
import 'package:flutter/widgets.dart';

abstract class DirectWidget extends Widget {
  bool operator ==(Object other) => other is DirectWidget;
}

abstract class DirectStatelessWidget extends StatelessWidget {
  bool operator ==(Object other) => other is DirectStatelessWidget;
}

abstract class DirectStatefulWidget extends StatefulWidget {
  bool operator ==(Object other) => other is DirectStatefulWidget;
}
''';
        final diagnostics = await analyzeLintRule(
          const AvoidWidgetOperatorEquals(),
          source,
        );

        expect(diagnostics, hasLength(3));
        for (final (index, declaration) in [
          'bool operator ==(Object other) => other is DirectWidget;',
          'bool operator ==(Object other) => other is DirectStatelessWidget;',
          'bool operator ==(Object other) => other is DirectStatefulWidget;',
        ].indexed) {
          expectLintDiagnostic(
            diagnostics[index],
            code: 'avoid_widget_operator_equals',
            message: 'Avoid overriding operator == on Widget classes.',
            correctionMessage:
                'Rely on Flutter widget identity and const constructors instead.',
            offset: source.indexOf(declaration),
            length: declaration.length,
          );
        }
      },
    );

    test('ignores same-named classes outside Flutter libraries', () async {
      final diagnostics = await analyzeLintRule(
        const AvoidWidgetOperatorEquals(),
        '''
class Widget {}
class StatelessWidget {}
class StatefulWidget {}

class LocalWidget extends Widget {
  bool operator ==(Object other) => other is LocalWidget;
}

class LocalStatelessWidget extends StatelessWidget {
  bool operator ==(Object other) => other is LocalStatelessWidget;
}

class LocalStatefulWidget extends StatefulWidget {
  bool operator ==(Object other) => other is LocalStatefulWidget;
}
''',
      );

      expect(diagnostics, isEmpty);
    });

    test('ignores indirect Flutter widget subclasses', () async {
      final diagnostics = await analyzeLintRule(
        const AvoidWidgetOperatorEquals(),
        '''
import 'package:flutter/widgets.dart';

abstract class BaseWidget extends StatelessWidget {}

class IndirectWidget extends BaseWidget {
  bool operator ==(Object other) => other is IndirectWidget;
}
''',
      );

      expect(diagnostics, isEmpty);
    });

    test('ignores direct widget subclasses without operator ==', () async {
      final diagnostics = await analyzeLintRule(
        const AvoidWidgetOperatorEquals(),
        '''
import 'package:flutter/widgets.dart';

abstract class PlainWidget extends Widget {}
abstract class PlainStatelessWidget extends StatelessWidget {}
abstract class PlainStatefulWidget extends StatefulWidget {}
''',
      );

      expect(diagnostics, isEmpty);
    });
  });
}
