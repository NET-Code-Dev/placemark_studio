import 'package:flutter/material.dart';
import '../app/themes/app_theme.dart';
import '../presentation/views/home/home_view.dart';

class PlacemarkStudioApp extends StatelessWidget {
  const PlacemarkStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Placemark Studio - KML Converter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const HomeView(),
    );
  }
}
