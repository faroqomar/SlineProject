/// Provides feature-view design-token lints for hardcoded Flutter UI values.
///
/// SLine views should consume theme, layout, and motion tokens so redesigns can
/// move through token files instead of scattered widget literals.
library;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' show ErrorSeverity;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

bool _isFeatureView(String path) {
  final normalized = path.replaceAll(String.fromCharCode(92), '/');
  return normalized.contains('/lib/features/') && normalized.contains('/view/');
}

/// Blocks hardcoded theme, motion, and layout values inside feature views.
class NoHardcodedFeatureViewTokensRule extends DartLintRule {
  /// Creates the hardcoded feature-view token rule.
  const NoHardcodedFeatureViewTokensRule() : super(code: _code);

  static const _code = LintCode(
    name: 'sline_no_hardcoded_feature_view_tokens',
    problemMessage:
        'Feature views must use SLine theme, layout, typography, or motion tokens.',
    correctionMessage:
        'Replace hardcoded Color, Duration, or TextStyle.fontSize values with AppColors, AppMotion, AppTypography, AppLayout, or AppDimens.',
    errorSeverity: ErrorSeverity.ERROR,
  );

  @override
  void run(
    CustomLintResolver resolver,
    ErrorReporter reporter,
    CustomLintContext context,
  ) {
    if (!_isFeatureView(resolver.path)) return;

    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name.lexeme;
      if (_isHardcodedColor(typeName, node) ||
          _isHardcodedDuration(typeName, node) ||
          _isHardcodedTextStyle(typeName, node) ||
          _isHardcodedSpacing(typeName, node) ||
          _isHardcodedRadius(typeName, node) ||
          typeName == 'BoxShadow') {
        reporter.atNode(node, code);
      }
    });

    context.registry.addPrefixedIdentifier((node) {
      if (node.prefix.name == 'Colors' || node.prefix.name == 'Curves') {
        reporter.atNode(node, code);
      }
    });
  }

  static bool _isHardcodedColor(
    String typeName,
    InstanceCreationExpression node,
  ) {
    if (typeName != 'Color') return false;
    return node.argumentList.arguments.any((argument) {
      return argument is IntegerLiteral;
    });
  }

  static bool _isHardcodedDuration(
    String typeName,
    InstanceCreationExpression node,
  ) {
    if (typeName != 'Duration') return false;
    return node.argumentList.arguments.any((argument) {
      return argument is NamedExpression &&
          _motionDurationLiteralNames.contains(argument.name.label.name) &&
          _containsNonZeroNumericLiteral(argument.expression);
    });
  }

  static bool _isHardcodedTextStyle(
    String typeName,
    InstanceCreationExpression node,
  ) {
    if (typeName != 'TextStyle') return false;
    return node.argumentList.arguments.any((argument) {
      return argument is NamedExpression &&
          argument.name.label.name == 'fontSize' &&
          (argument.expression is IntegerLiteral ||
              argument.expression is DoubleLiteral);
    });
  }

  static bool _isHardcodedSpacing(
    String typeName,
    InstanceCreationExpression node,
  ) {
    if (typeName != 'EdgeInsets') return false;
    return node.argumentList.arguments.any(_containsNonZeroNumericLiteral);
  }

  static bool _isHardcodedRadius(
    String typeName,
    InstanceCreationExpression node,
  ) {
    if (typeName != 'BorderRadius' && typeName != 'Radius') return false;
    return node.argumentList.arguments.any(_containsNonZeroNumericLiteral);
  }
}

const _motionDurationLiteralNames = <String>{'milliseconds', 'microseconds'};

bool _containsNonZeroNumericLiteral(Expression expression) {
  if (expression is IntegerLiteral) {
    return expression.value != 0;
  }

  if (expression is DoubleLiteral) {
    return expression.value != 0;
  }

  if (expression is NamedExpression) {
    return _containsNonZeroNumericLiteral(expression.expression);
  }

  return false;
}
