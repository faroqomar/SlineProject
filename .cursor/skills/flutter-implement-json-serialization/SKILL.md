---
name: flutter-implement-json-serialization
description: Implements SLine manual model mapping with fromJson, toJson, and copyWith. Use when adding or fixing models without build_runner/freezed.
metadata:
  model: models/gemini-3.1-pro-preview
  last_modified: Tue, 21 Apr 2026 21:44:50 GMT
---
# Serializing JSON Manually in Flutter
## SLine Project Overrides

These upstream Flutter/Dart instructions are adapted for SLine. Apply these rules before the generic workflow:

- Preserve SLine's strict MVVM boundary: Views render state and call ViewModels; ViewModels call services/repositories; services own Supabase, storage, realtime, and payment access.
- Do not put Supabase, RPC, storage, business rules, or navigation side effects directly in `lib/features/*/view/` widgets. If a View needs data the ViewModel does not expose, document the gap or extend the ViewModel/service layer.
- Prefer existing project patterns over new dependencies: Provider state management, manual `fromJson`/`toJson`/`copyWith`, `ViewState<T>` for new complex VMs, `AppLogger`, `AppFailure`, `ErrorMapper`, `AppMotion`, `AppColors`, `AppTypography`, `AppDimens`, `AppLayout`, and shared widgets under `lib/core/widgets/`.
- Do not introduce `build_runner`, `freezed`, generated mocks, `go_router`, `http`, or new architecture packages unless the user explicitly asks and the repo evidence supports it.
- Before implementation, search related feature files with `rg`, then keep changes scoped to the target feature or shared layer. Preserve unrelated user changes in the dirty worktree.
- After meaningful code changes, run `dart format` on touched Dart files, `flutter analyze --no-fatal-infos`, and focused `flutter test` targets. Run the full suite when shared behavior or cross-feature contracts changed.

### SLine Model Notes

SLine uses manual model mapping. Keep `fromJson`, `toJson`, and `copyWith` explicit, convert loosely typed Supabase rows with `Map<String, dynamic>.from(row)`, store UTC timestamps, and convert to local time only at UI boundaries.

## Contents
- [Core Guidelines](#core-guidelines)
- [Workflow: Implementing a Serializable Model](#workflow-implementing-a-serializable-model)
- [Workflow: Fetching and Parsing JSON](#workflow-fetching-and-parsing-json)
- [Examples](#examples)

## Core Guidelines

- **Import `dart:convert`**: Utilize Flutter's built-in `dart:convert` library for manual JSON encoding (`jsonEncode`) and decoding (`jsonDecode`).
- **Enforce Type Safety**: Always cast the `dynamic` result of `jsonDecode()` to the expected type, typically `Map<String, dynamic>` for objects or `List<dynamic>` for arrays.
- **Encapsulate Serialization Logic**: Define plain model classes containing properties corresponding to the JSON structure. Implement a `fromJson` factory constructor and a `toJson` method within the model.
- **Handle Background Parsing**: If parsing large JSON documents (execution time > 16ms), offload the parsing logic to a separate isolate using Flutter's `compute()` function to prevent UI jank.
- **Throw Exceptions on Failure**: When handling HTTP responses, throw an exception if the status code is not successful (e.g., not 200 OK or 201 Created). Do not return `null`.

## Workflow: Implementing a Serializable Model

Use this checklist to implement manual JSON serialization for a data model.

**Task Progress:**
- [ ] Define the plain model class with `final` properties.
- [ ] Implement the `factory Model.fromJson(Map<String, dynamic> json)` constructor.
- [ ] Implement the `Map<String, dynamic> toJson()` method.
- [ ] Write unit tests for both serialization methods.
- [ ] Run validator -> review type mismatch errors -> fix casting logic.

1. **Define the Model**: Create a class with properties matching the JSON keys.
2. **Implement `fromJson`**: Extract values from the `Map` and cast them to the appropriate Dart types. Use pattern matching or explicit casting.
3. **Implement `toJson`**: Return a `Map<String, dynamic>` mapping the class properties back to their JSON string keys.
4. **Validate**: Execute unit tests to ensure type safety, autocompletion, and compile-time exception handling function correctly.

## Workflow: Fetching and Parsing JSON

Use this conditional workflow when retrieving and parsing JSON from a network request.

**Task Progress:**
- [ ] Execute the HTTP request.
- [ ] Validate the response status code.
- [ ] Determine parsing strategy (Synchronous vs. Isolate).
- [ ] Decode and map the JSON to the model.

1. **Execute Request**: Use the `http` package to perform the network call.
2. **Validate Response**:
   - If `response.statusCode == 200` (or 201 for POST), proceed to parsing.
   - If the status code indicates failure, throw an `Exception`.
3. **Determine Parsing Strategy**:
   - If parsing a **small payload** (e.g., a single object), parse synchronously on the main thread.
   - If parsing a **large payload** (e.g., an array of thousands of objects), use `compute(parseFunction, response.body)` to parse in a background isolate.
4. **Decode and Map**: Pass the decoded JSON to your model's `fromJson` constructor.

## Examples

### High-Fidelity Model Implementation

```dart
import 'dart:convert';

class User {
  final int id;
  final String name;
  final String email;

  const User({
    required this.id,
    required this.name,
    required this.email,
  });

  // Factory constructor for deserialization
  factory User.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': int id,
        'name': String name,
        'email': String email,
      } =>
        User(
          id: id,
          name: name,
          email: email,
        ),
      _ => throw const FormatException('Failed to load User.'),
    };
  }

  // Method for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}
```

### Synchronous Parsing (Small Payload)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<User> fetchUser(http.Client client, int userId) async {
  final response = await client.get(
    Uri.parse('https://api.example.com/users/$userId'),
    headers: {'Accept': 'application/json'},
  );

  if (response.statusCode == 200) {
    // Decode returns dynamic, cast to Map<String, dynamic>
    final Map<String, dynamic> jsonMap = jsonDecode(response.body) as Map<String, dynamic>;
    return User.fromJson(jsonMap);
  } else {
    throw Exception('Failed to load user');
  }
}
```

### Background Parsing (Large Payload)

```dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// Top-level function required for compute()
List<User> parseUsers(String responseBody) {
  final parsed = (jsonDecode(responseBody) as List<dynamic>).cast<Map<String, dynamic>>();
  return parsed.map<User>((json) => User.fromJson(json)).toList();
}

Future<List<User>> fetchUsers(http.Client client) async {
  final response = await client.get(
    Uri.parse('https://api.example.com/users'),
    headers: {'Accept': 'application/json'},
  );

  if (response.statusCode == 200) {
    // Offload expensive parsing to a background isolate
    return compute(parseUsers, response.body);
  } else {
    throw Exception('Failed to load users');
  }
}
```
