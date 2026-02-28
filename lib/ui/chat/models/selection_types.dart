import 'package:flutter_app/app/routes/extra_codec.dart';

// 1. Selection Interaction Mode
enum SelectionMode { single, multiple }

// 2. Entity Category (Unified for Users and Groups)
enum EntityType { user, group }

// 3. Unified Selection Object (Represents a single row in the selection list)
class SelectionEntity {
  final String id;
  final String name;
  final String? avatar;
  final EntityType type;
  final String? desc; // Subtitle, e.g., "Group" or "ID: 12345"

  SelectionEntity({
    required this.id,
    required this.name,
    this.avatar,
    required this.type,
    this.desc,
  });

  /// Equality Overrides:
  /// Ensures that two entities are treated as identical if their IDs match,
  /// facilitating set operations and UI selection states.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is SelectionEntity &&
              runtimeType == other.runtimeType &&
              id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Route arguments for the Contact Selection page
class ContactSelectionArgs extends BaseRouteArgs {
  final String title;           // Page title (e.g., "Forward To", "Add Members")
  final SelectionMode mode;     // Interaction mode (Single vs Multiple selection)
  final List<String> excludeIds;// IDs to filter out (e.g., members already in a group)
  final String? confirmText;    // Custom label for the action button (e.g., "Send", "Invite")

  ContactSelectionArgs({
    this.title = "Select Contact",
    this.mode = SelectionMode.single,
    this.excludeIds = const [],
    this.confirmText,
  });

  /// Serialization logic for routing and deep linking
  Map<String, dynamic> toJson() => {
    'title': title,
    'mode': mode.name,
    'excludeIds': excludeIds,
    'confirmText': confirmText,
  };

  /// Deserialization factory for cross-page argument passing
  factory ContactSelectionArgs.fromJson(Map<String, dynamic> json) => ContactSelectionArgs(
    title: json['title'] ?? "Select Contact",
    mode: json['mode'] == SelectionMode.multiple.name
        ? SelectionMode.multiple
        : SelectionMode.single,
    excludeIds: List<String>.from(json['excludeIds'] ?? []),
    confirmText: json['confirmText'],
  );
}