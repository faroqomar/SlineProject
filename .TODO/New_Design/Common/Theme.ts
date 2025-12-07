export const getTheme = (isDarkMode: boolean) => ({
  // Main backgrounds
  phoneBg: isDarkMode ? "#0c0c0c" : "#f4f3f1",
  dynamicIsland: isDarkMode ? "#0c0c0c" : "#f4f3f1",

  // Status bar
  statusBarText: isDarkMode ? "#f4f3f1" : "#0c0c0c",

  // Auth screens
  authGradient: isDarkMode
    ? "from-[#146068]/5 to-[#0c0c0c]"
    : "from-[#93ccce]/15 to-[#f4f3f1]",
  authText: isDarkMode ? "#f4f3f1" : "#0c0c0c",
  authTextSecondary: isDarkMode ? "#9dbabb" : "#a9a8a7",
  authInputBg: isDarkMode ? "bg-[#f4f3f1]/10" : "bg-[#ffffff]",
  authInputBorder: isDarkMode ? "border-[#93ccce]/20" : "border-[#146068]/20",
  authInputText: isDarkMode ? "#f4f3f1" : "#0c0c0c",

  // Header
  headerBg: isDarkMode ? "bg-[#146068]/20" : "bg-[#93ccce]/15",
  headerBorder: isDarkMode ? "border-[#93ccce]/20" : "border-[#146068]/20",

  // Text
  text: isDarkMode ? "#f4f3f1" : "#0c0c0c",
  textSecondary: isDarkMode ? "#9dbabb" : "#a9a8a7",
  textTertiary: isDarkMode ? "#a9a8a7" : "#6b6b6b",

  // Cards
  cardBg: isDarkMode ? "bg-[#f4f3f1]/8" : "bg-[#ffffff]",
  cardBorder: isDarkMode ? "border-[#93ccce]/10" : "border-[#146068]/15",
  cardBorderHover: isDarkMode ? "border-[#146068]/40" : "border-[#146068]/50",

  // Input
  inputBg: isDarkMode ? "bg-[#f4f3f1]/10" : "bg-[#ffffff]",
  inputBorder: isDarkMode ? "border-[#93ccce]/20" : "border-[#146068]/20",
  inputFocusBg: isDarkMode ? "focus:bg-[#f4f3f1]/15" : "focus:bg-[#ffffff]",

  tagBg: isDarkMode ? "bg-[#f4f3f1]/10" : "bg-[#ffffff]",
  tagBorder: isDarkMode ? "border-[#93ccce]/10" : "border-[#146068]/15",

  // Content area
  contentGradient: isDarkMode
    ? "from-transparent to-[#0c0c0c]/70"
    : "from-transparent to-[#f4f3f1]",
  scrollbarColor: isDarkMode ? "#146068 transparent" : "#93ccce transparent",

  // Bottom navigation
  bottomNavInactive: isDarkMode ? "#9dbabb" : "#a9a8a7",
  bottomNavBg: isDarkMode ? "bg-[#146068]/20" : "bg-[#93ccce]/15",
  bottomNavBorder: isDarkMode ? "border-[#93ccce]/20" : "border-[#146068]/20",

  // Special elements
  dividerBg: isDarkMode ? "bg-[#93ccce]/20" : "bg-[#146068]/15",
  hotBadgeBg: "bg-[#f3bb19]/20",
  hotBadgeBorder: "border-[#f3bb19]/30",

  // Task gradient overlay
  taskGradient: isDarkMode ? "from-[#0c0c0c]/60" : "from-[#0c0c0c]/40",
});