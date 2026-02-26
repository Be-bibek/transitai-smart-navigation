import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/main_ai_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Immersive mode for spatial computing feel
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AERO Sathi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'Roboto', // Modern, clean
        useMaterial3: true,
      ),
      // Direct entry to the only screen in the app
      home: const MainAIPage(),
    );
  }
}
