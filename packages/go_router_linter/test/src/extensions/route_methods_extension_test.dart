// 🌎 Project imports:
import 'package:go_router_linter/src/extensions/route_methods_extension.dart';

// 🧪 Test imports:
import 'package:test/test.dart';

void main() {
  group('RouteMethodExtension', () {
    test('isRouteMethod returns true for known route methods', () {
      expect('go'.isRouteMethod, isTrue);
      expect('goNamed'.isRouteMethod, isTrue);
      expect('push'.isRouteMethod, isTrue);
      expect('pushNamed'.isRouteMethod, isTrue);
      expect('pushReplacement'.isRouteMethod, isTrue);
      expect('pushReplacementNamed'.isRouteMethod, isTrue);
      expect('replace'.isRouteMethod, isTrue);
      expect('replaceNamed'.isRouteMethod, isTrue);
    });

    test('isRouteMethod returns false for unknown methods', () {
      expect('l10n'.isRouteMethod, isFalse);
      expect('navigate'.isRouteMethod, isFalse);
    });
  });
}
