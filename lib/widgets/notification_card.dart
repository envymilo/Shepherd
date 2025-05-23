import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shepherd_mo/api/api_service.dart';
import 'package:shepherd_mo/controller/controller.dart';
import 'package:shepherd_mo/models/group_role.dart';
import 'package:shepherd_mo/models/notification.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shepherd_mo/pages/home_page.dart';
import 'package:shepherd_mo/pages/leader/request_page.dart';
import 'package:shepherd_mo/pages/leader/task_management_page.dart';
import 'package:shepherd_mo/pages/task_page.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';
import 'package:shepherd_mo/services/get_login.dart';
import 'package:shepherd_mo/utils/toast.dart';
import 'package:shepherd_mo/widgets/task_detail_dialog.dart';

class NotificationCard extends StatefulWidget {
  final NotificationModel notification;
  final Function(NotificationModel) onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onDelete,
  });

  @override
  NotificationCardState createState() => NotificationCardState();
}

class NotificationCardState extends State<NotificationCard> {
  List<GroupRole>? userGroups;
  final Stream<DateTime> _realTimeStream = Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
  bool isAuthorized = false;

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> initializeData() async {
    final userGroupInfo = await _loadUserGroupInfo();
    setState(() {
      userGroups = userGroupInfo;
    });
    _getUserRole();
  }

  void _getUserRole() async {
    final checkRole = await checkUserRoles();
    setState(() {
      isAuthorized = checkRole;
    });
  }

  Future<List<GroupRole>> _loadUserGroupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userGroups = prefs.getString("loginUserGroups");
    if (userGroups != null) {
      final decodedJson = jsonDecode(userGroups) as List<dynamic>;
      return decodedJson
          .map((item) => GroupRole.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  // Function to get the appropriate icon for the notification type
  IconData getTypeIcon(String type) {
    switch (type) {
      case 'Task':
        return Icons.task;
      case 'Group':
        return Icons.people;
      case 'GroupUser':
        return Icons.person;
      case 'Event':
        return Icons.event;
      case 'Activity':
        return Icons.wysiwyg;
      case 'Transaction':
        return Icons.attach_money;
      case 'Request':
        return Icons.request_page;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    final apiService = ApiService();
    final NotificationController notificationController =
        Get.find<NotificationController>();

    final uiProvider = Provider.of<UIProvider>(context);
    bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    Color cardColor = widget.notification.isRead
        ? isDark
            ? Colors.grey[900]!
            : const Color.fromARGB(255, 230, 236, 239)
        : isDark
            ? Colors.blue[900]!.withOpacity(0.4)
            : const Color.fromARGB(255, 192, 224, 250);

    final localizations = AppLocalizations.of(context)!;
    final String leader = dotenv.env['LEADER'] ?? '';
    final String groupAccountant = dotenv.env['GROUPACCOUNTANT'] ?? '';

    // Function to format the time duration
    String formatTimeAgo(DateTime pastTime, DateTime currentTime) {
      final language = localizations.localeName;
      Duration duration = currentTime.difference(pastTime);

      int days = duration.inDays.abs();
      int hours = duration.inHours.remainder(24).abs();
      int minutes = duration.inMinutes.remainder(60).abs();
      int seconds = duration.inSeconds.remainder(60).abs();
      int weeks = days ~/ 7;

      // Pluralization logic for English
      String dayLabel = (language == 'en' && days > 1)
          ? '${localizations.day}s'
          : localizations.day;
      String hourLabel = (language == 'en' && hours > 1)
          ? '${localizations.hour}s'
          : localizations.hour;
      String minuteLabel = (language == 'en' && minutes > 1)
          ? '${localizations.minute}s'
          : localizations.minute;
      String secondLabel = (language == 'en' && seconds > 1)
          ? '${localizations.second}s'
          : localizations.second;
      String weekLabel = (language == 'en' && weeks > 1)
          ? '${localizations.week}s'
          : localizations.week;

      // Logic to display the time ago format
      if (weeks > 0) {
        return '$weeks $weekLabel ${localizations.ago}';
      } else if (days > 1) {
        return '$days $dayLabel ${localizations.ago}';
      } else if (days == 1) {
        return '1 $dayLabel ${localizations.ago}';
      } else if (hours > 0) {
        return '$hours $hourLabel ${localizations.ago}';
      } else if (minutes > 0) {
        return '$minutes $minuteLabel ${localizations.ago}';
      } else if (seconds > 0) {
        return '$seconds $secondLabel ${localizations.ago}';
      } else {
        return localizations.justNow; // 'Just now' for very recent times
      }
    }

    if (userGroups == null) {
      return SizedBox.shrink();
    }
    bool isLeader = false;
    if (widget.notification.groupId != null &&
        widget.notification.type == "Task") {
      final userGroup = userGroups!
          .firstWhere((group) => group.groupId == widget.notification.groupId);
      isLeader =
          userGroup.roleName == leader || userGroup.roleName == groupAccountant;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.005),
      child: ElevatedButton(
        onPressed: () async {
          if (!widget.notification.isRead) {
            await apiService.readNoti(widget.notification.id, true);
            notificationController.fetchUnreadCount();
            setState(() {
              widget.notification.isRead = true;
            });
          }

          // Executes the callback if provided
          if (widget.notification.type == "Task") {
            if (widget.notification.taskStatus == 0 ||
                widget.notification.taskStatus == 1 ||
                isLeader) {
              final task = await apiService.fetchTaskDetail(
                  id: widget.notification.relevantId!);
              final BottomNavController bottomNavController =
                  Get.find<BottomNavController>();

              if (bottomNavController.selectedIndex.value != 2) {
                bottomNavController.changeTabIndex(2);
              }

              if (notificationController.openTabIndex.value == 2) {
                notificationController.closeNotificationPage();
              }

              // Navigate to ActivitiesTab
              Get.to(
                () => ActivitiesTab(
                  chosenDate: widget.notification.activityStartTime,
                ),
                id: 2,
                transition: Transition.fade,
              );
              final userGroup = userGroups!
                  .firstWhere((group) => group.groupId == task.groupId);

              final isLeader = userGroup.roleName == leader ||
                  userGroup.roleName == groupAccountant;

              // Navigate to the appropriate Task Page
              Get.to(
                  () => isLeader
                      ? TaskManagementPage(
                          activityId: task.activityId!,
                          activityName: task.activityName!,
                          group: userGroup,
                        )
                      : TaskPage(
                          activityId: task.activityId!,
                          activityName: task.activityName!,
                          group: userGroup,
                        ),
                  id: 2,
                  transition: Transition.rightToLeftWithFade,
                  routeName: isLeader ? "/TaskManagementPage" : "/TaskPage");

              // Show dialog after both navigations
              showDialog(
                context: context,
                builder: (context) {
                  return TaskDetailsDialog(
                    task: task,
                  );
                },
              );
            }
          } else if (widget.notification.type == "Request") {
            final isLeader = await checkGroupUserRoles();
            if (isLeader || isAuthorized) {
              final BottomNavController bottomNavController =
                  Get.find<BottomNavController>();

              if (bottomNavController.selectedIndex.value != 0) {
                bottomNavController.changeTabIndex(0);
              }

              if (notificationController.openTabIndex.value == 0) {
                notificationController.closeNotificationPage();
              }

              // Navigate to HomeTab
              Get.to(
                () => HomeTab(),
                id: 0,
                transition: Transition.fade,
              );
              // Navigate to Request

              Get.to(
                () => RequestList(),
                id: 0,
                transition: Transition.fade,
              );
            }
          } else if (widget.notification.type == "Transaction" &&
              isAuthorized) {
            // navigate to churchbudget screen
          }
        },
        onLongPress: () {
          showNotiBottomSheet(
              context, localizations, apiService, notificationController);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: cardColor, // Button color
          elevation: 4, // Elevation to create depth
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenHeight * 0.012),
          ),
          padding: EdgeInsets.only(
            top: screenHeight * 0.01,
            bottom: screenHeight * 0.01,
            left: screenHeight * 0.015,
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Type Icon
              Container(
                alignment: Alignment.center,
                child: Container(
                  padding: EdgeInsets.all(screenHeight * 0.012),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.blue[800] : Colors.blue[200],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    getTypeIcon(widget.notification.type),
                    color: isDark ? Colors.white : Colors.black,
                    size: screenHeight * 0.028,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              // Notification Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.notification.title,
                      style: TextStyle(
                        fontSize: screenHeight * 0.018,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    // Content
                    Text(
                      widget.notification.content,
                      style: TextStyle(
                        fontSize: screenHeight * 0.015,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    // Time
                    StreamBuilder<DateTime>(
                      stream: _realTimeStream,
                      builder: (context, snapshot) {
                        String formattedDuration = snapshot.hasData
                            ? formatTimeAgo(
                                widget.notification.time, snapshot.data!)
                            : formatTimeAgo(
                                widget.notification.time, DateTime.now());

                        return Text(
                          formattedDuration,
                          style: TextStyle(
                            fontSize: screenHeight * 0.0125,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          textAlign: TextAlign.end,
                        );
                      },
                    ),
                    if (!isLeader) ...[
                      if (widget.notification.type == 'Task' &&
                          widget.notification.taskStatus != null) ...[
                        if (widget.notification.taskStatus == 0) ...[
                          // Task not confirmed, show buttons (Accept / Decline)
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.005),
                            child: Row(
                              children: [
                                // Confirm Button
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      if (!widget.notification.isRead) {
                                        await apiService.readNoti(
                                            widget.notification.id, true);

                                        notificationController
                                            .fetchUnreadCount();
                                      }
                                      // Handle accept task logic
                                      final success =
                                          await apiService.confirmTask(
                                              widget.notification.relevantId!,
                                              true);
                                      if (success) {
                                        if (!widget.notification.isRead) {}
                                        showToast(
                                            '${localizations.confirmTask} ${localizations.success.toLowerCase()}');
                                        setState(() {
                                          widget.notification.taskStatus = 1;
                                          widget.notification.isRead = true;
                                        });
                                        notificationController
                                            .shouldReload.value = true;
                                      } else {
                                        showToast(
                                            '${localizations.confirmTask} ${localizations.unsuccess.toLowerCase()}');
                                      }
                                    },
                                    icon:
                                        Icon(Icons.check, color: Colors.white),
                                    label: Text(
                                      localizations.accept,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            screenHeight * 0.008),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          vertical: screenHeight * 0.005),
                                      elevation: 5,
                                    ),
                                  ),
                                ),

                                // Optional space between the buttons
                                SizedBox(width: screenWidth * 0.025),

                                // Decline Button
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      if (!widget.notification.isRead) {
                                        await apiService.readNoti(
                                            widget.notification.id, true);
                                        notificationController
                                            .fetchUnreadCount();
                                      }

                                      // Handle reject task logic
                                      final success =
                                          await apiService.confirmTask(
                                              widget.notification.relevantId!,
                                              false);
                                      if (success) {
                                        showToast(
                                            '${localizations.declineTask} ${localizations.success.toLowerCase()}');
                                        setState(() {
                                          widget.notification.taskStatus = 2;
                                          widget.notification.isRead = true;
                                        });
                                        notificationController
                                            .shouldReload.value = true;
                                      } else {
                                        showToast(
                                            '${localizations.declineTask} ${localizations.unsuccess.toLowerCase()}');
                                      }
                                    },
                                    icon:
                                        Icon(Icons.close, color: Colors.white),
                                    label: Text(
                                      localizations.decline,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            screenHeight * 0.008),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          vertical: screenHeight * 0.005),
                                      elevation: 5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (widget.notification.taskStatus == 1) ...[
                          // Task is accepted, show text
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.005),
                            child: Text(
                              localizations
                                  .taskAccepted, // "Task Accepted" message
                              style: TextStyle(
                                fontSize: screenHeight * 0.015,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ] else if (widget.notification.taskStatus == 2) ...[
                          // Task is rejected, show text
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.005),
                            child: Text(
                              localizations
                                  .taskDeclined, // "Task Declined" message
                              style: TextStyle(
                                fontSize: screenHeight * 0.015,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ] else if (widget.notification.taskStatus == 3) ...[
                          // Task is assigned to another person, show text
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: screenHeight * 0.005),
                            child: Text(
                              localizations
                                  .taskAssignedToAnother, // "Task Assigned to Another" message
                              style: TextStyle(
                                  fontSize: screenHeight * 0.015,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey),
                            ),
                          ),
                        ],
                      ]
                    ],
                  ],
                ),
              ),
              // Menu Icon Button (for actions)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: Icon(Icons.more_horiz,
                      color: isDark ? Colors.white : Colors.black),
                  onPressed: () {
                    // Handle menu action here (e.g., show a menu, etc.)
                    showNotiBottomSheet(context, localizations, apiService,
                        notificationController);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<dynamic> showNotiBottomSheet(
      BuildContext context,
      AppLocalizations localizations,
      ApiService apiService,
      NotificationController notificationController) async {
    final modalController = Get.find<ModalStateController>();
    modalController.openModal();
    try {
      return await showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        builder: (context) => Consumer<UIProvider>(
          builder: (context, UIProvider notifier, child) {
            bool isDark = notifier.themeMode == ThemeMode.dark ||
                (MediaQuery.of(context).platformBrightness == Brightness.dark);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
                // Mark as Read
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                    child: Icon(
                        widget.notification.isRead
                            ? Icons.mark_chat_unread_rounded
                            : Icons.mark_chat_read_rounded,
                        color: Colors.blue),
                  ),
                  title: Text(widget.notification.isRead
                      ? localizations.markAsUnread
                      : localizations.markAsRead),
                  onTap: () async {
                    await apiService.readNoti(
                        widget.notification.id, !widget.notification.isRead);
                    notificationController.fetchUnreadCount();

                    setState(() {
                      widget.notification.isRead = !widget.notification.isRead;
                    });

                    Navigator.pop(context); // Close the bottom sheet
                  },
                ),
                // Delete Notification
                ListTile(
                  leading: CircleAvatar(
                      backgroundColor:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                      child: Icon(Icons.delete, color: Colors.red)),
                  title: Text(localizations.deleteNoti),
                  onTap: () {
                    widget.onDelete(widget.notification);
                    showToast(
                        "${localizations.delete} ${localizations.notification.toLowerCase()} ${localizations.success}");
                    Navigator.pop(context); // Close the bottom sheet
                  },
                ),
                // Other actions
              ],
            );
          },
        ),
      );
    } finally {
      // Ensure the modal state is reset when the modal closes
      modalController.closeModal();
    }
  }
}
