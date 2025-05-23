import 'package:shepherd_mo/models/activity.dart';
import 'package:shepherd_mo/models/group.dart';
import 'package:shepherd_mo/models/task.dart';

class GroupActivity {
  String? id;
  String? groupID;
  String? activityID;
  String? groupName;
  String? description;
  int? cost;
  DateTime? createDate;
  String? createdBy;
  DateTime? updateDate;
  String? updatedBy;
  bool? isDeleted;
  Group? group;
  Activity? activity;
  List<Task>? tasks;

  GroupActivity({
    this.id,
    this.groupID,
    this.activityID,
    this.groupName,
    this.description,
    this.cost,
    this.createDate,
    this.createdBy,
    this.updateDate,
    this.updatedBy,
    this.isDeleted,
    this.group,
    this.activity,
    this.tasks,
  });

  // From JSON constructor
  factory GroupActivity.fromJson(Map<String, dynamic> json) {
    return GroupActivity(
      id: json['id'] as String?,
      groupID: json['groupID'] as String?,
      activityID: json['activityID'] as String?,
      groupName: json['groupName'] as String?,
      description: json['description'] as String?,
      cost: json['cost'] != null ? (json['cost'] as num).toInt() : null,
      createDate: json['createDate'] != null
          ? DateTime.parse(json['createDate'] as String)
          : null,
      createdBy: json['createdBy'] as String?,
      updateDate: json['updateDate'] != null
          ? DateTime.parse(json['updateDate'] as String)
          : null,
      updatedBy: json['updatedBy'] as String?,
      isDeleted: json['isDeleted'] as bool?,
      group: json['group'] != null ? Group.fromJson(json['group']) : null,
      activity:
          json['activity'] != null ? Activity.fromJson(json['activity']) : null,
      tasks: json['tasks'] != null
          ? (json['tasks'] as List<dynamic>)
              .map((e) => Task.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (groupID != null) 'groupID': groupID,
      if (activityID != null) 'activityID': activityID,
      if (description != null) 'description': description,
      if (cost != null) 'cost': cost,
      if (createDate != null) 'createDate': createDate!.toIso8601String(),
      if (createdBy != null) 'createdBy': createdBy,
      if (updateDate != null) 'updateDate': updateDate!.toIso8601String(),
      if (updatedBy != null) 'updatedBy': updatedBy,
      if (isDeleted != null) 'isDeleted': isDeleted,
      if (group != null) 'group': group,
      if (activity != null) 'activity': activity,
      if (tasks != null) 'tasks': tasks,
    };
  }

  // Debugging string representation
  @override
  String toString() {
    return 'GroupActivity(id: $id, groupID: $groupID, activityID: $activityID, '
        'description: $description, cost: $cost, createDate: $createDate, '
        'createdBy: $createdBy, updateDate: $updateDate, updatedBy: $updatedBy, '
        'isDeleted: $isDeleted, group: $group, activity: $activity, tasks: $tasks)';
  }
}
