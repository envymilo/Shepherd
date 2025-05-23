import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shepherd_mo/controller/controller.dart';
import 'package:shepherd_mo/pages/notification_page.dart';
import 'package:shepherd_mo/utils/toast.dart';

Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Payload: ${message.data}');
}

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  final _androidChannel = const AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This chanel is used for important notification',
    importance: Importance.max,
    playSound: true,
    showBadge: true,
  );
  final _localNotifications = FlutterLocalNotificationsPlugin();

  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    final NotificationController notiControl =
        Get.find<NotificationController>();
    final BottomNavController bottomNavControl =
        Get.find<BottomNavController>();

    if (notiControl.openTabIndex.value != -1) {
      bottomNavControl.selectedIndex.value = notiControl.openTabIndex.value;
    } else if (notiControl.openTabIndex.value == -1) {
      Get.to(
        () => const NotificationPage(),
        id: bottomNavControl.selectedIndex.value,
        transition: Transition.topLevel,
      );
      notiControl.openNotificationPage(bottomNavControl.selectedIndex.value);
    }
  }

  Future initLocalNotifications() async {
    const iOS = DarwinInitializationSettings();
    const android = AndroidInitializationSettings('@drawable/ic_launcher');
    const settings = InitializationSettings(android: android, iOS: iOS);

    await _localNotifications.initialize(settings,
        onDidReceiveNotificationResponse: (details) {
      final message = RemoteMessage.fromMap(jsonDecode(details.payload!));
      handleMessage(message);
    });

    final platform = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(_androidChannel);
  }

  Future initPushNotifications() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;

      if (notification == null) return;
      final LocaleController localeController = Get.find<LocaleController>();
      bool isEnglish = localeController.currentLocale.countryCode == 'en';
      if (isEnglish) {
        showToast("New notification");
      } else {
        showToast("Thông báo mới");
      }

      _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
              android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: '@drawable/ic_launcher',
            playSound: true,
            importance: Importance.max,
            showWhen: true,
            priority: Priority.high,
            channelShowBadge: true,
          )),
          payload: jsonEncode(message.toMap()));
    });
  }

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();
    final fCMToken = await _firebaseMessaging.getToken();
    print('Token: $fCMToken');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('fCMToken', fCMToken!);

    initPushNotifications();
    initLocalNotifications();
  }
}
