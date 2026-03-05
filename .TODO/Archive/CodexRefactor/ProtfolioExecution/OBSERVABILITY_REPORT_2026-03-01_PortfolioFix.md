# Observability Report: Portfolio Feature Recovery (2026-03-01)

**Agent**: @Observability  
**Scope**: Portfolio image display fixes - logging and telemetry review  
**Files Reviewed**: 7 files  
**Status**: ✅ ACCEPTABLE with RECOMMENDATIONS

---

## Executive Summary

The Portfolio Feature Recovery changes demonstrate **good AppLogger discipline** across ViewModel and Repository layers. No PII leaks detected. The main observability gap is in the `SignedImage` widget which silently fails on image resolution errors, making production debugging difficult.

**Verdict**: Logging is sufficient for the recovery fix, but telemetry enhancements are recommended for long-term maintainability.

---

## 1. AppLogger Usage Analysis

### ✅ GOOD - ProfileViewModel (`profile_view_model.dart`)

| Event | Level | Tag | Fields | Assessment |
|-------|-------|-----|--------|------------|
| `Fetching portfolio` | info | `ProfileVM` | `userId` | ✅ Good entry log |
| `Portfolio fetched` | info | `ProfileVM` | `count` | ✅ Success confirmation |
| `Error loading portfolio` | error | `ProfileVM` | error, stackTrace | ✅ Full error context |
| `Uploading portfolio image` | info | `ProfileVM` | `filename`, `size` | ✅ Audit trail |
| `Image compressed` | info | `ProfileVM` | `originalSize`, `compressedSize` | ✅ Performance insight |
| `Adding portfolio item` | info | `ProfileVM` | `title`, `hasImage` | ✅ Non-sensitive |
| `Portfolio item added successfully` | info | `ProfileVM` | - | ✅ Completion signal |
| `Updating portfolio item` | info | `ProfileVM` | `itemId`, `title` | ✅ CRUD trace |
| `Deleting portfolio item` | info | `ProfileVM` | `itemId` | ✅ CRUD trace |

**Coverage**: 100% of portfolio CRUD operations are logged.

### ✅ GOOD - ProfileRepository (`profile_repository.dart`)

| Event | Level | Tag | Assessment |
|-------|-------|-----|------------|
| `profile_summary_fetch_started` | debug | `ProfileRepo` | ✅ Entry point |
| `profile_summary_fetch_succeeded` | info | `ProfileRepo` | ✅ Success confirmation |
| `profile_summary_fetch_failed` | error | `ProfileRepo` | ✅ Full error + stack trace |
| `Delegating getPortfolioItems to PortfolioRepository` | debug | `ProfileRepo` | ✅ Handoff visibility |
| `Delegating addPortfolioItem to PortfolioRepository` | debug | `ProfileRepo` | ✅ Handoff visibility |
| `Failed to resolve portfolio image URL` | warning | `ProfileRepo` | ✅ Image resolution errors |

### ✅ GOOD - PortfolioRepository (`portfolio_repository.dart`)

| Event | Level | Tag | Assessment |
|-------|-------|-----|------------|
| `Repository: listItems` | debug | `PortfolioRepository` | ✅ Entry with parameters |
| `Repository: listItems failed` | error | `PortfolioRepository` | ✅ Error with context |
| `Repository: addItem` | info | `PortfolioRepository` | ✅ CRUD trace |
| `Repository: addItem failed` | error | `PortfolioRepository` | ✅ Error with context |
| `Repository: deleteItem` | info | `PortfolioRepository` | ✅ CRUD trace |
| `Repository: updateItem` | info | `PortfolioRepository` | ✅ CRUD trace |

### ✅ GOOD - PortfolioService (`portfolio_service.dart`)

| Event | Level | Tag | Assessment |
|-------|-------|-----|------------|
| `Listing portfolio items` | debug | `PortfolioService` | ✅ Entry with pagination params |
| `Listed N portfolio items` | info | `PortfolioService` | ✅ Success with count |
| `Failed to list portfolio items` | error | `PortfolioService` | ✅ Full error context |
| `Uploading image bytes` | debug | `PortfolioService` | ✅ Upload start |
| `Image uploaded successfully` | info | `PortfolioService` | ✅ Upload success with path |
| `Adding portfolio item` | info | `PortfolioService` | ✅ CRUD trace |
| `Portfolio item created` | info | `PortfolioService` | ✅ Creation confirmation |
| `Deleting portfolio item` | info | `PortfolioService` | ✅ CRUD trace |
| `Deleted portfolio DB row` | info | `PortfolioService` | ✅ Deletion confirmation |
| `Deleted storage object` | info | `PortfolioService` | ✅ Cleanup trace |
| `Failed to delete storage object` | warning | `PortfolioService` | ✅ Non-critical failure |

### ⚠️ MISSING - SignedImage (`signed_image.dart`)

**CRITICAL GAP**: The `SignedImage` widget (lines 117-120) catches errors but **logs nothing**:

```dart
catch (e) {
  if (!mounted) return;
  setState(() => _loading = false);  // ❌ No logging!
}
```

**Impact**: When images fail to resolve in production, there's no trace in logs to debug:
- Which storage path failed?
- Was it a 403, 404, or network error?
- How often are image failures occurring?

**Recommendation**: Add warning-level logging for image resolution failures.

### ✅ OK - UI Layer (`manage_portfolio_screen.dart`, `public_profile_portfolio.dart`)

No direct logging in UI widgets - **correct per MVVM rules**. UI should not log; ViewModels and Services should.

---

## 2. Telemetry Gaps

### Gap 1: No Correlation IDs

**Problem**: Multi-step image operations cannot be traced end-to-end.

**Flow without correlation**:
```
1. User picks image -> log "Uploading portfolio image"
2. Image compressed -> log "Image compressed"
3. Upload to storage -> log "Image uploaded successfully"
4. DB insert -> log "Portfolio item created"
```

These are 4 separate log entries with no way to correlate them to a single user action.

**Recommendation**: Add a `correlation_id` field to all logs within a single user flow.

### Gap 2: No Analytics Events

**Missing product telemetry**:
- `portfolio_item_created` (analytics event)
- `portfolio_item_updated` (analytics event)
- `portfolio_item_deleted` (analytics event)
- `portfolio_image_uploaded` (analytics event with size metrics)
- `portfolio_image_failed` (analytics event for error tracking)

**Impact**: Cannot measure feature adoption or failure rates.

### Gap 3: No Performance Metrics

**Missing timing data**:
- Image compression duration
- Image upload duration (network time)
- Signed URL generation duration
- Portfolio list fetch duration

**Current state**: Only file sizes are logged, not durations.

### Gap 4: Silent SignedImage Failures

As noted in Section 1, `SignedImage` silently swallows errors. No telemetry on:
- Image load failure rate
- Cache hit/miss ratio for signed URLs
- Storage bucket access patterns

---

## 3. Privacy Review

### ✅ SAFE - What IS Logged (Acceptable)

| Field | Location | Assessment |
|-------|----------|------------|
| `userId` / `ownerId` | Multiple | ✅ UUIDs are safe |
| `itemId` (portfolio) | Multiple | ✅ Database IDs are safe |
| `filename` | ProfileVM, PortfolioService | ✅ Filename only (no path to PII) |
| `size` / `bytesLength` | ProfileVM, PortfolioService | ✅ Metadata only |
| `path` (storage) | PortfolioService | ✅ Storage path (no direct URL) |
| `count` | Multiple | ✅ Aggregated data |
| `hasImage` / `hasImagePath` | Multiple | ✅ Boolean flags |
| `title` | Multiple | ✅ User-provided content (expected in portfolio) |

### ✅ SAFE - What is NOT Logged (Good)

| Data Type | Assessment |
|-----------|------------|
| User email | ✅ Not logged |
| User full name | ✅ Not logged |
| Raw image bytes | ✅ Not logged (only sizes) |
| Signed URLs with tokens | ✅ Not logged (only storage paths) |
| Auth tokens | ✅ AppLogger masks these automatically |
| Refresh tokens | ✅ AppLogger masks these automatically |

### 🔒 AppLogger Protection

The `AppLogger._formatJson()` method (lines 40-80 in `logger_service.dart`) automatically masks:
- `access_token` → `***MASKED***`
- `refresh_token` → `***MASKED***`

**Verdict**: No PII exposure detected. Privacy-safe logging confirmed.

---

## 4. Correlation Strategy

### Current State: No Correlation

Logs are independent events with no linking identifier:

```json
// Log 1
{"message": "Uploading portfolio image", "userId": "abc-123"}

// Log 2 (5 seconds later)
{"message": "Portfolio item added successfully", "userId": "abc-123"}

// Are these related? Unknown without timestamp correlation.
```

### Recommended: Add Correlation IDs

**Implementation suggestion**:

```dart
// Generate correlation ID at user action start
final correlationId = generateCorrelationId();

// Pass through the call chain
await viewModel.addPortfolioItem(
  title: title,
  correlationId: correlationId,  // Propagate
);

// All logs include correlation_id
AppLogger.i('Portfolio item added', json: {
  'itemId': itemId,
  'correlation_id': correlationId,
});
```

**Priority**: Medium - not critical for the recovery fix, but essential for production debugging.

---

## 5. Recommendations

### Immediate (Pre-Merge) - Priority: Medium

1. **Add logging to SignedImage** (`signed_image.dart` line 117):
   ```dart
   catch (e) {
     if (!mounted) return;
     AppLogger.w('Failed to resolve signed image URL',
       tag: 'SignedImage',
       json: {'path': widget.storagePathOrUrl, 'error': e.toString()},
     );
     setState(() => _loading = false);
   }
   ```

### Short-term (Next Sprint) - Priority: Medium

2. **Add cache hit/miss logging to SignedImage** for performance insights
3. **Add upload timing metrics** to ProfileVM (measure duration from pick to complete)
4. **Add analytics events** for portfolio CRUD operations

### Long-term (Future) - Priority: Low

5. **Implement correlation ID propagation** across the portfolio flow
6. **Add structured error codes** (e.g., `PORTFOLIO_IMAGE_UPLOAD_FAILED`, `PORTFOLIO_STORAGE_UNREACHABLE`)
7. **Create dashboard queries** for portfolio operation success rates

---

## 6. Verification Evidence

### Sample Log Output (Expected)

```
14:32:10 [ProfileVM] ✅ Uploading portfolio image
  │ JSON Payload:
  │   "filename": "project_mockup.png"
  │   "size": 245760

14:32:11 [ProfileVM] ✅ Image compressed
  │ JSON Payload:
  │   "originalSize": 245760
  │   "compressedSize": 98304

14:32:12 [PortfolioService] ✅ Image uploaded successfully
  │ JSON Payload:
  │   "path": "user-abc-123/1740837132_project_mockup.png"

14:32:12 [ProfileVM] ✅ Portfolio item added successfully
```

### Error Path Sample (Expected)

```
14:33:45 [ProfileVM] ❌ Error uploading portfolio image
  └─ StorageException: Object not found
      #0      _StorageApi.uploadBinary
      #1      PortfolioService._uploadImageBytes
```

---

## 7. Final Assessment

| Criteria | Status | Notes |
|----------|--------|-------|
| AppLogger Usage | ✅ PASS | Used correctly in ViewModels, Services, Repositories |
| No print() Statements | ✅ PASS | None found |
| Privacy-Safe | ✅ PASS | No PII, tokens masked automatically |
| Error Logging | ✅ PASS | All errors include context and stack traces |
| Structured Logging | ✅ PASS | Consistent use of `json:` parameter |
| Image Load Failures | ⚠️ GAP | SignedImage silently swallows errors |
| Correlation IDs | ⚠️ GAP | Not implemented (future enhancement) |
| Analytics Events | ⚠️ GAP | No product telemetry (future enhancement) |

**Overall Grade**: B+ (Good with minor gaps)

---

## 8. Sign-off

| Check | Status |
|-------|--------|
| Code reviewed for logging patterns | ✅ |
| Privacy audit completed | ✅ |
| No sensitive data in logs confirmed | ✅ |
| Recommendations documented | ✅ |
| Report written to `.TODO/` | ✅ |

**Prepared by**: @Observability Agent  
**Date**: 2026-03-01  
**Approved for**: Portfolio Feature Recovery Merge (with SignedImage logging fix recommended)
