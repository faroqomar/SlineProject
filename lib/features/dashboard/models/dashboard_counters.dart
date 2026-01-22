class DashboardCounters {
  final int pendingBookings;
  final int activeWork;
  final int unreadMessages;
  final int
  newOffers; // For client: offers received. For freelancer: offers on own tasks (rare)
  final int openTasks; // Client only
  final int activeBookings; // Client only

  const DashboardCounters({
    this.pendingBookings = 0,
    this.activeWork = 0,
    this.unreadMessages = 0,
    this.newOffers = 0,
    this.openTasks = 0,
    this.activeBookings = 0,
  });
}
