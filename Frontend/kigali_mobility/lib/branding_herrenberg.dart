import 'package:flutter/material.dart';

final brandingKigaliMobility = ThemeData.from(
  useMaterial3: false,
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: const MaterialColor(
      0xfffecc01,
      <int, Color>{
        50: Color(0xfffff8e0),
        100: Color(0xffffedb0),
        200: Color(0xfffee17c),
        300: Color(0xfffed643),
        400: Color(0xfffecb01),
        500: Color(0xffffc200),
        600: Color(0xffffb400),
        700: Color(0xffffa000),
        800: Color(0xffff8e00),
        900: Color(0xffff6d00),
      },
    ),
    accentColor: const Color(0xfffecc01),
    cardColor: Colors.white,
    backgroundColor: Colors.grey[50],
    errorColor: Colors.red,
  ),
).copyWith(
  primaryColor: Colors.black,
  scaffoldBackgroundColor: Colors.grey[200],
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xfffecc01),
    foregroundColor: Colors.black,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
  ),
);
