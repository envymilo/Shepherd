import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shepherd_mo/constant/constant.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shepherd_mo/controller/controller.dart';
import 'package:shepherd_mo/formatter/custom_currency_format.dart';
import 'package:shepherd_mo/models/activity.dart';
import 'package:shepherd_mo/models/group_activity.dart';
import 'package:shepherd_mo/models/group_role.dart';
import 'package:shepherd_mo/pages/home_page.dart';
import 'package:shepherd_mo/pages/leader/task_management_page.dart';
import 'package:shepherd_mo/pages/task_page.dart';

class GroupExpandableCard extends StatelessWidget {
  const GroupExpandableCard({
    super.key,
    required this.group,
    required this.screenHeight,
    required this.isDark,
    required this.screenWidth,
    required this.isUserGroup,
    required this.showParticipating,
    this.isLeader,
    required this.activity,
    this.userGroup,
  });

  final GroupActivity group;
  final double screenHeight;
  final bool isDark;
  final double screenWidth;
  final bool isUserGroup;
  final bool showParticipating;
  final bool? isLeader;
  final Activity activity;
  final GroupRole? userGroup;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final groupName =
        "${group.groupName ?? localizations.noData} ${showParticipating ? '(${localizations.participating})' : ''}";
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          groupName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: screenHeight * 0.019, fontWeight: FontWeight.bold),
        ),
        leading: Icon(Icons.group, color: Const.primaryGoldenColor),
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${group.description}",
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                SizedBox(height: screenHeight * 0.004),
                Text(
                  "${localizations.budget}: ${formatCurrency(group.cost)} VND",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                isUserGroup
                    ? Align(
                        alignment: Alignment.bottomRight,
                        child: TextButton(
                          onPressed: () {
                            // Navigate based on the user's role
                            final BottomNavController controller =
                                Get.find<BottomNavController>();
                            if (controller.selectedIndex.toInt() != 2) {
                              controller.changeTabIndex(2);
                            }
                            Get.to(
                              () => ActivitiesTab(
                                chosenDate: activity.startTime,
                              ),
                              id: 2,
                              transition: Transition.fade,
                            );
                            Get.to(
                              () => isLeader!
                                  ? TaskManagementPage(
                                      activityId: activity.id,
                                      activityName: activity.activityName!,
                                      group: userGroup!,
                                    )
                                  : TaskPage(
                                      activityId: activity.id,
                                      activityName: activity.activityName!,
                                      group: userGroup!,
                                    ),
                              id: 2,
                              transition: Transition.rightToLeftWithFade,
                              routeName: isLeader!
                                  ? "/TaskManagementPage"
                                  : "/TaskPage",
                            );
                          },
                          child: Text(AppLocalizations.of(context)!.details),
                        ),
                      )
                    : SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
