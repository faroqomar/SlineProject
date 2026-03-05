# CodeGuard Review Report: Portfolio Feature Recovery

**Date**: 2026-03-01
**Scope**: Portfolio Feature Recovery - Image Display Fixes
**Review Type**: HARD-GATE (Image handling, storage, RLS)
**Files Reviewed**: 5 core files + 2 dependencies

---

## Scope

- **Change Type**: MEDIUM (Business logic changes, storage operations, image handling)
- **Areas**: MVVM / Storage / RLS / Image Optimization / Backwards Compatibility
- **Files Reviewed**:
  1. `lib/features/profile/view/manage_portfolio_screen.dart`
  2. `lib/features/profile/viewmodels/profile_view_model.dart`
  3. `lib/features/profile/data/profile_repository.dart`
  4. `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart`
  5. `lib/core/widgets/signed_image.dart`
  6. `lib/features/portfolio/data/portfolio_repository.dart`
  7. `lib/features/portfolio/models/portfolio_item.dart`

---

## Evidence Collected

### Commands Run
```bash
$ flutter analyze
✅ No issues found! (ran in 3.6s)

$ flutter pub outdated
⚠️ 19 dependencies are constrained to versions older than resolvable
⚠️ js package has been discontinued
```

### Docs Scanned
- `Sline_everything/SUPABASE_SETUP.md` - RLS policies, storage buckets, portfolio_items table
- `Sline_everything/DEVELOPER_GUIDE.md` - MVVM conventions
- `Sline_everything/CODE_REVIEW.md` - Code quality patterns

---

## Critical Issues (BLOCKERS)

**NONE IDENTIFIED** ✅

---

## Warnings (Should Fix)

### 1. Dependency Freshness (MEDIUM)
- **Issue**: Multiple outdated dependencies including critical ones:
  - `supabase_flutter` 1.10.25 → 2.12.0 (major version behind)
  - `file_picker` 8.3.7 → 10.3.10 (used for image picking)
  - `js` package discontinued
- **Risk**: Security patches, bug fixes, and performance improvements not available
- **Suggestion**: Schedule migration to supabase_flutter v2.x (breaking changes expected)
- **Owner**: @SlinePlanner for migration plan

### 2. Resource Leak (LOW)
- **Location**: `manage_portfolio_screen.dart:33-34`
- **Issue**: TextEditingControllers created in `_showAddEditDialog` are not disposed
- **Code**:
  ```dart
  final titleController = TextEditingController(text: item?['title']);
  final descController = TextEditingController(text: item?['description']);
  ```
- **Risk**: Minor memory leak on dialog open/close cycles
- **Fix**: Wrap dialog in StatefulBuilder with proper dispose or use TextFormField with onSaved
- **Owner**: @Architect

### 3. Error Handling Gap (LOW)
- **Location**: `public_profile_portfolio.dart:127-135`
- **Issue**: No error handling when SignedImage fails to load
- **Suggestion**: Add errorWidget or onError callback for better UX
- **Owner**: @Pixel

---

## Security Review

### ✅ RLS Policies (PASSED)
- `portfolio_items` table has RLS enabled (confirmed in SUPABASE_SETUP.md line 33)
- All queries use authenticated client with session-based access
- No service_role key usage detected in client code

### ✅ Storage Security (PASSED)
- Portfolio bucket is **public** (correct for image sharing)
- Signed URLs generated with 2-hour TTL (7200s) - appropriate
- Signed URL cache expires at 90 minutes (early refresh) - good practice
- Storage paths validated before URL generation

### ✅ Input Validation (PASSED)
- Image compression applied before upload (flutter_image_compress)
- File type allowlist via FilePicker (type: FileType.image)
- No raw SQL - all queries use Supabase client with parameterization

### ✅ Secrets Handling (PASSED)
- No hardcoded API keys, tokens, or credentials found
- Anon key in `supabase_config.dart` correctly documented as safe to expose
- Token masking in AppLogger for access_token/refresh_token

---

## Performance Review

### ✅ Image Optimization (PASSED)
- **Compression**: Images compressed to 1920x1920 max, quality 80 before upload
- **Memory**: CachedNetworkImage uses memCacheWidth/Height based on devicePixelRatio
- **Caching**: SignedUrlCache prevents redundant API calls (90-min cache, 2-hr signed URL)
- **iOS Stability**: FilePicker with `withData: true` prevents iOS image picker crashes

### ✅ Query Efficiency (PASSED)
- No N+1 queries detected - portfolio items fetched in batch
- Pagination supported via cursor-based approach (created_at ISO strings)
- Parallel URL resolution in `fetchPortfolio()` using `Future.wait`

### ✅ Widget Performance (PASSED)
- `Consumer<ProfileViewModel>` properly scoped
- No heavy work in build() methods
- SliverList for efficient list rendering
- Image placeholders prevent layout shift

---

## Compatibility Review

### ✅ Backwards Compatibility (PASSED)
- **Legacy Support**: `imageUrl` field maintained for existing data
- **Migration Path**: `imagePath` (canonical) preferred, `imageUrl` fallback
- **Model Handling**: `PortfolioItem.effectiveImageRef` abstracts the choice
- **Data Integrity**: `fromJson` reads both fields, `toJson` writes only canonical

### ✅ API Compatibility (PASSED)
- Supabase client v1.x calls are correct for current version
- Storage API usage matches Supabase Flutter SDK patterns

---

## Architecture Review

### ✅ MVVM Compliance (PASSED)
- View (`manage_portfolio_screen.dart`): No direct Supabase calls
- ViewModel (`profile_view_model.dart`): All business logic, proper ChangeNotifier usage
- Repository (`profile_repository.dart`): Clean abstraction, delegates to PortfolioRepository
- Service Layer: PortfolioService handles Supabase operations

### ✅ Error Handling (PASSED)
- Consistent use of `AppLogger` throughout
- Try-catch blocks with stack traces in critical paths
- User feedback via SnackBar for upload failures
- State management for loading/error states

---

## Passed Checks

- ✅ `flutter analyze` - No lint issues
- ✅ RLS enabled on portfolio_items table
- ✅ No hardcoded secrets/credentials
- ✅ Image compression before upload
- ✅ Signed URL caching implemented
- ✅ Memory-efficient image loading
- ✅ Proper error handling with AppLogger
- ✅ MVVM architecture maintained
- ✅ Backwards compatibility for legacy URLs
- ✅ iOS stability fixes (FilePicker, delay after picker)

---

## Risk Notes

### Threat Model (Portfolio Feature)
1. **Image Upload Abuse**: Mitigated by compression (size limits) and file type restriction
2. **Storage Enumeration**: Mitigated by RLS (users can only access their own items)
3. **Signed URL Replay**: Mitigated by 2-hour TTL and cache expiry at 90 minutes
4. **iOS Picker Crash**: Mitigated by FilePicker + 300ms delay workaround

### Regression Risks
- Portfolio images may not display for users with legacy `image_url` data
- **Mitigation**: `effectiveImageRef` getter handles fallback correctly

---

## Dependency Status

| Package | Current | Latest | Risk |
|---------|---------|--------|------|
| supabase_flutter | 1.10.25 | 2.12.0 | **HIGH** - Major version behind |
| file_picker | 8.3.7 | 10.3.10 | MEDIUM |
| flutter_image_compress | *locked* | latest | LOW |
| cached_network_image | *locked* | latest | LOW |

**Note**: `js` package is discontinued but appears to be transitive dependency.

---

## Final Decision

### ✅ APPROVED

**Rationale**:
1. No critical security blockers identified
2. No severe performance issues detected
3. RLS properly configured and enforced
4. Error handling consistent with project standards
5. Backwards compatibility maintained
6. iOS stability issues addressed

**Conditions**:
- Address the TextEditingController disposal warning (LOW priority)
- Schedule supabase_flutter v2.x migration (MEDIUM priority)

**Next Actions**:
1. Merge this PR - code is production-ready
2. Create tech debt ticket for dependency updates
3. Monitor image loading performance in production

---

## Sign-off

**Reviewer**: CodeGuard Agent
**Date**: 2026-03-01
**Decision**: APPROVED ✅
