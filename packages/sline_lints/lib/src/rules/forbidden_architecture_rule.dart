/// Provides SLine MVVM boundary lints for feature-layer Dart files.
///
/// These checks replace fragile shell greps with analyzer-backed diagnostics
/// that point at the offending import or expression.
library;

import 'package:analyzer/dart/ast/ast.dart';
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

bool _isAllowedSupabaseViewReference(String path) {
  final normalized = path.replaceAll(String.fromCharCode(92), '/');
  return normalized.endsWith(
    '/lib/features/booking/view/payment_webview_screen.dart',
  );
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
