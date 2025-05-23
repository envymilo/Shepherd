class GroupAndUser {
  final String id;
  final String groupActivityId;
  final String groupID;
  final String userID;
  final String groupName;
  final String groupDescription;
  final bool priority;
  final String groupRole;
  final String groupStatus;

  GroupAndUser({
    required this.id,
    required this.groupActivityId,
    required this.groupID,
    required this.userID,
    required this.groupName,
    required this.groupDescription,
    required this.priority,
    required this.groupRole,
    required this.groupStatus,
  });

  // Factory method to create an instance from JSON
  factory GroupAndUser.fromJson(Map<String, dynamic> json) {
    return GroupAndUser(
      id: json['id'],
      groupActivityId: json['groupActivityId'],
      groupID: json['groupID'],
      userID: json['userID'],
      groupName: json['groupName'],
      groupDescription: json['groupDescription'],
      priority: json['priority'],
      groupRole: json['groupRole'],
      groupStatus: json['groupStatus'],
    );
  }

  // Method to convert the instance back to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupActivityId': groupActivityId,
      'groupID': groupID,
      'userID': userID,
      'groupName': groupName,
      'groupDescription': groupDescription,
      'priority': priority,
      'groupRole': groupRole,
      'groupStatus': groupStatus,
    };
  }
}
