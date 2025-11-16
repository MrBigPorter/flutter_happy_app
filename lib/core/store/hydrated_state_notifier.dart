import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// HydratedStateNotifier - A StateNotifier that persists its state using SharedPreferences
/// Methods:
/// - HydratedStateNotifier(T initialState)
/// - String get storageKey
/// - T fromJson(Map<String, dynamic> json)
/// - Map<String, dynamic> toJson(T state)
/// - Future<'void'> _load()
/// - Future<'void'> _save(T value)
/// - @override set state(T value)
/// Parameters:
/// - T initialState: The initial state of the notifier
/// Usage:
/// ```dart
/// class CounterNotifier extends HydratedStateNotifier<int> {
///  CounterNotifier() : super(0);
///
abstract class HydratedStateNotifier<T> extends StateNotifier<T> {
  HydratedStateNotifier(T initialState) : super(initialState){
    _load();
  }

  /// Unique key for storing the state in SharedPreferences
  String get storageKey;

  /// Converts JSON map to state object
  T fromJson(Map<String, dynamic> json);

  /// Converts state object to JSON map
  Map<String, dynamic> toJson(T state);

  /// Loads the state from SharedPreferences
  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(storageKey);

    if(raw == null) return;

    try{
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final loaded = fromJson(map);
      super.state = loaded;
    } catch (e) {
      // Handle JSON parsing error
      print('Error loading state for $storageKey: $e');
    }
  }

  /// Saves the state to SharedPreferences
  Future<void> _save(T value) async {
    final sp = await SharedPreferences.getInstance();
    final map = toJson(value);
    await sp.setString(storageKey, jsonEncode(map));
  }

  @override
  set state(T value) {
    super.state = value;
    _save(value);
  }
}