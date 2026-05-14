import 'package:flutter/foundation.dart';

/// Value object that scopes a work-log query to a single related entity.
@immutable
class WorkLogScope {
  final String entityId;
  final String entityType;

  const WorkLogScope({required this.entityId, required this.entityType});

  Map<String, String> toFilters() {
    return {'related_entity_id': entityId, 'related_entity_type': entityType};
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkLogScope &&
            runtimeType == other.runtimeType &&
            entityId == other.entityId &&
            entityType == other.entityType;
  }

  @override
  int get hashCode => Object.hash(entityId, entityType);
}
