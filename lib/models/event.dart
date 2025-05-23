import 'package:shepherd_mo/models/activity.dart';

class Event {
  String? id;
  String? eventName;
  String? ceremonyId;
  String? description;
  DateTime? fromDate;
  DateTime? toDate;
  bool? isPublic;
  String? status;
  int? totalCost;
  DateTime? approvalDate;
  String? approvedBy;
  List<Activity>? activities;
  String? location;
  String? imageURL;

  Event({
    this.id,
    this.eventName,
    this.ceremonyId,
    this.description,
    this.fromDate,
    this.toDate,
    this.isPublic,
    this.status,
    this.totalCost,
    this.approvalDate,
    this.approvedBy,
    this.activities,
    this.location,
    this.imageURL,
  });

  // Factory constructor to parse from JSON (for fetching from API)
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      eventName: json['eventName'],
      ceremonyId: json['ceremonyId'],
      description: json['description'],
      fromDate:
          json['fromDate'] != null ? DateTime.parse(json['fromDate']) : null,
      toDate: json['toDate'] != null ? DateTime.parse(json['toDate']) : null,
      isPublic: json['isPublic'],
      status: json['status'],
      totalCost:
          json['totalCost'] != null ? (json['totalCost'] as num).toInt() : null,
      approvalDate: json['approvalDate'] != null
          ? DateTime.parse(json['approvalDate'])
          : null,
      approvedBy: json['approvedBy'],
      activities: json['activities'] != null
          ? (json['activities'] as List<dynamic>)
              .map((e) => Activity.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      location: json['location'],
      imageURL: json['imageURL'],
    );
  }

  // Method to convert to JSON (for sending to API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventName': eventName,
      'ceremonyId': ceremonyId,
      'description': description,
      'fromDate': fromDate?.toIso8601String(),
      'toDate': toDate?.toIso8601String(),
      'isPublic': isPublic,
      'status': status,
      'totalCost': totalCost,
      'approvalDate': approvalDate?.toIso8601String(),
      'approvedBy': approvedBy,
    };
  }

  @override
  String toString() {
    return '''
Event Details:
  ID: $id
  Name: $eventName
  Ceremony ID: $ceremonyId
  Description: $description
  From Date: ${fromDate != null ? fromDate.toString() : 'N/A'}
  To Date: ${toDate != null ? toDate.toString() : 'N/A'}
  Is Public: ${isPublic != null ? (isPublic! ? 'Yes' : 'No') : 'N/A'}
  Status: $status
  Total Cost: ${totalCost != null ? '$totalCost VND' : 'N/A'}
  Approval Date: ${approvalDate != null ? approvalDate.toString() : 'N/A'}
  Approved By: $approvedBy
    ''';
  }
}
