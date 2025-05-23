class Ceremony {
  final String id;
  final String name;
  final String description;
  final int recursionType;
  final String recursionDate;
  final String? createDate;
  final String? createdBy;
  final String? updateDate;
  final String? updatedBy;
  final int? totalCost;
  final List<ActivityPreset> activityPresets;
  final List<GroupCeremony> groupCeremonies;
  final TimeSlot timeSlot;

  Ceremony({
    required this.id,
    required this.name,
    required this.description,
    required this.recursionType,
    required this.recursionDate,
    this.createDate,
    this.createdBy,
    this.updateDate,
    this.updatedBy,
    this.totalCost,
    required this.activityPresets,
    required this.groupCeremonies,
    required this.timeSlot,
  });

  factory Ceremony.fromJson(Map<String, dynamic> json) {
    return Ceremony(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      recursionType: json['recursionType'],
      recursionDate: json['recursionDate'],
      createDate: json['createDate'],
      createdBy: json['createdBy'],
      updateDate: json['updateDate'],
      updatedBy: json['updatedBy'],
      totalCost:
          json['totalCost'] != null ? (json['totalCost'] as num).toInt() : null,
      activityPresets: (json['activityPresets'] as List)
          .map((item) => ActivityPreset.fromJson(item))
          .toList(),
      groupCeremonies: (json['groupCeremonies'] as List)
          .map((item) => GroupCeremony.fromJson(item))
          .toList(),
      timeSlot: TimeSlot.fromJson(json['timeSlot']),
    );
  }
}

class ActivityPreset {
  final String id;
  final String ceremonyID;
  final String name;
  final String description;
  final String startTime;
  final String endTime;
  final int? totalCost;
  final String createDate;
  final String createdBy;

  ActivityPreset({
    required this.id,
    required this.ceremonyID,
    required this.name,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.totalCost,
    required this.createDate,
    required this.createdBy,
  });

  factory ActivityPreset.fromJson(Map<String, dynamic> json) {
    return ActivityPreset(
      id: json['id'],
      ceremonyID: json['ceremonyID'],
      name: json['name'],
      description: json['description'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      totalCost:
          json['totalCost'] != null ? (json['totalCost'] as num).toInt() : null,
      createDate: json['createDate'],
      createdBy: json['createdBy'],
    );
  }
}

class GroupCeremony {
  final String id;
  final String groupName;
  final String groupID;
  final String ceremonyID;
  final String component;

  GroupCeremony({
    required this.id,
    required this.groupName,
    required this.groupID,
    required this.ceremonyID,
    required this.component,
  });

  factory GroupCeremony.fromJson(Map<String, dynamic> json) {
    return GroupCeremony(
      id: json['id'],
      groupName: json['groupName'],
      groupID: json['groupID'],
      ceremonyID: json['ceremonyID'],
      component: json['component'],
    );
  }
}

class TimeSlot {
  final String id;
  final String startTime;
  final String endTime;
  final String name;
  final String description;
  final bool isAvailable;

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.name,
    required this.description,
    required this.isAvailable,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      name: json['name'],
      description: json['description'],
      isAvailable: json['isAvailable'],
    );
  }
}
