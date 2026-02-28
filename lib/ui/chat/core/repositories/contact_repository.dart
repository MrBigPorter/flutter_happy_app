import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/lucky_api.dart';
import '../../models/conversation.dart'; // Ensure ChatUser is defined here
import '../../services/database/local_database_service.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository(LocalDatabaseService());
});

class ContactRepository {
  final LocalDatabaseService _localDb;

  ContactRepository(this._localDb);

  /// Core synchronization logic (Sync)
  /// Process: API -> DB -> Sembast Index
  Future<void> syncContacts() async {
    try {
      // 1. Invoke the real API to fetch the contact list
      // Ensure Api.getContactsApi() returns a List<ChatUser>
      final List<ChatUser> remoteUsers = await Api.getContactsApi();

      if (remoteUsers.isNotEmpty) {
        // 2. Persist to local database
        // This step is critical as it triggers _updateSearchIndex in LocalDatabaseService,
        // which decomposes Chinese names into Pinyin for search indexing.
        await _localDb.saveContacts(remoteUsers);

        debugPrint("[ContactRepo] Synced ${remoteUsers.length} contacts & built index.");
      }
    } catch (e) {
      debugPrint("[ContactRepo] Sync failed: $e");
      // Re-throwing allows the UI layer to handle the error if necessary
      rethrow;
    }
  }

  /// Search for contacts (Search)
  Future<List<ChatUser>> search(String query) {
    return _localDb.searchContacts(query);
  }

  /// Retrieve all contacts (List)
  Future<List<ChatUser>> getAllContacts() {
    return _localDb.getAllContacts();
  }
}