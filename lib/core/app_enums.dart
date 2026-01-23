/// Defines application-wide enumerations.
library;

/// Represents the possible views or tabs in the main navigation of the application.
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
enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  canceled,
  noShow,
  declined,
}

/// Status of an Offer (Task Request).
enum OfferStatus { pending, accepted, rejected, withdrawn }

/// Type of item in the Unified Workspace.
enum WorkItemType { task, booking }

/// Primary action to be taken on a WorkItem.
enum PrimaryActionType { startWork, markCompleted, approveClose }

/// Tabs in the Unified Dashboard.
enum DashboardTab { overview, manage, bookings, activeWork, inbox }
