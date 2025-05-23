import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RouteTracker extends GetObserver {
  final Function(String) onRouteChange;
  String currentRoute = '/Home'; // Initial route

  RouteTracker({required this.onRouteChange});

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    currentRoute = route.settings.name ?? '/Home';
    onRouteChange(currentRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    currentRoute = previousRoute?.settings.name ?? '/Home';
    onRouteChange(currentRoute);
  }

  // Function to get the current route
  String getCurrentRoute() {
    return currentRoute;
  }
}
