class DashboardCounters {
  final int activeWork;
  final int pendingRequests;
  final int newMessages;
  final int newOffers;
  final int needsReview;
  final int pendingPayment;
  final int completed;

  const DashboardCounters({
    this.activeWork = 0,
    this.pendingRequests = 0,
    this.newMessages = 0,
    this.newOffers = 0,
    this.needsReview = 0,
    this.pendingPayment = 0,
    this.completed = 0,
  });

  bool get isEmpty =>
      activeWork == 0 &&
      pendingRequests == 0 &&
      newMessages == 0 &&
      newOffers == 0 &&
      needsReview == 0 &&
      pendingPayment == 0 &&
      completed == 0;

  /// Serialize to Map for caching
  Map<String, int> toMap() {
    return {
      'activeWork': activeWork,
      'pendingRequests': pendingRequests,
      'newMessages': newMessages,
      'newOffers': newOffers,
      'needsReview': needsReview,
      'pendingPayment': pendingPayment,
      'completed': completed,
    };
  }

  /// Deserialize from Map for cache retrieval
  factory DashboardCounters.fromMap(Map<String, int> map) {
    return DashboardCounters(
      activeWork: map['activeWork'] ?? 0,
      pendingRequests: map['pendingRequests'] ?? 0,
      newMessages: map['newMessages'] ?? 0,
      newOffers: map['newOffers'] ?? 0,
      needsReview: map['needsReview'] ?? 0,
      pendingPayment: map['pendingPayment'] ?? 0,
      completed: map['completed'] ?? 0,
    );
  }
}
