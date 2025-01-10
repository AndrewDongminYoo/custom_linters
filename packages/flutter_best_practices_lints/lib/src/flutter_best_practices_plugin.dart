// 📦 Package imports:
import 'package:custom_lint_builder/custom_lint_builder.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/rules/matching_class_and_file_name.dart';
import 'package:flutter_best_practices_lints/src/rules/single_class_per_file.dart';

/// This is the entrypoint of our custom linter
PluginBase createPlugin() => FlutterBestPracticesPlugin();

/// A plugin class is used to list all the assists/lints defined by a plugin.
class FlutterBestPracticesPlugin extends PluginBase {
  /// We list all the custom warnings/infos/errors
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => <LintRule>[
        const SingleClassPerFile(),
        const MatchingClassAndFileName(),
      ];
}
