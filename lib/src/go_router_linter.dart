// 📦 Package imports:
import 'package:custom_lint_builder/custom_lint_builder.dart';

// 🌎 Project imports:
import 'package:go_router_linter/src/missing_go_route_name_property.dart';
import 'package:go_router_linter/src/use_context_directly_for_go_router.dart';

/// This is the entrypoint of our custom linter
PluginBase createPlugin() => _GoRouterLintPlugin();

/// A plugin class is used to list all the assists/lints defined by a plugin.
class _GoRouterLintPlugin extends PluginBase {
  /// We list all the custom warnings/infos/errors
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => <LintRule>[
        const UseContextDirectlyForGoRouter(),
        const MissingGoRouteNameProperty(),
      ];
}
