import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cross_file/cross_file.dart';

import 'package:flutter_app/common.dart';
import 'package:flutter_app/core/services/socket_service.dart';
import 'package:flutter_app/core/providers/socket_provider.dart';
import 'package:flutter_app/ui/chat/models/chat_ui_model.dart';
import 'package:flutter_app/core/store/lucky_store.dart';
import 'package:flutter_app/ui/chat/services/media/video_processor.dart';
import 'package:flutter_app/ui/chat/services/network/offline_queue_manager.dart';

import '../../../utils/asset/asset_manager.dart';
import '../../../utils/upload/global_upload_service.dart';
import '../../../utils/upload/upload_types.dart';
import '../models/conversation.dart';
import '../services/compression/image_compression_service.dart';
import '../services/database/local_database_service.dart';
import 'conversation_provider.dart';

// --- Riverpod Providers ---

final chatStreamProvider = StreamProvider.family
    .autoDispose<List<ChatUiModel>, String>((ref, conversationId) {
      return LocalDatabaseService().watchMessages(conversationId);
    });

final chatLoadingMoreProvider = StateProvider.family<bool, String>(
  (ref, id) => false,
);

final chatControllerProvider = Provider.family
    .autoDispose<ChatRoomController, String>((ref, conversationId) {
      final socketService = ref.read(socketServiceProvider);
      final uploadService = ref.read(uploadServiceProvider);
      final controller = ChatRoomController(
        socketService,
        uploadService,
        conversationId,
        ref,
      );
      ref.onDispose(() => controller.dispose());
      return controller;
    });

class ChatRoomController with WidgetsBindingObserver {
  final SocketService _socketService;
  final GlobalUploadService _uploadService;
  final String conversationId;
  final Ref _ref;

  StreamSubscription? _msgSub, _readStatusSub, _connectionSub, _recallSub;
  final _readReceiptSubject = PublishSubject<void>();
  final Set<String> _processedMsgIds = {};
  bool _mounted = true;
  String? _nextCursor;
  bool _isLoadingMore = false;
  int _maxReadSeqId = 0;

  // --- Fixed Missing Getters & Helpers ---

  bool get hasMore => _nextCursor != null; //

  String get _currentUserId => _ref.read(luckyProvider).userInfo?.id ?? ""; //

  static final Map<String, String> _sessionPathCache = {};

  static String? getPathFromCache(String msgId) => _sessionPathCache[msgId];

  ChatRoomController(
    this._socketService,
    this._uploadService,
    this.conversationId,
    this._ref,
  ) {
    WidgetsBinding.instance.addObserver(this);
    _setup();
    _setupReadReceiptDebounce();
  }

  void dispose() {
    _mounted = false;
    WidgetsBinding.instance.removeObserver(this);
    _socketService.leaveChatRoom(conversationId);
    _msgSub?.cancel();
    _readStatusSub?.cancel();
    _connectionSub?.cancel();
    _recallSub?.cancel();
    _readReceiptSubject.close();
  }

  // ===========================================================================
  // CORE PIPELINE
  // ===========================================================================

  Future<void> _sendPipeline({
    required ChatUiModel msg,
    required Future<String> Function() getContentTask,
    Map<String, dynamic>? extraMeta,
  }) async {
    try {
      await LocalDatabaseService().saveMessage(msg);
      _updateConversationList(msg.content, msg.createdAt);

      final finalContent = await getContentTask();

      // Fix: Explicitly typed Map for metadata merging
      final Map<String, dynamic> combinedMeta = <String, dynamic>{
        if (msg.meta != null) ...msg.meta!,
        if (extraMeta != null) ...extraMeta,
      };

      final serverMsg = await Api.sendMessage(
        id: msg.id,
        conversationId: conversationId,
        content: finalContent,
        type: msg.type.value,
        meta: combinedMeta.isEmpty ? null : combinedMeta,
      );

      await LocalDatabaseService().updateMessage(msg.id, {
        'status': MessageStatus.success.name,
        'seqId': serverMsg.seqId,
        'createdAt': timeToInt(serverMsg.createdAt),
        if (serverMsg.meta != null) 'meta': serverMsg.meta,
        if (msg.type != MessageType.text) 'content': serverMsg.content,
      });
    } catch (e) {
      debugPrint("Send Pipeline Error: $e");
      await LocalDatabaseService().updateMessageStatus(
        msg.id,
        MessageStatus.pending,
      );
      OfflineQueueManager().startFlush();
    }
  }

  Future<String> _uploadAttachment(
    String? localName,
    MessageType type, {
    String? fallbackPath,
  }) async {
    if (localName == null && fallbackPath == null) return "";
    final fullPath = await AssetManager.getFullPath(localName, type);
    final uploadPath = fullPath ?? fallbackPath;
    if (uploadPath == null) throw Exception("Local asset not found");

    return await _uploadService.uploadFile(
      file: XFile(uploadPath),
      module: UploadModule.chat,
      onProgress: (_) {},
    );
  }

  // ===========================================================================
  //  MESSAGE ACTIONS
  // ===========================================================================

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final msg = _createBaseMessage(content: text, type: MessageType.text);
    await _sendPipeline(msg: msg, getContentTask: () async => text);
  }

  Future<void> sendImage(XFile file) async {
    final msgId = const Uuid().v4();
    final results = await Future.wait([
      ImageCompressionService.getTinyThumbnail(file),
      AssetManager.save(file, MessageType.image),
      _calculateImageSize(file),
    ]);

    final fileName = results[1] as String;
    final meta = results[2] as Map<String, dynamic>;

    final absPath = await AssetManager.getFullPath(fileName, MessageType.image);
    if (absPath != null) _sessionPathCache[msgId] = absPath;

    final msg = _createBaseMessage(
      id: msgId,
      content: "[Image]",
      type: MessageType.image,
      localPath: fileName,
      previewBytes: results[0] as Uint8List,
      meta: meta,
    );

    await _sendPipeline(
      msg: msg,
      getContentTask: () => _uploadAttachment(
        fileName,
        MessageType.image,
        fallbackPath: file.path,
      ),
    );
  }

  Future<void> sendVoiceMessage(String path, int duration) async {
    final msgId = const Uuid().v4();
    final fileName = await AssetManager.save(XFile(path), MessageType.audio);

    final absPath = await AssetManager.getFullPath(fileName, MessageType.audio);
    if (absPath != null) _sessionPathCache[msgId] = absPath;

    final msg = _createBaseMessage(
      id: msgId,
      content: "[Voice]",
      type: MessageType.audio,
      localPath: fileName,
      duration: duration,
      meta: {'duration': duration},
    );

    await _sendPipeline(
      msg: msg,
      getContentTask: () =>
          _uploadAttachment(fileName, MessageType.audio, fallbackPath: path),
    );
  }

  Future<void> sendVideo(XFile file) async {
    final msgId = const Uuid().v4();
    final result = await VideoProcessor.process(file);
    if (result == null) return;

    final videoName = await AssetManager.save(
      result.videoFile,
      MessageType.video,
    );
    final thumbName = await AssetManager.save(
      XFile(result.thumbnailFile.path),
      MessageType.image,
    );

    final absPath = await AssetManager.getFullPath(
      videoName,
      MessageType.video,
    );
    if (absPath != null) _sessionPathCache[msgId] = absPath;

    final Map<String, dynamic> videoMeta = {
      'thumb': thumbName,
      'w': result.width,
      'h': result.height,
      'duration': result.duration,
    };

    final msg = _createBaseMessage(
      id: msgId,
      content: "[Video]",
      type: MessageType.video,
      localPath: videoName,
      meta: videoMeta,
    );

    await _sendPipeline(
      msg: msg,
      getContentTask: () async {
        final thumbUrl = await _uploadService.uploadFile(
          file: XFile(result.thumbnailFile.path),
          module: UploadModule.chat,
          onProgress: (_) {},
        );
        videoMeta['thumb'] = thumbUrl;
        return await _uploadAttachment(videoName, MessageType.video);
      },
      extraMeta: videoMeta,
    );
  }

  Future<void> resendMessage(String msgId) async {
    final target = await LocalDatabaseService().getMessageById(msgId);
    if (target == null) return;

    final msg = target.copyWith(
      status: MessageStatus.sending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    await _sendPipeline(
      msg: msg,
      getContentTask: () async {
        if (msg.type == MessageType.text) return msg.content;
        if (!msg.content.startsWith('http')) {
          return await _uploadAttachment(msg.localPath, msg.type);
        }
        return msg.content;
      },
    );
  }

  // ===========================================================================
  //  HELPERS
  // ===========================================================================

  ChatUiModel _createBaseMessage({
    String? id,
    required String content,
    required MessageType type,
    String? localPath,
    Uint8List? previewBytes,
    Map<String, dynamic>? meta,
    int? duration,
  }) {
    return ChatUiModel(
      id: id ?? const Uuid().v4(),
      conversationId: conversationId,
      content: content,
      type: type,
      isMe: true,
      status: MessageStatus.sending,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      localPath: localPath,
      previewBytes: previewBytes,
      meta: meta,
      duration: duration,
    );
  }

  int timeToInt(dynamic value) {
    if (value is int) return value;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is String) return DateTime.parse(value).millisecondsSinceEpoch;
    return DateTime.now().millisecondsSinceEpoch;
  }

  Future<Map<String, dynamic>> _calculateImageSize(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      return {'w': frameInfo.image.width, 'h': frameInfo.image.height};
    } catch (_) {
      return {};
    }
  }

  // --- Socket & State Logic ---

  Future<void> _setup() async {
    _connectionSub = _socketService.onSyncNeeded.listen((_) => _joinRoom());
    if (_socketService.isConnected) _joinRoom();
    _msgSub = _socketService.chatMessageStream.listen(_onSocketMessage);
    _readStatusSub = _socketService.readStatusStream.listen(
      _onReadStatusUpdate,
    );
    _recallSub = _socketService.recallEventStream.listen(_onMessageRecalled);
  }

  void _joinRoom() {
    if (_socketService.isConnected) _socketService.joinChatRoom(conversationId);
  }

  void _setupReadReceiptDebounce() {
    _readReceiptSubject.debounceTime(const Duration(milliseconds: 500)).listen((
      _,
    ) {
      if (_mounted &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _executeMarkRead();
      }
    });
  }

  void markAsRead() {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed)
      _executeMarkRead();
  }

  void _executeMarkRead() {
    try {
      _ref.read(conversationListProvider.notifier).clearUnread(conversationId);
    } catch (_) {}
    Api.messageMarkAsReadApi(
      MessageMarkReadRequest(conversationId: conversationId),
    );
  }

  Future<void> refresh() async {
    try {
      markAsRead();
      final response = await Api.chatMessagesApi(
        MessageHistoryRequest(conversationId: conversationId, pageSize: 20),
      );
      _maxReadSeqId = response.partnerLastReadSeqId;
      _nextCursor = response.nextCursor;
      final uiMsgs = _applyReadStatusLocally(
        _mapToUiModels(response.list),
        _maxReadSeqId,
      );
      await LocalDatabaseService().saveMessages(uiMsgs);
    } catch (e) {
      debugPrint("Refresh Error: $e");
    }
  }

  Future<void> loadMore() async {
    if (_nextCursor == null || _isLoadingMore) return;
    _isLoadingMore = true;
    _ref.read(chatLoadingMoreProvider(conversationId).notifier).state = true;
    try {
      final response = await Api.chatMessagesApi(
        MessageHistoryRequest(
          conversationId: conversationId,
          pageSize: 20,
          cursor: _nextCursor,
        ),
      );
      _nextCursor = response.nextCursor;
      final uiMsgs = _applyReadStatusLocally(
        _mapToUiModels(response.list),
        _maxReadSeqId,
      );
      await LocalDatabaseService().saveMessages(uiMsgs);
    } finally {
      _isLoadingMore = false;
      _ref.read(chatLoadingMoreProvider(conversationId).notifier).state = false;
    }
  }

  Future<void> recallMessage(String messageId) async {
    try {
      final res = await Api.messageRecallApi(
        MessageRecallRequest(
          conversationId: conversationId,
          messageId: messageId,
        ),
      );
      await LocalDatabaseService().doLocalRecall(messageId, res.tip);
      _updateConversationList(
        "[message recalled]",
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await LocalDatabaseService().deleteMessage(messageId);
      await Api.messageDeleteApi(
        MessageDeleteRequest(
          messageId: messageId,
          conversationId: conversationId,
        ),
      );
    } catch (_) {}
  }

  void _onSocketMessage(Map<String, dynamic> data) async {
    if (!_mounted) return;
    final msg = SocketMessage.fromJson(data);
    if (msg.conversationId != conversationId ||
        _processedMsgIds.contains(msg.id) ||
        msg.sender?.id == _currentUserId)
      return;

    _processedMsgIds.add(msg.id);
    if (_processedMsgIds.length > 50)
      _processedMsgIds.remove(_processedMsgIds.first);
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed)
      _readReceiptSubject.add(null);

    var uiMsg = ChatUiModel.fromApiModel(
      ChatMessage(
        id: msg.id,
        content: msg.content,
        type: msg.type,
        seqId: msg.seqId,
        createdAt: msg.createdAt,
        isSelf: false,
        meta: msg.meta,
      ),
      conversationId,
      _currentUserId,
    );

    final localMsg = await LocalDatabaseService().getMessageById(uiMsg.id);
    if (localMsg != null &&
        localMsg.previewBytes != null &&
        localMsg.previewBytes!.isNotEmpty) {
      uiMsg = uiMsg.copyWith(previewBytes: localMsg.previewBytes);
    }
    await LocalDatabaseService().saveMessage(uiMsg);
  }

  void _onReadStatusUpdate(SocketReadEvent event) async {
    if (!_mounted ||
        event.conversationId != conversationId ||
        event.readerId == _currentUserId)
      return;
    if (event.lastReadSeqId > _maxReadSeqId)
      _maxReadSeqId = event.lastReadSeqId;
    await LocalDatabaseService().markMessagesAsRead(
      conversationId,
      _maxReadSeqId,
    );
  }

  void _onMessageRecalled(SocketRecallEvent event) async {
    if (event.conversationId != conversationId) return;
    final tip = event.isSelf
        ? "You unsent a message"
        : "This message was unsent";
    await LocalDatabaseService().doLocalRecall(event.messageId, tip);
    _updateConversationList(tip, DateTime.now().millisecondsSinceEpoch);
  }

  List<ChatUiModel> _mapToUiModels(List<dynamic> list) => list
      .map(
        (dto) => ChatUiModel.fromApiModel(dto, conversationId, _currentUserId),
      )
      .toList();

  List<ChatUiModel> _applyReadStatusLocally(
    List<ChatUiModel> list,
    int waterLine,
  ) {
    return list
        .map(
          (msg) =>
              (msg.isMe &&
                  msg.status == MessageStatus.success &&
                  msg.seqId != null &&
                  msg.seqId! <= waterLine)
              ? msg.copyWith(status: MessageStatus.read)
              : msg,
        )
        .toList();
  }

  void _updateConversationList(String text, int time) {
    try {
      _ref
          .read(conversationListProvider.notifier)
          .updateLocalItem(
            conversationId: conversationId,
            lastMsgContent: text,
            lastMsgTime: time,
          );
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) markAsRead();
  }
}
