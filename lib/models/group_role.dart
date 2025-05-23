class GroupRole {
  String groupUserId;
  String groupId;
  String groupName;
  String roleName;

  GroupRole({
    required this.groupUserId,
    required this.groupId,
    required this.groupName,
    required this.roleName,
  });

  factory GroupRole.fromJson(Map<String, dynamic> json) {
    return GroupRole(
      groupUserId: json['groupUserId'],
      groupId: json['groupId'],
      groupName: json['groupName'],
      roleName: json['roleName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupUserId': groupUserId,
      'groupId': groupId,
      'groupName': groupName,
      'roleName': roleName,
    };
  }
}
