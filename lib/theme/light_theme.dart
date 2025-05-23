import 'package:flutter/material.dart';
import 'package:shepherd_mo/constant/constant.dart';

// Define the primary color

ThemeData lightTheme = ThemeData(
  primaryColor: Colors.white,
  useMaterial3: true,
  brightness: Brightness.light,
  primaryColorLight: Colors.white,

  // AppBar Theme
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.black),
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
  ),

  // Color Scheme
  colorScheme: ColorScheme.light(
    surface: Colors.grey[100]!,
    primary:
        Const.primaryGoldenColor, // Main primary color for widgets like buttons
    secondary: Colors.grey[200]!,
    onPrimary: Colors.black, // Text color on primary surfaces
  ),

  // Text Selection Theme (TextField selection, cursor, etc.)
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Const.primaryGoldenColor,
    selectionColor: Const.primaryGoldenColor.withOpacity(0.5),
    selectionHandleColor: Const.primaryGoldenColor,
  ),

  iconTheme: const IconThemeData(color: Colors.black),
  primaryIconTheme: const IconThemeData(color: Colors.black),

  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all(Colors.black), // Text color
      backgroundColor: WidgetStateProperty.all(Const.primaryGoldenColor),
      padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0)),
      textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      shape: WidgetStateProperty.all(RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      )),
    ),
  ),

  // Input Decoration Theme (TextField styling)
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[200],
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Const.primaryGoldenColor, width: 2.0),
      borderRadius: BorderRadius.circular(8.0),
    ),
    labelStyle: const TextStyle(color: Colors.black),
    focusColor: Const.primaryGoldenColor,
    iconColor: Colors.black,
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey[300]!, width: 1.0),
      borderRadius: BorderRadius.circular(8.0),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
    ),
  ),

  // Elevated Button Theme
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Const.primaryGoldenColor,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
  ),
);
