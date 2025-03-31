import 'package:flutter/material.dart';
import 'home_page.dart';     // Наш экран HomePage
import 'auth_page.dart';    // Экран авторизации (AuthPage)
import 'style.dart';        // Стиль приложения

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {  
    return MaterialApp(
      title: 'Social Stats Tracker',
      theme: ThemeData(
        primaryColor: AppStyle.primaryColor,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppStyle.primaryColor,
          secondary: AppStyle.accentColor,
        ),
      ),
      initialRoute: '/auth', // Точка входа: экран авторизации
      routes: {
        '/auth': (context) => const AuthPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
