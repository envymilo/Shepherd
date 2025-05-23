import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shepherd_mo/api/api_service.dart';
import 'package:shepherd_mo/controller/controller.dart';
import 'package:shepherd_mo/formatter/custom_currency_format.dart';
import 'package:shepherd_mo/models/group_role.dart';
import 'package:shepherd_mo/models/task.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shepherd_mo/models/user.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';
import 'package:shepherd_mo/services/get_login.dart';
import 'package:shepherd_mo/utils/toast.dart';

class TaskDetailsDialog extends StatelessWidget {
  final Task task; // Replace 'Task' with your task model class
  final Function(Task)? onTaskUpdated;

  const TaskDetailsDialog({super.key, required this.task, this.onTaskUpdated});

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> checkIsLeader() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final loginUserGroupsJson = prefs.getString('loginUserGroups');

    if (loginUserGroupsJson != null) {
      List<dynamic> decodedJson = jsonDecode(loginUserGroupsJson);
      List<GroupRole> loginUserGroupsList = decodedJson
          .map((item) => GroupRole.fromJson(item as Map<String, dynamic>))
          .toList();

      final groupRole = loginUserGroupsList
          .firstWhere((groupRole) => groupRole.groupId == task.groupId);
      final leader = dotenv.env['LEADER'] ?? "";
      return groupRole.roleName == leader;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final uiProvider = Provider.of<UIProvider>(context);
    bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    double screenHeight = MediaQuery.of(context).size.height;
    final apiService = ApiService();
    final RefreshController refreshController = Get.find();

    return FutureBuilder<User?>(
      future: getLoginInfoFromPrefs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(localizations.errorOccurred));
        } else {
          final user = snapshot.data;
          return FutureBuilder<bool>(
            future: checkIsLeader(),
            builder: (context, isLeaderSnapshot) {
              if (isLeaderSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (isLeaderSnapshot.hasError) {
                return Center(child: Text(localizations.errorOccurred));
              } else {
                final isLeader = isLeaderSnapshot.data ?? false;

                return AlertDialog(
                  title: Text(
                    task.title ?? localizations.noData,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task.description ?? localizations.noData),
                      SizedBox(height: screenHeight * 0.0165),

                      // Status Row
                      _buildDetailRow("${localizations.status}: ",
                          task.status ?? localizations.noData, isDark),

                      // Assigned to Row
                      _buildDetailRow(
                          "${localizations.assignedTo}: ",
                          task.status != "Bản nháp"
                              ? task.userName ?? localizations.notAssignedYet
                              : localizations.notAssignedYet,
                          isDark),

                      // Cost Row
                      _buildDetailRow("${localizations.totalCost}: ",
                          "${formatCurrency(task.cost!)} VND", isDark),
                    ],
                  ),
                  actions: [
                    if (task.status == 'Đang chờ' &&
                        task.userId == user!.id) ...[
                      ElevatedButton(
                        onPressed: () async {
                          // Handle accept task logic
                          final success =
                              await apiService.confirmTask(task.id!, true);
                          if (success) {
                            showToast(
                                '${localizations.confirmTask} ${localizations.success.toLowerCase()}');

                            refreshController.setShouldRefresh(true);
                            Navigator.of(context).pop();
                          } else {
                            showToast(
                                '${localizations.confirmTask} ${localizations.unsuccess.toLowerCase()}');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text(
                          localizations.accept,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // Handle reject task logic
                          final success =
                              await apiService.confirmTask(task.id!, false);
                          if (success) {
                            showToast(
                                '${localizations.declineTask} ${localizations.success.toLowerCase()}');

                            refreshController.setShouldRefresh(true);
                            Navigator.of(context).pop();
                          } else {
                            showToast(
                                '${localizations.declineTask} ${localizations.unsuccess.toLowerCase()}');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text(
                          localizations.decline,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    if (task.status == 'Xem xét' && isLeader) ...[
                      ElevatedButton(
                        onPressed: () async {
                          // Handle accept task logic
                          final success = await apiService.updateTaskStatus(
                              task, "Đã hoàn thành");
                          if (success) {
                            task.status = "Đã hoàn thành";
                            if (onTaskUpdated != null) {
                              onTaskUpdated?.call(task);
                            } else {
                              refreshController.setShouldRefresh(true);
                            }
                            showToast(
                                "${localizations.updateProgress} ${localizations.success.toLowerCase()}");
                            Navigator.of(context).pop();
                          } else {
                            showToast(
                                "${localizations.updateProgress} ${localizations.unsuccess.toLowerCase()}");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: Text(
                          localizations.approve,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          // Handle reject task logic
                          final success = await apiService.updateTaskStatus(
                              task, "Đang thực hiện");
                          if (success) {
                            task.status = "Đang thực hiện";
                            if (onTaskUpdated != null) {
                              onTaskUpdated?.call(task);
                            } else {
                              refreshController.setShouldRefresh(true);
                            }
                            showToast(
                                "${localizations.updateProgress} ${localizations.success.toLowerCase()}");
                            Navigator.of(context).pop();
                          } else {
                            showToast(
                                "${localizations.updateProgress} ${localizations.unsuccess.toLowerCase()}");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text(
                          localizations.reject,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(localizations.close),
                    ),
                  ],
                );
              }
            },
          );
        }
      },
    );
  }
}
