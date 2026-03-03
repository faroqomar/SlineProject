/// Typed result for favorites add/remove (replaces void-return + side-channel error).
enum FavoritesMutationResult {
  success,
  duplicate,
  /// Operation skipped because same id is already in progress (no snackbar).
  skipped,
  unauthenticated,
  forbidden,
  failure,
}
