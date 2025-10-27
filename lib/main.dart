import 'package:dpmssurveyapp/pages/login_and_home_manager.dart';
import 'package:dpmssurveyapp/pages/authenticate_with_o_auth_offline.dart';
import 'package:dpmssurveyapp/pages/authenticate_and_export_offline.dart';
import 'package:flutter/material.dart';
import 'package:arcgis_maps/arcgis_maps.dart';

void main() {
  const apiKey = 'AAPK02c8ef93a9984180bbebab60498ccd5eFkjYiIVXsIc4VFPBm0Bu82nzFI6eIJDNHBBiRUlRmuyNxfvjf_MKL30fVpuRcmlA';
  if (apiKey.isEmpty) {
    throw Exception('API key undefined');
  } else {
    ArcGISEnvironment.apiKey = apiKey;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginAndHomeManager());
  // Widget build(BuildContext context) => MaterialApp(home: AuthenticateWithOAuthOffline());
  // Widget build(BuildContext context) => MaterialApp(home: AuthenticateAndExportOffline());
}

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,

  // Primary color scheme - Indigo focus
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    primary: Colors.indigo.shade700,
    secondary: Colors.indigo.shade400,
    surface: Colors.white,
    background: Colors.indigo.shade50,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.indigo.shade900,
    onBackground: Colors.indigo.shade900,
  ),

  // Scaffold & Background
  scaffoldBackgroundColor: Colors.indigo.shade50,

  // AppBar styling
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.indigo.shade700,
    foregroundColor: Colors.white,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
    ),
    titleTextStyle: TextStyle(
      fontSize: 20,
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
    iconTheme: const IconThemeData(color: Colors.white),
  ),

  // Elevated Buttons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.disabled)) {
            return Colors.indigo.shade200;
          }
          return Colors.indigo.shade700;
        },
      ),
      foregroundColor: MaterialStateProperty.all(Colors.white),
      elevation: MaterialStateProperty.all(0), // Flat buttons by default
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      padding: MaterialStateProperty.all(
        const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
      textStyle: MaterialStateProperty.all(
        const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
  ),

  // Outlined (Holo) buttons
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.indigo.shade700,
      side: BorderSide(color: Colors.indigo.shade400, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    ),
  ),

  // Inputs and text fields
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.indigo.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
    ),
    labelStyle: TextStyle(color: Colors.indigo.shade700),
    hintStyle: TextStyle(color: Colors.indigo.shade400),
  ),

  // // Dialog styling (Material 3: DialogThemeData)
  // dialogTheme: DialogThemeData(
  //   backgroundColor: Colors.white,
  //   surfaceTintColor: Colors.white,
  //   shadowColor: Colors.black.withOpacity(0.1),
  //   elevation: 10,
  //   shape: RoundedRectangleBorder(
  //     borderRadius: BorderRadius.circular(16),
  //     side: BorderSide(color: Colors.indigo.shade200, width: 1),
  //   ),
  //   titleTextStyle: TextStyle(
  //     color: Colors.indigo.shade700,
  //     fontSize: 22,
  //     fontWeight: FontWeight.w600,
  //   ),
  //   contentTextStyle: TextStyle(
  //     color: Colors.indigo.shade900,
  //     fontSize: 16,
  //   ),
  // ),
  dialogTheme: DialogThemeData(
    backgroundColor: const Color(0xFFE8F7FF),
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.black.withOpacity(0.1),
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: Colors.indigo.shade200, width: 1),
    ),
    titleTextStyle: TextStyle(
      color: Colors.indigo.shade700,
      fontSize: 22,
      fontWeight: FontWeight.w600,
    ),
    contentTextStyle: TextStyle(
      color: Colors.indigo.shade900,
      fontSize: 16,
    ),
  ),



  // Cards (Material 3: CardThemeData)
  cardTheme: CardThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.white,
    shadowColor: Colors.black.withOpacity(0.1),
    elevation: 4,
    margin: const EdgeInsets.all(12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.indigo.shade100, width: 1),
    ),
  ),

  // Lists, Texts & Icons
  listTileTheme: ListTileThemeData(
    iconColor: Colors.indigo.shade700,
    textColor: Colors.indigo.shade900,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),

  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: const Color(0xFFE8F7FF),
    modalBackgroundColor: const Color(0xFFE8F7FF),
    surfaceTintColor: Colors.transparent,
    elevation: 8,
    modalElevation: 8,
    showDragHandle: true,
    clipBehavior: Clip.antiAliasWithSaveLayer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: Color(0xFF8DCAFF), width: 1),
    ),
  ),

  iconTheme: IconThemeData(color: Colors.indigo.shade700),

  textTheme: TextTheme(
    bodyMedium: TextStyle(color: Colors.indigo.shade900),
    bodyLarge: TextStyle(
      color: Colors.indigo.shade900,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: TextStyle(color: Colors.indigo.shade700),
  ),
);






