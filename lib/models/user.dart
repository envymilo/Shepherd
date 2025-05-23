class User {
  String? id;
  String? name;
  String? phone;
  String? email;
  String? role;
  String? imageURL;
  DateTime? createDate;
  DateTime? updateDate;
  bool? isDeleted;

  User({
    this.id,
    this.name,
    this.phone,
    this.email,
    this.role,
    this.imageURL,
    this.createDate,
    this.updateDate,
    this.isDeleted,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      role: json['role'],
      imageURL: json['imageURL'],
      createDate: json['createDate'] != null
          ? DateTime.parse(json['createDate'])
          : null,
      updateDate: json['updateDate'] != null
          ? DateTime.parse(json['updateDate'])
          : null,
      isDeleted: json['isDeleted'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
      'imageURL': imageURL,
    };
  }
}
