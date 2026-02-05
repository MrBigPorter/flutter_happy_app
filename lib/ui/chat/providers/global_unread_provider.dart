
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/ui/chat/services/database/local_database_service.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
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

  // 4. yield the stream
  await for(final total in stream) {
    // update app icon badge
    _updateAppIconBadge(total);
    // yield total unread count
    yield total;
  }

});

// update app icon badge count
void _updateAppIconBadge(int count) {
  if(kIsWeb){
    final String title = count > 0 ? '($count) ' : '';
    // 1. 修改点：直接修改 document.title 来显示未读数
    SystemChrome.setApplicationSwitcherDescription(
      ApplicationSwitcherDescription(
        label: '$title Chat',
        primaryColor: 0xFF000000,
      ),
    );
    return;
  }
  FlutterAppBadger.isAppBadgeSupported().then((supported) {
    if (supported) {
      if (count > 0) {
        FlutterAppBadger.updateBadgeCount(count);
      } else {
        FlutterAppBadger.removeBadge();
      }
    }
  });
}