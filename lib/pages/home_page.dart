import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shepherd_mo/api/api_service.dart';
import 'package:shepherd_mo/constant/constant.dart';
import 'package:shepherd_mo/controller/controller.dart';
import 'package:shepherd_mo/formatter/avatar.dart';
import 'package:shepherd_mo/models/activity.dart';
import 'package:shepherd_mo/models/event.dart';
import 'package:shepherd_mo/models/group.dart';
import 'package:shepherd_mo/models/group_role.dart';
import 'package:shepherd_mo/models/group_user.dart';
import 'package:shepherd_mo/models/user.dart';
import 'package:shepherd_mo/observer/route_observer.dart';
import 'package:shepherd_mo/pages/change_password_page.dart';
import 'package:shepherd_mo/pages/group_members_page.dart';
import 'package:shepherd_mo/pages/leader/task_management_page.dart';
import 'package:shepherd_mo/pages/login_page.dart';
import 'package:shepherd_mo/pages/settings_page.dart';
import 'package:shepherd_mo/pages/task_page.dart';
import 'package:shepherd_mo/pages/upcoming_activity_page.dart';
import 'package:shepherd_mo/pages/upcoming_event_page.dart';
import 'package:shepherd_mo/pages/update_profile_page.dart';
import 'package:shepherd_mo/providers/signalr_provider.dart';
import 'package:shepherd_mo/providers/ui_provider.dart';
import 'package:shepherd_mo/services/get_login.dart';
import 'package:shepherd_mo/utils/toast.dart';
import 'package:shepherd_mo/widgets/activity_card.dart';
import 'package:shepherd_mo/widgets/custom_appbar.dart';
import 'package:shepherd_mo/widgets/custom_marquee.dart';
import 'package:shepherd_mo/widgets/empty_data.dart';
import 'package:shepherd_mo/widgets/event_card.dart';
import 'package:shepherd_mo/widgets/organization_card.dart';
import 'package:shepherd_mo/widgets/photo_viewer.dart';
import 'package:shepherd_mo/widgets/profile_menu_widget.dart';
import 'package:shepherd_mo/widgets/progressHUD.dart';
import 'package:shepherd_mo/widgets/upcoming_card.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  final BottomNavController controller = Get.find<BottomNavController>();

  final List<String> _tabsRoutes = [
    '/home',
    '/schedule',
    '/activities',
    '/menu',
  ];

  final List<Widget> tabs = [
    const HomeTab(),
    const ScheduleTab(),
    const ActivitiesTab(),
    const MenuTab(),
  ];

  late List<GlobalKey<NavigatorState>> navigatorKeys;
  Timer? _roleUpdateTimer;

  void _onTabTapped(int index) {
    if (controller.selectedIndex.value == index) {
      final NotificationController notificationController =
          Get.find<NotificationController>();
      if (notificationController.openTabIndex.value ==
          controller.selectedIndex.value) {
        notificationController.closeNotificationPage();
      }
      Get.offAllNamed(_tabsRoutes[index], id: index);
    } else {
      controller.selectedIndex.value = index;
    }
  }

  @override
  void dispose() {
    _roleUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    navigatorKeys = List.generate(
      tabs.length,
      (index) => GlobalKey<NavigatorState>(),
    );
    _startRoleUpdateTaskIfLoggedIn();
  }

  Future<void> _startRoleUpdateTaskIfLoggedIn() async {
    bool loggedIn = await isUserLoggedIn();
    ApiService apiService = ApiService();

    if (loggedIn) {
      // Fetch and update roles immediately
      await apiService.fetchAndCompareGroupRoles(null);
      await _updateAuthorizationStatus();

      // Set up periodic task every 5 seconds
      _roleUpdateTimer = Timer.periodic(Duration(minutes: 1), (timer) async {
        await apiService.fetchAndCompareGroupRoles(null);
        await _updateAuthorizationStatus();
      });
    }
  }

  Future<void> _updateAuthorizationStatus() async {
    bool isAuthorized = await checkUserRoles();
    bool isLeader = await checkGroupUserRoles();
    Get.find<AuthorizationController>().updateAuthorizationStatus(isAuthorized);
    Get.find<AuthorizationController>()
        .updateGroupAuthorizationStatus(isLeader);
  }

  Future<bool> isUserLoggedIn() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');
    return token != null;
  }

  @override
  Widget build(BuildContext context) {
    final uiProvider = Provider.of<UIProvider>(context);
    bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;
    final signalR = Provider.of<SignalRService>(context, listen: false);

    return Obx(
      () => Scaffold(
        appBar: CustomAppBar(
            screenWidth: MediaQuery.of(context).size.width,
            screenHeight: MediaQuery.of(context).size.height),
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: List.generate(
            tabs.length,
            (index) => _buildNestedNavigator(index),
          ),
        ),
        bottomNavigationBar: GNav(
          backgroundColor: Const.primaryGoldenColor,
          color: isDark ? Colors.black : Colors.white,
          activeColor: Colors.blue,
          tabBackgroundColor: isDark ? Colors.black : Colors.grey.shade100,
          gap: screenWidth * 0.03,
          selectedIndex: controller.selectedIndex.value,
          onTabChange: _onTabTapped,
          padding: EdgeInsets.all(screenWidth * 0.04),
          tabs: [
            GButton(
              icon: Icons.home,
              iconActiveColor: Const.primaryGoldenColor,
              text: localizations.home,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFEEC05C),
              ),
            ),
            GButton(
              icon: Icons.event,
              iconActiveColor: Const.primaryGoldenColor,
              text: localizations.schedule,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFEEC05C),
              ),
            ),
            GButton(
              icon: Icons.wysiwyg,
              iconActiveColor: Const.primaryGoldenColor,
              text: localizations.activity,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFEEC05C),
              ),
            ),
            GButton(
              icon: Icons.menu,
              iconActiveColor: Const.primaryGoldenColor,
              text: localizations.menu,
              textStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFEEC05C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitialRouteForTab(int index) {
    return _tabsRoutes[index];
  }

  Widget _buildNestedNavigator(int index) {
    return Navigator(
      key: Get.nestedKey(index),
      initialRoute: _getInitialRouteForTab(index),
      observers: [
        RouteTracker(onRouteChange: (route) {
          final RouteController routeController = Get.find<RouteController>();
          routeController.updateRoute(route);
        })
      ],
      onGenerateRoute: (RouteSettings settings) {
        Widget page;
        switch (settings.name) {
          case '/home':
            page = const HomeTab();
            break;
          case '/schedule':
            page = const ScheduleTab();
            break;
          case '/activities':
            page = const ActivitiesTab();
            break;
          case '/menu':
            page = const MenuTab();
            break;
          default:
            page = const HomeTab();
        }
        return GetPageRoute(
          page: () => page,
          transition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 500),
        );
      },
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  User? loginInfo;
  bool isLoading = false;

  Future<List<Group>>? groups;

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
    setState(() {
      isLoading = true;
    });

    await loadUserInfo(); // Wait for loadUserInfo to complete
    groups = fetchGroups(); // Now, load groups with user info
  }

  Future<List<Group>> fetchGroups() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Assuming the ApiService fetchGroups function requires parameters
      final apiService = ApiService();
      return await apiService.fetchGroups(
        searchKey: '',
        pageNumber: 1,
        pageSize: 20,
        userId: loginInfo!.id,
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> loadUserInfo() async {
    final user = await getLoginInfoFromPrefs();

    if (user != null) {
      setState(() {
        loginInfo = user;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
        inAsyncCall: isLoading, // Show ProgressHUD overlay when loading
        opacity: 0.3,
        child: _uiSetup(context));
  }

  Widget _uiSetup(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final now = DateTime.now();

    // Ensure loginInfo is not null before using it
    final String name = loginInfo?.name ?? "User";
    final greetingMessage = getGreetingMessage(now.hour, name);

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
        greetingMessage, TextStyle(fontSize: screenHeight * 0.025));

    // Access provider and check for null or default values
    final uiProvider = Provider.of<UIProvider>(context, listen: false);
    final bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            children: [
              Container(
                height: screenHeight * 0.032,
                alignment: Alignment.topLeft,
                child: textWidth <= (screenWidth * 0.8838)
                    ? Text(
                        greetingMessage,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: screenHeight * 0.025,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : CustomMarquee(
                        text: greetingMessage,
                        fontSize: screenHeight * 0.025,
                      ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.group ?? localizations.noData,
                    style: TextStyle(
                      fontSize: screenHeight * 0.03,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  FutureBuilder<List<Group>>(
                    future:
                        groups, // Ensure `groups` is initialized as a Future
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            localizations.errorOccurred,
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text(localizations.noParticipatedGroup),
                        );
                      } else {
                        final groups = snapshot.data!;
                        return Column(
                          children: [
                            Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                    '${localizations.currentlyIn} ${groups.length} ${localizations.group.toLowerCase()}')),
                            SizedBox(height: screenHeight * 0.02),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: groups.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  var group = entry.value;

                                  // Set color based on index
                                  final cardColor = index % 2 == 0
                                      ? Colors.lightBlue.shade200
                                      : Colors.purple.shade200;

                                  return OrganizationCard(
                                    color: cardColor,
                                    title: group.groupName,
                                    membersCount: group
                                        .memberCount, // Replace with actual member count if available
                                    onDetailsPressed: () {
                                      Get.to(() => GroupDetail(group: group),
                                          id: 0,
                                          transition:
                                              Transition.rightToLeftWithFade);
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  SizedBox(height: screenHeight * 0.03),
                  Text(
                    "${localizations.event} & ${localizations.activity}",
                    style: TextStyle(
                      fontSize: screenHeight * 0.03,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      UpcomingCard(
                        icon: Icon(Icons.event,
                            size: screenHeight * 0.09, color: Colors.black),
                        color: Const.primaryGoldenColor,
                        title: localizations.upcomingEvents,
                        onCardPressed: () {
                          Get.to(() => const UpcomingEventPage(),
                              id: 0,
                              transition: Transition.rightToLeftWithFade);
                        },
                      ),
                      UpcomingCard(
                        icon: Icon(Icons.wysiwyg,
                            size: screenHeight * 0.09, color: Colors.black),
                        color: Const.primaryGoldenColor,
                        title: localizations.upcomingActivities,
                        onCardPressed: () {
                          Get.to(() => const UpcomingActivityPage(),
                              id: 0,
                              transition: Transition.rightToLeftWithFade);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getGreetingMessage(int hour, String name) {
    if (hour >= 3 && hour < 11) {
      return '${AppLocalizations.of(context)!.morning}, $name';
    } else if (hour >= 11 && hour < 16) {
      return '${AppLocalizations.of(context)!.afternoon}, $name';
    } else if (hour >= 16 && hour < 18) {
      return '${AppLocalizations.of(context)!.evening}, $name';
    } else {
      return '${AppLocalizations.of(context)!.night}, $name';
    }
  }
}

class ScheduleTab extends StatefulWidget {
  final DateTime? chosenDate;
  const ScheduleTab({this.chosenDate, super.key});
  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  DateTime today = DateTime.now();
  late DateTime selectedDay;
  late DateTime focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool headerTappedCalled = false;

  final localeController = Get.find<LocaleController>();
  final authorizationController = Get.find<AuthorizationController>();

  bool isLoading = true;
  Map<DateTime, List<Event>> eventsByDate = {};
  List<Event> selectedEvents = [];
  Map<DateTime, List<Event>> ceremoniesByDate = {};
  List<Event> selectedCeremonies = [];

  String? selectedGroup;
  String? selectedOrganization;
  String userOnly = "false";
  Future<List<GroupRole>>? userGroups;

  Future<void> fetchEventsAndCeremonies() async {
    setState(() {
      isLoading = true;
    });
    try {
      final apiService = ApiService();
      //Fetch events
      eventsByDate = await apiService.fetchEventsCalendar(
        focusedDay.toString(),
        selectedOrganization ?? "",
        _calendarFormat == CalendarFormat.week ? 0 : 1,
        userOnly,
        "false",
      );

      // Fetch ceremonies
      ceremoniesByDate = await apiService.fetchCeremoniesCalendar(
        focusedDay.toString(),
        selectedOrganization ?? "",
        _calendarFormat == CalendarFormat.week ? 0 : 1,
        "false",
        "false",
      );
    } finally {
      setState(() {
        isLoading = false;
      });
      _updateSelectedDayEventsAndCeremonies();
    }
  }

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    if (mounted) {
      setState(() {
        selectedDay = day;
        this.focusedDay = focusedDay;
        _updateSelectedDayEventsAndCeremonies();
      });
    }
  }

  void _updateSelectedDayEventsAndCeremonies() {
    setState(() {
      final date =
          DateTime(selectedDay.year, selectedDay.month, selectedDay.day);

      selectedEvents = eventsByDate[date] ?? [];
      selectedCeremonies = ceremoniesByDate[date] ?? [];
    });
  }

  @override
  void initState() {
    super.initState();
    initializeData();
    fetchEventsAndCeremonies();
  }

  Future<void> initializeData() async {
    setState(() {
      isLoading = true;
    });

    if (widget.chosenDate != null) {
      selectedDay = widget.chosenDate!;
      focusedDay = widget.chosenDate!;
    } else {
      selectedDay = today;
      focusedDay = today;
    }

    userGroups = _loadUserGroupInfo();
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

  void _onOrganizationChanged(String? newValue) {
    setState(() {
      selectedGroup = newValue;
      if (newValue == "All") {
        selectedOrganization = null;
        userOnly = "false";
      } else if (newValue == "AllOrg") {
        selectedOrganization = null;
        userOnly = "true";
      } else {
        selectedOrganization = newValue;
        userOnly = "true";
      }
      isLoading = true;
    });
    fetchEventsAndCeremonies();
  }

  Widget _buildGroupDropdown(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? Colors.orangeAccent : Colors.orange.shade600,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: FutureBuilder<List<GroupRole>>(
        future: userGroups,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text(localizations.errorOccurred);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text(localizations.noParticipatedGroup);
          } else {
            final userGroups = snapshot.data!;
            return DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isDense: true, // Reduce dropdown size
                hint: Text(
                  localizations.all,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                value: selectedGroup,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down),
                items: [
                  DropdownMenuItem(
                    value: "All",
                    child: Text(
                      localizations.all,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  DropdownMenuItem(
                    value: "AllOrg",
                    child: Text(
                      localizations.allCurrentlyUserOrganizations,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  ...userGroups.map((group) {
                    return DropdownMenuItem(
                      value: group.groupId,
                      child: Text(
                        group.groupName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    );
                  }),
                ],
                onChanged: _onOrganizationChanged,
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
        inAsyncCall: isLoading, opacity: 0.3, child: _uiSetup(context));
  }

  Widget _uiSetup(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final uiProvider = Provider.of<UIProvider>(context);
    bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          localizations.schedule,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
        child: Column(
          children: [
            _buildGroupDropdown(context),
            Obx(
              () => TableCalendar(
                locale: localeController.currentLocale.languageCode,
                rowHeight: screenHeight * 0.05,
                focusedDay: focusedDay,
                firstDay: DateTime.utc(2020, 01, 01),
                lastDay: DateTime.utc(2040, 12, 31),
                calendarFormat: _calendarFormat,
                availableCalendarFormats:
                    localeController.availableCalendarFormats,
                availableGestures: AvailableGestures.all,
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.grey : Colors.black,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                  ),
                  titleTextFormatter: (date, locale) {
                    if (locale == 'vi') {
                      final String formattedDate =
                          DateFormat.yMMMM(locale).format(date);
                      List<String> parts = formattedDate.split(' ');

                      if (parts.length > 3) {
                        parts[0] =
                            parts[0][0].toUpperCase() + parts[0].substring(1);
                        parts[2] =
                            parts[2][0].toUpperCase() + parts[2].substring(1);
                      }

                      return parts.join(' ');
                    } else {
                      return DateFormat.yMMMM(locale).format(date);
                    }
                  },
                ),
                eventLoader: (day) {
                  final date = DateTime(day.year, day.month, day.day);
                  final events = eventsByDate[date] ?? [];
                  final ceremonies = ceremoniesByDate[date] ?? [];
                  return [...events, ...ceremonies];
                },
                // Customizing Calendar Appearance
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey, // Border color
                      width: 1.0, // Border width
                    ),
                  ),
                  selectedDecoration: BoxDecoration(
                    color: isDark
                        ? Colors.blueGrey.shade200
                        : Colors.blue.shade300,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                  ),
                  todayTextStyle: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  defaultTextStyle: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  weekendTextStyle: const TextStyle(
                    color: Colors.red,
                  ),
                  outsideTextStyle: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                onFormatChanged: (format) {
                  if (_calendarFormat != format && mounted) {
                    setState(() {
                      _calendarFormat = format;
                      focusedDay = selectedDay;
                    });
                    fetchEventsAndCeremonies();
                  }
                },
                // Calendar builders to customize markers
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    final date = DateTime(day.year, day.month, day.day);
                    final events = eventsByDate[date] ?? [];
                    final ceremonies = ceremoniesByDate[date] ?? [];

                    if (events.isEmpty && ceremonies.isEmpty) return null;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (events.isNotEmpty)
                          Container(
                            width: screenHeight * 0.021,
                            height: screenHeight * 0.021,
                            margin: const EdgeInsets.symmetric(horizontal: 2.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.orange, // Color for events
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${events.length}', // Number of events
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenHeight * 0.011,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (ceremonies.isNotEmpty)
                          Container(
                            width: screenHeight * 0.021,
                            height: screenHeight * 0.021,
                            margin: const EdgeInsets.symmetric(horizontal: 2.0),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.red, // Color for ceremonies
                              shape:
                                  BoxShape.circle, // Rectangle for ceremonies
                            ),
                            child: Text(
                              '${ceremonies.length}', // Number of ceremonies
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenHeight * 0.011,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),

                // Handle day selection
                selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                onDaySelected: _onDaySelected,

                // When the calendar header is tapped
                onHeaderTapped: (day) {
                  if (mounted) {
                    setState(() {
                      selectedDay = today;
                      focusedDay = today;
                    });
                    fetchEventsAndCeremonies();
                  }
                },

                // Handle page changes (e.g., scrolling through months)
                onPageChanged: (newFocusedDay) {
                  setState(() {
                    focusedDay =
                        newFocusedDay; // Update the focused day without affecting selectedDay
                  });
                  fetchEventsAndCeremonies();
                },
              ),
            ),
            Expanded(
              child: selectedEvents.isEmpty && selectedCeremonies.isEmpty
                  ? EmptyData(
                      noDataMessage: localizations.noEvent,
                      message: localizations.takeABreak)
                  : ListView(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      children: [
                        if (selectedEvents.isNotEmpty) ...[
                          Text(localizations.event,
                              style: Theme.of(context).textTheme.titleLarge),
                          ...selectedEvents.map(
                            (event) => EventCard(
                              event: event,
                              screenHeight: screenHeight,
                              isDark: isDark,
                              screenWidth: screenWidth,
                            ),
                          ),
                        ],
                        if (selectedEvents.isNotEmpty &&
                            selectedCeremonies.isNotEmpty)
                          SizedBox(height: screenHeight * 0.016),
                        if (selectedCeremonies.isNotEmpty) ...[
                          Text(localizations.ceremony,
                              style: Theme.of(context).textTheme.titleLarge),
                          ...selectedCeremonies.map(
                            (ceremony) => EventCard(
                              event: ceremony,
                              screenHeight: screenHeight,
                              isDark: isDark,
                              screenWidth: screenWidth,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActivitiesTab extends StatefulWidget {
  final DateTime? chosenDate;
  const ActivitiesTab({this.chosenDate, super.key});

  @override
  State<ActivitiesTab> createState() => _ActivitiesTabState();
}

class _ActivitiesTabState extends State<ActivitiesTab> {
  String? selectedOrganization;
  int selectedIndex = -1;
  DateTime today = DateTime.now();
  late DateTime selectedDay;
  late DateTime focusedDay;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  bool isLoading = true;
  Map<DateTime, List<Activity>> activitiesByDate = {};
  List<Activity> selectedActivities = [];
  final LocaleController localeController = Get.find<LocaleController>();
  final authorizationController = Get.find<AuthorizationController>();

  Future<List<GroupRole>>? userGroups;
  User? loginInfo;

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    if (mounted) {
      setState(() {
        selectedDay = day;
        this.focusedDay = focusedDay;
        _updateSelectedDayActivities();
      });
    }
  }

  Future<void> initializeData() async {
    setState(() {
      isLoading = true;
    });

    if (widget.chosenDate != null) {
      selectedDay = widget.chosenDate!;
      focusedDay = widget.chosenDate!;
    } else {
      selectedDay = today;
      focusedDay = today;
    }

    userGroups = loadUserGroupInfo();
  }

  Future<List<GroupRole>> loadUserGroupInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userGroups = prefs.getString("loginUserGroups");
    List<GroupRole> loginUserGroupsList = [];
    if (userGroups != null) {
      List<dynamic> decodedJson = jsonDecode(userGroups);
      loginUserGroupsList = decodedJson
          .map((item) => GroupRole.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return loginUserGroupsList;
  }

  Future<void> fetchActivities() async {
    setState(() {
      isLoading = true;
    });
    try {
      final apiService = ApiService();
      activitiesByDate = await apiService.fetchActivitiesCalendar(
          focusedDay.toString(),
          selectedOrganization,
          _calendarFormat == CalendarFormat.week ? 0 : 1,
          "true",
          "false");
    } finally {
      setState(() {
        isLoading = false;
      });
      _updateSelectedDayActivities();
    }
  }

  void _updateSelectedDayActivities() {
    setState(() {
      final date =
          DateTime(selectedDay.year, selectedDay.month, selectedDay.day);

      selectedActivities = activitiesByDate[date] ?? [];
    });
  }

  void onChanged(String? newValue) {
    setState(() {
      selectedOrganization = newValue == "All" ? null : newValue;
      isLoading = true;
    });
    fetchActivities();
  }

  @override
  void initState() {
    super.initState();
    initializeData();
    fetchActivities();
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
        inAsyncCall: isLoading, opacity: 0.3, child: _uiSetup(context));
  }

  Widget _uiSetup(BuildContext context) {
    final uiProvider = Provider.of<UIProvider>(context);
    bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          localizations.activity,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: Column(
          children: [
            // Dropdown Menu with FutureBuilder
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(
                    color:
                        isDark ? Colors.orangeAccent : Colors.orange.shade600,
                    width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FutureBuilder<List<GroupRole>>(
                future: userGroups, // Replace with your method to fetch groups
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text(localizations.errorOccurred);
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Text(localizations.noParticipatedGroup);
                  } else {
                    final userGroups = snapshot.data!;
                    return DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        hint: Text(localizations.allCurrentlyUserOrganizations),
                        value: selectedOrganization,
                        isExpanded: true,
                        focusColor: Colors.orange,
                        icon: const Icon(Icons.arrow_drop_down),
                        iconSize: screenHeight * 0.025,
                        dropdownColor: isDark ? Colors.black : Colors.white,
                        style: TextStyle(
                          fontSize: screenHeight * 0.016,
                          fontWeight: FontWeight.bold,
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: "All", // Special value for "All" option
                            child: Row(
                              children: [
                                const Icon(Icons.group),
                                SizedBox(width: screenWidth * 0.03),
                                Text(
                                  localizations.allCurrentlyUserOrganizations,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...userGroups.map((GroupRole userGroup) {
                            return DropdownMenuItem<String>(
                              value: userGroup.groupId,
                              child: Row(
                                children: [
                                  const Icon(Icons.group),
                                  SizedBox(width: screenWidth * 0.03),
                                  Text(
                                    userGroup.groupName,
                                    style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: onChanged,
                      ),
                    );
                  }
                },
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            // Horizontal scrolling with TableCalendar (or other widget)
            Obx(
              () => TableCalendar(
                locale: localeController.currentLocale.languageCode,
                rowHeight: screenHeight * 0.05,
                focusedDay: focusedDay,
                firstDay: DateTime.utc(2010, 01, 01),
                lastDay: DateTime.utc(2050, 12, 31),
                calendarFormat: _calendarFormat,
                availableCalendarFormats:
                    localeController.availableCalendarFormats,
                availableGestures: AvailableGestures.all,
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.grey : Colors.black,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                  ),
                  titleTextFormatter: (date, locale) {
                    if (locale == 'vi') {
                      final String formattedDate =
                          DateFormat.yMMMM(locale).format(date);
                      List<String> parts = formattedDate.split(' ');

                      if (parts.length > 3) {
                        parts[0] =
                            parts[0][0].toUpperCase() + parts[0].substring(1);
                        parts[2] =
                            parts[2][0].toUpperCase() + parts[2].substring(1);
                      }

                      return parts.join(' ');
                    } else {
                      return DateFormat.yMMMM(locale).format(date);
                    }
                  },
                ),
                eventLoader: (day) {
                  final date = DateTime(day.year, day.month, day.day);
                  return activitiesByDate[date] ?? [];
                },

                // Customizing Calendar Appearance
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey, // Border color
                      width: 1.0, // Border width
                    ),
                  ),
                  selectedDecoration: BoxDecoration(
                    color: isDark
                        ? Colors.blueGrey.shade200
                        : Colors.blue.shade300,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                  ),
                  todayTextStyle: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  defaultTextStyle: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  weekendTextStyle: const TextStyle(
                    color: Colors.red,
                  ),
                  outsideTextStyle: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                onFormatChanged: (format) {
                  if (_calendarFormat != format && mounted) {
                    setState(() {
                      _calendarFormat = format;
                      focusedDay = selectedDay;
                    });
                    fetchActivities();
                  }
                },
                // Calendar builders to customize markers
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isNotEmpty) {
                      return Container(
                        width: 15,
                        height: 15,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.red[700],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${events.length}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenHeight * 0.011,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),

                // Handle day selection
                selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                onDaySelected: _onDaySelected,

                // When the calendar header is tapped
                onHeaderTapped: (focusedDay) {
                  if (mounted) {
                    setState(() {
                      selectedDay = today;
                      focusedDay = today;
                    });
                    fetchActivities();
                  }
                },

                // Handle page changes (e.g., scrolling through months)
                onPageChanged: (newFocusedDay) {
                  // Only update the focusedDay when switching months, do not reset selectedDay
                  setState(() {
                    focusedDay =
                        newFocusedDay; // Update the focused day without affecting selectedDay
                  });
                  fetchActivities();
                },
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            // Expanded ListView for Activities with no glow

            Expanded(
              child: selectedActivities.isEmpty
                  ? EmptyData(
                      noDataMessage: localizations.noActivity,
                      message: localizations.takeABreak,
                    )
                  : ListView.builder(
                      itemCount: selectedActivities.length,
                      itemBuilder: (context, index) {
                        final activity = selectedActivities[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 8.0),
                          child: ActivityCard(
                            activity: activity,
                            onTap: () async {
                              final groupAndUsers = activity.groupAndUsers;

                              // Ensure there are groups in the activity
                              if (groupAndUsers == null ||
                                  groupAndUsers.isEmpty) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(localizations.noGroup),
                                      content:
                                          Text(localizations.noAssociatedOrgs),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: Text("OK"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                                return; // Exit since there are no groups
                              }

                              if (selectedOrganization != null) {
                                try {
                                  // Find the group matching the selected organization
                                  final selectedGroup =
                                      groupAndUsers.firstWhere(
                                    (group) =>
                                        group.groupID == selectedOrganization,
                                  );

                                  // Proceed with the found group
                                  await _checkRoleAndNavigate(
                                      selectedGroup, activity, localizations);
                                  return; // Exit after successful navigation
                                } catch (e) {
                                  // Handle the case where no matching group is found
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(localizations.error),
                                        content:
                                            Text(localizations.errorOccurred),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: Text("OK"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  return; // Exit after showing the error
                                }
                              }

                              // Handle multiple groups
                              if (groupAndUsers.length > 1) {
                                // Show dialog to select a group
                                final selectedGroup =
                                    await showDialog<GroupAndUser>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                        localizations.selectGroup,
                                        style: TextStyle(
                                          fontSize: screenHeight * 0.018,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: groupAndUsers.length,
                                          itemBuilder: (context, index) {
                                            final group = groupAndUsers[index];
                                            return Card(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4,
                                                      horizontal: 8),
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: ListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8),
                                                title: Text(
                                                  group.groupName ??
                                                      localizations.noData,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                trailing: Icon(
                                                    Icons.chevron_right,
                                                    color:
                                                        Colors.grey.shade700),
                                                onTap: () {
                                                  Navigator.of(context).pop(
                                                      group); // Return selected group
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context)
                                              .pop(null), // No selection
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.redAccent,
                                          ),
                                          child: Text(
                                            localizations.cancel,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    );
                                  },
                                );

                                if (selectedGroup == null) {
                                  // If the user cancels the selection, return
                                  return;
                                }

                                // Proceed with the selected group
                                await _checkRoleAndNavigate(
                                    selectedGroup, activity, localizations);
                              } else {
                                // Only one group exists, proceed directly
                                await _checkRoleAndNavigate(groupAndUsers.first,
                                    activity, localizations);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkRoleAndNavigate(GroupAndUser selectedGroup,
      Activity activity, AppLocalizations localizations) async {
    try {
      // Await the userGroups Future to get the actual list
      final userGroupList = await userGroups;

      // Find the user group matching the selected group
      final userGroup = userGroupList!.firstWhere(
        (group) => group.groupId == selectedGroup.groupID,
      );
      final String leader = dotenv.env['LEADER'] ?? '';
      final String accountant = dotenv.env['GROUPACCOUNTANT'] ?? '';

      // Determine if the user is a leader
      final isLeader =
          userGroup.roleName == leader || userGroup.roleName == accountant;

      // Navigate based on the user's role
      Get.to(
          () => isLeader
              ? TaskManagementPage(
                  activityId: activity.id,
                  activityName: activity.activityName!,
                  group: userGroup,
                )
              : TaskPage(
                  activityId: activity.id,
                  activityName: activity.activityName!,
                  group: userGroup,
                ),
          id: 2,
          transition: Transition.rightToLeftWithFade,
          routeName: isLeader ? "/TaskManagementPage" : "/TaskPage");
    } catch (e) {
      // Handle errors during role checking
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(localizations.error),
            content: Text(localizations.errorOccurred),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }
}

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  User? currentUser;
  final refreshController = Get.find<RefreshController>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getUserLogin();
  }

  void getUserLogin() async {
    setState(() {
      isLoading = true;
    });

    final user = await getLoginInfoFromPrefs();

    if (mounted) {
      setState(() {
        currentUser = user;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProgressHUD(
        inAsyncCall: isLoading, opacity: 0.3, child: _uiSetup(context));
  }

  Widget _uiSetup(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    final uiProvider = Provider.of<UIProvider>(context);
    bool isDark = uiProvider.themeMode == ThemeMode.dark ||
        (uiProvider.themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    final localizations = AppLocalizations.of(context)!;

    // Show loading state until user data is fetched
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(localizations.menu,
              style: Theme.of(context).textTheme.headlineMedium),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Obx(() {
      if (refreshController.shouldRefresh.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          getUserLogin();
          refreshController.setShouldRefresh(false);
        });
      } else if (refreshController.user.value.id != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          getUserLogin();
          refreshController.resetUser();
        });
      }

      String getLocalizedRole(BuildContext context, String roleKey) {
        final role = dotenv.env[roleKey.toUpperCase()];
        if (role == null) {
          return localizations.noData; // Fallback for unknown roles
        }
        switch (role.toLowerCase()) {
          case 'admin':
            return localizations.admin;
          case 'priest':
            return localizations.priest;
          case 'council':
            return localizations.council;
          case 'accountant':
            return localizations.accountant;
          case 'member':
            return localizations.member;
          default:
            return localizations.noData;
        }
      }

      final role = getLocalizedRole(context, currentUser!.role!);
      final defaultAvatar = AvatarFormat().getRandomAvatarColor();
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(localizations.menu,
              style: Theme.of(context).textTheme.headlineMedium),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            child: Column(
              children: [
                Center(
                  child: currentUser?.imageURL != null
                      ? GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierColor: Colors.black.withOpacity(0.8),
                              builder: (context) => Dialog(
                                backgroundColor: Colors.transparent,
                                child: PhotoViewer(
                                  imageUrl: currentUser!.imageURL!,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: screenHeight * 0.13,
                            height: screenHeight * 0.13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade200,
                            ),
                            child: ClipOval(
                              child: Image.network(
                                currentUser!.imageURL!,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  }
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  (loadingProgress
                                                          .expectedTotalBytes ??
                                                      1)
                                              : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.error,
                                      color: Colors.red,
                                      size: screenHeight * 0.065,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: defaultAvatar,
                          radius: screenHeight * 0.065,
                          child: Text(
                            AvatarFormat().getInitials(
                                currentUser?.name ?? localizations.noData,
                                twoLetters: true),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.1,
                            ),
                          ),
                        ),
                ),
                SizedBox(height: screenHeight * 0.02),
                Text(currentUser?.name ?? localizations.noData,
                    style: TextStyle(
                        fontSize: screenHeight * 0.02,
                        fontWeight: FontWeight.bold)),
                Text(currentUser?.email ?? localizations.noData,
                    style: TextStyle(fontSize: screenHeight * 0.016)),
                Text(role, style: TextStyle(fontSize: screenHeight * 0.016)),
                SizedBox(height: screenHeight * 0.02),
                SizedBox(
                  width: screenWidth * 0.45,
                  height: screenHeight * 0.06,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.to(() => const UpdateProfilePage(),
                          id: 3, transition: Transition.rightToLeftWithFade);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Const.primaryGoldenColor,
                      side: BorderSide.none,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      localizations.editProfile,
                      style: TextStyle(
                          color: Colors.black, fontSize: screenHeight * 0.02),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                const Divider(
                  thickness: 0.2,
                ),
                SizedBox(height: screenHeight * 0.005),
                ProfileMenuWidget(
                  title: localizations.changePassword,
                  icon: LineAwesomeIcons.lock_open_solid,
                  iconColor: isDark
                      ? Const.primaryGoldenColor
                      : Colors.orange.shade800,
                  onTap: () {
                    Get.to(() => const ChangePasswordPage(),
                        id: 3, transition: Transition.rightToLeftWithFade);
                  },
                ),
                ProfileMenuWidget(
                  title: localizations.settings,
                  icon: LineAwesomeIcons.cog_solid,
                  iconColor: isDark
                      ? Const.primaryGoldenColor
                      : Colors.orange.shade800,
                  onTap: () {
                    Get.to(() => const SettingsPage(),
                        id: 3, transition: Transition.rightToLeftWithFade);
                  },
                ),
                ProfileMenuWidget(
                  title: localizations.logout,
                  icon: LineAwesomeIcons.sign_out_alt_solid,
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  endIcon: false,
                  onTap: () async {
                    final firebaseMessaging = FirebaseMessaging.instance;
                    final deviceId = await firebaseMessaging.getToken();
                    final apiService = ApiService();
                    if (deviceId != null) {
                      await apiService.deleteDeviceId(deviceId);
                    }
                    const storage = FlutterSecureStorage();
                    final SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await storage.delete(key: 'token');
                    prefs.remove('loginInfo');
                    prefs.remove('loginUserGroups');

                    showToast(localizations.logOutSuccess);
                    Get.off(const LoginPage());
                  },
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
