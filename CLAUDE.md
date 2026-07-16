# JoyMini Flutter App

## Stack

- Flutter 3.10+ (Dart 3.x)
- State: Riverpod (StateNotifierProvider.family)
- HTTP: Dio (ResponseType.stream for SSE)
- Routing: GoRouter + ShellRoute (bottom tabs)
- Real-time: socket_io_client (Socket.IO)
- Persistence: sqflite (local messages), SharedPreferences (settings)
- Auth: JWT + flutter_secure_storage

## Architecture

### State Management
- `StateNotifier` + `Provider.family` for scoped state (by conversationId etc.)
- `@Riverpod(keepAlive: true)` for singletons (socket, auth, conversation list)
- `.autoDispose` for page-scoped providers (chat room, view model)

### Chat System (Core)
```
ChatPage(conversationId)
  ├── Socket.IO path (default):
  │     chatControllerProvider → ChatRoomController → ChatEventHandler → SocketService
  │     chatActionServiceProvider → pipeline → SyncStep (REST POST /api/v1/chat/message)
  │     chatViewModelProvider → DB watchMessages() → reactive UI
  │
  └── SSE path (conversationId == 'ai_chat'):
        aiChatViewModelProvider → SseClient → SSE stream
        token events → in-memory state → done → DB persist
```

- **Send**: REST POST (not Socket.IO), pipeline pattern (PersistStep → UploadStep → SyncStep)
- **Receive**: Socket.IO chatMessageStream → GlobalChatHandler → DB → reactive UI
- **DB**: sqflite, watched via `_dbService.watchMessages()`, drives UI reactivity

### Key Directories

```
lib/
  app/                     — Pages + routing
    page/                  — Screen-level widgets
    routes/                — GoRouter config
  core/                    — Infrastructure
    api/                   — HTTP client, API methods
    services/              — Socket, FCM, AI (SseClient)
    store/                 — State notifiers (auth, wallet, ai_chat)
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
  components/              — Shared widgets
  theme/                   — Design tokens
  utils/                   — Helpers
```

### Conversation Model
- `ConversationType`: direct, group, business, support
- `MessageType`: text, image, audio, video, file, location, ai(8), card(9), system(99)
- `MessageStatus`: sending, success, failed, read, pending

## Code Style

- **File naming**: snake_case (chat_page.dart, chat_room_provider.dart)
- **Class naming**: PascalCase (ChatPage, ChatRoomController)
- **Part files**: `chat_page.dart` = main + `_logic.dart` + `_widgets.dart` for large files
- **Logging**: `debugPrint()` not `print()`
- **Error handling**: `try/catch` + `catchError` on futures, never bare async
- **Riverpod**: `ref.read()` for one-time, `ref.watch()` for reactive, `ref.listen()` for side effects
- **Imports**: relative `../` for intra-module, `package:flutter_app/` for cross-module

## AI Chat SSE Integration

- Backend: `POST /api/v1/ai/customer/chat-stream` (Bearer token)
- Client: `core/services/ai/sse_client.dart` — Dio stream + line buffer + SseEvent
- State: `core/store/ai_chat/ai_chat_state.dart` + `ai_chat_view_model.dart`
- Integration plan: `docs/AI-joymini/67-AI-Chat-ChatPage-Integration-Plan.md` (Nest repo)

## Dependencies (key)

- dio, flutter_riverpod, go_router, socket_io_client, shared_preferences
- flutter_secure_storage, uuid, equatable, sqflite
- easy_localization (i18n), flutter_screenutil (responsive)

## Rules (mandatory before coding)

1. Check `docs/current-task.md` (Nest repo) — confirm what to work on
2. Read 2 existing files in the same area to match style and patterns before writing new code
3. Run `dart analyze lib/` before marking done
4. New files must match project naming (snake_case, PascalCase classes)
5. Don't over-abstract — simple `if (conversationId == 'ai_chat')` beats a Transport interface with 2 implementations
