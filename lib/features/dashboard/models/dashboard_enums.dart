enum UserRole { client, freelancer }

enum DashboardTab { overview, manage, bookings, activeWork, inbox }

enum TaskStatus { open, assigned, inProgress, completed, closed, canceled }

enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,
  canceled,
  noShow,
  declined,
}

enum OfferStatus { pending, accepted, rejected, withdrawn }

enum WorkItemType { task, booking }

enum PrimaryActionType {
  startWork,
  markCompleted,
  approveClose,
  openChat,
  confirm,
  pay,
  review,
  none,
}
