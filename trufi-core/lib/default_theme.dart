import 'package:flutter/material.dart';

final ColorScheme lightColorScheme =
    ColorScheme.fromSeed(
      seedColor: const Color(0xFF4285F4), // azul similar al de Google Maps
      secondary: const Color(0xFFD81B60), // acento magenta del tema original
      brightness: Brightness.light,
    ).copyWith(
      // en Material 3 el fondo se basa en las nuevas tonalidades de superficie,
      // aquí lo ajustamos para que las pantallas queden ligeramente grisáceas
      background: Colors.grey[50],
      surfaceTint: Colors
          .transparent, // evita superposiciones con tinte [oai_citation:5‡docs.flutter.dev](https://docs.flutter.dev/release/breaking-changes/material-3-migration#:~:text=The%20,AppBar)
    );

final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF4285F4),
  secondary: const Color(0xFFD81B60),
  brightness: Brightness.dark,
).copyWith(background: Colors.grey[850], surfaceTint: Colors.transparent);

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: lightColorScheme,
  // Superficie general de la aplicación (fondo de Scaffold)
  scaffoldBackgroundColor: lightColorScheme.surfaceContainerLowest,
  // Barra de navegación superior
  appBarTheme: AppBarTheme(
    backgroundColor: lightColorScheme.surface,
    foregroundColor: lightColorScheme.onSurface,
    centerTitle: true,
    elevation: 0,
  ),
  // Botón flotante (FAB)
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: lightColorScheme.primaryContainer,
    foregroundColor: lightColorScheme.onPrimaryContainer,
    shape: const StadiumBorder(),
  ),
  // Estilo de selección de texto (cursor y selección)
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: lightColorScheme.secondary,
    selectionColor: lightColorScheme.secondary.withOpacity(0.4),
    selectionHandleColor: lightColorScheme.secondary,
  ),
  // Tarjetas (Cards)
  cardTheme: CardThemeData(
    color: lightColorScheme.surface,
    elevation: 1,
    margin: const EdgeInsets.all(8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  // Campos de texto (InputDecoration)
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: lightColorScheme.surfaceContainerLow,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: lightColorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: lightColorScheme.primary),
    ),
  ),
  // Botones elevados conforme a Material 3
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: lightColorScheme.primary,
      foregroundColor: lightColorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
    ),
  ),
  // Estilo para la barra de navegación inferior de Material 3
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: lightColorScheme.surfaceContainerLow,
    indicatorColor: lightColorScheme.primaryContainer,
    labelTextStyle: MaterialStateProperty.all(
      TextStyle(color: lightColorScheme.onSurface),
    ),
    iconTheme: MaterialStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(MaterialState.selected)
            ? lightColorScheme.onPrimaryContainer
            : lightColorScheme.onSurfaceVariant,
      ),
    ),
  ),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: darkColorScheme,
  scaffoldBackgroundColor: darkColorScheme.surfaceContainerLowest,
  appBarTheme: AppBarTheme(
    backgroundColor: darkColorScheme.surface,
    foregroundColor: darkColorScheme.onSurface,
    centerTitle: true,
    elevation: 0,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: darkColorScheme.primaryContainer,
    foregroundColor: darkColorScheme.onPrimaryContainer,
    shape: const StadiumBorder(),
  ),
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: darkColorScheme.secondary,
    selectionColor: darkColorScheme.secondary.withOpacity(0.4),
    selectionHandleColor: darkColorScheme.secondary,
  ),
  cardTheme: CardThemeData(
    color: darkColorScheme.surface,
    elevation: 1,
    margin: const EdgeInsets.all(8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: darkColorScheme.surfaceContainerLow,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: darkColorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: darkColorScheme.primary),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    backgroundColor: darkColorScheme.surfaceContainerLow,
    indicatorColor: darkColorScheme.primaryContainer,
    labelTextStyle: MaterialStateProperty.all(
      TextStyle(color: darkColorScheme.onSurface),
    ),
    iconTheme: MaterialStateProperty.resolveWith(
      (states) => IconThemeData(
        color: states.contains(MaterialState.selected)
            ? darkColorScheme.onPrimaryContainer
            : darkColorScheme.onSurfaceVariant,
      ),
    ),
  ),
);
