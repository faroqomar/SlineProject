class AccountGuardState {
  const AccountGuardState({
    required this.isAuthenticated,
    required this.isRevoked,
    required this.isRestricted,
    required this.accountStatus,
    this.moderationReason,
    this.restrictionScope,
    this.forceLogoutAfterUtc,
    this.sessionIssuedAtUtc,
  });

  final bool isAuthenticated;
  final bool isRevoked;
  final bool isRestricted;
  final String accountStatus;
  final String? moderationReason;
  final String? restrictionScope;
  final DateTime? forceLogoutAfterUtc;
  final DateTime? sessionIssuedAtUtc;

  static const AccountGuardState unauthenticated = AccountGuardState(
    isAuthenticated: false,
    isRevoked: false,
    isRestricted: false,
    accountStatus: 'unknown',
  );
}
