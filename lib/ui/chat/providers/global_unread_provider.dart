
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sembast/sembast.dart';

// global unread count Provider
final globalUnreadProvider = StreamProvider<int>((ref) async* {
  // 1. wait for socketService initialization
  final dbService = LocalDatabaseService();
  final db = await dbService.database;
  
  // create finder for unread conversations
  final store = stringMapStoreFactory.store('conversations');
  final query = store.query(
   finder: Finder(
      filter: Filter.greaterThan('unreadCount', 0),
   )
  );

  // 3. listen to changes and calculate total unread count
  final stream = query.onSnapshots(db).map((snapshots) {
    int total = 0;
    for (final record in snapshots) {
      final unread = record.value['unreadCount'] as int? ?? 0;
      total += unread;
    }
    return total;
  });

  // give unread count to ui
  yield* stream;
});

