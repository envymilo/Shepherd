class NotificationModel {
  final String id;
  final String title;
  final String content;
  final DateTime time;
  final String? timeAgo;
  final String type;
  final String? groupId;
  final String? relevantId;
  bool isRead;
  int? taskStatus;
  DateTime? activityStartTime;

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.time,
    this.timeAgo,
    required this.type,
    this.groupId,
    this.relevantId,
    required this.isRead,
    this.taskStatus,
    this.activityStartTime,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      time: DateTime.parse(json['time']),
      timeAgo: json['timeAgo'],
      type: json['type'],
      groupId: json['groupID'],
      relevantId: json['relevantId'],
      isRead: json['isRead'],
      taskStatus: json['taskStatus'],
      activityStartTime: json['activityStartTime'] != null
          ? DateTime.parse(json['activityStartTime'])
          : null,
    );
  }

  @override
  String toString() {
    return 'NotificationModel{id: $id, title: $title, content: $content, time: $time, timeAgo: $timeAgo, type: $type, groupId: $groupId, relevantId: $relevantId, isRead: $isRead}';
  }
}
