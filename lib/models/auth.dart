import 'package:shepherd_mo/models/group_role.dart';
import 'package:shepherd_mo/models/user.dart';

class LoginResponseModel {
  String token;
  String? errorMessage;
  bool success;
  User? user;
  String? message;
  String? isActive;
  List<GroupRole>? listGroupRole;

  LoginResponseModel({
    required this.token,
    this.errorMessage,
    required this.success,
    this.user,
    this.message,
    this.isActive,
    this.listGroupRole,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      token: json['data']['token'],
      errorMessage: json['errorMessage'],
      success: json['success'],
      user: json['data']['user'] != null
          ? User.fromJson(json['data']['user'])
          : null,
      message: json['data']['message'],
      isActive: json['data']['isActive'],
      listGroupRole: json['data']['listGroupRole'] != null
          ? (json['data']['listGroupRole'] as List)
              .map((item) => GroupRole.fromJson(item))
              .toList()
          : null,
    );
  }
}

class LoginRequestModel {
  String? username;
  String? password;

  LoginRequestModel({this.username, this.password});

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'username': username?.trim(),
      'password': password?.trim(),
    };
    return map;
  }
}

class RegisterResponseModel {
  String token;
  final String? errorMessage;

  RegisterResponseModel({
    required this.token,
    this.errorMessage,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      token: json['token'],
    );
  }
}

class RegisterRequestModel {
  String? email;
  String? password;
  String? phone;

  RegisterRequestModel({this.email, this.password});

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'Email': email?.trim(),
      'Password': password?.trim(),
      'Phone': phone?.trim(),
    };
    return map;
  }
}
