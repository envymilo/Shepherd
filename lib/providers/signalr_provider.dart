import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shepherd_mo/controller/controller.dart';
import 'package:shepherd_mo/models/task.dart';
import 'package:shepherd_mo/models/user.dart';
import 'package:shepherd_mo/services/get_login.dart';
import 'package:shepherd_mo/utils/toast.dart';
import 'package:signalr_core/signalr_core.dart';

class SignalRService with ChangeNotifier {
  late HubConnection hubConnection;
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  Task task = Task();

  bool _isDisposed = false; // Track if the service is disposed

  SignalRService() {
    String url = dotenv.env['SIGNALR_URL'] ?? '';
    hubConnection = HubConnectionBuilder()
        .withUrl(
          url,
          HttpConnectionOptions(
            logging: (level, message) =>
                print("SignalR Log [$level]: $message"),
          ),
        )
        .withAutomaticReconnect()
        .build();

    hubConnection.serverTimeoutInMilliseconds = 60000;
    hubConnection.keepAliveIntervalInMilliseconds = 15000;

    configureConnectionEvents();
  }

  Future<void> startConnection() async {
    try {
      if (hubConnection.state == HubConnectionState.connected) {
        print('SignalR is already connected.');
        return;
      }

      print('Starting SignalR connection...');
      await hubConnection.start();
      _isConnected = true;
      if (!_isDisposed) {
        notifyListeners();
      }
      print('SignalR Connected.');
      setupListeners();
    } catch (e, stackTrace) {
      _isConnected = false;
      print('Error connecting to SignalR: $e');
      print('StackTrace: $stackTrace');
      Future.delayed(Duration(seconds: 5), () {
        print('Retrying SignalR connection...');
        startConnection();
      });
    }
  }

  Future<void> stopConnection() async {
    if (hubConnection.state == HubConnectionState.disconnected) {
      print('SignalR is already disconnected.');
      return;
    }

    try {
      await hubConnection.stop();
      _isConnected = false;
      if (!_isDisposed) {
        notifyListeners();
      }
      print('SignalR Disconnected.');
    } catch (e) {
      print('Error stopping SignalR connection: $e');
    }
  }

  void setupListeners() {
    hubConnection.on('LoadNotifications', (arguments) async {
      if (_isDisposed) return; // Prevent further execution if disposed

      if (arguments != null && arguments.isNotEmpty) {
        final notiUsers = arguments;
        final loginInfo = await getLoginInfoFromPrefs();
        final NotificationController notiControl =
            Get.find<NotificationController>();

        if (loginInfo != null) {
          final user = loginInfo!.id;
          if (notiUsers.contains(user)) {
            await notiControl.fetchUnreadCount();
          }
          if (notiControl.openTabIndex.value != -1) {
            notiControl.shouldReload.value = true;
          }
          if (!_isDisposed) {
            notifyListeners();
          }
        }
      }
    });

    // Listener for Kanban updates
    hubConnection.on('LoadTasks', (arguments) async {
      if (arguments != null && arguments.isNotEmpty) {
        final RouteController routeController = Get.find<RouteController>();
        final RefreshController refreshController =
            Get.find<RefreshController>();
        final currentRoute = routeController.currentRoute.value;
        if (currentRoute == "/TaskPage" ||
            currentRoute == "/TaskManagementPage" ||
            currentRoute == "/UpdateProgress") {
          refreshController.shouldRefreshSignal.value = true;
          refreshController.task.value = Task.fromJson(arguments[0]);
        }
        if (!_isDisposed) {
          notifyListeners();
        }
      }
    });

    hubConnection.on('LoadUsers', (arguments) async {
      if (arguments != null && arguments.isNotEmpty) {
        final user = User.fromJson(arguments[0]);
        final loginInfo = await getLoginInfoFromPrefs();

        if (loginInfo != null) {
          if (loginInfo.id == user.id) {
            final SharedPreferences prefs =
                await SharedPreferences.getInstance();
            final RefreshController refreshController =
                Get.find<RefreshController>();
            refreshController.user.value = user;
            prefs.setString('loginInfo', jsonEncode(user));
          }
        }
        if (!_isDisposed) {
          notifyListeners();
        }
      }
    });
  }

  void configureConnectionEvents() {
    hubConnection.onclose((error) {
      _isConnected = false;
      if (!_isDisposed) {
        notifyListeners();
      }
      print('Connection closed: $error');
      Future.delayed(Duration(seconds: 5), () {
        print('Reconnecting SignalR...');
        startConnection();
      });
    });

    hubConnection.onreconnecting((error) {
      _isConnected = false;
      if (!_isDisposed) {
        notifyListeners();
      }
      print('Reconnecting to SignalR: $error');
    });

    hubConnection.onreconnected((connectionId) {
      _isConnected = true;
      if (!_isDisposed) {
        notifyListeners();
      }
      print('Reconnected to SignalR with connectionId: $connectionId');
    });
  }

  @override
  void dispose() {
    _isDisposed = true; // Mark the service as disposed
    super.dispose();
  }
}
