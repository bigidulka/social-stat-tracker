import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'groups_page.dart';
import 'metrics_page.dart';
import 'profile_page.dart';


enum BottomTabs { publics, metrics, profile }

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BottomTabs _currentTab = BottomTabs.publics;
  String? _token;                   // Токен, полученный из аргументов
  Map<String, dynamic>? _userData;  // Данные пользователя

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Забираем аргументы (токен) из навигатора
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _token = args;
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    if (_token == null) return;
    final url = Uri.parse('http://bigidulka2.ddns.net:8000/auth/me');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $_token',
      },
    );
    if (response.statusCode == 200) {
      if (mounted) {
      setState(() {
        _userData = json.decode(response.body);
      });}
    } else {
      // Здесь можно добавить обработку ошибки
    }
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/auth');
  }

  @override
  Widget build(BuildContext context) {
    Widget currentPage;
    switch (_currentTab) {
      case BottomTabs.publics:
        currentPage = GroupsPage(token: _token);
        break;
      case BottomTabs.metrics:
        currentPage = MetricsPage(token: _token);
        break;
      case BottomTabs.profile:
        currentPage = ProfilePage(
          userData: _userData,
          token: _token, 
          onLogout: _logout,
        );
        break;
    }

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Social Stats Tracker'),
      // ),
      body: currentPage,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab.index,
        onTap: (index) {
          if (mounted) {
          setState(() {
            _currentTab = BottomTabs.values[index];
          });
        }},
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Паблики',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart),
            label: 'Метрики',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Кабинет',
          ),
        ],
      ),
    );
  }
}
