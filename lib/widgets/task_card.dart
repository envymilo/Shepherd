import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shepherd_mo/constant/constant.dart';
import 'package:shepherd_mo/formatter/status_language.dart';
import 'package:shepherd_mo/models/group_role.dart';
import 'package:shepherd_mo/models/task.dart';
import 'package:shepherd_mo/pages/leader/create_edit_task.dart';
import 'package:shepherd_mo/widgets/task_detail_dialog.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final bool showStatus;
  final bool isLeader;
  final String activityId;
  final String activityName;
  final GroupRole group;
  final int? totalCost;

  const TaskCard(
      {super.key,
      required this.task,
      this.showStatus = true, // Defaults to true to show status by default
      this.isLeader = false,
      required this.activityId,
      required this.activityName,
      required this.group,
      this.totalCost});

  @override
  TaskCardState createState() => TaskCardState();
}

class TaskCardState extends State<TaskCard> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;
    final uiProvider = Provider.of<UIProvider>(context);
    bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    String? taskStatus = getTaskStatus(widget.task.status, localizations);

    return Card(
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.008),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        title: Text(
          widget.task.title ?? localizations.noData,
          style: TextStyle(
            fontSize: screenHeight * 0.0165,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description Section
                Text(
                  widget.task.description ?? localizations.noData,
                  style: TextStyle(
                    fontSize: screenHeight * 0.0145,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                // Assigned User Section
                Text(
                  (widget.task.userName != null &&
                          widget.task.status != "Bản nháp")
                      ? '${localizations.assignedTo}: ${widget.task.userName}'
                      : localizations.notAssignedYet,
                  style: TextStyle(
                    fontSize: screenHeight * 0.0125,
                    fontStyle: widget.task.userName == null
                        ? FontStyle.italic
                        : FontStyle.normal,
                    color: isDark
                        ? widget.task.userName == null
                            ? Colors.grey
                            : Colors.white
                        : widget.task.userName == null
                            ? Colors.grey
                            : Colors.black,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                // Display status only if currentStatus is not null and showStatus is true
                if (widget.task.status != null && widget.showStatus)
                  Text(
                    '${localizations.status}: $taskStatus',
                    style: TextStyle(
                        fontSize: screenHeight * 0.0125,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(widget.task.status)),
                  ),
                SizedBox(height: screenHeight * 0.005),
                // Buttons Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (widget.isLeader &&
                        (widget.task.status == "Bản nháp" ||
                            widget.task.status == "Đang chờ"))
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to edit page or allow editing
                          Get.to(
                            () => CreateEditTaskPage(
                              activityId: widget.activityId,
                              activityName: widget.activityName,
                              group: widget.group,
                              task: widget.task,
                              totalCost: widget.totalCost != null
                                  ? widget.totalCost!
                                  : 0,
                            ),
                            id: 2,
                            transition: Transition.rightToLeftWithFade,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                        child: Text(
                          localizations.edit,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    SizedBox(width: screenWidth * 0.02),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to details page or show detailed view
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return TaskDetailsDialog(
                              task: widget.task, // Pass the task object
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Const.primaryGoldenColor,
                      ),
                      child: Text(
                        localizations.details,
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Bản nháp':
        return Colors.blueGrey.shade200;
      case 'Đang chờ':
        return Colors.yellow.shade800;
      case 'Việc cần làm':
        return Colors.red.shade400;
      case 'Đang thực hiện':
        return Colors.orange.shade400;
      case 'Xem xét':
        return Colors.orange.shade400;
      case 'Quá hạn':
        return Colors.deepOrange.shade600;
      case 'Đã hoàn thành':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade500;
    }
  }
}
