import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shepherd_mo/api/api_service.dart';
import 'package:shepherd_mo/constant/constant.dart';
import 'package:shepherd_mo/controller/controller.dart';
import 'package:shepherd_mo/formatter/custom_currency_format.dart';
import 'package:shepherd_mo/formatter/status_language.dart';
import 'package:shepherd_mo/models/activity.dart';
import 'package:shepherd_mo/models/event.dart';
import 'package:shepherd_mo/models/group_role.dart';
import 'package:shepherd_mo/models/task.dart';
import 'package:shepherd_mo/pages/update_progress_page.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';
import 'package:shepherd_mo/services/get_login.dart';
import 'package:shepherd_mo/widgets/custom_marquee.dart';
import 'package:shepherd_mo/widgets/empty_data.dart';
import 'package:shepherd_mo/widgets/end_of_line.dart';
import 'package:shepherd_mo/widgets/task_card.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TaskPage extends StatefulWidget {
  final String activityId;
  final String activityName;
  final GroupRole group;

  const TaskPage(
      {super.key,
      required this.activityId,
      required this.activityName,
      required this.group});

  @override
  TaskPageState createState() => TaskPageState();
}

class TaskPageState extends State<TaskPage> {
  int selectedIndex = 0;
  final PagingController<int, Task> _pagingController =
      PagingController(firstPageKey: 1);
  final int _pageSize = 10;
  String? eventId;
  Future<Map<String, dynamic>>? _initialData;
  final refreshController = Get.find<RefreshController>();

  List<Map<String, dynamic>> statusList = [];
  List<Task> _allTasks = [];
  int totalCount = 0;

  @override
  void initState() {
    super.initState();
    _initialData = fetchData();
    _pagingController.addPageRequestListener((pageKey) {
      if (eventId != null) {
        _fetchTasks(pageKey);
      }
    });
  }

  void _initializeStatusList() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final localizations = AppLocalizations.of(context)!;
      setState(() {
        statusList = [
          {
            'label': localizations.all,
            'backgroundColor': Const.primaryGoldenColor,
          },
          {
            'label': localizations.pendingTask,
            'backgroundColor': Colors.yellow.shade700,
            'status': 'Đang chờ'
          },
          {
            'label': localizations.toDo,
            'backgroundColor': Colors.blueAccent,
            'status': 'Việc cần làm'
          },
          {
            'label': localizations.inProgress,
            'backgroundColor': Colors.orangeAccent,
            'status': 'Đang diễn ra'
          },
          {
            'label': localizations.review,
            'backgroundColor': Colors.redAccent,
            'status': 'Xem xét'
          },
          {
            'label': localizations.done,
            'backgroundColor': Colors.green,
            'status': 'Đã hoàn thành'
          },
        ];
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeStatusList();
    _refreshList();
  }

  Future<Map<String, dynamic>> fetchData() async {
    ApiService apiService = ApiService();
    final results =
        await apiService.fetchActivities(searchKey: widget.activityId) ?? [];
    final data = results.first;

    setState(() {
      eventId = data.event!.id;
    });

    return {
      'activity': data,
      'event': data.event,
    };
  }

  Future<void> _fetchTasks(int pageKey) async {
    final apiService = ApiService();
    String selectedStatus =
        selectedIndex == 0 ? '' : statusList[selectedIndex]['status'];
    final loginInfo = await getLoginInfoFromPrefs();

    try {
      final response = await apiService.fetchTasks(
        searchKey: '',
        pageNumber: pageKey,
        pageSize: _pageSize,
        groupId: widget.group.groupId,
        activityId: widget.activityId,
        userId: loginInfo!.id,
        status: selectedStatus,
      );

      totalCount = response.$1;
      final List<Task> newTasks = response.$2;
      if (selectedIndex == 0) {
        if (pageKey == 1) {
          // If it's the first page, initialize _allTasks with newTasks
          _allTasks = newTasks;
        } else {
          // Otherwise, append the new tasks to the existing list
          _allTasks.addAll(newTasks);
        }
        _updateTaskCounts();
      } else {
        _updateTaskCounts();
      }
      final isLastPage = newTasks.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newTasks);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newTasks, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  void _updateTaskCounts() {
    final localizations = AppLocalizations.of(context)!;
    setState(() {
      final taskCounts = {
        localizations.all: totalCount,
        localizations.pendingTask:
            _allTasks.where((task) => task.status == 'Đang chờ').length,
        localizations.toDo:
            _allTasks.where((task) => task.status == 'Việc cần làm').length,
        localizations.inProgress:
            _allTasks.where((task) => task.status == 'Đang thực hiện').length,
        localizations.review:
            _allTasks.where((task) => task.status == 'Xem xét').length,
        localizations.done:
            _allTasks.where((task) => task.status == 'Đã hoàn thành').length,
      };

      for (var status in statusList) {
        status['count'] = taskCounts[status['label']] ?? 0;
      }
    });
  }

  String formatEventDateRange(DateTime? fromDate, DateTime? toDate) {
    if (fromDate == null || toDate == null) return 'Invalid date range';
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final date = dateFormat.format(fromDate);
    final fromTime = timeFormat.format(fromDate);
    final toTime = timeFormat.format(toDate);
    return '$date | $fromTime - $toTime';
  }

  Future<void> _refreshList() async {
    _pagingController.refresh();
  }

  void _filterTasksByStatus() {
    _pagingController.refresh();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uiProvider = Provider.of<UIProvider>(context);
    bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final localizations = AppLocalizations.of(context)!;
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.task,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _initialData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(localizations.errorOccurred));
          } else if (snapshot.hasData) {
            final activity = snapshot.data!['activity'] as Activity;
            final event = snapshot.data!['event'] as Event;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Header Card
                  _buildEventHeaderCard(
                    screenWidth,
                    screenHeight,
                    isDark,
                    event,
                    localizations,
                  ),

                  // Activity Details
                  _buildActivityDetails(screenHeight, screenWidth, activity,
                      localizations, isDark),

                  // Tasks Section with Heading and Status Chips
                  Container(
                    padding: EdgeInsets.only(
                        top: screenWidth * 0.04,
                        left: screenWidth * 0.04,
                        right: screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTasksHeading(
                            screenHeight, screenWidth, localizations),
                        _buildStatusChipsRow(
                            screenWidth, screenHeight, localizations, isDark),
                      ],
                    ),
                  ),

                  // Expanded Task List to take up remaining height
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.only(
                        bottom: screenWidth * 0.03,
                        left: screenWidth * 0.03,
                        right: screenWidth * 0.03,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.white,
                      ),
                      child: Obx(() {
                        if (refreshController.shouldRefresh.value) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            selectedIndex = 0;
                            _refreshList();
                            refreshController.setShouldRefresh(false);
                          });
                        } else if (refreshController
                                .shouldRefreshSignal.value &&
                            refreshController.task.value.id != null &&
                            refreshController.task.value.activityId ==
                                widget.activityId &&
                            refreshController.task.value.groupId ==
                                widget.group.groupId) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            selectedIndex = 0;
                            _refreshList();
                            refreshController.setShouldRefreshSignal(false);
                            refreshController.resetTask();
                          });
                        }
                        return RefreshIndicator(
                          onRefresh: _refreshList,
                          child: PagedListView<int, Task>(
                            pagingController: _pagingController,
                            builderDelegate: PagedChildBuilderDelegate<Task>(
                              itemBuilder: (context, task, index) => TaskCard(
                                task: task,
                                showStatus: selectedIndex == 0 ? true : false,
                                isLeader: false,
                                activityId: widget.activityId,
                                activityName: widget.activityName,
                                group: widget.group,
                              ),
                              firstPageProgressIndicatorBuilder: (_) =>
                                  const Center(
                                child: CircularProgressIndicator(),
                              ),
                              newPageProgressIndicatorBuilder: (_) =>
                                  const Center(
                                child: CircularProgressIndicator(),
                              ),
                              noItemsFoundIndicatorBuilder: (context) =>
                                  EmptyData(
                                noDataMessage: localizations.noTask,
                                message: localizations.takeABreak,
                              ),
                              noMoreItemsIndicatorBuilder: (_) => Padding(
                                padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.02),
                                child: EndOfListWidget(),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return EmptyData(
              noDataMessage: localizations.noTask,
              message: localizations.takeABreak,
            );
          }
        },
      ),
    );
  }

  Widget _buildEventHeaderCard(double screenWidth, double screenHeight,
      bool isDark, Event event, AppLocalizations localizations) {
    String? eventStatus = getStatus(event.status, localizations);

    double calculateTextWidth(String text, TextStyle style) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: ui.TextDirection.ltr,
      );

      textPainter.layout();
      return textPainter.width;
    }

    final double textWidth = calculateTextWidth(
        widget.group.groupName, TextStyle(fontSize: screenHeight * 0.018));

    return Card(
      color: isDark ? Colors.grey.shade900 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.only(bottom: screenHeight * 0.01),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.eventName ?? localizations.noData,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: screenHeight * 0.02,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.005),
                  decoration: BoxDecoration(
                    color: _getStatusColor(event.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    eventStatus ?? localizations.noData,
                    style: TextStyle(
                        fontSize: screenHeight * 0.018,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.005),
            Divider(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                thickness: 1),
            SizedBox(height: screenHeight * 0.005),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: screenHeight * 0.025, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Text(
                      formatEventDateRange(event.fromDate, event.toDate),
                      style: TextStyle(
                        fontSize: screenHeight * 0.015,
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Container(
                    width: screenWidth * 0.28,
                    height: screenHeight * 0.035,
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03,
                        vertical: screenHeight * 0.005),
                    decoration: BoxDecoration(
                      color: Const.primaryGoldenColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: textWidth <= screenWidth * 0.28
                        ? Text(
                            widget.group.groupName ?? localizations.noData,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: screenHeight * 0.018,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                overflow: TextOverflow.ellipsis),
                          )
                        : CustomMarquee(
                            text: widget.group.groupName,
                            fontSize: screenHeight * 0.018)),
              ],
            ),
          ],
        ),
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

  Widget _buildActivityDetails(double screenHeight, double screenWidth,
      Activity activity, AppLocalizations localizations, bool isDark) {
    String? activityStatus = getStatus(activity.status, localizations);

    return Card(
      color: isDark ? Colors.grey.shade900 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.only(bottom: screenHeight * 0.01),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    activity.activityName ?? localizations.noData,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenHeight * 0.02,
                      color: isDark
                          ? Colors.blueGrey.shade100
                          : Colors.blueGrey.shade900,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.005),
                  decoration: BoxDecoration(
                    color: _getStatusColor(activity.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    activityStatus ?? localizations.noData,
                    style: TextStyle(
                        fontSize: screenHeight * 0.018,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.005),
            ExpandableText(
              '${activity.description}\n${localizations.totalCost}: ${formatCurrency(activity.totalCost!)} VND' ??
                  localizations.noData,
              expandText: localizations.showMore,
              collapseText: localizations.showLess,
              maxLines: 2,
              linkColor: Colors.blueAccent,
              style: TextStyle(
                fontSize: screenHeight * 0.016,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChipsRow(double screenWidth, double screenHeight,
      AppLocalizations localizations, bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List<Widget>.generate(
            statusList.length,
            (int index) {
              var status = statusList[index];
              int taskCount = status['count'] ?? 0;

              return Padding(
                padding: EdgeInsets.only(right: screenWidth * 0.02),
                child: ChoiceChip(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  showCheckmark: false,
                  label: Text(
                    "${status['label']} ($taskCount)",
                    style: TextStyle(
                      color:
                          selectedIndex == index ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: screenHeight * 0.017,
                    ),
                  ),
                  selectedColor: status['backgroundColor'],
                  backgroundColor:
                      isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                  selected: selectedIndex == index,
                  onSelected: (bool selected) {
                    setState(() {
                      selectedIndex = index;
                      _filterTasksByStatus();
                    });
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTasksHeading(
      double screenHeight, double screenWidth, AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          localizations.task,
          style: TextStyle(
            fontSize: screenHeight * 0.025,
            fontWeight: FontWeight.w700,
          ),
        ),
        TextButton(
          onPressed: () {
            Get.to(
                () => UpdateProgress(
                      tasks: _allTasks,
                      isLeader: false,
                      activityId: widget.activityId,
                      groupId: widget.group.groupId,
                    ),
                id: 2,
                transition: Transition.rightToLeftWithFade);
          },
          style: TextButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(
            localizations.updateProgress,
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        )
      ],
    );
  }
}
