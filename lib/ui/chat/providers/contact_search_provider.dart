import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/repositories/contact_repository.dart';
import '../models/conversation.dart'; // ChatUser 模型

// 1. 保存用户输入的关键词
final searchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

// 2. 核心：监听关键词变化 -> 自动触发搜索 -> 返回结果
// autoDispose: 退出页面时自动销毁数据，下次进来是空的
final contactSearchResultsProvider = FutureProvider.autoDispose<List<ChatUser>>((ref) async {
  // 监听关键词
  final query = ref.watch(searchQueryProvider);

  // 监听仓库
  final repository = ref.watch(contactRepositoryProvider);

  // 如果没输入，或者是空字符串，直接返回空列表
  if (query.trim().isEmpty) {
    return [];
  }

  //  调用底层 Sembast 的倒排索引搜索
  // 哪怕你有 10000 个好友，这里也是毫秒级返回
  return await repository.search(query);
});