import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/portfolio_item.dart';
import '../services/portfolio_service.dart';

/// PortfolioController
///
/// Minimal ChangeNotifier that orchestrates PortfolioService and exposes
/// list + pagination + mutations to the UI.
/// All comments MUST be in English only.
class PortfolioController extends ChangeNotifier {
  PortfolioController({SupabaseClient? client, PortfolioService? service})
      : _client = client ?? Supabase.instance.client,
        _service = service ?? PortfolioService(client ?? Supabase.instance.client);

  final SupabaseClient _client;
  final PortfolioService _service;

  /// Current owner whose items are being viewed (usually current user id).
  String? _ownerId;

  /// Portfolio items in descending created_at order.
  final List<PortfolioItem> _items = [];
  List<PortfolioItem> get items => List.unmodifiable(_items);

  /// Loading flags and last error message (if any).
  bool _initialLoading = false;
  bool get initialLoading => _initialLoading;

  bool _loadingMore = false;
  bool get loadingMore => _loadingMore;

  String? _error;
  String? get error => _error;

  /// Pagination state:
  /// - We use a simple "created_at" cursor (ISO string in UTC).
  /// - hasMore: whether we believe there are more items to fetch.
  String? _cursorCreatedAtIso;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  /// Guards to prevent overlapping requests.
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _setError(Object? e) {
    _error = e?.toString();
  }

  void _clearError() {
    _error = null;
  }

  /// Loads the first page for [ownerId]. If [ownerId] is null, defaults to
  /// the current authenticated user's id.
  Future<void> load({String? ownerId, int pageSize = 30}) async {
    final uid = ownerId ?? _client.auth.currentUser?.id;
    if (uid == null) {
      _setError('Not authenticated');
      _notify();
      return;
    }
    _ownerId = uid;

    // Reset pagination
    _initialLoading = true;
    _loadingMore = false;
    _cursorCreatedAtIso = null;
    _hasMore = true;
    _clearError();
    _items.clear();
    _notify();

    try {
      final page = await _service.listItems(
        ownerId: _ownerId!,
        limit: pageSize,
        cursorCreatedAtIso: null,
      );
      _items.addAll(page);

      // Update cursor (created_at of the last item)
      if (_items.isNotEmpty) {
        _cursorCreatedAtIso = _items.last.createdAt.toIso8601String();
      }
      _hasMore = page.length >= pageSize;
    } catch (e) {
      _setError(e);
      _hasMore = false;
    } finally {
      _initialLoading = false;
      _notify();
    }
  }

  /// Loads the next page using the current [_cursorCreatedAtIso].
  Future<void> loadMore({int pageSize = 30}) async {
    if (_ownerId == null) return;
    if (!_hasMore) return;
    if (_loadingMore) return;

    _loadingMore = true;
    _clearError();
    _notify();

    try {
      final page = await _service.listItems(
        ownerId: _ownerId!,
        limit: pageSize,
        cursorCreatedAtIso: _cursorCreatedAtIso,
      );

      _items.addAll(page);

      if (_items.isNotEmpty) {
        _cursorCreatedAtIso = _items.last.createdAt.toIso8601String();
      }
      _hasMore = page.length >= pageSize;
    } catch (e) {
      _setError(e);
      _hasMore = false;
    } finally {
      _loadingMore = false;
      _notify();
    }
  }

  /// Adds a new portfolio item for the current [_ownerId].
  /// Accepts image bytes (nullable) so UI can be web/mobile friendly.
  Future<bool> addItem({
    required String title,
    String? description,
    Uint8List? imageBytes,
    String? imageFilename,
  }) async {
    final uid = _ownerId ?? _client.auth.currentUser?.id;
    if (uid == null) {
      _setError('Not authenticated');
      _notify();
      return false;
    }
    _clearError();
    _notify();

    try {
      final created = await _service.addItem(
        ownerId: uid,
        title: title,
        description: description,
        imageBytes: imageBytes,
        imageFilename: imageFilename,
      );

      // Prepend to the top (newest-first list)
      _items.insert(0, created);

      // Move cursor if this is the first item
      if (_cursorCreatedAtIso == null && _items.isNotEmpty) {
        _cursorCreatedAtIso = _items.last.createdAt.toIso8601String();
      }

      _notify();
      return true;
    } catch (e) {
      _setError(e);
      _notify();
      return false;
    }
  }

  /// Deletes an item by id and updates in-memory list.
  Future<bool> deleteItem(String id) async {
    _clearError();
    _notify();

    try {
      await _service.deleteItem(id: id, alsoDeleteImage: true);
      final idx = _items.indexWhere((it) => it.id == id);
      if (idx != -1) {
        _items.removeAt(idx);
      }
      _notify();
      return true;
    } catch (e) {
      _setError(e);
      _notify();
      return false;
    }
  }

  void _notify() {
    if (_mounted) {
      notifyListeners();
    }
  }
}
