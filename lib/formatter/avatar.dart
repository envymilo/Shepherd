import 'dart:math';
import 'package:flutter/material.dart';

class AvatarFormat {
  final List<Color> _avatarColors = [
    Colors.brown,
    Colors.deepOrange,
    Colors.indigo,
    Colors.teal,
    Colors.blueGrey,
    Colors.deepPurple,
  ];
  final Random _random = Random();

  String getInitials(String fullName, {bool twoLetters = false}) {
    if (fullName.isEmpty) return '?';

    List<String> nameParts = fullName.trim().split(' ');

    if (twoLetters) {
      if (nameParts.length > 1) {
        return nameParts[nameParts.length - 2][0] + nameParts.last[0];
      }
    }
    return nameParts.last[0];
  }

  Color getRandomAvatarColor() {
    return _avatarColors[_random.nextInt(_avatarColors.length)];
  }
}
