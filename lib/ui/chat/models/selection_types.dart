// 1. 选择模式
enum SelectionMode { single, multiple }

// 2. 实体类型 (为了统一 User 和 Group)
enum EntityType { user, group }

// 3. 统一实体对象 (列表里的一行数据)
class SelectionEntity {
  final String id;
  final String name;
  final String? avatar;
  final EntityType type;
  final String? desc; // 副标题，比如 "群组" 或 "ID: xxx"

  SelectionEntity({
    required this.id,
    required this.name,
    this.avatar,
    required this.type,
    this.desc,
  });

  // 方便判等
  @override
  bool operator ==(Object other) =>
      identical(this, other) || //1.如果是同一个内存对象，直接由真 (性能优化)
          other is SelectionEntity && // 2. 对方必须也是 SelectionEntity 类型
              runtimeType == other.runtimeType &&
              id == other.id; //核心：只要 ID 一样，我就认为你们是同一个东西！

  @override
  int get hashCode => id.hashCode;
}

class ContactSelectionArgs {
  final String title;           // 页面标题 (如 "Forward To", "Add Members")
  final SelectionMode mode;     // 选择模式 (单选 single / 多选 multi)
  final List<String> excludeIds;// 需要排除的人 (比如拉人进群时，不能选已经在群里的人)
  final String? confirmText;    // 多选模式下，右上角确定按钮的文字 (如 "Send", "Invite")

  ContactSelectionArgs({
    this.title = "Select Contact",
    this.mode = SelectionMode.single,
    this.excludeIds = const [],
    this.confirmText,
  });
}
