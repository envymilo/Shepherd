class Group {
  final String id;
  final String groupName;
  final String description;
  final bool priority;
  final int memberCount;

  Group({
    required this.id,
    required this.groupName,
    required this.description,
    required this.priority,
    required this.memberCount,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
        id: json['id'],
        groupName: json['groupName'],
        description: json['description'],
        priority: json['priority'],
        memberCount: json['memberCount']);
  }
}
