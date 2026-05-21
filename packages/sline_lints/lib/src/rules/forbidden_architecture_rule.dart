/// Provides SLine MVVM boundary lints for feature-layer Dart files.
///
/// These checks replace fragile shell greps with analyzer-backed diagnostics
/// that point at the offending import or expression.
library;

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

bool _isFeatureView(String path) {
  final normalized = path.replaceAll(String.fromCharCode(92), '/');
  return normalized.contains('/lib/features/') && normalized.contains('/view/');
}

bool _isFeatureViewModel(String path) {
  final normalized = path.replaceAll(String.fromCharCode(92), '/');
  return normalized.contains('/lib/features/') &&
      normalized.contains('/viewmodels/');
}

bool _isFeatureService(String path) {
  final normalized = path.replaceAll(String.fromCharCode(92), '/');
  return normalized.contains('/lib/features/') &&
      normalized.contains('/services/');
}

bool _isFeatureModel(String path) {
  final normalized = path.replaceAll(String.fromCharCode(92), '/');
  return normalized.contains('/lib/features/') &&
      normalized.contains('/models/');
}

bool _isTestFile(String path) {
  final normalized = path.replaceAll(String.fromCharCode(92), '/');
  return normalized.contains('/test/');
}

bool _isRestrictedNonViewLayer(String path) {
  final normalized = path.replaceAll(String.fromCharCode(92), '/');
  if (normalized.contains('/lib/features/') && normalized.contains('/view/')) {
    return false;
  }

  return normalized.contains('/lib/features/') &&
      (normalized.contains('/viewmodels/') ||
          normalized.contains('/data/') ||
          normalized.contains('/repositories/'));
}

bool _isServiceOrDataLayer(String path) {
  final normalized = path.replaceAll(String.fromCharCode(92), '/');
  if (normalized.endsWith('_deep_link_handler.dart')) return false;

  return normalized.contains('/lib/features/') &&
      (normalized.contains('/services/') ||
          normalized.contains('/data/') ||
          normalized.contains('/repositories/'));
}

bool _isCoreLayer(String path) {
  final normalized = path.replaceAll(String.fromCharCode(92), '/');
  return normalized.contains('/lib/core/');
}

bool _isAllowedSupabaseViewReference(String path) {
  final normalized = path.replaceAll(String.fromCharCode(92), '/');
  return normalized.endsWith(
    '/lib/features/booking/view/payment_webview_screen.dart',
  );
}

bool _importsFeatureView(String uri) {
  return uri.contains('/features/') && uri.contains('/view/');
}

bool _importsFeatureViewModel(String uri) {
  return uri.contains('/features/') && uri.contains('/viewmodels/');
}

bool _isAllowedFeatureViewServiceImport(String uri) {
  return uri.endsWith('/logger_service.dart') ||
      uri.endsWith('/deep_link_service.dart') ||
      uri.endsWith('/payment_pending_store.dart');
}

bool _isAllowedCoreServiceImport(String uri) {
  return uri.endsWith('/logger_service.dart') ||
      uri.endsWith('/deep_link_service.dart') ||
      uri.endsWith('/payment_pending_store.dart');
}

/// Prevents direct Supabase access from feature views.
class NoSupabaseInFeatureViewsRule extends DartLintRule {
  /// Creates the Supabase-in-view boundary rule.
  const NoSupabaseInFeatureViewsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_supabase_in_feature_views',
    problemMessage: 'Feature views must not access Supabase directly.',
    correctionMessage:
        'Move backend access behind a ViewModel, repository, or service.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureView(resolver.path) ||
        _isAllowedSupabaseViewReference(resolver.path)) {
      return;
    }

    context.registry.addImportDirective((node) {
      if (node.uri.stringValue ==
          'package:supabase_flutter/supabase_flutter.dart') {
        reporter.atNode(node, code);
      }
    });

    context.registry.addSimpleIdentifier((node) {
      if (node.name == 'Supabase') {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents feature views from importing repositories directly.
class NoRepositoryImportsInFeatureViewsRule extends DartLintRule {
  /// Creates the repository-import boundary rule.
  const NoRepositoryImportsInFeatureViewsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_repository_imports_in_feature_views',
    problemMessage: 'Feature views must not import repositories directly.',
    correctionMessage: 'Expose UI state through a ViewModel instead.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureView(resolver.path)) return;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue ?? '';
      if (uri.contains('/repository') || uri.contains('_repository.dart')) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents feature views from importing feature services directly.
class NoServicesInFeatureViewsRule extends DartLintRule {
  /// Creates the service-import boundary rule.
  const NoServicesInFeatureViewsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_services_in_feature_views',
    problemMessage: 'Feature views must not import feature services directly.',
    correctionMessage: 'Expose service work through a ViewModel instead.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureView(resolver.path)) return;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue ?? '';
      if (uri.contains('/features/') &&
          uri.contains('/services/') &&
          !_isAllowedFeatureViewServiceImport(uri)) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents feature views from importing core services directly.
class NoCoreServicesInFeatureViewsRule extends DartLintRule {
  /// Creates the core-service-import boundary rule.
  const NoCoreServicesInFeatureViewsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_core_services_in_feature_views_except_allowed',
    problemMessage: 'Feature views must not import core services directly.',
    correctionMessage:
        'Use a ViewModel or an explicitly approved UI-adjacent helper.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureView(resolver.path)) return;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue ?? '';
      if (uri.contains('/core/services/') &&
          !_isAllowedCoreServiceImport(uri)) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents raw network clients from being imported directly by feature views.
class NoRawNetworkImportsInFeatureViewsRule extends DartLintRule {
  /// Creates the raw-network-import boundary rule.
  const NoRawNetworkImportsInFeatureViewsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_raw_network_imports_in_feature_views',
    problemMessage: 'Feature views must not import raw network clients.',
    correctionMessage:
        'Move HTTP or socket access behind a ViewModel, repository, or service.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureView(resolver.path)) return;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue ?? '';
      if (uri.startsWith('package:http/') || uri == 'dart:io') {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents ViewModels from importing view-layer code.
class NoViewImportsInViewModelsRule extends DartLintRule {
  /// Creates the view-import boundary rule.
  const NoViewImportsInViewModelsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_view_imports_in_viewmodels',
    problemMessage: 'ViewModels must not import view-layer code.',
    correctionMessage:
        'Move shared types into models/core or expose behavior through services.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureViewModel(resolver.path)) return;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue ?? '';
      if (uri.contains('/view/')) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents feature services/data from importing view-layer code.
class NoViewImportsInServiceDataRule extends DartLintRule {
  /// Creates the service/data view-import boundary rule.
  const NoViewImportsInServiceDataRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_view_imports_in_services_data',
    problemMessage: 'Services and data layers must not import feature views.',
    correctionMessage:
        'Move shared UI-neutral types to models/core or invert the dependency.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isServiceOrDataLayer(resolver.path)) return;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue ?? '';
      if (_importsFeatureView(uri)) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents feature services/data from importing ViewModels.
class NoViewModelImportsInServiceDataRule extends DartLintRule {
  /// Creates the service/data ViewModel-import boundary rule.
  const NoViewModelImportsInServiceDataRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_viewmodel_imports_in_services_data',
    problemMessage:
        'Services and data layers must not import feature ViewModels.',
    correctionMessage:
        'Keep dependencies flowing from ViewModel to service/data, not back.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isServiceOrDataLayer(resolver.path)) return;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue ?? '';
      if (_importsFeatureViewModel(uri)) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents core from depending on feature UI or ViewModels.
class NoFeatureUiImportsInCoreRule extends DartLintRule {
  /// Creates the core feature-UI import boundary rule.
  const NoFeatureUiImportsInCoreRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_feature_ui_imports_in_core',
    problemMessage: 'Core must not import feature views or ViewModels.',
    correctionMessage:
        'Move shared contracts into core or keep feature wiring in app/features.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isCoreLayer(resolver.path)) return;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue ?? '';
      if (_importsFeatureView(uri) || _importsFeatureViewModel(uri)) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents ViewModels from importing UI framework/provider packages.
class NoUiFrameworkImportsInViewModelsRule extends DartLintRule {
  /// Creates the ViewModel UI-framework import boundary rule.
  const NoUiFrameworkImportsInViewModelsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_ui_framework_imports_in_viewmodels',
    problemMessage:
        'ViewModels must not import UI framework or Provider packages.',
    correctionMessage:
        'Keep Provider, Material, Widgets, and Cupertino imports in views.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureViewModel(resolver.path)) return;

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue ?? '';
      if (uri == 'package:provider/provider.dart' ||
          uri == 'package:flutter/material.dart' ||
          uri == 'package:flutter/widgets.dart' ||
          uri == 'package:flutter/cupertino.dart') {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents navigation from being orchestrated inside ViewModels.
class NoNavigatorInViewModelsRule extends DartLintRule {
  /// Creates the Navigator-in-ViewModel boundary rule.
  const NoNavigatorInViewModelsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_navigator_in_viewmodels',
    problemMessage: 'ViewModels must not call Navigator.',
    correctionMessage:
        'Expose state/events and let the view decide navigation.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureViewModel(resolver.path)) return;

    context.registry.addSimpleIdentifier((node) {
      if (node.name == 'Navigator') {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents UI controllers and form keys from being owned by ViewModels.
class NoUiControllersInViewModelsRule extends DartLintRule {
  /// Creates the UI-controller-in-ViewModel boundary rule.
  const NoUiControllersInViewModelsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_ui_controllers_in_viewmodels',
    problemMessage: 'ViewModels must not own UI controllers or form keys.',
    correctionMessage:
        'Keep TextEditingController and GlobalKey<FormState> in the view layer.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureViewModel(resolver.path)) return;

    context.registry.addSimpleIdentifier((node) {
      if (node.name == 'TextEditingController' ||
          _isFormGlobalKeyIdentifier(node)) {
        reporter.atNode(node, code);
      }
    });
  }

  static bool _isFormGlobalKeyIdentifier(SimpleIdentifier node) {
    if (node.name != 'GlobalKey') return false;
    final parent = node.parent;
    if (parent is! NamedType) return false;

    final type = parent.type;
    if (type is! InterfaceType) return false;

    return type.typeArguments.any((typeArgument) {
      return typeArgument.element?.name == 'FormState';
    });
  }
}

/// Prevents direct Supabase access from ViewModel executable bodies.
class NoSupabaseInViewModelsRule extends DartLintRule {
  /// Creates the Supabase-in-ViewModel rule.
  const NoSupabaseInViewModelsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_supabase_in_viewmodels',
    problemMessage: 'ViewModel logic must not access Supabase directly.',
    correctionMessage:
        'Inject a service or repository instead of SupabaseClient/Supabase.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureViewModel(resolver.path)) return;

    context.registry.addSimpleIdentifier((node) {
      if (node.name == 'Supabase' && _isInsideExecutableBody(node)) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents one feature view from importing another feature view.
class NoFeatureToFeatureViewImportsRule extends DartLintRule {
  /// Creates the feature-view import boundary rule.
  const NoFeatureToFeatureViewImportsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_feature_to_feature_view_imports',
    problemMessage: 'Feature views must not import other feature views.',
    correctionMessage:
        'Move shared UI to core/widgets or a feature-neutral module.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureView(resolver.path)) return;
    final currentFeature = _featureNameFromPath(resolver.path);

    context.registry.addImportDirective((node) {
      final uri = node.uri.stringValue ?? '';
      if (!uri.contains('/features/') || !uri.contains('/view/')) return;
      final importedFeature = _featureNameFromImport(uri);
      if (importedFeature != null && importedFeature != currentFeature) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents BuildContext from leaking into non-view state/data layers.
class NoBuildContextOutsideViewsRule extends DartLintRule {
  /// Creates the BuildContext boundary rule.
  const NoBuildContextOutsideViewsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_build_context_outside_views',
    problemMessage:
        'BuildContext must stay in the view layer, not ViewModels or data layers.',
    correctionMessage:
        'Pass plain values or callbacks instead of BuildContext.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isRestrictedNonViewLayer(resolver.path)) return;

    context.registry.addSimpleIdentifier((node) {
      if (node.name == 'BuildContext') {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents notifyListeners from being called inside loops.
class NoNotifyListenersInLoopsRule extends DartLintRule {
  /// Creates the notifyListeners-in-loop rule.
  const NoNotifyListenersInLoopsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_notify_listeners_in_loops',
    problemMessage: 'Do not call notifyListeners inside loops.',
    correctionMessage:
        'Update state in the loop and notify once after the loop completes.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureViewModel(resolver.path)) return;

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'notifyListeners' && _isInsideLoop(node)) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Requires conventional ViewModel files to expose a ChangeNotifier class.
class RequireChangeNotifierForViewModelsRule extends DartLintRule {
  /// Creates the ChangeNotifier ViewModel rule.
  const RequireChangeNotifierForViewModelsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_require_changenotifier_for_viewmodels',
    problemMessage: 'ViewModel files should expose a ChangeNotifier class.',
    correctionMessage:
        'Extend ChangeNotifier or move pure delegates out of *_view_model.dart files.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final normalized = resolver.path.replaceAll(String.fromCharCode(92), '/');
    if (!normalized.endsWith('_view_model.dart') ||
        !normalized.contains('/viewmodels/')) {
      return;
    }

    context.registry.addCompilationUnit((node) {
      final hasChangeNotifierViewModel = node.declarations
          .whereType<ClassDeclaration>()
          .any(_extendsChangeNotifier);
      if (!hasChangeNotifierViewModel) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents public mutable fields in ViewModels.
class NoPublicMutableViewModelStateRule extends DartLintRule {
  /// Creates the public mutable ViewModel state rule.
  const NoPublicMutableViewModelStateRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_public_mutable_viewmodel_state',
    problemMessage: 'ViewModels must not expose public mutable fields.',
    correctionMessage: 'Use private fields plus public getters.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureViewModel(resolver.path)) return;

    context.registry.addFieldDeclaration((node) {
      if (node.isStatic || node.fields.isFinal || node.fields.isConst) return;
      for (final variable in node.fields.variables) {
        if (!variable.name.lexeme.startsWith('_')) {
          reporter.atNode(variable, code);
        }
      }
    });
  }
}

/// Prevents raw exception strings from being assigned as user-facing errors.
class NoRawExceptionStringForUiErrorsRule extends DartLintRule {
  /// Creates the raw exception string rule.
  const NoRawExceptionStringForUiErrorsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_raw_exception_string_for_ui_errors',
    problemMessage: 'Do not expose raw exception strings as UI errors.',
    correctionMessage:
        'Map exceptions through ErrorMapper or a feature-specific friendly mapper.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureViewModel(resolver.path)) return;

    context.registry.addAssignmentExpression((node) {
      final leftName = _assignmentName(node.leftHandSide);
      if (_looksUserFacingErrorName(leftName) &&
          _containsRawExceptionToString(node.rightHandSide)) {
        reporter.atNode(node, code);
      }
    });

    context.registry.addVariableDeclaration((node) {
      final initializer = node.initializer;
      if (initializer == null) return;
      if (_looksUserFacingErrorName(node.name.lexeme) &&
          _containsRawExceptionToString(initializer)) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents print-style logging from bypassing AppLogger.
class NoPrintInLibRule extends DartLintRule {
  /// Creates the print/debugPrint rule.
  const NoPrintInLibRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_print_in_lib',
    problemMessage: 'Production code must use AppLogger instead of print.',
    correctionMessage: 'Replace print/debugPrint with AppLogger.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final normalized = resolver.path.replaceAll(String.fromCharCode(92), '/');
    if (!_isProductionPrintCheckedPath(normalized)) return;

    context.registry.addMethodInvocation((node) {
      final methodName = node.methodName.name;
      if (methodName == 'print' || methodName == 'debugPrint') {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Requires AppLogger calls to include a tag.
class RequireAppLoggerTagRule extends DartLintRule {
  /// Creates the AppLogger tag rule.
  const RequireAppLoggerTagRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_require_app_logger_tag',
    problemMessage: 'AppLogger calls must include a tag.',
    correctionMessage: 'Add a stable feature or class tag.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final normalized = resolver.path.replaceAll(String.fromCharCode(92), '/');
    if (!normalized.contains('/lib/features/')) return;

    context.registry.addMethodInvocation((node) {
      final target = node.target;
      if (target is SimpleIdentifier &&
          target.name == 'AppLogger' &&
          !node.argumentList.arguments.any(_isTagArgument)) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents empty catch blocks.
class NoEmptyCatchRule extends DartLintRule {
  /// Creates the empty catch rule.
  const NoEmptyCatchRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_empty_catch',
    problemMessage: 'Catch blocks must not be empty.',
    correctionMessage:
        'Log, map, rethrow, or explicitly document the recovery.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final normalized = resolver.path.replaceAll(String.fromCharCode(92), '/');
    if (!normalized.contains('/lib/')) return;

    context.registry.addCatchClause((node) {
      if (node.body.statements.isEmpty) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Requires catch blocks to handle failures visibly.
class NoSwallowedCatchRule extends DartLintRule {
  /// Creates the swallowed catch rule.
  const NoSwallowedCatchRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_swallowed_catch',
    problemMessage:
        'Catch blocks must log, map, rethrow, or return a fallback.',
    correctionMessage:
        'Use AppLogger, ErrorMapper, rethrow, or an explicit fallback return.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final normalized = resolver.path.replaceAll(String.fromCharCode(92), '/');
    if (!normalized.contains('/lib/')) return;

    context.registry.addCatchClause((node) {
      if (!_catchHandlesFailure(node)) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Requires model fromJson methods to take typed maps.
class NoDynamicMapsInModelsRule extends DartLintRule {
  /// Creates the dynamic map model rule.
  const NoDynamicMapsInModelsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_dynamic_maps_in_models',
    problemMessage: 'Model fromJson methods must use typed map parameters.',
    correctionMessage: 'Use Map<String, dynamic> or a safer concrete map type.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureModel(resolver.path)) return;

    context.registry.addMethodDeclaration((node) {
      if (node.name.lexeme != 'fromJson') return;
      for (final parameter
          in node.parameters?.parameters ?? <FormalParameter>[]) {
        final source = parameter.toSource();
        if (source.contains('Map ') || source.contains('Map<dynamic')) {
          reporter.atNode(parameter, code);
        }
      }
    });
  }
}

/// Prevents common raw status strings outside model mapping code.
class NoStringlyTypedStatusRule extends DartLintRule {
  /// Creates the string status rule.
  const NoStringlyTypedStatusRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_stringly_typed_status',
    problemMessage: 'Do not use repeated raw status strings.',
    correctionMessage: 'Use enums, constants, or mapper helpers.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final normalized = resolver.path.replaceAll(String.fromCharCode(92), '/');
    if (!normalized.contains('/lib/features/') ||
        normalized.contains('/models/') ||
        normalized.contains('/app_enums.dart') ||
        normalized.contains('/presenter') ||
        normalized.contains('/mapper') ||
        normalized.contains('/utils/')) {
      return;
    }

    context.registry.addSimpleStringLiteral((node) {
      if (_statusStrings.contains(node.value)) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents database column names from leaking into views.
class NoMagicDatabaseColumnsInViewsRule extends DartLintRule {
  /// Creates the magic DB column view rule.
  const NoMagicDatabaseColumnsInViewsRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_magic_database_columns_in_views',
    problemMessage: 'Feature views must not reference raw database columns.',
    correctionMessage: 'Expose typed model/ViewModel fields instead.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureView(resolver.path)) return;

    context.registry.addSimpleStringLiteral((node) {
      if (_databaseColumnStrings.contains(node.value)) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents signed URLs from being persisted in DB payloads.
class NoSignedUrlPersistenceRule extends DartLintRule {
  /// Creates the signed URL persistence rule.
  const NoSignedUrlPersistenceRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_signed_url_persistence',
    problemMessage: 'Do not persist signed URLs as source-of-truth data.',
    correctionMessage:
        'Persist storage paths and generate signed URLs at render time.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final normalized = resolver.path.replaceAll(String.fromCharCode(92), '/');
    if (!normalized.contains('/lib/')) return;

    context.registry.addSimpleStringLiteral((node) {
      final value = node.value.toLowerCase();
      if ((value.contains('signed_url') || value.contains('signedurl')) &&
          _isInsidePersistencePayload(node)) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Requires mounted checks after await before using context or setState.
class NoFutureWithoutMountedCheckInStateRule extends DartLintRule {
  /// Creates the mounted-check rule.
  const NoFutureWithoutMountedCheckInStateRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_future_without_mounted_check_in_state',
    problemMessage:
        'State methods must check mounted after await before UI use.',
    correctionMessage:
        'Add if (!mounted) return; before context or setState usage after await.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureView(resolver.path)) return;

    context.registry.addMethodDeclaration((node) {
      if (!_isInsideStateClass(node) || node.body is! BlockFunctionBody) return;
      final body = node.body as BlockFunctionBody;
      final checker = _MountedAfterAwaitVisitor();
      body.visitChildren(checker);
      if (checker.violation != null) {
        reporter.atNode(checker.violation!, code);
      }
    });
  }
}

/// Blocks select('*') in Supabase service/repository code.
class NoSupabaseSelectStarRule extends DartLintRule {
  /// Creates the select-star rule.
  const NoSupabaseSelectStarRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_supabase_select_star',
    problemMessage: "Avoid Supabase select('*').",
    correctionMessage:
        'Select explicit columns or document a deliberate exception.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureService(resolver.path) &&
        !resolver.path.contains('/data/') &&
        !resolver.path.contains('/repositories/')) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'select' &&
          node.argumentList.arguments.any(_isStarString)) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents offset-style pagination.
class NoOffsetPaginationRule extends DartLintRule {
  /// Creates the offset pagination rule.
  const NoOffsetPaginationRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_offset_pagination',
    problemMessage: 'Use cursor pagination instead of offset/range pagination.',
    correctionMessage: 'Use timestamp/id cursors with order and limit.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureService(resolver.path) &&
        !resolver.path.contains('/data/') &&
        !resolver.path.contains('/repositories/')) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'range' || node.methodName.name == 'offset') {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Requires collection queries with limit to also specify order.
class RequireOrderWithLimitRule extends DartLintRule {
  /// Creates the order-with-limit rule.
  const RequireOrderWithLimitRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_require_order_with_limit',
    problemMessage: 'Queries with limit must define deterministic order.',
    correctionMessage: 'Add an order(...) clause before limit(...).',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!resolver.path.contains('/lib/')) return;

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'limit' &&
          !_chainContainsMethod(node, 'order')) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Requires collection queries to have a limit.
class RequireLimitOnCollectionQueriesRule extends DartLintRule {
  /// Creates the collection limit rule.
  const RequireLimitOnCollectionQueriesRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_require_limit_on_collection_queries',
    problemMessage: 'Collection queries should specify a limit.',
    correctionMessage:
        'Add limit(...) or document why the query is intentionally unbounded.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureService(resolver.path) &&
        !resolver.path.contains('/data/') &&
        !resolver.path.contains('/repositories/')) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'select' &&
          _looksLikeCollectionSelect(node) &&
          !_chainContainsMethod(node, 'limit')) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Flags comments that imply client-side RLS bypass behavior.
class NoRlsBypassLanguageInClientRule extends DartLintRule {
  /// Creates the RLS bypass language rule.
  const NoRlsBypassLanguageInClientRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_rls_bypass_language_in_client',
    problemMessage: 'Client code must not describe bypassing RLS/security.',
    correctionMessage:
        'Move privileged behavior to backend docs/migrations or rewrite the comment.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!resolver.path.contains('/lib/')) return;

    context.registry.addComment((node) {
      final text = node.tokens
          .map((token) => token.lexeme.toLowerCase())
          .join(' ');
      if (text.contains('bypass rls') ||
          text.contains('skip rls') ||
          text.contains('disable rls')) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Requires widget tests to use a theme-aware pump harness.
class NoPumpWidgetWithoutThemeRule extends DartLintRule {
  /// Creates the pumpWidget theme harness rule.
  const NoPumpWidgetWithoutThemeRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_pumpwidget_without_theme',
    problemMessage:
        'Widget tests should pump app widgets with a theme harness.',
    correctionMessage:
        'Use the app test harness or wrap the widget in MaterialApp/theme providers.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isTestFile(resolver.path) ||
        resolver.path.contains('/integration_test/support/')) {
      return;
    }

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'pumpWidget' &&
          node.argumentList.arguments.isNotEmpty &&
          _isInsideWidgetTest(node) &&
          !_pumpWidgetArgumentLooksThemed(node.argumentList.arguments.first)) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Prevents duplicate test names inside a file.
class NoDuplicateTestNamesRule extends DartLintRule {
  /// Creates the duplicate test name rule.
  const NoDuplicateTestNamesRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_duplicate_test_names',
    problemMessage: 'Test names must be unique within a file.',
    correctionMessage: 'Rename the duplicated test to describe the case.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isTestFile(resolver.path)) return;
    final seen = <String>{};

    context.registry.addMethodInvocation((node) {
      if ((node.methodName.name == 'test' ||
              node.methodName.name == 'testWidgets') &&
          node.argumentList.arguments.isNotEmpty) {
        final first = node.argumentList.arguments.first;
        if (first is SimpleStringLiteral && !seen.add(first.value)) {
          reporter.atNode(first, code);
        }
      }
    });
  }
}

/// Requires conventional ViewModels to have a matching unit test file.
class RequireViewModelTestRule extends DartLintRule {
  /// Creates the ViewModel test file rule.
  const RequireViewModelTestRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_require_viewmodel_test_for_new_viewmodel',
    problemMessage: 'ViewModel files should have a matching unit test.',
    correctionMessage: 'Add a test under test/unit/<feature>/ or test/**.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final normalized = resolver.path.replaceAll(String.fromCharCode(92), '/');
    if (!normalized.endsWith('_view_model.dart') ||
        !normalized.contains('/viewmodels/')) {
      return;
    }

    context.registry.addCompilationUnit((node) {
      if (!_hasMatchingTest(resolver.path)) {
        reporter.atNode(node, code);
      }
    });
  }
}

/// Requires screen files to have a matching widget test file.
class RequireWidgetTestForScreenRule extends DartLintRule {
  /// Creates the screen widget test file rule.
  const RequireWidgetTestForScreenRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_require_widget_test_for_new_screen',
    problemMessage: 'Screen files should have a matching widget test.',
    correctionMessage:
        'Add a widget test under test/widget/<feature>/ or test/**.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    final normalized = resolver.path.replaceAll(String.fromCharCode(92), '/');
    if (!_isFeatureView(resolver.path) ||
        !normalized.endsWith('_screen.dart')) {
      return;
    }

    context.registry.addCompilationUnit((node) {
      if (!_hasMatchingTest(resolver.path)) {
        reporter.atNode(node, code);
      }
    });
  }
}

bool _isInsideExecutableBody(AstNode node) {
  var current = node.parent;
  while (current != null) {
    if (current is MethodDeclaration || current is FunctionDeclaration) {
      return true;
    }

    if (current is FieldDeclaration || current is ConstructorDeclaration) {
      return false;
    }
    current = current.parent;
  }

  return false;
}

String? _assignmentName(Expression expression) {
  if (expression is SimpleIdentifier) return expression.name;
  if (expression is PropertyAccess) return expression.propertyName.name;
  if (expression is PrefixedIdentifier) return expression.identifier.name;
  return null;
}

bool _looksUserFacingErrorName(String? name) {
  if (name == null) return false;
  final lower = name.toLowerCase();
  return lower == 'error' ||
      lower == 'message' ||
      lower.contains('errormessage') ||
      lower.contains('error_message') ||
      lower.endsWith('error');
}

bool _containsRawExceptionToString(Expression expression) {
  var found = false;
  expression.visitChildren(
    _MethodInvocationVisitor((node) {
      if (node.methodName.name == 'toString' &&
          node.target is SimpleIdentifier) {
        final targetName = (node.target! as SimpleIdentifier).name;
        if (targetName == 'e' || targetName == 'error') {
          found = true;
        }
      }
    }),
  );
  return found;
}

bool _isInsideLoop(AstNode node) {
  var current = node.parent;
  while (current != null) {
    if (current is ForStatement ||
        current is ForElement ||
        current is WhileStatement ||
        current is DoStatement) {
      return true;
    }
    if (current is MethodDeclaration || current is FunctionDeclaration) {
      return false;
    }
    current = current.parent;
  }
  return false;
}

bool _extendsChangeNotifier(ClassDeclaration node) {
  final extendsClause = node.extendsClause;
  if (extendsClause == null) return false;
  return extendsClause.superclass.name.lexeme == 'ChangeNotifier';
}

bool _isTagArgument(Expression expression) {
  return expression is NamedExpression && expression.name.label.name == 'tag';
}

bool _catchHandlesFailure(CatchClause node) {
  final bodySource = node.body.toSource();
  return bodySource.contains('AppLogger.') ||
      bodySource.contains('ErrorMapper.') ||
      bodySource.contains('rethrow') ||
      bodySource.contains('throw ') ||
      bodySource.contains('return ') ||
      bodySource.contains('// intentionally') ||
      bodySource.contains('// ignore');
}

String? _featureNameFromPath(String path) {
  final normalized = path.replaceAll(String.fromCharCode(92), '/');
  final match = RegExp('/lib/features/([^/]+)/').firstMatch(normalized);
  return match?.group(1);
}

String? _featureNameFromImport(String uri) {
  final match = RegExp('features/([^/]+)/').firstMatch(uri);
  return match?.group(1);
}

bool _isInsideStateClass(MethodDeclaration node) {
  final parent = node.parent;
  if (parent is! ClassDeclaration) return false;
  final superType = parent.extendsClause?.superclass.name.lexeme;
  return superType == 'State';
}

bool _isStarString(Expression expression) {
  return expression is SimpleStringLiteral && expression.value.trim() == '*';
}

bool _chainContainsMethod(MethodInvocation node, String methodName) {
  AstNode? current = node;
  while (current != null) {
    if (current is MethodInvocation && current.methodName.name == methodName) {
      return true;
    }
    current = current.parent;
    if (current is Statement) return false;
  }
  return false;
}

bool _isInsidePersistencePayload(AstNode node) {
  var current = node.parent;
  while (current != null) {
    if (current is MethodInvocation) {
      final methodName = current.methodName.name;
      return methodName == 'insert' ||
          methodName == 'update' ||
          methodName == 'upsert';
    }

    if (current is Statement || current is MethodDeclaration) return false;
    current = current.parent;
  }

  return false;
}

bool _looksLikeCollectionSelect(MethodInvocation node) {
  final source = node.parent?.toSource() ?? node.toSource();
  return source.contains('List<') ||
      source.contains('.map(') ||
      source.contains(' as List') ||
      source.contains('for (') ||
      source.contains('final rows') ||
      source.contains('final data') ||
      source.contains('final result');
}

bool _pumpWidgetArgumentLooksThemed(Expression expression) {
  final source = expression.toSource();
  return source.contains('MaterialApp') ||
      source.contains('Theme') ||
      source.contains('pumpApp') ||
      source.contains('appWrapper') ||
      source.contains('SlineApp');
}

bool _isInsideWidgetTest(AstNode node) {
  var current = node.parent;
  while (current != null) {
    if (current is MethodInvocation &&
        current.methodName.name == 'testWidgets') {
      return true;
    }
    current = current.parent;
  }
  return false;
}

bool _isProductionPrintCheckedPath(String normalizedPath) {
  const checkedSegments = <String>[
    '/lib/features/',
    '/lib/core/services/',
    '/lib/core/utils/',
    '/lib/core/providers/',
    '/lib/core/config/',
    '/lib/app/',
  ];

  return checkedSegments.any(normalizedPath.contains);
}

bool _hasMatchingTest(String sourcePath) {
  final normalized = sourcePath.replaceAll(String.fromCharCode(92), '/');
  if (!normalized.contains('/lib/') || !normalized.endsWith('.dart')) {
    return true;
  }

  final expectedTestPath = normalized
      .replaceFirst('/lib/', '/test/')
      .replaceFirst(RegExp(r'\.dart$'), '_test.dart');
  return File(expectedTestPath).existsSync();
}

const _statusStrings = <String>{
  'pending',
  'accepted',
  'rejected',
  'cancelled',
  'completed',
  'released',
  'refunded',
  'held',
  'paid',
  'failed',
};

const _databaseColumnStrings = <String>{
  'created_at',
  'updated_at',
  'user_id',
  'owner_user_id',
  'client_id',
  'freelancer_id',
  'task_id',
  'booking_id',
  'request_id',
  'profile_id',
};

class _MountedAfterAwaitVisitor extends RecursiveAstVisitor<void> {
  AstNode? violation;
  var _sawAwait = false;
  var _mountedChecked = false;

  @override
  void visitAwaitExpression(AwaitExpression node) {
    _sawAwait = true;
    _mountedChecked = false;
    super.visitAwaitExpression(node);
  }

  @override
  void visitIfStatement(IfStatement node) {
    if (_sawAwait && node.expression.toSource().contains('mounted')) {
      _mountedChecked = true;
    }
    super.visitIfStatement(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (_sawAwait &&
        !_mountedChecked &&
        (node.methodName.name == 'setState' ||
            node.toSource().contains('context'))) {
      violation ??= node;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (_sawAwait && !_mountedChecked && node.name == 'context') {
      violation ??= node;
    }
    super.visitSimpleIdentifier(node);
  }
}

class _MethodInvocationVisitor extends RecursiveAstVisitor<void> {
  _MethodInvocationVisitor(this._visit);

  final void Function(MethodInvocation node) _visit;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _visit(node);
    super.visitMethodInvocation(node);
  }
}
