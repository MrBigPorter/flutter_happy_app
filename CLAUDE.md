# JoyMini Flutter App

## Stack

- Flutter 3.10+ (Dart 3.x)
- State: Riverpod (StateNotifierProvider.family, riverpod_annotation)
- HTTP: Dio
- Routing: GoRouter + ShellRoute (bottom tabs)
- Real-time: socket_io_client (Socket.IO unified dispatch)
- Persistence: sembast (local messages), SharedPreferences (settings)
- Auth: JWT + flutter_secure_storage

## Architecture

### State Management
- `StateNotifier` + `Provider.family` for scoped state (by conversationId etc.)
- `@Riverpod(keepAlive: true)` for singletons (socket, auth, conversation list)
- `.autoDispose` for page-scoped providers (chat room, view model)

### Chat System (Core)
```
ChatPage(conversationId)
  │
  ├── chatControllerProvider
  │     └── ChatRoomController → ChatEventHandler
  │           ├── chatMessageStream → _onSocketMessage() (read receipts, unread)
  │           ├── aiEventStream    → _onAiEvent() (ai_token/ai_done)
  │           ├── readStatusStream → _onReadStatusUpdate()
  │           └── recallEventStream → _onMessageRecalled()
  │
  ├── chatActionServiceProvider
  │     └── ChatActionService → pipeline (PersistStep→UploadStep→SyncStep)
  │           └── SyncStep → POST /api/v1/chat/message
  │
  ├── chatViewModelProvider
  │     └── ChatViewModel → DB watchMessages() → reactive UI
  │           ├── performIncrementalSync() → API fetch + saveBatch()
  │           └── loadMore() → pagination
  │
  └── ConversationList (keepAlive)
        └── _onNewMessage() → saves chat_message events to DB
```

- **Send**: REST POST `/api/v1/chat/message` (not Socket.IO), pipeline pattern
- **Receive**: Socket.IO `dispatch` event → `chatMessageStream` / `aiEventStream` → DB → reactive UI
- **AI Reply**: Server sends `ai_token`/`ai_step`/`ai_done` via Socket.IO (NOT SSE)
  - `ai_token` → `ChatViewModel.currentAiToken` → typewriter bubble in UI
  - `ai_done` → `_saveAiMessage()` → DB → stream refreshes message list
- **DB**: sembast, watched via `_dbService.watchMessages()`, drives UI reactivity

### Key Directories

```
lib/
  app/                     — Pages + routing
    page/                  — Screen-level widgets
    routes/                — GoRouter config
  core/                    — Infrastructure
    api/                   — HTTP client, API methods
    services/              — Socket, FCM
      socket/              — SocketService + mixins (chat, contact, notification)
    store/                 — State notifiers (auth, wallet)
    providers/             — Riverpod providers
    config/                — AppConfig, env vars
    network/               — Interceptors
  ui/                      — Reusable UI components
    chat/                  — Chat system
      chat_room/           — ChatPage (+ _logic.dart, _widgets.dart parts)
      components/          — ChatBubble, input bar, bubbles/*
      models/              — ChatUiModel, Conversation, MessageType
      providers/           — ChatRoomController, ChatViewModel, ConversationList
      handlers/            — ChatEventHandler, GlobalChatHandler
      services/            — ChatActionService, pipeline, database
      pipeline/            — PipelineContext, PipelineStep (Persist, Upload, Sync, etc.)
  components/              — Shared widgets
  theme/                   — Design tokens
  utils/                   — Helpers
```

### Conversation Model
- `ConversationType`: direct, group, business, support, ai
- `MessageType`: text(0), image(1), audio(2), video(3), recalled(4), file(5), location(6), ai(8), card(9), system(99)
- `MessageStatus`: sending, success, failed, read, pending

## Code Style

- **File naming**: snake_case (chat_page.dart, chat_room_provider.dart)
- **Class naming**: PascalCase (ChatPage, ChatRoomController)
- **Part files**: `chat_page.dart` = main + `_logic.dart` + `_widgets.dart` for large files
- **Logging**: `debugPrint()` not `print()`
- **Error handling**: `try/catch` + `catchError` on futures, never bare async
- **Riverpod**: `ref.read()` for one-time, `ref.watch()` for reactive, `ref.listen()` for side effects
- **Imports**: relative `../` for intra-module, `package:flutter_app/` for cross-module

## AI Chat (Socket.IO Streaming)

- **Send**: `Api.sendMessage()` → `POST /api/v1/chat/message` — same as regular IM
- **Receive**: Socket.IO `dispatch` → `aiEventStream`
  - `ai_token` → `ChatEventHandler._onAiEvent()` → `ChatViewModel.updateAiToken()` → typewriter bubble
  - `ai_step` → `ChatViewModel.updateAiStatusText()` → step indicator
  - `ai_done` → `_saveAiMessage(content, [messageId], [seqId])` → `LocalDatabaseService.saveAiMessage()` → DB
  - `ai_error` → clear buffer + show error
  - `ai_transfer` → save + show "Transferred to human agent"
- **State**: `ChatListState` fields: `isAiStreaming`, `currentAiToken`, `aiStatusText`
- **Duplication Prevention**: 
  - `SyncStep` saves `seqId` from server response so local records match API
  - `saveMessages()` residual cleanup deletes `seqId=null` orphans during API sync
- **Key files**: `chat_event_handler.dart`, `chat_view_model.dart`, `local_database_service.dart`

## Dependencies (key)

- dio, flutter_riverpod, go_router, socket_io_client, shared_preferences
- flutter_secure_storage, uuid, equatable, sembast
- easy_localization (i18n), flutter_screenutil (responsive)
- rxdart, riverpod_annotation

## Rules (mandatory before coding)

1. Check `docs/current-task.md` (Nest repo) — confirm what to work on
2. Read 2 existing files in the same area to match style and patterns before writing new code
3. Run `dart analyze lib/` before marking done
4. New files must match project naming (snake_case, PascalCase classes)
5. Don't over-abstract — simple `if (conversationId == 'ai_chat')` beats a Transport interface with 2 implementations
