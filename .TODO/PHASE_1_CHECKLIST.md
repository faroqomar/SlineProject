# ✅ Phase 1: Design System Architecture Checklist

**Objective:** Implement the "Control Center" for the new Glassmorphism design.
**Source of Truth:** `.TODO/Future_Plans/DESIGN_IMPLEMENTATION_PLAN.md`
**Design Reference:** `.TODO/New_Design_Code/Organized/Common/Theme.ts`

---

## 🎨 Step 1: Theme Foundation (`lib/core/theme/`)

- [x] **Map Colors (`app_colors.dart`)**
    - **Agent:** `@Pixel`
    - **Prompt:** "Create `lib/core/theme/app_colors.dart`. Analyze `.TODO/New_Design_Code/Organized/Common/Theme.ts` and map all colors (Teal `#146068`, Gold `#f3bb19`, etc.) to a static `AppColors` class. Include separate palettes for Light/Dark modes."

- [x] **Define Typography (`app_typography.dart`)**
    - **Agent:** `@Pixel`
    - **Prompt:** "Create `lib/core/theme/app_typography.dart`. Define an `AppTypography` class with static `TextStyle` getters (h1, h2, body, caption) using `GoogleFonts.plusJakartaSans`. Match the font sizes from `Theme.ts`."

- [x] **Define Dimensions (`app_dimens.dart`)**
    - **Agent:** `@Pixel`
    - **Prompt:** "Create `lib/core/theme/app_dimens.dart`. Define constant values for Spacing (`p4`, `p8`, `p16`, `p24`) and Radii (`r12`, `r20`, `r30`)."

- [x] **Define Decorations (`app_decorations.dart`)**
    - **Agent:** `@Pixel`
    - **Prompt:** "Create `lib/core/theme/app_decorations.dart`. Implement an `AppDecorations` class. Add static methods returning `BoxDecoration` for the specific 'Glass' effect (blur, gradient background, border) seen in the design."

- [x] **Assemble Theme (`app_theme.dart`)**
    - **Agent:** `@Pixel`
    - **Prompt:** "Create `lib/core/theme/app_theme.dart`. Define `AppTheme` factory with `static ThemeData light` and `static ThemeData dark`. Combine `AppColors` and `AppTypography` into the Flutter `ThemeData` object."

---

## 🧩 Step 2: Shared Widgets (`lib/core/widgets/`)

- [x] **Glass Container (`glass_container.dart`)**
    - **Agent:** `@Pixel`
    - **Prompt:** "Create `lib/core/widgets/glass_container.dart`. Build a reusable widget that accepts `child`, `padding`, `margin`, and `radius`. Use `AppDecorations` to apply the glass style (backdrop filter + gradient)."

- [x] **App Button (`app_button.dart`)**
    - **Agent:** `@Pixel`
    - **Prompt:** "Create `lib/core/widgets/app_button.dart`. Implement the primary button style from the Auth screens (Height 54px, rounded corners, shadow, `AppColors.primary`). Support a `isLoading` state."

- [x] **App Text Field (`app_text_field.dart`)**
    - **Agent:** `@Pixel`
    - **Prompt:** "Create `lib/core/widgets/app_text_field.dart`. Implement the input field style from `AuthScreens.tsx` (Border behavior, focus state, glass background)."

- [x] **Bottom Navigation (`custom_bottom_nav_bar.dart`)**
    - **Agent:** `@Pixel`
    - **Prompt:** "Refactor `lib/core/widgets/custom_bottom_nav_bar.dart`. Update it to match the new 'Floating Island' design using `GlassContainer`. Refer to the `App.tsx` navigation render logic."

---

## 🔌 Step 3: Integration

- [x] **Wire to Main App**
    - **Agent:** `@Architect`
    - **Prompt:** "Update `lib/main.dart` (or `app.dart`) to apply `AppTheme.light` and `AppTheme.dark` to the `MaterialApp`. Ensure `themeMode` is connected to a Provider/Controller."

---

## 🛡️ Step 4: Verification

- [x] **Audit Code**
    - **Agent:** `@Sentinel`
    - **Prompt:** "Review `lib/core/theme/` and `lib/core/widgets/`. Ensure no hardcoded hex codes exist (everything must reference `AppColors`). Verify `flutter analyze` passes."