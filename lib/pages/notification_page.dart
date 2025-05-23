import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:shepherd_mo/api/api_service.dart';
import 'package:shepherd_mo/constant/constant.dart';
import 'package:shepherd_mo/controller/controller.dart';
import 'package:shepherd_mo/models/notification.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';
import 'package:shepherd_mo/services/get_login.dart';
import 'package:shepherd_mo/widgets/empty_data.dart';
import 'package:shepherd_mo/widgets/end_of_line.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shepherd_mo/widgets/notification_card.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  static const _pageSize = 10;
  final PagingController<int, NotificationModel> _pagingController =
      PagingController(firstPageKey: 1, invisibleItemsThreshold: 2);
  final NotificationController notificationController =
      Get.find<NotificationController>();
  final BottomNavController bottomNavController =
      Get.find<BottomNavController>();
  bool _isUnread = false;
  String _filterType = "";
  bool isAuthorized = false;
  bool isLeader = false;
  bool shouldRefreshList = true;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    notificationController.fetchUnreadCount();
    _getUserRole();
    ever(notificationController.shouldReload, (value) {
      _refreshList();
      notificationController.shouldReload.value = false;
    }, condition: () => notificationController.shouldReload.value);
  }

  void _toggleUnreadView(bool isUnread) {
    setState(() {
      if (isUnread == false && _isUnread == isUnread) {
        _filterType = "";
      }
      _isUnread = isUnread;
      _refreshList();
    });
  }

  void _onFilterTypeChanged(String? newValue) {
    if (newValue != null) {
      setState(() {
        _filterType = newValue;
        _refreshList(); // Refresh the list when the filter changes
      });
    }
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      ApiService apiService = ApiService();

      final newItems = await apiService.fetchNotifications(
          searchKey: null,
          pageNumber: pageKey,
          pageSize: _pageSize,
          type: (_filterType.isNotEmpty) ? _filterType : null,
          isRead: _isUnread ? false : null);

      final isLastPage = newItems.length < _pageSize;

      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (e) {
      _pagingController.error = e;
    }
  }

  void _getUserRole() async {
    final checkRole = await checkUserRoles();
    final checkGroupRole = await checkGroupUserRoles();
    setState(() {
      isAuthorized = checkRole;
      isLeader = checkGroupRole;
    });
  }

  // Method to refresh the entire list
  Future<void> _refreshList() async {
    notificationController.fetchUnreadCount();
    _pagingController.refresh(); // Refresh the PagingController
  }

  void _markAllAsRead() async {
    // Add your "mark all as read" logic here
    final apiService = ApiService();
    await apiService.readAllNoti();
    notificationController.fetchUnreadCount();

    setState(() {
      // Update the list locally (this depends on how your notification data is structured)
      for (var notification in _pagingController.itemList!) {
        notification.isRead = true; // Assuming there's an 'isRead' property
      }
    });
  }

  // Delete notification
  void _deleteNotification(NotificationModel notification) {
    setState(() {
      _pagingController.itemList?.remove(notification);
    });
    ApiService().deleteNoti(notification.id); // Call API to delete
    notificationController.fetchUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    final localizations = AppLocalizations.of(context)!;
    final uiProvider = Provider.of<UIProvider>(context);
    bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final modalController = Get.find<ModalStateController>();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          localizations.notification,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.black,
              ),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // Use the default back icon
          onPressed: () {
            notificationController.closeNotificationPage();
            Navigator.of(context).pop();
          },
        ),
        iconTheme: IconThemeData(
          color: Colors.black, // Set leading icon color explicitly
        ),
        backgroundColor: Const.primaryGoldenColor,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onPressed: () async {
              // Handle menu action here (e.g., show a menu, etc.)
              modalController.openModal();
              try {
                await showModalBottomSheet(
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
                          (MediaQuery.of(context).platformBrightness ==
                              Brightness.dark);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
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
                          // Mark All as Read
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                              child: Icon(Icons.mark_chat_read_rounded,
                                  color: Colors.blue),
                            ),
                            title: Text(localizations.markAllAsRead),
                            onTap: () async {
                              _markAllAsRead();
                              Navigator.pop(context); // Close the bottom sheet
                            },
                          ),
                        ],
                      );
                    },
                  ),
                );
              } finally {
                modalController.closeModal();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ToggleButtons(
                  isSelected: [_isUnread == false, _isUnread == true],
                  onPressed: (index) {
                    _toggleUnreadView(index == 1);
                  },
                  fillColor: isDark ? Colors.grey[700] : Color(0xFFEEC05C),
                  selectedColor: Colors.white,
                  borderColor: isDark ? Colors.grey[700] : Color(0xFFEEC05C),
                  selectedBorderColor:
                      isDark ? Colors.grey[700] : Color(0xFFEEC05C),
                  borderRadius: BorderRadius.circular(15),
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.035),
                      child: SizedBox(
                        width: screenWidth *
                            0.18, // Fixed width for equal-sized buttons
                        child: Center(
                          child: Text(
                            localizations.all,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: screenWidth * 0.035),
                      child: SizedBox(
                        width: screenWidth *
                            0.18, // Fixed width for equal-sized buttons
                        child: Center(
                          child: Text(
                            localizations.unread,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  position: PopupMenuPosition
                      .under, // Opens the popup menu below the button
                  initialValue: _filterType,
                  onSelected: (value) {
                    modalController.closeModal();
                    _onFilterTypeChanged(value);
                  },
                  onCanceled: () {
                    modalController.closeModal();
                  },
                  itemBuilder: (context) {
                    modalController.openModal();
                    return [
                      PopupMenuItem(
                        value: "",
                        child: Text(localizations.all),
                      ),
                      PopupMenuItem(
                        value: "Group",
                        child: Text(localizations.group),
                      ),
                      PopupMenuItem(
                        value: "Event",
                        child: Text(localizations.event),
                      ),
                      PopupMenuItem(
                        value: "Activity",
                        child: Text(localizations.activity),
                      ),
                      PopupMenuItem(
                        value: "Task",
                        child: Text(localizations.task),
                      ),
                      if (isAuthorized || isLeader)
                        PopupMenuItem(
                          value: "Request",
                          child: Text(localizations.request),
                        ),
                      if (isAuthorized)
                        PopupMenuItem(
                          value: "Transaction",
                          child: Text(localizations.transaction),
                        ),
                    ];
                  },
                  icon: Icon(
                    Icons.filter_alt_outlined,
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.01),
            Expanded(
              child: RefreshIndicator(
                displacement: 20,
                onRefresh: _refreshList, // Triggers the refresh method
                child: PagedListView<int, NotificationModel>(
                  pagingController: _pagingController,
                  builderDelegate: PagedChildBuilderDelegate<NotificationModel>(
                    itemBuilder: (context, item, index) => NotificationCard(
                      notification: item,
                      onDelete: _deleteNotification,
                    ),
                    firstPageProgressIndicatorBuilder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                    newPageProgressIndicatorBuilder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                    noItemsFoundIndicatorBuilder: (context) => EmptyData(
                      noDataMessage: localizations.noNotification,
                      message: localizations.wellDoneServant,
                    ),
                    noMoreItemsIndicatorBuilder: (_) => EndOfListWidget(),
                    animateTransitions: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.removePageRequestListener(_fetchPage);
    _pagingController.dispose();
    super.dispose();
  }
}
