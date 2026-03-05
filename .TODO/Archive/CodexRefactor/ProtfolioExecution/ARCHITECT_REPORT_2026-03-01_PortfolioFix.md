# Architecture Review: Portfolio Feature Recovery

**Date:** 2026-03-01  
**Scope:** Portfolio image display fixes  
**Contract:** `.TODO/portfolio_contract_2026-03-01.md`  
**Status:** ✅ Approved with Minor Issues

---

## 1. Executive Summary

The Portfolio Feature Recovery changes successfully fix image display issues by:
1. Properly passing `imagePath` through the entire data flow
2. Using `SignedImage` widget for consistent storage path handling
3. Fixing the tab ScrollController attachment error

**Overall Assessment:** Architecture is sound with minor technical debt items identified.

---

## 2. MVVM Boundary Analysis

### ✅ Layer Separation (PASSED)

| Layer | Responsibilities | Assessment |
|-------|------------------|------------|
| **View** (`manage_portfolio_screen.dart`, `public_profile_screen.dart`, `public_profile_portfolio.dart`) | UI only, uses Consumer/Provider pattern | ✅ Clean - no direct Supabase calls |
| **ViewModel** (`profile_view_model.dart`) | State management, business logic, calls Repository | ✅ Clean - never calls Supabase directly |
| **Repository** (`profile_repository.dart`) | Supabase API calls, data orchestration | ⚠️ Minor bypass pattern (see Issues) |
| **Service** (`portfolio_repository.dart`, `portfolio_service.dart`) | Low-level Supabase operations | ✅ Clean - properly delegated |

### Key Finding: Proper MVVM Chain

```
User Action → View → ViewModel → ProfileRepository → PortfolioRepository → Service → Supabase
```

The chain is properly maintained. The ViewModel never talks directly to Supabase, and Views never bypass the ViewModel.

---

## 3. Data Flow Analysis

### Image Path Flow (CORRECT)

```
1. User picks image
   ↓
2. VM.pickAndUploadPortfolioImage() → Returns storage path
   ↓
3. User fills form, clicks Add
   ↓
4. VM.addPortfolioItem(imagePath: path) → Passes path to repository
   ↓
5. Repository inserts to DB with image_path column
```

This flow correctly implements the contract: **write only to `image_path`**.

### Image Resolution Flow (CORRECT with Optimization Opportunity)

```
Manage Portfolio Screen:
  VM.fetchPortfolio() → resolves URLs → stores in _portfolioItems['image_url']
  → View renders with resolved URL → SignedImage displays

Public Profile Screen:
  VM.getPublicProfile() → PortfolioItem with effectiveImageRef
  → PublicProfilePortfolio → SignedImage resolves again
```

**Note:** Double resolution occurs - VM resolves once, then SignedImage may resolve again. SignedImage has caching to mitigate this.

---

## 4. API Consistency

### ✅ Consistent Patterns

| Aspect | Status | Notes |
|--------|--------|-------|
| Method signatures | ✅ | `addPortfolioItem` accepts optional `imagePath` parameter |
| Model usage | ✅ | Uses `PortfolioItem` model throughout |
| Error handling | ✅ | Uses `AppLogger` consistently, throws to caller |
| Naming conventions | ✅ | Follows SLine patterns |

### Method Signatures Review

```dart
// ViewModel - clean signature
Future<void> addPortfolioItem({
  required String title,
  String? description,
  String? imagePath,
})

// Repository - accepts both old and new patterns
Future<PortfolioItem> addPortfolioItem({
  required String userId,
  required String title,
  String? description,
  Uint8List? imageBytes,       // Legacy: upload new image
  String? imageFilename,
  String? imagePath,          // New: use existing path
})
```

---

## 5. Issues Identified

### Issue #1: Repository Bypass Pattern (MINOR)

**Location:** `lib/features/profile/data/profile_repository.dart:187-200`

```dart
// PROBLEM: Direct DB insert bypasses PortfolioRepository
if (imagePath != null) {
  final row = await _client
      .from('portfolio_items')
      .insert({...})  // ← Direct insert, bypasses PortfolioRepository
      .select()
      .single();
  return PortfolioItem.fromJson(row as Map<String, dynamic>);
}
```

**Impact:** Low - logic is correct, but breaks single source of truth for portfolio CRUD.

**Recommendation:** Add a method `addItemWithPath()` to `PortfolioRepository` that accepts a pre-existing path instead of bytes. This keeps all portfolio insert logic in one place.

---

### Issue #2: Inefficient Upload Workaround (MINOR)

**Location:** `lib/features/profile/data/profile_repository.dart:246-260`

```dart
// PROBLEM: Creates temp item just to upload image
final result = await _portfolioRepository.addItem(
  title: '_temp_upload_$filename',  // ← Temp item created
  ...
);
await _portfolioRepository.deleteItem(
  id: result.id,
  alsoDeleteImage: false  // ← Then deleted, keeping image
);
```

**Impact:** Low - creates unnecessary DB rows that are immediately deleted.

**Recommendation:** Extract image upload logic to a dedicated method in `PortfolioService` that can be called independently. Add `uploadImageOnly()` method to `PortfolioRepository`.

---

### Issue #3: Double URL Resolution (OPTIMIZATION)

**Location:** 
- `profile_view_model.dart:205-214` (eager resolution)
- `public_profile_portfolio.dart:129` (widget resolution)

**Current Flow:**
```dart
// VM resolves eagerly
final resolvedUrl = await _repo.resolvePortfolioImageUrl(item.effectiveImageRef);

// SignedImage may resolve again if URL not cached
SignedImage(storagePathOrUrl: imageRef)  // internally calls createSignedUrl
```

**Impact:** Very Low - `SignedUrlCache` prevents redundant API calls.

**Recommendation:** For the manage portfolio screen, since URLs are already resolved, pass them directly to avoid `SignedImage` resolution logic. However, the current implementation is acceptable due to caching.

---

## 6. Positive Patterns

### ✅ SignedImage Widget Usage

```dart
// CORRECT: Handles both URLs and storage paths
SignedImage(
  storagePathOrUrl: item['image_url'],  // Can be path OR URL
  fit: BoxFit.cover,
  bucket: 'portfolio',
)
```

The `SignedImage` widget is an excellent abstraction that:
- Detects URL vs path automatically
- Uses shared caching (`SignedUrlCache`)
- Handles loading/error states
- Optimizes memory usage with `CachedNetworkImage`

### ✅ Separate ScrollControllers Fix

```dart
// CORRECT: Separate controllers for each tab
final ScrollController _aboutScrollController = ScrollController();
final ScrollController _portfolioScrollController = ScrollController();
// ... etc
```

This properly fixes the "attached to multiple ScrollPosition" error by ensuring each tab has its own controller.

### ✅ Contract Compliance

The implementation correctly follows the contract:
- Writes only to `image_path` (canonical)
- Reads `image_path` with fallback to `image_url` (legacy)
- Uses `effectiveImageRef` getter for unified access

---

## 7. Technical Debt Register

| Item | Severity | Location | Recommendation |
|------|----------|----------|----------------|
| Repository bypass | Low | `profile_repository.dart:187-200` | Add `addItemWithPath()` to PortfolioRepository |
| Inefficient upload | Low | `profile_repository.dart:246-260` | Extract `uploadImageOnly()` to PortfolioRepository |
| Double URL resolution | Very Low | `profile_view_model.dart:205-214` | Acceptable with caching |

---

## 8. Security & Performance Review

### Security (PASSED)
- ✅ RLS policies enforced (all DB calls go through authenticated client)
- ✅ No hardcoded credentials or secrets
- ✅ Path validation: storage paths follow `{ownerId}/{filename}` pattern

### Performance (PASSED)
- ✅ Uses `Future.wait()` for parallel URL resolution (line 205 VM)
- ✅ Image compression before upload (minWidth: 1920, quality: 80)
- ✅ Signed URL caching via `SignedUrlCache`
- ✅ Memory optimization with `memCacheWidth/Height` in SignedImage

### N+1 Check (PASSED)
- ✅ `fetchPortfolio()` resolves URLs in parallel with `Future.wait()`
- No async calls inside loops

---

## 9. Verification Checklist

| Contract Requirement | Status | Evidence |
|---------------------|--------|----------|
| Model reads `image_path` first | ✅ | `portfolio_item.dart:34-44` |
| Model writes only to `image_path` | ✅ | `portfolio_item.dart:51-63` |
| Storage path format correct | ✅ | `portfolio_contract_2026-03-01.md` |
| Delete cleans up storage | ⚠️ | Partial - `alsoDeleteImage` param exists |
| AppLogger used (no print) | ✅ | All files use `AppLogger` |
| RLS policies respected | ✅ | All queries use authenticated client |

---

## 10. Conclusion

### Overall Rating: ✅ APPROVED

The Portfolio Feature Recovery changes are architecturally sound and follow SLine patterns. The code is production-ready with minor technical debt items that can be addressed in future refactors.

### Action Items

1. **Optional:** Add `addItemWithPath()` to `PortfolioRepository` to eliminate bypass pattern
2. **Optional:** Extract `uploadImageOnly()` to `PortfolioRepository` to clean up upload workaround
3. **No action required:** Double URL resolution is mitigated by caching

### Files Approved for Merge

- ✅ `lib/features/profile/view/manage_portfolio_screen.dart`
- ✅ `lib/features/profile/viewmodels/profile_view_model.dart`
- ✅ `lib/features/profile/data/profile_repository.dart`
- ✅ `lib/features/profile/view/widgets/public_profile/public_profile_portfolio.dart`
- ✅ `lib/features/profile/view/public_profile_screen.dart`

---

*Report generated by @Architect (SLineArchitect)*  
*Contract reference: `.TODO/portfolio_contract_2026-03-01.md`*
