// 📦 Package imports:
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

// 🌎 Project imports:
import 'package:go_router_linter/src/rules/avoid_hardcoded_routes.dart';
import 'package:go_router_linter/src/rules/avoid_navigator_named_routes_with_go_router.dart';
import 'package:go_router_linter/src/rules/missing_go_router_error_handler.dart';
import 'package:go_router_linter/src/rules/missing_go_route_name_property.dart';
import 'package:go_router_linter/src/rules/use_context_directly_for_go_router.dart';

/// The entrypoint loaded by the analyzer plugin host.
final plugin = _GoRouterLintPlugin();

class _GoRouterLintPlugin extends Plugin {
  @override
  String get name => 'go_router_linter';

  @override
  void register(PluginRegistry registry) {
    registry
      ..registerLintRule(UseContextDirectlyForGoRouter())
      ..registerLintRule(MissingGoRouteNameProperty())
      ..registerLintRule(AvoidHardcodedRoutes())
      ..registerLintRule(AvoidNavigatorNamedRoutesWithGoRouter())
      ..registerLintRule(MissingGoRouterErrorHandler());
  }
}
