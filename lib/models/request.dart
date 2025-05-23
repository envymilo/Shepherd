import 'package:shepherd_mo/models/event.dart';
import 'package:shepherd_mo/models/group.dart';
import 'package:shepherd_mo/models/user.dart';

class RequestModel {
  final String id;
  final String title;
  final String content;
  final String? type;
  final bool? isAccepted;
  final DateTime createDate;
  final String? createdBy;
  final DateTime updateDate;
  final String? updatedBy;
  final String to;
  final Group? group;
  final Event? event;
  final List<dynamic> reports;
  final User? createdUser;
  final User? updatedUser;

  RequestModel({
    required this.id,
    required this.title,
    required this.content,
    this.type,
    this.isAccepted,
    required this.createDate,
    this.createdBy,
    required this.updateDate,
    this.updatedBy,
    required this.to,
    this.group,
    this.event,
    this.reports = const [],
    this.createdUser,
    this.updatedUser,
  });

  // Factory method for creating an instance from a JSON map
  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      type: json['type'],
      isAccepted: json['isAccepted'],
      createDate: DateTime.parse(json['createDate']),
      createdBy: json['createdBy'],
      updateDate: DateTime.parse(json['updateDate']),
      updatedBy: json['updatedBy'],
      to: json['to'],
      group: json['group'] != null ? Group.fromJson(json['group']) : null,
      event: json['event'] != null ? Event.fromJson(json['event']) : null,
      reports: json['reports'] ?? [],
      createdUser: json['createdUser'] != null
          ? User.fromJson(json['createdUser'])
          : null,
      updatedUser: json['updatedUser'] != null
          ? User.fromJson(json['updatedUser'])
          : null,
    );
  }

  // Method to convert instance to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'isAccepted': isAccepted,
      'createDate': createDate.toIso8601String(),
      'createdBy': createdBy,
      'updateDate': updateDate.toIso8601String(),
      'updatedBy': updatedBy,
      'to': to,
      'group': group,
      'event': event,
      'reports': reports,
      'createdUser': createdUser,
      'updatedUser': updatedUser,
    };
  }
}
