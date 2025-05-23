import 'package:flutter/material.dart';

ThemeData buildLearnNThemes(Color textIconColorProvider, Color userColor) {
  return ThemeData(
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: textIconColorProvider,
      selectionColor: const Color.fromRGBO(255, 255, 255, 0.5),
      selectionHandleColor: textIconColorProvider,
    ),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(
        fontFamily: 'PressStart2P',
        color: textIconColorProvider,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: textIconColorProvider,
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: textIconColorProvider,
          width: 2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: textIconColorProvider,
          width: 3,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      shape: const StadiumBorder(),
      backgroundColor: userColor,
      contentTextStyle: TextStyle(
        color: textIconColorProvider,
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
