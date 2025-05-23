import 'package:get/get.dart';
import 'package:shepherd_mo/pages/home_page.dart';
import 'package:shepherd_mo/pages/notification_page.dart';
import 'package:shepherd_mo/pages/settings_page.dart';

class AppRoutes {
  static const String home = '/home';
  static const String schedule = '/schedule';
  static const String activities = '/activities';
  static const String menu = '/menu';
  static const String settings = '/settings';
  static const String notifications = '/notifications';

  static final List<GetPage> routes = [
    GetPage(name: home, page: () => const HomeTab()),
    GetPage(name: schedule, page: () => const ScheduleTab()),
    GetPage(name: activities, page: () => const ActivitiesTab()),
    GetPage(name: menu, page: () => const MenuTab()),
    GetPage(name: settings, page: () => const SettingsPage()),
    GetPage(name: notifications, page: () => const NotificationPage()),
  ];
}
