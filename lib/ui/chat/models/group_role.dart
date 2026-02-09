import 'package:json_annotation/json_annotation.dart';

enum GroupRole {
  @JsonValue('OWNER')
  owner,

  @JsonValue('ADMIN')
  admin,

  @JsonValue('MEMBER')
  member;

  // who is owner or admin
  bool get isAdminOrOwner => this == GroupRole.owner || this == GroupRole.admin;

  //  who is owner
  bool get isOwner => this == GroupRole.owner;
}