import 'package:flutter/material.dart';

ThemeData buildAppTheme(BuildContext context) {
  const seed = Color(0xFF3B2F4A); // dark whimsical purple
  final colorScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFF121018),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    useMaterial3: true,
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: 'Roboto',
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colorScheme.surfaceContainerHigh,
      contentTextStyle: const TextStyle(color: Colors.white),
    ),
  );
}
