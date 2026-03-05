part of 'group_lobby_page.dart';

mixin GroupLobbyLogic on ConsumerState<GroupLobbyPage> {
  late PageListController<GroupForTreasureItem> listCtl;
  StreamSubscription? _syncSubscription;
  StreamSubscription? _updateSubscription;
  late final SocketService _socketService;

  bool get isGlobalMode => widget.treasureId == null;

  void initLobbyLogic() {
    listCtl = PageListController<GroupForTreasureItem>(
      requestKey: widget.treasureId ?? 'global_group_lobby',
      request: ({required int pageSize, required int page}) {
        final requestFunc = ref.read(groupsPageListProvider(widget.treasureId ?? ''));
        return requestFunc(pageSize: pageSize, page: page);
      },
    );

    _socketService = ref.read(socketServiceProvider);
    _socketService.joinLobby();

    _updateSubscription = _socketService.groupUpdateStream.listen(_handleUpdate);
    _syncSubscription = _socketService.onSyncNeeded.listen((_) {
      if (mounted) {
        debugPrint(' [UI] 网络重连，正在校准数据...');
        listCtl.refresh();
      }
    });
  }

  void _handleUpdate(dynamic data) {
    if (!mounted) return;
    try {
      final String groupId = data['groupId'];
      final int newCount = data['currentMembers'];
      final int status = data['status'];
      final num serverUpdatedAt = data['updatedAt'] ?? 0;

      final currentList = listCtl.value.items;
      final index = currentList.indexWhere((item) => item.groupId == groupId);

      if (index != -1) {
        final currentItem = currentList[index];
        if (currentItem.updatedAt >= serverUpdatedAt) return;

        if (currentItem.currentMembers != newCount || currentItem.groupStatus != status) {
          final newItem = currentItem.copyWith(
            currentMembers: newCount,
            groupStatus: status,
            updatedAt: serverUpdatedAt,
          );

          final newList = List<GroupForTreasureItem>.from(currentList);
          newList[index] = newItem;
          listCtl.value = listCtl.value.copyWith(items: newList);
        }
      }
    } catch (e) {
      debugPrint('[Socket] Error handling group_update: $e');
    }
  }

  void disposeLobbyLogic() {
    _socketService.leaveLobby();
    _updateSubscription?.cancel();
    _syncSubscription?.cancel();
    listCtl.dispose();
  }
}