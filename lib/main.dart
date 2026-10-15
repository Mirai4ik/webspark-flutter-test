import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/task_api.dart';
import 'presentation/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(WebsparkApp(
    api: TaskApi(preferences: preferences),
  ));
}

class WebsparkApp extends StatelessWidget {
  const WebsparkApp({super.key, required this.api});

  final TaskApi api;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF2196F3);
    return MaterialApp(
      title: 'Shortest Path',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE6EAF0)),
          ),
        ),
      ),
      home: HomePage(api: api),
    );
  }
}
