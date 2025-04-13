// lib/main.dart
import 'package:flutter/material.dart';
import 'home.dart'; // Import the new home.dart file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chess Timer',
      theme: ThemeData(
        // Consistent dark theme base
        brightness: Brightness.dark,
        primaryColor: Colors.grey[900],
        scaffoldBackgroundColor: Colors.grey[900],
        // Define a color scheme (optional but good practice)
        colorScheme: ColorScheme.dark(
          primary: Colors.green[700]!, // Use green as primary accent
          secondary: Colors.blueGrey[600]!, // Secondary accent
          surface: Colors.grey[850]!, // Card/dialog backgrounds
          background: Colors.grey[900]!, // Main background
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white.withOpacity(0.9),
          onBackground: Colors.white.withOpacity(0.9),
          error: Colors.redAccent,
          onError: Colors.white,
        ),
         // Apply theme to specific widgets if needed
         appBarTheme: AppBarTheme(
           backgroundColor: Colors.grey[900],
           elevation: 0,
           titleTextStyle: const TextStyle(
             color: Colors.white,
             fontSize: 24,
             fontWeight: FontWeight.bold
           ),
           iconTheme: const IconThemeData(color: Colors.white70), // Back button etc.
         ),
         dialogTheme: DialogTheme(
            backgroundColor: Colors.grey[850],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
         ),
        // You can further customize button themes, text themes, etc. here
      ),
      home: const HomePage(), // Point to HomePage from home.dart
    );
  }
}