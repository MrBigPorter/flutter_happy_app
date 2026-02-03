part of 'socket_service.dart';

mixin SocketLobbyMixin on _SocketBase {
  void joinLobby() { if (isConnected) socket!.emit(SocketEvents.joinLobby); }
  void leaveLobby() { if (isConnected) socket!.emit(SocketEvents.leaveLobby); }
}