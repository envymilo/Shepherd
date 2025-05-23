import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shepherd_mo/models/group_role.dart';
import 'package:shepherd_mo/models/user.dart';

Future<User?> getLoginInfoFromPrefs() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final loginInfoJson = prefs.getString('loginInfo');
  if (loginInfoJson != null) {
    final loginInfo = User.fromJson(jsonDecode(loginInfoJson));
    return loginInfo;
  }
  return null;
}

Future<bool> isUserLoggedIn() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final loginInfo = prefs.getString('loginInfo');
  return loginInfo != null;
}

Future<bool> checkUserRoles() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Retrieve JSON strings from SharedPreferences
  String? loginInfoJson = prefs.getString('loginInfo');

  // Check for roles in loginInfo
  if (loginInfoJson != null) {
    final loginInfo = User.fromJson(jsonDecode(loginInfoJson));
    final String admin = dotenv.env['ADMIN'] ?? '';
    final String priest = dotenv.env['PRIEST'] ?? '';
    final String accountant = dotenv.env['ACCOUNTANT'] ?? '';
    final String council = dotenv.env['COUNCIL'] ?? '';

    if (loginInfo.role == admin ||
        loginInfo.role == priest ||
        loginInfo.role == accountant ||
        loginInfo.role == council) {
      return true;
    }
  }
  return false; // No specified roles found
}

Future<bool> checkGroupUserRoles() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Retrieve JSON string from SharedPreferences
  final loginUserGroupsJson = prefs.getString('loginUserGroups');

  // Check for roles in loginUserGroups
  if (loginUserGroupsJson != null) {
    // Decode JSON string to a list of maps
    List<dynamic> decodedJson = jsonDecode(loginUserGroupsJson);

    // Convert each map into a GroupRole instance
    List<GroupRole> loginUserGroupsList = decodedJson
        .map((item) => GroupRole.fromJson(item as Map<String, dynamic>))
        .toList();
    final String leader = dotenv.env['LEADER'] ?? '';
    final String accountant = dotenv.env['GROUPACCOUNTANT'] ?? '';

    final isLeader = loginUserGroupsList.any((userGroup) =>
        (userGroup.roleName == leader || userGroup.roleName == accountant));
    return isLeader;
  }

  return false; // No specified roles found
}
