import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'style.dart';

class GroupsPage extends StatefulWidget {
  final String? token;
  const GroupsPage({Key? key, this.token}) : super(key: key);
  

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  final _groupIdController = TextEditingController();

  bool _isLoading = true;
  // Список данных. Каждый элемент: {"db_data": {...}, "vk_data": {...}}
  List<dynamic> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _groupIdController.dispose();
    super.dispose();
  }

  // Декодируем ответ (UTF-8 -> JSON)
  dynamic _decodeResponse(http.Response response) {
    Uint8List bytes = response.bodyBytes;
    String utf8Body = utf8.decode(bytes);
    return json.decode(utf8Body);
  }

Future<void> _loadGroups() async {
  if (widget.token == null) return;
  setState(() {
    _isLoading = true; // <- показываем индикатор
  });

  final url = Uri.parse('http://bigidulka2.ddns.net:8000/groups/');
  try {
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      final decoded = _decodeResponse(response);
      if (decoded is List) {
        if (!mounted) return;
        setState(() {
          _groups = decoded;
        });
      }
    } else {
      print('Ошибка при загрузке групп: ${response.body}');
    }
  } catch (e) {
    print('Исключение при загрузке групп: $e');
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false; // <- убираем индикатор
      });
    }
  }
}


  // Диалоговая функция для показа формы добавления паблика
  void _showAddPublicSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Добавить паблик',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _groupIdController,
                decoration: AppStyle.inputDecoration.copyWith(
                  labelText: 'Введите ID паблика',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: AppStyle.buttonStyle,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _addPublic();
                },
                child: const Text('Добавить'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Функция показа статуса в диалоге
  void _showStatusDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Показываем красивую карточку добавленного паблика (данные из VK)
  void _showNewGroupDialog(Map<String, dynamic> vkData) {
    final coverData = vkData['cover'];
    final coverUrl = (coverData != null &&
            coverData['enabled'] == 1 &&
            coverData['images'] != null &&
            (coverData['images'] as List).isNotEmpty)
        ? coverData['images'].last['url']
        : null;
    final photoUrl = vkData['photo_100'] ?? vkData['photo_50'];
    final name = vkData['name'] ?? '';
    final description = vkData['description'] ?? '';
    final cityObj = vkData['city'];
    final cityTitle = cityObj != null ? cityObj['title'] : '';
    final site = vkData['site'] ?? '';
    final membersCount = vkData['members_count'] ?? 0;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (coverUrl != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            if (photoUrl != null)
                              CircleAvatar(
                                backgroundImage: NetworkImage(photoUrl),
                                radius: 40,
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(description),
                        ),
                      if (cityTitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8),
                          child: Text('Город: $cityTitle'),
                        ),
                      if (site.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8),
                          child: Text('Сайт: $site'),
                        ),
                      if (membersCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8),
                          child: Text('Участников: $membersCount'),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  // Добавление новой группы
  Future<void> _addPublic() async {
    if (widget.token == null || _groupIdController.text.isEmpty) {
      _showStatusDialog('Ошибка', 'Введите ID паблика и авторизуйся.');
      return;
    }
    final url = Uri.parse('http://bigidulka2.ddns.net:8000/groups/');
    final body = {
      "screen_name": _groupIdController.text,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
      Map<String, dynamic>? parsed;
      try {
        parsed = _decodeResponse(response) as Map<String, dynamic>?;
      } catch (_) {
        parsed = null;
      }
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (parsed != null) {
          if (!mounted) return;
          setState(() {
            _groups.add(parsed);
          });
          _groupIdController.clear();
          final vkData = parsed["vk_data"] ?? {};
          _showNewGroupDialog(vkData);
        }
      } else {
        final detail = parsed?['detail'] ?? 'Неизвестная ошибка';
        _showStatusDialog('Ошибка ${response.statusCode}', detail);
      }
    } catch (e) {
      _showStatusDialog('Сетевая ошибка', 'Проверь соединение.\n$e');
    }
  }

  // Меню настроек группы с карточкой и кнопкой закрытия (крестик)
  void _showSettingsMenu(Map<String, dynamic> groupItem) {
    final dbData = groupItem["db_data"];
    final vkData = groupItem["vk_data"];

    final coverData = vkData['cover'];
    final coverUrl = (coverData != null &&
            coverData['enabled'] == 1 &&
            coverData['images'] != null &&
            (coverData['images'] as List).isNotEmpty)
        ? coverData['images'].last['url']
        : null;
    final photoUrl = vkData['photo_100'] ?? vkData['photo_50'];
    final name = vkData['name'] ?? '';
    final description = vkData['description'] ?? '';
    final cityObj = vkData['city'];
    final cityTitle = cityObj != null ? cityObj['title'] : '';
    final site = vkData['site'] ?? '';
    final membersCount = vkData['members_count'] ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 32.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (coverUrl != null)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.network(
                                    coverUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Row(
                                  children: [
                                    if (photoUrl != null)
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(photoUrl),
                                        radius: 40,
                                      ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(description),
                                ),
                              if (cityTitle.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8),
                                  child: Text('Город: $cityTitle'),
                                ),
                              if (site.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8),
                                  child: Text('Сайт: $site'),
                                ),
                              if (membersCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8),
                                  child: Text('Участников: $membersCount'),
                                ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text('Отвязать паблик'),
                          onTap: () => _unlinkGroup(dbData["id"] as int),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                // Кнопка "крестик" в правом верхнем углу
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Удаляем связь user->group
  Future<void> _unlinkGroup(int groupId) async {
    if (widget.token == null) return;
    final url = Uri.parse('http://bigidulka2.ddns.net:8000/groups/unlink/$groupId');
    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (!mounted) return;
        setState(() {
          _groups.removeWhere((element) => element["db_data"]["id"] == groupId);
        });
        Navigator.of(context).pop();
      } else {
        print("Ошибка при отвязке: ${response.body}");
      }
    } catch (e) {
      print("Исключение: $e");
    }
  }

  // Построение экрана групп
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Паблики'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPublicSheet,
            tooltip: 'Добавить паблик',
          ),
        ],
      ),
body: _isLoading
    ? const Center(child: CircularProgressIndicator())
    : _groups.isEmpty
        ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.group, size: 64, color: Colors.blueAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'Паблики отсутствуют',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Добавьте паблик, чтобы начать отслеживать его метрики.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddPublicSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить паблик'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
    : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _groups.length,
            itemBuilder: (_, index) {
              final item = _groups[index];
              final dbData = item["db_data"];
              final vkData = item["vk_data"];
              final title = vkData != null && vkData["name"] != null
                  ? vkData["name"]
                  : (dbData["name"] ?? "Без названия");
              return ListTile(
                title: Text(title),
                subtitle: Text('${dbData["screen_name"]}'),
                trailing: IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => _showSettingsMenu(item),
                ),
              );
            },
          ),
        ),
      ),

    );
  }
}
