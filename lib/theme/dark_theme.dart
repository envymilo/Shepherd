import 'package:flutter/material.dart';
import 'package:shepherd_mo/constant/constant.dart';

ThemeData darkTheme = ThemeData.dark().copyWith(
  primaryColor: Colors.black,
  brightness: Brightness.dark,
  primaryColorLight: Colors.grey[900],
  scaffoldBackgroundColor: Colors.black,
  cardColor: Colors.grey[800],
  dividerColor: Colors.grey[700],
  disabledColor: Colors.grey[600],
  focusColor: Const.primaryGoldenColor,
  hoverColor: Const.primaryGoldenColor.withOpacity(0.2),
  highlightColor: Const.primaryGoldenColor.withOpacity(0.2),
  splashColor: Const.primaryGoldenColor.withOpacity(0.3),
  unselectedWidgetColor: Colors.grey[500],

  // AppBar Theme
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Const.primaryGoldenColor,
      fontWeight: FontWeight.bold,
      fontSize: 20,
    ),
  ),

  // Color Scheme
  colorScheme: ColorScheme.dark(
    surface: Colors.grey[850]!,
    primary: Const.primaryGoldenColor,
    secondary: Colors.grey[700]!,
    onPrimary: Colors.black,
    onSecondary: Colors.white,
    error: Colors.redAccent,
    onSurface: Colors.white,
  ),

  // Text Selection Theme
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: Const.primaryGoldenColor,
    selectionColor: Const.primaryGoldenColor.withOpacity(0.5),
    selectionHandleColor: Const.primaryGoldenColor,
  ),

  // Input Decoration Theme (TextField styling)
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[700], // Background color for TextFormField
    focusColor: Const.primaryGoldenColor,
    iconColor: Colors.white,
    labelStyle: const TextStyle(color: Colors.white), // Label text color
    hintStyle: const TextStyle(color: Colors.white70), // Hint text color
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Const.primaryGoldenColor, width: 2.0),
      borderRadius: BorderRadius.circular(8.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey[600]!, width: 1.0),
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

  // Icon Theme
  iconTheme: const IconThemeData(color: Colors.white),
  primaryIconTheme: const IconThemeData(color: Colors.white),

  textButtonTheme: TextButtonThemeData(
    style: ButtonStyle(
      foregroundColor: WidgetStateProperty.all(Colors.black),
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
  // Slider Theme
  sliderTheme: SliderThemeData(
    activeTrackColor: Const.primaryGoldenColor,
    inactiveTrackColor: Colors.grey[700],
    thumbColor: Const.primaryGoldenColor,
    overlayColor: Const.primaryGoldenColor.withOpacity(0.2),
  ),

  // Floating Action Button Theme
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Const.primaryGoldenColor,
    foregroundColor: Colors.black,
  ),

  // Button Theme
  buttonTheme: ButtonThemeData(
    buttonColor: Const.primaryGoldenColor,
    disabledColor: Colors.grey[700],
    textTheme: ButtonTextTheme.primary,
  ),
);
