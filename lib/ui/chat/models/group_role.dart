import 'package:json_annotation/json_annotation.dart';

enum GroupRole {
  @JsonValue('OWNER')
  owner(3),// 1. owner 权限最高，拥有所有权限

  @JsonValue('ADMIN')
  admin(2), // 2. admin 权限次之，可以管理成员但不能修改群信息

  @JsonValue('MEMBER')
  member(1); // 3. member 权限最低，只能参与聊天

  final int level;
  const GroupRole(this.level);

  // who is owner or admin
  bool get isAdminOrOwner => this == GroupRole.owner || this == GroupRole.admin;

  //  who is owner
  bool get isOwner => this == GroupRole.owner;

  //  core logic: can I manage the target?
  //  (My Level > Target Level) rules: My Level must be strictly greater than Target Level
  //  True same as: 3 > 2 -> True
  // owner(3) > admin(2) -> True (owner 可以踢 admin) admin(2) > member(1) -> True (admin 可以踢 member) owner(3) > member(1) -> True (owner 可以踢 member)
  bool canManageMembers(GroupRole targetRole){
    return level > targetRole.level;
  }
}