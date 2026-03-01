/// Defines application-wide enumerations.
library;

/// Represents the possible views or tabs in the main navigation of the application.
///
/// `orders` is a legacy enum name preserved to avoid a broad navigation rename.
/// The live slot renders the unified dashboard, not the removed orders module.
enum NavView { home, tender, booking, orders, messages, profile, wallet }

/// User Roles in the application.
enum UserRole { client, freelancer }

/// Status of a Task (Tender/Booking parent).
enum TaskStatus {
  open,
  assigned,
  inProgress,
  completed,
  closed,
  canceled,
  draft,
}

/// Status of a Booking execution.
/// Status of a Booking execution.
enum BookingStatus {
  pending,
  confirmed,
  active, // Replaces inProgress
  delivered,
  completed,
  canceled, // Also covers declined
  refunded,
  paidRequestPending,
  expiredUnanswered,
  // Legacy/UI specific (map to DB equivalents)
  inProgress,
  noShow,
  declined,
}

/// Status of the payment linked to a Booking.
enum PaymentStatus { unpaid, held, released, refunded }

/// Status of an Offer (Task Request).
enum OfferStatus { pending, accepted, rejected, withdrawn, unknown }

/// Type of item in the Unified Workspace.
enum WorkItemType { task, booking }

/// Primary action to be taken on a WorkItem.
enum PrimaryActionType {
  startWork,
  markCompleted,
  approveClose,
  reviewDelivery,
  payEscrow,
  submitEvidence,
  viewDetails,
}

/// Tabs in the Unified Dashboard.
enum DashboardTab { overview, bookings, activeWork, inbox }

/// Tabs for the Search Screen
enum SearchTab {
  /// Find Tasks (for freelancers)
  findWork,

  /// Find Freelancers (for clients)
  findTalent,
}

/// Status of a Unified Work Item (Task/Booking).
enum UnifiedWorkStatus {
  pending,
  pendingPayment,
  requestPending,
  active,
  delivered,
  completed,
  canceled,
  disputed,
  unknown,
}
