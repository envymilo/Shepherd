import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shepherd_mo/controller/controller.dart';
import 'package:shepherd_mo/models/event.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shepherd_mo/pages/ceremony_detail_page.dart';
import 'package:shepherd_mo/pages/event_detail_page.dart';
import 'package:shepherd_mo/pages/home_page.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.screenHeight,
    required this.isDark,
    required this.screenWidth,
  });

  final Event event;
  final double screenHeight;
  final bool isDark;
  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Card(
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        title: Text(
          event.eventName!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: screenHeight * 0.019, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          children: [
            Row(
              children: [
                Icon(Icons.event, size: screenHeight * 0.016),
                SizedBox(width: screenHeight * 0.004),
                Text(
                    "${AppLocalizations.of(context)!.start}: ${DateFormat('dd/MM/yyyy').format(event.fromDate!)} | ${DateFormat('HH:mm').format(event.fromDate!)}"),
              ],
            ),
            SizedBox(height: screenHeight * 0.004),
            Row(
              children: [
                Icon(Icons.event_available, size: screenHeight * 0.016),
                SizedBox(width: screenHeight * 0.004),
                Text(
                    "${AppLocalizations.of(context)!.end}: ${DateFormat('dd/MM/yyyy').format(event.toDate!)} | ${DateFormat('HH:mm').format(event.toDate!)}"),
              ],
            ),
          ],
        ),
        leading: Icon(Icons.event,
            color: event.ceremonyId != null ? Colors.red : Colors.orange),
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${event.description}",
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                SizedBox(height: screenHeight * 0.004),
                Text(
                  "${localizations.status}: ${event.status}",
                  style: TextStyle(
                    color: _getStatusColor(event.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (event.isPublic != null) Text("Public: ${event.isPublic}"),
                // Action buttons
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () {
                      final BottomNavController controller =
                          Get.find<BottomNavController>();

                      if (controller.selectedIndex.value != 1) {
                        controller.changeTabIndex(1);
                      }
                      Get.to(
                          () => ScheduleTab(
                                chosenDate: event.fromDate,
                              ),
                          id: 1);
                      if (event.id != null && event.ceremonyId == null) {
                        Get.to(() => EventDetailsPage(eventId: event.id!),
                            id: 1, transition: Transition.rightToLeftWithFade);
                      } else if (event.id == null && event.ceremonyId != null) {
                        Get.to(
                            () => CeremonyDetailsPage(
                                  ceremonyId: event.ceremonyId!,
                                  ceremony: event,
                                ),
                            id: 1,
                            transition: Transition.rightToLeftWithFade);
                      }
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
