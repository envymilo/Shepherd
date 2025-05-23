class GroupMember {
  final String id;
  final String groupID;
  final String userID;
  final String name;
  final String phone;
  final String email;
  final String groupRole;
  final String status;
  final String description;
  final DateTime createDate;
  final String? createdBy;
  final DateTime? updateDate;
  final String? updatedBy;

  GroupMember({
    required this.id,
    required this.groupID,
    required this.userID,
    required this.name,
    required this.phone,
    required this.email,
    required this.groupRole,
    required this.status,
    required this.description,
    required this.createDate,
    this.createdBy,
    this.updateDate,
    this.updatedBy,
  });

  // Factory constructor to create a GroupMember instance from JSON
  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'],
      groupID: json['groupID'],
      userID: json['userID'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      groupRole: json['groupRole'],
      status: json['status'],
      description: json['description'],
      createDate: DateTime.parse(json['createDate']),
      createdBy: json['createdBy'],
      updateDate: json['updateDate'] != null
          ? DateTime.parse(json['updateDate'])
          : null,
      updatedBy: json['updatedBy'],
    );
  }

  // Method to convert a GroupMember instance to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupID': groupID,
      'userID': userID,
      'name': name,
      'phone': phone,
      'email': email,
      'groupRole': groupRole,
      'status': status,
      'description': description,
      'createDate': createDate.toIso8601String(),
      'createdBy': createdBy,
      'updateDate': updateDate?.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }
}
