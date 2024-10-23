import 'package:ai3/pages/auth_page.dart';
import 'package:ai3/pages/dashboard.dart';
import 'package:ai3/pages/history.dart';
import 'package:ai3/pages/home_page.dart';
import 'package:ai3/pages/notifications.dart';
import 'package:ai3/pages/watchscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(); // Initialize Firebase
  } catch (e) {
    // Handle initialization error
    print('Firebase initialization error: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Computer Vision',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      routes: {
        '/': (context) => AuthPage(),
        '/auth_page': (context) => const AuthPage(),
        '/dashboard': (context) => DashboardPage(),
        '/home_page': (context) => HomePage(),
        '/history': (context) => HistoryPage(),
        '/notifications': (context) => NotificationsPage(),
        '/watch_screen': (context) => WatchScreenPage(),
        // Define other routes here
      },
      // Optional: Add localization, theme customization, etc.
    );
  }
}
