import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shepherd_mo/controller/controller.dart';
import 'package:shepherd_mo/pages/leader/request_page.dart';
import 'package:shepherd_mo/pages/notification_page.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final double screenWidth;
  final double screenHeight;

  const CustomAppBar({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  CustomAppBarState createState() => CustomAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}

class CustomAppBarState extends State<CustomAppBar> {
  Timer? _timer;
  final NotificationController notificationController =
      Get.find<NotificationController>();

  @override
  void initState() {
    super.initState();
    notificationController.fetchUnreadCount(); // Initial fetch
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(Duration(seconds: 30), (timer) {
      notificationController
          .fetchUnreadCount(); // Refresh the unread count every 30 seconds
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiProvider = Provider.of<UIProvider>(context);
    final authorizationController = Get.find<AuthorizationController>();
    final localizations = AppLocalizations.of(context)!;
    bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final modalController = Get.find<ModalStateController>();
    final bottomNavController = Get.find<BottomNavController>();

    return AppBar(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.grey.shade300,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true,
      leading: Obx(() {
        return authorizationController.isAuthorized.value ||
                authorizationController.isLeader.value
            ? PopupMenuButton<int>(
                position: PopupMenuPosition.under,
                icon: Icon(
                  Icons.menu,
                  size: widget.screenWidth * 0.075,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: [
                        Icon(Icons.request_page, color: Colors.grey),
                        SizedBox(width: widget.screenWidth * 0.02),
                        Text(
                            "${localizations.list} ${localizations.request.toLowerCase()}"),
                      ],
                    ),
                    onTap: () {
                      Get.to(() => RequestList(),
                          transition: Transition.rightToLeftWithFade);
                    },
                  ),
                ],
              )
            : SizedBox.shrink();
      }),
      actions: [
        // Notification Button
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Stack(
            children: <Widget>[
              SizedBox(
                width: widget.screenWidth * 0.15,
                height: widget.screenWidth * 0.15,
                child: Obx(
                  () {
                    return IconButton(
                      onPressed: (modalController.isModalOpen.value &&
                              modalController.modalOnTab.contains(
                                  bottomNavController.selectedIndex.value))
                          ? null
                          : () {
                              final BottomNavController bottomNavController =
                                  Get.find<BottomNavController>();
                              final NotificationController
                                  notificationController =
                                  Get.find<NotificationController>();

                              if (notificationController.openTabIndex.value ==
                                  bottomNavController.selectedIndex.value) {
                                Get.back(
                                    id: notificationController
                                        .openTabIndex.value);
                                notificationController.closeNotificationPage();
                              } else {
                                if (notificationController.openTabIndex.value !=
                                    -1) {
                                  Get.back(
                                      id: notificationController
                                          .openTabIndex.value);
                                  notificationController
                                      .closeNotificationPage();
                                }
                                notificationController.openNotificationPage(
                                    bottomNavController.selectedIndex.value);
                                Get.to(() => NotificationPage(),
                                    transition: Transition.topLevel,
                                    id: bottomNavController
                                        .selectedIndex.value);
                              }
                            },
                      icon: Icon(
                        Icons.notifications_none,
                        size: widget.screenWidth * 0.075,
                        color: isDark ? Colors.white70 : Colors.grey[700],
                      ),
                    );
                  },
                ),
              ),
              // Display the red dot with unread count, only if there are unread notifications
              Obx(
                () {
                  return notificationController.haveUnread.value
                      ? Positioned(
                          right: widget.screenWidth * 0.03,
                          top: widget.screenWidth * 0.015,
                          child: IgnorePointer(
                            child: CircleAvatar(
                              radius: widget.screenHeight * 0.01,
                              backgroundColor: Colors.red,
                              child: Text(
                                notificationController.unreadCount.value
                                    .toString(),
                                style: TextStyle(
                                  fontSize: widget.screenHeight * 0.01,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                      : SizedBox.shrink();
                },
              )
            ],
          ),
        ),
      ],
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding:
                EdgeInsets.symmetric(horizontal: widget.screenWidth * 0.02),
            child: Image.asset(
              'assets/images/shepherd.png',
              height: widget.screenHeight * 0.04,
              fit: BoxFit.contain,
            ),
          ),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.shade900,
                Colors.orange.shade600,
              ],
              stops: const [0.2, 0.8],
            ).createShader(bounds),
            child: Text(
              'Shepherd',
              style: TextStyle(
                fontSize: widget.screenWidth * 0.08,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
