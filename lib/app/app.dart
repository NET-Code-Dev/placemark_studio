import 'package:flutter/material.dart';
import '../app/themes/app_theme.dart';
import '../app/routes/route_generator.dart';

class PlacemarkStudioApp extends StatelessWidget {
  const PlacemarkStudioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Placemark Studio - File Converter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/',
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
