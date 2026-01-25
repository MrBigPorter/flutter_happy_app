import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/cupertino.dart';

import '../../models/chat_ui_model.dart';
import '../database/local_database_service.dart';

class OfflineQueueManager {
  //sigleton pattern
  static final OfflineQueueManager _instance = OfflineQueueManager._internal();

  // Factory constructor
  factory OfflineQueueManager() => _instance;

  // Private constructor
  OfflineQueueManager._internal();

  // status lock
  bool _isFlushing = false;
  StreamSubscription? _networkSubscription;

  // initialize network listener
  void init() {
    debugPrint(" [QueueManager] Initialized & Listening...");

    // listen to network changes
    _networkSubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      // if connected, flush the queue, it's either wifi or mobile
      final result = results.first;
      // try flush when connected
      if (result != ConnectivityResult.none) {
        debugPrint(
          " [QueueManager] Network connected: $result, attempting to flush queue...",
        );
        flushQueue();
      }
    });
  }

  // flush the offline queue
  Future<void> flushQueue() async {
    if(_isFlushing) {
      debugPrint(" [QueueManager] Flush already in progress, skipping...");
      return;
    }
    _isFlushing = true;

    try{
      // find offline queue from local database
      final pendingMsgs = await LocalDatabaseService().getPendingMessages();
      if(pendingMsgs.isEmpty) {
        return;
      }
      debugPrint(" [QueueManager] Found ${pendingMsgs.length} pending messages, flushing...");
      // iterate and send each message
      for(final msg in pendingMsgs) {
        await _resendSingleMessage(msg);
        // small delay to avoid flooding
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }catch(e){
      debugPrint(" [QueueManager] Error while flushing queue: $e");
    } finally {
      _isFlushing = false; // reset lock
    }
  }

  Future<void> _resendSingleMessage(ChatUiModel msg) async {
    try{
      debugPrint(" [QueueManager] Resending message ID: ${msg.id}");

      // 1. change status to sending
      await LocalDatabaseService().updateMessageStatus(msg.id, MessageStatus.sending);
      // 2.
    }catch(e){}
  }
}
