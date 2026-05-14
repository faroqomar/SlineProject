/// Typed status enum for services.
///
/// Maps to the `status` text column in `public.services`.
/// DB default is `draft`.
enum ServiceStatus {
  active,
  draft,
  paused;

  /// Parses a DB string into a [ServiceStatus].
  /// Falls back to [draft] for unknown values.
  static ServiceStatus fromString(String? value) {
    if (value == null) return ServiceStatus.draft;
    return ServiceStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => ServiceStatus.draft,
    );
  }

  /// Human-readable label for display.
  String get label => switch (this) {
        ServiceStatus.active => 'Active',
        ServiceStatus.draft => 'Draft',
        ServiceStatus.paused => 'Paused',
      };
}
