/// Defines common dimension values for spacing, padding, and border radii
/// throughout the application, consistent with the design system.
///
/// This class provides static constant values to ensure a consistent visual
/// rhythm and simplifies UI development by centralizing these frequently
/// used measurements.
class AppDimens {
  AppDimens._(); // Private constructor to prevent instantiation

  // --- Spacing / Padding (Multiples of 4 and 8 for a consistent grid) ---
  static const double p0 = 0.0;
  static const double p2 = 2.0;
  static const double p4 = 4.0;
  static const double p6 = 6.0;
  static const double p8 = 8.0;
  static const double p10 = 10.0;
  static const double p12 = 12.0;
  static const double p14 = 14.0;
  static const double p16 = 16.0;
  static const double p18 = 18.0;
  static const double p20 = 20.0;
  static const double p22 = 22.0; // Added for icon size
  static const double p24 = 24.0;
  static const double p28 = 28.0;
  static const double p32 = 32.0;
  static const double p36 = 36.0;
  static const double p40 = 40.0;
  static const double p48 = 48.0;
  static const double p50 = 50.0;
  static const double p52 = 52.0;
  static const double p54 = 54.0;
  static const double p60 = 60.0;
  static const double p64 = 64.0;
  static const double p70 = 70.0;
  static const double p80 = 80.0;
  static const double p100 = 100.0;
  static const double p120 = 120.0;
  static const double p140 = 140.0;

  /// Header height for booking skeleton cards.
  static const double bookingHeaderHeight = p80 + p10;

  /// Hairline divider for dense timeline and ledger rows.
  static const double hairlineDivider = 0.5;

  // --- Border Radii ---
  static const double r2 = 2.0;
  static const double r4 = 4.0;
  static const double r8 = 8.0;
  static const double r10 = 10.0;
  static const double r12 = 12.0; // rounded-[12px]
  static const double r14 = 14.0; // rounded-[14px]
  static const double r16 = 16.0; // rounded-[16px]
  static const double r18 = 18.0; // rounded-[18px]
  static const double r20 = 20.0; // rounded-[20px]
  static const double r23 = 23.0; // rounded-[23px] (chat input)
  static const double r24 = 24.0; // rounded-[24px]
  static const double r30 = 30.0; // rounded-[30px]
  static const double r50 = 50.0; // rounded-[50px] (phone mockup border)

  // --- Icon Sizes ---
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // --- Semantic UI Tokens ---
  // Empty states reuse one visual pattern across multiple screens.
  static const double emptyStateIconContainer = p80;
  static const double emptyStateIconSize = p48;

  // Update-required gates reuse the empty-state visual scale but keep a
  // dedicated semantic name so system screens are not coupled to empty states.
  static const double updateRequiredIconContainer = p80;
  static const double updateRequiredIconSize = p48;

  // Favorite card avatar and actions keep these values centralized.
  static const double avatarMedium = 44.0;
  static const double avatarRadius = 22.0;
  static const double touchTarget = p48;
  static const double iconSmall = 20.0;

  // Public-profile hero geometry mirrors the Open Design phone profile frame.
  static const double profileHeroHeight = 136.0;
  static const double publicProfileAvatarSize = p80;
  static const double publicProfileAvatarTop = p80;
  static const double publicProfileAvatarLeft = p20;
  static const double publicProfileAvatarBorder = p4;
  static const double publicProfileOnlineBadgeSize = p16;
  static const double publicProfileOnlineBadgeTop = p80 + p60;
  static const double publicProfileOnlineBadgeLeft = p80;

  /// Minimum height for public-profile proof metric cells from Open Design.
  static const double publicProfileMetricMinHeight = 78.0;

  /// Bottom padding that keeps public profile tabs clear of the sticky action bar.
  static const double publicProfileStickyBarClearance = p100;

  /// Hairline divider used between public profile sticky actions.
  static const double publicProfileActionDividerWidth = 1.0;

  /// Height for the public profile sticky action divider.
  static const double publicProfileActionDividerHeight = p24;

  /// Button height used inside the public profile sticky action bar.
  static const double publicProfileActionButtonHeight = 46.0;

  /// Compact icon well for Amber Dusk settings rows.
  static const double settingsRowIconWell = 34.0;

  /// Image preview height for manage-portfolio edit rows.
  static const double managePortfolioImagePreviewHeight = 150.0;

  /// Maximum readable width for modal dialogs on tablet and landscape layouts.
  static const double dialogMaxWidth = 640.0;
}
