// lib/profile_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'style.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? userData; // Данные пользователя: {username, role, name, telegram, unique_code, ...}
  final String? token;                 // Токен для API
  final VoidCallback onLogout;

  const ProfilePage({
    Key? key,
    required this.userData,
    required this.onLogout,
    this.token,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<dynamic> _analysts = [];        // Список аналитиков для директора
  Map<String, dynamic>? _myDirector;     // Данные директора для аналитика

  @override
  void initState() {
    super.initState();
    _loadAnalystsIfDirector();     // Загрузка аналитиков для директора
    _loadMyDirectorIfAnalyst();    // Загрузка директора для аналитика
  }

  // Функция для загрузки аналитиков (для директора)
  Future<void> _loadAnalystsIfDirector() async {
    if (widget.userData == null || widget.token == null) return;
    if (widget.userData!["role"] != "smm_director") return;
    final url = Uri.parse('http://bigidulka2.ddns.net:8000/directors/analysts?token=${widget.token}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is List) {
          if (!mounted) return;
          setState(() {
            _analysts = decoded;
          });
        }
      } else {
        print('Ошибка при загрузке аналитиков: ${response.body}');
      }
    } catch (e) {
      print('Исключение при загрузке аналитиков: $e');
    }
  }

  // Функция для загрузки директора (для аналитика)
  Future<void> _loadMyDirectorIfAnalyst() async {
    if (widget.userData == null || widget.token == null) return;
    if (widget.userData!["role"] != "smm_analyst") return;
    final url = Uri.parse('http://bigidulka2.ddns.net:8000/directors/my-director?token=${widget.token}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          _myDirector = decoded;
        });
      } else {
        setState(() {
          _myDirector = null;
        });
      }
    } catch (e) {
      print('Исключение при загрузке директора: $e');
    }
  }

  // Функция для отвязки аналитика (для директора)
  Future<void> _unlinkAnalyst(int analystId) async {
    if (widget.token == null) return;
    final url = Uri.parse('http://bigidulka2.ddns.net:8000/directors/unlink-analyst/$analystId?token=${widget.token}');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _analysts.removeWhere((a) => a["id"] == analystId);
        });
      } else {
        print('Ошибка при отвязке: ${response.body}');
      }
    } catch (e) {
      print('Исключение: $e');
    }
  }

  // Функция для отвязки директора (для аналитика)
  Future<void> _unlinkMyDirector() async {
    if (widget.token == null) return;
    final url = Uri.parse('http://bigidulka2.ddns.net:8000/directors/unlink-my-director?token=${widget.token}');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        setState(() {
          _myDirector = null;
        });
      } else {
        print('Ошибка при отвязке директора: ${response.body}');
      }
    } catch (e) {
      print('Исключение: $e');
    }
  }

  // Диалог привязки аналитика по логину
  Future<void> _linkAnalystDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Привязать аналитика (логин)'),
          content: TextField(
            controller: controller,
            decoration: AppStyle.inputDecoration.copyWith(
              labelText: 'Логин аналитика',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              style: AppStyle.buttonStyle,
              onPressed: () async {
                final success = await _linkAnalystByLogin(controller.text.trim());
                if (success) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Привязать'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _linkAnalystByLogin(String analystUsername) async {
    if (widget.token == null) return false;
    final url = Uri.parse('http://bigidulka2.ddns.net:8000/directors/link-analyst?token=${widget.token}');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({"analyst_username": analystUsername}),
      );
      if (response.statusCode == 200) {
        await _loadAnalystsIfDirector();
        return true;
      } else {
        print('Ошибка при привязке: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Исключение: $e');
      return false;
    }
  }

  // Построение QR-кода для директора
  Widget _buildQrForDirector(String uniqueCode) {
    if (uniqueCode.isEmpty) {
      return const Text("unique_code пуст. Обратись к администратору.");
    }
    return Column(
      children: [
        const Text(
          'Поделись этим QR-кодом с SMM-аналитиком:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        QrImageView(
          data: uniqueCode,
          version: QrVersions.auto,
          size: 200.0,
        ),
        const SizedBox(height: 8),
        Text("Код: $uniqueCode", style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  // Переход на экран сканирования QR (для аналитика)
  void _goToScanPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _QrScanPage(token: widget.token ?? "")),
    ).then((_) {
      _loadMyDirectorIfAnalyst();
    });
  }

  // Улучшенная карточка с информацией о пользователе с иконками
  Widget _buildInfoCard(Map<String, dynamic> user) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _infoRow(Icons.person, "Логин", user["username"]),
            _infoRow(Icons.badge, "Имя", user["name"]),
            _infoRow(Icons.telegram, "Телеграм", user["telegram"]),
            _infoRow(Icons.work, "Роль", user["role"]),
            _infoRow(Icons.date_range, "Дата регистрации", "${user["date_of_registration"]}"),
            _infoRow(Icons.code, "Уникальный код", user["unique_code"]),
          ],
        ),
      ),
    );
  }

  // Виджет строки с информацией, где добавлена иконка
  Widget _infoRow(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty || value == "null") {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userData;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final isDirector = user["role"] == "smm_director";
    final isAnalyst = user["role"] == "smm_analyst";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Личный кабинет'),
        // centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoCard(user),
            const SizedBox(height: 16),
            // Виджет для директора: список аналитиков и QR-код
            if (isDirector)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Привязанные аналитики',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (_analysts.isEmpty)
                        const Text('Пока нет привязанных аналитиков.'),
                      for (final a in _analysts)
                        ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              a["name"] != null && a["name"].toString().isNotEmpty
                                  ? a["name"][0]
                                  : a["username"][0],
                            ),
                          ),
                          title: Text(a["name"] ?? a["username"] ?? "Без имени"),
                          subtitle: Text("Логин: ${a["username"]}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.link_off),
                            tooltip: 'Отвязать',
                            onPressed: () => _unlinkAnalyst(a["id"]),
                          ),
                        ),
                      const Divider(),
                      _buildQrForDirector(user["unique_code"] ?? ""),
                    ],
                  ),
                ),
              ),
            // Виджет для аналитика: либо кнопка сканирования, либо карточка с информацией о директоре
            if (isAnalyst) ...[
              _myDirector == null
                  ? ElevatedButton.icon(
                      style: AppStyle.buttonStyle,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Сканировать QR директора'),
                      onPressed: _goToScanPage,
                    )
                  : Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_circle, size: 30, color: Colors.blueAccent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Ваш SMM-директор: ${_myDirector!["name"] ?? _myDirector!["username"]}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              style: AppStyle.buttonStyle,
                              icon: const Icon(Icons.link_off),
                              label: const Text("Отвязаться"),
                              onPressed: _unlinkMyDirector,
                            ),
                          ],
                        ),
                      ),
                    ),
            ],
            const SizedBox(height: 24),
            // Кнопка выхода
TextButton(
  onPressed: widget.onLogout,
  style: TextButton.styleFrom(
    foregroundColor: Colors.red, // Цвет текста
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: const Text(
    'Выйти',
    style: TextStyle(
      color: Colors.red,         // Цвет текста
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ),
),


          ],
        ),
      ),
    );
  }
}

// Экран сканирования QR (без изменений)
class _QrScanPage extends StatefulWidget {
  final String token; // Токен аналитика

  const _QrScanPage({required this.token});

  @override
  State<_QrScanPage> createState() => __QrScanPageState();
}

class __QrScanPageState extends State<_QrScanPage> {
  bool _isScanning = true;

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;
    final barcode = capture.barcodes.first;
    final code = barcode.rawValue;
    if (code == null || code.isEmpty) return;
    if (!mounted) return;
    setState(() => _isScanning = false);
    final url = Uri.parse("http://bigidulka2.ddns.net:8000/directors/link-by-code");
    final body = {"unique_code": code, "token": widget.token};
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Успех"),
            content: const Text("Ты успешно привязался к директору!"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              )
            ],
          ),
        ).then((_) => Navigator.of(context).pop());
      } else {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        final rawDetail = decoded["detail"];
        String detailMessage;
        if (rawDetail is List) {
          detailMessage = rawDetail.join(", ");
        } else if (rawDetail is String) {
          detailMessage = rawDetail;
        } else {
          detailMessage = "Неизвестная ошибка";
        }
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Ошибка"),
            content: Text(detailMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Ошибка"),
          content: Text("$e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            )
          ],
        ),
      ).then((_) => Navigator.of(context).pop());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Сканирование QR-кода"),
        centerTitle: true,
      ),
      body: _isScanning
          ? MobileScanner(onDetect: _onDetect)
          : const Center(child: Text("Сканирование завершено")),
    );
  }
}
