/// Registers SLine-specific `custom_lint` analyzer rules.
///
/// These rules turn the project's MVVM and design-token conventions into
/// executable checks that run in local hooks and CI.
library;

import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:sline_lints/src/rules/forbidden_architecture_rule.dart';
import 'package:sline_lints/src/rules/no_hardcoded_feature_view_tokens_rule.dart';

/// Entry point required by `custom_lint`.
PluginBase createPlugin() => _SLineLintPlugin();

class _SLineLintPlugin extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => const [
    NoSupabaseInFeatureViewsRule(),
    NoRepositoryImportsInFeatureViewsRule(),
    NoRawNetworkImportsInFeatureViewsRule(),
    NoViewImportsInViewModelsRule(),
    NoViewImportsInServiceDataRule(),
    NoViewModelImportsInServiceDataRule(),
    NoFeatureUiImportsInCoreRule(),
    NoUiFrameworkImportsInViewModelsRule(),
    NoNavigatorInViewModelsRule(),
    NoUiControllersInViewModelsRule(),
    NoSupabaseInViewModelsRule(),
    NoBuildContextOutsideViewsRule(),
    NoNotifyListenersInLoopsRule(),
    RequireChangeNotifierForViewModelsRule(),
    NoRawExceptionStringForUiErrorsRule(),
    NoPrintInLibRule(),
    NoDynamicMapsInModelsRule(),
    NoSignedUrlPersistenceRule(),
    NoOffsetPaginationRule(),
    NoHardcodedFeatureViewTokensRule(),
  ];
}
