/// Financial metrics from the ledger system for dashboard display.
/// These metrics reflect real-time platform financial data.
class FinancialMetrics {
  const FinancialMetrics({
    required this.gmv,
    required this.revenue,
    required this.escrowHeld,
    required this.platformCash,
    required this.lifetimeRefunds,
    required this.calculatedAt,
    this.currency = 'IQD',
  });

  /// Gross Merchandise Value - total value of all completed transactions
  final double gmv;

  /// Platform revenue - total fees collected
  final double revenue;

  /// Total amount currently held in escrow
  final double escrowHeld;

  /// Platform cash balance
  final double platformCash;

  /// Total refunds issued
  final double lifetimeRefunds;

  /// When these metrics were calculated
  final DateTime calculatedAt;

  /// Currency code (always IQD for MVP)
  final String currency;

  /// Take rate as percentage (revenue / gmv * 100)
  double get takeRatePercent {
    if (gmv <= 0) return 0;
    return (revenue / gmv) * 100;
  }

  /// Refund rate as percentage (refunds / gmv * 100)
  double get refundRatePercent {
    if (gmv <= 0) return 0;
    return (lifetimeRefunds / gmv) * 100;
  }

  factory FinancialMetrics.fromJson(Map<String, dynamic> json) {
    return FinancialMetrics(
      gmv: ((json['gmv_iqd'] ?? json['gmv'] ?? 0) as num).toDouble(),
      revenue: ((json['revenue_iqd'] ?? json['revenue'] ?? 0) as num).toDouble(),
      escrowHeld: ((json['escrow_held_iqd'] ?? json['escrow_held'] ?? 0) as num).toDouble(),
      platformCash: ((json['platform_cash_iqd'] ?? json['platform_cash'] ?? 0) as num).toDouble(),
      lifetimeRefunds: ((json['lifetime_refunds_iqd'] ?? json['lifetime_refunds'] ?? 0) as num).toDouble(),
      calculatedAt: DateTime.tryParse(json['calculated_at'] ?? '') ?? DateTime.now(),
      currency: json['currency'] as String? ?? 'IQD',
    );
  }

  /// Empty/zero metrics
  factory FinancialMetrics.zero() {
    return FinancialMetrics(
      gmv: 0,
      revenue: 0,
      escrowHeld: 0,
      platformCash: 0,
      lifetimeRefunds: 0,
      calculatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gmv_iqd': gmv,
      'revenue_iqd': revenue,
      'escrow_held_iqd': escrowHeld,
      'platform_cash_iqd': platformCash,
      'lifetime_refunds_iqd': lifetimeRefunds,
      'calculated_at': calculatedAt.toIso8601String(),
      'currency': currency,
    };
  }

  @override
  String toString() {
    return 'FinancialMetrics(gmv: $gmv, revenue: $revenue, escrow: $escrowHeld, cash: $platformCash)';
  }
}

/// Period-based financial metrics (daily, weekly, monthly)
class PeriodFinancialMetrics {
  const PeriodFinancialMetrics({
    required this.periodStart,
    required this.periodEnd,
    required this.period,
    required this.gmv,
    required this.revenue,
    required this.refunds,
    required this.transactionCount,
    required this.takeRate,
    required this.refundRate,
    this.currency = 'IQD',
  });

  final DateTime periodStart;
  final DateTime periodEnd;
  final String period; // 'day', 'week', 'month'
  final double gmv;
  final double revenue;
  final double refunds;
  final int transactionCount;
  final double takeRate; // Percentage
  final double refundRate; // Percentage
  final String currency;

  factory PeriodFinancialMetrics.fromJson(Map<String, dynamic> json) {
    return PeriodFinancialMetrics(
      periodStart: DateTime.tryParse(json['period_start'] ?? '') ?? DateTime.now(),
      periodEnd: DateTime.tryParse(json['period_end'] ?? '') ?? DateTime.now(),
      period: json['period'] as String? ?? 'day',
      gmv: ((json['gmv'] ?? 0) as num).toDouble(),
      revenue: ((json['revenue'] ?? 0) as num).toDouble(),
      refunds: ((json['refunds'] ?? 0) as num).toDouble(),
      transactionCount: (json['transaction_count'] ?? 0) as int,
      takeRate: ((json['take_rate'] ?? 0) as num).toDouble(),
      refundRate: ((json['refund_rate'] ?? 0) as num).toDouble(),
      currency: json['currency'] as String? ?? 'IQD',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
      'period': period,
      'gmv': gmv,
      'revenue': revenue,
      'refunds': refunds,
      'transaction_count': transactionCount,
      'take_rate': takeRate,
      'refund_rate': refundRate,
      'currency': currency,
    };
  }
}
