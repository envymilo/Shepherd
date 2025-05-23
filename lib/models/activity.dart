import 'package:shepherd_mo/models/event.dart';
import 'package:shepherd_mo/models/group_activity.dart';
import 'package:shepherd_mo/models/group_user.dart';

class Activity {
  String id;
  String? activityName;
  String? description;
  DateTime? startTime;
  DateTime? endTime;
  DateTime? createTime;
  DateTime? updateTime;
  String? status;
  int? totalCost;
  String? location;
  String? imageURL;
  String? comment;
  List<GroupAndUser>? groupAndUsers;
  List<GroupActivity>? groupActivities;
  Event? event;

  Activity(
      {required this.id,
      this.activityName,
      this.description,
      this.startTime,
      this.endTime,
      this.createTime,
      this.updateTime,
      this.status,
      this.totalCost,
      this.location,
      this.imageURL,
      this.comment,
      this.groupAndUsers,
      this.groupActivities,
      this.event});

  // Factory method to create an Activity from a JSON map
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      activityName: json['activityName'] as String,
      description:
          json['description'] != null ? json['description'] as String : null,
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'] as String)
          : null,
      createTime: json['createTime'] != null
          ? DateTime.parse(json['createTime'] as String)
          : null,
      updateTime: json['updateTime'] != null
          ? DateTime.parse(json['updateTime'] as String)
          : null,
      status: json['status'] as String,
      totalCost:
          json['totalCost'] != null ? (json['totalCost'] as num).toInt() : null,
      location: json['location'] != null ? json['location'] as String : null,
      imageURL: json['imageURL'] != null ? json['imageURL'] as String : null,
      comment: json['comment'] != null ? json['comment'] as String : null,
      groupAndUsers: json['groupAndUsers'] != null
          ? (json['groupAndUsers'] as List<dynamic>)
              .map((e) => GroupAndUser.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      groupActivities: json['groupActivities'] != null
          ? (json['groupActivities'] as List<dynamic>)
              .map((e) => GroupActivity.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      event: json['event'] != null ? Event.fromJson(json['event']) : null,
    );
  }

  // Method to convert an Activity instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityName': activityName,
      'description': description,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'createTime': createTime?.toIso8601String(),
      'updateTime': updateTime?.toIso8601String(),
      'status': status,
      'totalCost': totalCost,
    };
  }
}
