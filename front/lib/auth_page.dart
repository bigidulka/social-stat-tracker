import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'style.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Новые поля для регистрации
  final _nameController = TextEditingController();
  final _telegramController = TextEditingController();

  // Переменная для роли — "SMM" или "SMM директор"
  String _selectedRole = 'SMM';
  final List<String> _roles = ['SMM', 'SMM директор'];

  // Храним токен
  String? _token;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  //=== ФУНКЦИИ РАБОТЫ С СЕРВЕРОМ ==============================================

  // Логин
  Future<void> _login() async {
    final url = Uri.parse('http://bigidulka2.ddns.net:8000/auth/login');
    final body = {
      "username": _usernameController.text.trim(),
      "password": _passwordController.text.trim(),
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final data = _decodeJson(response);
        _token = data["access_token"];
        // Переходим на основную страницу
        Navigator.pushReplacementNamed(context, '/home', arguments: _token);
      } else {
        _showErrorDialog(_extractDetail(response));
      }
    } catch (e) {
      _showErrorDialog("Ошибка сети: $e");
    }
  }

  // Регистрация (с проверкой совпадения паролей + обязательные поля)
  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final name = _nameController.text.trim();
    final telegram = _telegramController.text.trim();

    if (username.isEmpty) {
      _showErrorDialog('Введите имя пользователя');
      return;
    }
    if (name.isEmpty) {
      _showErrorDialog('Введите ваше имя');
      return;
    }
    if (telegram.isEmpty) {
      _showErrorDialog('Введите ваш Telegram');
      return;
    }
    if (telegram.startsWith('@')) {
      _showErrorDialog('Не указывайте символ "@" в Telegram');
      return;
    }
    if (password.length < 6) {
      _showErrorDialog('Пароль должен быть не менее 6 символов');
      return;
    }
    if (password != confirmPassword) {
      _showErrorDialog('Пароли не совпадают');
      return;
    }

    final url = Uri.parse('http://bigidulka2.ddns.net:8000/auth/register');
    final body = {
      "username": username,
      "password": password,
      "confirm_password": confirmPassword,
      "role": _selectedRole == 'SMM' ? 'smm_analyst' : 'smm_director',
      "name": name,
      "telegram": telegram
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // После успешной регистрации сразу выполним вход, чтобы не заставлять юзера делать лишние действия
        await _login();
      } else {
        _showErrorDialog(_extractDetail(response));
      }
    } catch (e) {
      _showErrorDialog("Ошибка соединения: $e");
    }
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
  final utf8Body = utf8.decode(response.bodyBytes);
  return json.decode(utf8Body);
}

  // Забыли пароль
  Future<void> _forgotPassword() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _showErrorDialog("Введите логин, чтобы сбросить пароль");
      return;
    }

    final url = Uri.parse('http://bigidulka2.ddns.net:8000/auth/forgot-password');
    final body = {"username": username};

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200) {
        final data = _decodeJson(response);
        final newPass = data["new_password"] ?? "???";
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Пароль сброшен'),
            content: Text('Ваш новый пароль: $newPass'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              )
            ],
          ),
        );
      } else {
        _showErrorDialog(_extractDetail(response));
      }
    } catch (e) {
      _showErrorDialog("Ошибка сети: $e");
    }
  }

  //=== ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ================================================

  String _extractDetail(http.Response response) {
    try {
      final data =  _decodeJson(response);
      return data["detail"] ?? "Неизвестная ошибка";
    } catch (_) {
      return "Неизвестная ошибка: ${response.statusCode}";
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  //=== ПОСТРОЕНИЕ UI =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Заголовок
                    Text(
                      _isLogin ? 'Вход' : 'Регистрация',
                      style: AppStyle.titleTextStyle,
                    ),
                    const SizedBox(height: 16),

                    // ЛОГИН
                    TextField(
                      controller: _usernameController,
                      decoration: AppStyle.inputDecoration.copyWith(
                        labelText: 'Логин',
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Пароль
                    TextField(
                      controller: _passwordController,
                      decoration: AppStyle.inputDecoration.copyWith(
                        labelText: 'Пароль',
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),

                    // Если регистрируемся — показываем дополнительные поля
                    if (!_isLogin) ...[
                      const SizedBox(height: 16),
                      // Повтор пароля
                      TextField(
                        controller: _confirmPasswordController,
                        decoration: AppStyle.inputDecoration.copyWith(
                          labelText: 'Повторите пароль',
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),

                      // Имя
                      TextField(
                        controller: _nameController,
                        decoration: AppStyle.inputDecoration.copyWith(
                          labelText: 'Ваше имя',
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Telegram
                      TextField(
                        controller: _telegramController,
                        decoration: AppStyle.inputDecoration.copyWith(
                          labelText: 'Telegram (без @)',
                          prefixIcon: const Icon(Icons.alternate_email),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Роль
                      Row(
                        children: [
                          const Text('Роль:'),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: _selectedRole,
                            items: _roles.map((role) {
                              return DropdownMenuItem<String>(
                                value: role,
                                child: Text(role),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (!mounted) return;
                              setState(() {
                                _selectedRole = value!;
                              });
                            },
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Кнопка Войти/Зарегистрироваться
                    ElevatedButton(
                      style: AppStyle.buttonStyle,
                      onPressed: () {
                        if (_isLogin) {
                          _login();
                        } else {
                          _register();
                        }
                      },
                      child: Text(
                        _isLogin ? 'Войти' : 'Зарегистрироваться',
                      ),
                    ),

                    // Кнопка "Забыли пароль"
                    TextButton(
                      onPressed: _forgotPassword,
                      child: const Text('Забыли пароль?'),
                    ),

                    const SizedBox(height: 8),

                    // Переключатель "Нет аккаунта? / Уже есть аккаунт?"
                    GestureDetector(
                      onTap: () {
                        if (!mounted) return;
                        setState(() {
                          _isLogin = !_isLogin;
                        });
                      },
                      child: Text(
                        _isLogin
                            ? 'Нет аккаунта? Нажми для регистрации'
                            : 'Уже есть аккаунт? Нажми для входа',
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
