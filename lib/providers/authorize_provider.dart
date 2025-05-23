import 'package:flutter/material.dart';

class AuthorizationProvider with ChangeNotifier {
  bool _isAuthorized = false;

  bool get isAuthorized => _isAuthorized;

  bool _isLeader = false;

  bool get isLeader => _isLeader;

  // Method to update authorization state
  Future<void> updateAuthorizationStatus(bool newStatus) async {
    if (_isAuthorized != newStatus) {
      _isAuthorized = newStatus;
      notifyListeners(); // Notify listeners when the state changes
    }
  }

  Future<void> updateLeaderAuthorizationStatus(bool newStatus) async {
    if (_isLeader != newStatus) {
      _isLeader = newStatus;
      notifyListeners(); // Notify listeners when the state changes
    }
  }
}
