/// Mock Supabase RPC helper for testing
///
/// Provides comprehensive mocking capabilities for Supabase RPC calls
/// and chainable query builder operations using mocktail.
///
/// This extends the basic mock_supabase.dart with helper methods for
/// common RPC and query patterns used throughout the SLine app.
///
/// Usage:
/// ```dart
/// import '../helpers/mock_supabase_rpc.dart';
///
/// void main() {
///   late MockSupabaseClient mockClient;
///
///   setUp(() {
///     mockClient = MockSupabaseClient();
///     mockRpcCall(
///       client: mockClient,
///       functionName: 'my_function',
///       params: {'p_id': '123'},
///       returnValue: [{'id': '123', 'name': 'Test'}],
///     );
///   });
/// }
/// ```
library;

import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sline_app/core/services/logger_service.dart';

const String _logTag = 'mock_supabase_rpc';

// ============================================================================
// Mock Classes
// ============================================================================

/// Mock implementation of [SupabaseQueryBuilder] for table operations
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {
  MockSupabaseQueryBuilder() {
    AppLogger.d('MockSupabaseQueryBuilder created', tag: _logTag);
  }
}

/// Mock implementation of [PostgrestFilterBuilder] for filter operations
/// Uses dynamic type to avoid complex generic constraints
class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<dynamic> {
  MockPostgrestFilterBuilder() {
    AppLogger.d('MockPostgrestFilterBuilder created', tag: _logTag);
  }
}

// ============================================================================
// RPC Mocking Helpers
// ============================================================================

/// Mocks an RPC call on the Supabase client
///
/// [client] - The mock Supabase client
/// [functionName] - Name of the RPC function
/// [params] - Parameters to pass to the RPC function (optional)
/// [returnValue] - Value to return from the RPC call
void mockRpcCall({
  required SupabaseClient client,
  required String functionName,
  Map<String, dynamic>? params,
  required dynamic returnValue,
}) {
  AppLogger.d(
    'Mocking RPC call: $functionName with params: $params',
    tag: _logTag,
  );

  if (params != null) {
    when<Future<dynamic>>(
      () => client.rpc(functionName, params: params),
    ).thenAnswer((_) async => returnValue);
  } else {
    when<Future<dynamic>>(
      () => client.rpc(functionName),
    ).thenAnswer((_) async => returnValue);
  }
}

/// Mocks an RPC call with any parameters (useful for flexible matching)
///
/// [client] - The mock Supabase client
/// [functionName] - Name of the RPC function
/// [returnValue] - Value to return from the RPC call
void mockRpcCallAnyParams({
  required SupabaseClient client,
  required String functionName,
  required dynamic returnValue,
}) {
  AppLogger.d('Mocking RPC call: $functionName with ANY params', tag: _logTag);

  when<Future<dynamic>>(
    () => client.rpc(functionName, params: any(named: 'params')),
  ).thenAnswer((_) async => returnValue);
}

/// Mocks an RPC call that throws an exception
///
/// [client] - The mock Supabase client
/// [functionName] - Name of the RPC function
/// [params] - Parameters to pass to the RPC function (optional)
/// [exception] - Exception to throw
void mockRpcError({
  required SupabaseClient client,
  required String functionName,
  Map<String, dynamic>? params,
  required Exception exception,
}) {
  AppLogger.d(
    'Mocking RPC error: $functionName with exception: $exception',
    tag: _logTag,
  );

  if (params != null) {
    when<Future<dynamic>>(
      () => client.rpc(functionName, params: params),
    ).thenThrow(exception);
  } else {
    when<Future<dynamic>>(() => client.rpc(functionName)).thenThrow(exception);
  }
}

// ============================================================================
// SELECT Query Mocking Helpers
// ============================================================================

/// Mocks a basic SELECT query on a table that returns a list
///
/// Sets up the mock chain: client.from(table).select(columns) -> builder
/// The builder can be chained with .eq(), .order(), .limit() etc.
///
/// Usage:
/// ```dart
/// final builder = mockSelect(
///   client: mockClient,
///   table: 'tasks',
///   returnValue: [{'id': '1', 'title': 'Test'}],
/// );
/// // Now in your test, when the code does:
/// // await client.from('tasks').select().eq('status', 'open').order('created_at');
/// // It will return the mocked data.
/// ```
///
/// [client] - The mock Supabase client
/// [table] - Table name to query
/// [columns] - Columns to select (default: '*')
/// [returnValue] - Data to return from the query
///
/// Returns the mock filter builder for additional configuration if needed
MockPostgrestFilterBuilder mockSelect({
  required SupabaseClient client,
  required String table,
  String columns = '*',
  required List<dynamic> returnValue,
}) {
  AppLogger.d(
    'Mocking SELECT on $table returning ${returnValue.length} rows',
    tag: _logTag,
  );

  final mockQueryBuilder = MockSupabaseQueryBuilder();
  final mockFilterBuilder = MockPostgrestFilterBuilder();

  // Setup the chain: client.from(table).select(columns) -> mockFilterBuilder
  when(() => mockQueryBuilder.select(columns)).thenReturn(mockFilterBuilder);
  when(() => client.from(table)).thenReturn(mockQueryBuilder);

  // Setup common filter methods to return the same builder for chaining
  setupFilterChaining(mockFilterBuilder);

  return mockFilterBuilder;
}

/// Mocks a SELECT query with specific equality filters already set up
///
/// [client] - The mock Supabase client
/// [table] - Table name to query
/// [columns] - Columns to select
/// [filters] - Map of column names to values for equality filters
MockPostgrestFilterBuilder mockSelectWithEqFilters({
  required SupabaseClient client,
  required String table,
  String columns = '*',
  required Map<String, dynamic> filters,
  required List<dynamic> returnValue,
}) {
  AppLogger.d('Mocking SELECT with filters on $table: $filters', tag: _logTag);

  final mockQueryBuilder = MockSupabaseQueryBuilder();
  final mockFilterBuilder = MockPostgrestFilterBuilder();

  // Setup the chain: client.from(table).select(columns) -> mockFilterBuilder
  when(() => mockQueryBuilder.select(columns)).thenReturn(mockFilterBuilder);
  when(() => client.from(table)).thenReturn(mockQueryBuilder);

  // Setup eq filters to return the same builder for chaining
  filters.forEach((column, value) {
    when(
      () => mockFilterBuilder.eq(column, value),
    ).thenReturn(mockFilterBuilder);
  });

  // Setup other filter chaining
  setupFilterChaining(mockFilterBuilder);

  return mockFilterBuilder;
}

// ============================================================================
// INSERT Query Mocking Helpers
// ============================================================================

/// Mocks an INSERT operation on a table
///
/// [client] - The mock Supabase client
/// [table] - Table name to insert into
/// [returnValue] - Data to return after insert (usually the inserted row)
MockPostgrestFilterBuilder mockInsert({
  required SupabaseClient client,
  required String table,
  required List<dynamic> returnValue,
}) {
  AppLogger.d(
    'Mocking INSERT on $table returning ${returnValue.length} rows',
    tag: _logTag,
  );

  final mockQueryBuilder = MockSupabaseQueryBuilder();
  final mockFilterBuilder = MockPostgrestFilterBuilder();

  // Setup insert to return the filter builder
  when(() => mockQueryBuilder.insert(any())).thenReturn(mockFilterBuilder);
  when(() => client.from(table)).thenReturn(mockQueryBuilder);

  // Setup select() to return the same builder for chaining
  when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);

  // Setup filter chaining for subsequent operations
  setupFilterChaining(mockFilterBuilder);

  return mockFilterBuilder;
}

/// Mocks an UPSERT operation on a table
///
/// [client] - The mock Supabase client
/// [table] - Table name to upsert into
/// [onConflict] - Conflict resolution column(s) (optional)
/// [returnValue] - Data to return after upsert
MockPostgrestFilterBuilder mockUpsert({
  required SupabaseClient client,
  required String table,
  String? onConflict,
  required List<dynamic> returnValue,
}) {
  AppLogger.d(
    'Mocking UPSERT on $table${onConflict != null ? ' on conflict: $onConflict' : ''}',
    tag: _logTag,
  );

  final mockQueryBuilder = MockSupabaseQueryBuilder();
  final mockFilterBuilder = MockPostgrestFilterBuilder();

  // Setup upsert to return the filter builder
  if (onConflict != null) {
    when(
      () => mockQueryBuilder.upsert(any(), onConflict: onConflict),
    ).thenReturn(mockFilterBuilder);
  } else {
    when(() => mockQueryBuilder.upsert(any())).thenReturn(mockFilterBuilder);
  }
  when(() => client.from(table)).thenReturn(mockQueryBuilder);

  // Setup select() and filter chaining
  when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
  setupFilterChaining(mockFilterBuilder);

  return mockFilterBuilder;
}

// ============================================================================
// UPDATE Query Mocking Helpers
// ============================================================================

/// Mocks an UPDATE operation on a table
///
/// [client] - The mock Supabase client
/// [table] - Table name to update
/// [returnValue] - Data to return after update
MockPostgrestFilterBuilder mockUpdate({
  required SupabaseClient client,
  required String table,
  required List<dynamic> returnValue,
}) {
  AppLogger.d(
    'Mocking UPDATE on $table returning ${returnValue.length} rows',
    tag: _logTag,
  );

  final mockQueryBuilder = MockSupabaseQueryBuilder();
  final mockFilterBuilder = MockPostgrestFilterBuilder();

  // Setup update to return the filter builder
  when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
  when(() => client.from(table)).thenReturn(mockQueryBuilder);

  // Setup select() and filter chaining
  when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
  setupFilterChaining(mockFilterBuilder);

  return mockFilterBuilder;
}

/// Mocks an UPDATE operation with specific filters
///
/// [client] - The mock Supabase client
/// [table] - Table name to update
/// [filters] - Map of column names to values for equality filters
/// [returnValue] - Data to return after update
MockPostgrestFilterBuilder mockUpdateWithFilters({
  required SupabaseClient client,
  required String table,
  required Map<String, dynamic> filters,
  required List<dynamic> returnValue,
}) {
  AppLogger.d('Mocking UPDATE with filters on $table: $filters', tag: _logTag);

  final mockQueryBuilder = MockSupabaseQueryBuilder();
  final mockFilterBuilder = MockPostgrestFilterBuilder();

  // Setup update to return the filter builder
  when(() => mockQueryBuilder.update(any())).thenReturn(mockFilterBuilder);
  when(() => client.from(table)).thenReturn(mockQueryBuilder);

  // Setup eq filters
  filters.forEach((column, value) {
    when(
      () => mockFilterBuilder.eq(column, value),
    ).thenReturn(mockFilterBuilder);
  });

  // Setup select() and filter chaining
  when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);
  setupFilterChaining(mockFilterBuilder);

  return mockFilterBuilder;
}

// ============================================================================
// DELETE Query Mocking Helpers
// ============================================================================

/// Mocks a DELETE operation on a table
///
/// [client] - The mock Supabase client
/// [table] - Table name to delete from
MockPostgrestFilterBuilder mockDelete({
  required SupabaseClient client,
  required String table,
}) {
  AppLogger.d('Mocking DELETE on $table', tag: _logTag);

  final mockQueryBuilder = MockSupabaseQueryBuilder();
  final mockFilterBuilder = MockPostgrestFilterBuilder();

  // Setup delete to return the filter builder
  when(() => mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
  when(() => client.from(table)).thenReturn(mockQueryBuilder);

  // Setup eq for filtering and select()
  setupFilterChaining(mockFilterBuilder);
  when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);

  return mockFilterBuilder;
}

/// Mocks a DELETE operation with specific filters
///
/// [client] - The mock Supabase client
/// [table] - Table name to delete from
/// [filters] - Map of column names to values for equality filters
MockPostgrestFilterBuilder mockDeleteWithFilters({
  required SupabaseClient client,
  required String table,
  required Map<String, dynamic> filters,
}) {
  AppLogger.d('Mocking DELETE with filters on $table: $filters', tag: _logTag);

  final mockQueryBuilder = MockSupabaseQueryBuilder();
  final mockFilterBuilder = MockPostgrestFilterBuilder();

  // Setup delete to return the filter builder
  when(() => mockQueryBuilder.delete()).thenReturn(mockFilterBuilder);
  when(() => client.from(table)).thenReturn(mockQueryBuilder);

  // Setup eq filters
  filters.forEach((column, value) {
    when(
      () => mockFilterBuilder.eq(column, value),
    ).thenReturn(mockFilterBuilder);
  });

  // Setup other filter chaining and select()
  setupFilterChaining(mockFilterBuilder);
  when(() => mockFilterBuilder.select()).thenReturn(mockFilterBuilder);

  return mockFilterBuilder;
}

// ============================================================================
// Chainable Filter Helpers
// ============================================================================

/// Sets up common filter methods to return the same builder for chaining
///
/// [builder] - The mock filter builder to configure
void setupFilterChaining(MockPostgrestFilterBuilder builder) {
  // Equality filters
  when(() => builder.eq(any(), any())).thenReturn(builder);
  when(() => builder.neq(any(), any())).thenReturn(builder);

  // Comparison filters
  when(() => builder.gt(any(), any())).thenReturn(builder);
  when(() => builder.gte(any(), any())).thenReturn(builder);
  when(() => builder.lt(any(), any())).thenReturn(builder);
  when(() => builder.lte(any(), any())).thenReturn(builder);

  // Text filters
  when(() => builder.like(any(), any())).thenReturn(builder);
  when(() => builder.ilike(any(), any())).thenReturn(builder);

  // List filters
  when(() => builder.in_(any(), any())).thenReturn(builder);

  // Null check filters
  when(() => builder.is_(any(), any())).thenReturn(builder);

  // Logical filters
  when(() => builder.not(any(), any(), any())).thenReturn(builder);
  when(() => builder.or(any())).thenReturn(builder);

  // Range
  when(() => builder.range(any(), any())).thenReturn(builder);

  AppLogger.d('Filter chaining configured', tag: _logTag);
}

// ============================================================================
// Verification Helpers
// ============================================================================

/// Verifies that an RPC call was made with specific parameters
///
/// [client] - The mock Supabase client
/// [functionName] - Name of the RPC function
/// [params] - Expected parameters (optional)
void verifyRpcCall({
  required SupabaseClient client,
  required String functionName,
  Map<String, dynamic>? params,
}) {
  AppLogger.d('Verifying RPC call: $functionName', tag: _logTag);

  if (params != null) {
    verify(() => client.rpc(functionName, params: params)).called(1);
  } else {
    verify(() => client.rpc(functionName)).called(1);
  }
}

/// Verifies that a table query was made
///
/// [client] - The mock Supabase client
/// [table] - Table name
/// [times] - Number of times the query should have been made (default: 1)
void verifyTableQuery({
  required SupabaseClient client,
  required String table,
  int times = 1,
}) {
  AppLogger.d('Verifying query on $table called $times times', tag: _logTag);
  verify(() => client.from(table)).called(times);
}

/// Verifies that an insert was made on a table
///
/// [queryBuilder] - The mock query builder
/// [expectedData] - Expected data to be inserted (optional, verifies any if null)
void verifyInsert({
  required MockSupabaseQueryBuilder queryBuilder,
  dynamic expectedData,
}) {
  AppLogger.d('Verifying insert', tag: _logTag);
  if (expectedData != null) {
    verify(() => queryBuilder.insert(expectedData)).called(1);
  } else {
    verify(() => queryBuilder.insert(any())).called(1);
  }
}

/// Verifies that an update was made on a table
///
/// [queryBuilder] - The mock query builder
/// [expectedData] - Expected data for update (optional, verifies any if null)
void verifyUpdate({
  required MockSupabaseQueryBuilder queryBuilder,
  Map<String, dynamic>? expectedData,
}) {
  AppLogger.d('Verifying update', tag: _logTag);
  if (expectedData != null) {
    verify(() => queryBuilder.update(expectedData)).called(1);
  } else {
    verify(() => queryBuilder.update(any())).called(1);
  }
}

/// Verifies that a delete was made on a table
///
/// [queryBuilder] - The mock query builder
void verifyDelete({required MockSupabaseQueryBuilder queryBuilder}) {
  AppLogger.d('Verifying delete', tag: _logTag);
  verify(() => queryBuilder.delete()).called(1);
}
