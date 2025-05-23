import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shepherd_mo/constant/constant.dart';
import 'package:shepherd_mo/models/activity.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shepherd_mo/pages/activity_detail_page.dart';

class ActivityExpandableCard extends StatelessWidget {
  const ActivityExpandableCard({
    super.key,
    required this.activity,
    required this.screenHeight,
    required this.isDark,
    required this.screenWidth,
  });

  final Activity activity;
  final double screenHeight;
  final bool isDark;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final startDate = DateFormat('dd/MM/yyyy | HH:mm')
        .format(DateTime.parse(activity.startTime.toString()));
    final endDate = DateFormat('dd/MM/yyyy | HH:mm')
        .format(DateTime.parse(activity.endTime.toString()));
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          activity.activityName ?? localizations.noData,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: screenHeight * 0.019, fontWeight: FontWeight.bold),
        ),
        leading: Icon(Icons.wysiwyg, color: Const.primaryGoldenColor),
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event, size: screenHeight * 0.016),
                        SizedBox(width: screenHeight * 0.004),
                        Text(
                            "${AppLocalizations.of(context)!.start}: $startDate"),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.004),
                    Row(
                      children: [
                        Icon(Icons.event_available, size: screenHeight * 0.016),
                        SizedBox(width: screenHeight * 0.004),
                        Text("${AppLocalizations.of(context)!.end}: $endDate"),
                      ],
                    ),
                  ],
                ),
                Text(
                  "${activity.description}",
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                SizedBox(height: screenHeight * 0.004),
                Text(
                  "${localizations.status}: ${activity.status}",
                  style: TextStyle(
                    color: _getStatusColor(activity.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () {
                      // final BottomNavController controller =
                      //     Get.find<BottomNavController>();

                      // if (controller.selectedIndex != 2) {
                      //   controller.changeTabIndex(2);
                      // }
                      Get.to(() => ActivityDetailPage(activityId: activity.id),
                          id: 1, transition: Transition.rightToLeftWithFade);
                    },
                    child: Text(AppLocalizations.of(context)!.details),
                  ),
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
      case 'Đang duyệt':
        return Colors.blueGrey.shade200;
      case 'Được thông qua':
        return Colors.green;
      case 'Không được thông qua':
        return Colors.red.shade400;
      case 'Đang diễn ra':
        return Colors.orangeAccent;
      case 'Quá hạn':
        return Colors.red.shade400;
      case 'Chưa bắt đầu':
        return Colors.lightBlueAccent;
      default:
        return Colors.grey.shade300;
    }
  }
}
