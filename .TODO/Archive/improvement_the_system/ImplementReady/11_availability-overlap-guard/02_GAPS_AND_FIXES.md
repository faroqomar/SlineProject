# Gaps & Fixes: 11_availability-overlap-guard

## 1. Missing Entry Point

- **Gap:** Freelancers have no way in the Flutter app to publish availability. The database supports `availability_slots` with robust constraints, but the UI isn't there. `lib/` only possesses model parsing code.
- **Fix:** Architect `AvailabilityService.dart` to POST slots. Implement `AvailabilityViewModel` and UI screens where hours can be selected.

## 2. Diagram is Too Narrow

- **Gap:** Diagram only shows the INSERT failure condition. It doesn't show the successful read path (e.g., Client checking slots) nor the interaction with Bookings.
- **Fix:** A sequence diagram that includes booking confirmation setting `is_blocked = true`.

## 3. Ambiguity in "is_blocked"

- **Gap:** The original diagram mentions `is_blocked=false only` but doesn't explain how `is_blocked` becomes `true`.
- **Fix:** Explicitly state that booking acceptance blocks the slot.
