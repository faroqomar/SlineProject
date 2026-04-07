// Re-export from canonical location in core.
//
// WorkItem was moved to `lib/core/models/work_item.dart` in Phase 1
// (Core Widget Redesign) to resolve architecture violation where
// `lib/core/widgets/status_badge.dart` imported from features/dashboard.
//
// This re-export ensures all existing feature imports continue to work
// without modification. New code should import from core directly:
// `import 'package:sline_app/core/models/work_item.dart';`
export 'package:sline_app/core/models/work_item.dart';
