import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

// directors_groups_page.dart
// Страница, где SMM-директор может выбрать аналитика,
// а потом добавлять/удалять ему паблики как в стандартном GroupsPage.

// Пример эндпоинтов (их нужно реализовать на бэкенде для полной работы):
//  1) GET /directors/analysts?token=...
//  2) GET /directors/{analyst_id}/groups?token=...
//  3) POST /directors/{analyst_id}/groups?token=... (в body: { "screen_name": "..." })
//  4) DELETE /directors/{analyst_id}/groups/{group_id}?token=...

class DirectorsGroupsPage extends StatefulWidget {
  final String? token; // Токен директора

  const DirectorsGroupsPage({Key? key, this.token}) : super(key: key);

  @override
  State<DirectorsGroupsPage> createState() => _DirectorsGroupsPageState();
}

class _DirectorsGroupsPageState extends State<DirectorsGroupsPage> {
  bool _isLoadingAnalysts = false;           // Для загрузки списка аналитиков
  bool _isLoadingGroups = false;             // Для загрузки пабликов выбранного аналитика

  List<dynamic> _analysts = [];              // Список аналитиков
  int? _selectedAnalystId;                   // ID выбранного аналитика
  String _selectedAnalystName = '';          // Имя выбранного аналитика (для заголовка)

  final _groupIdController = TextEditingController();

  List<dynamic> _groups = []; // Список пабликов выбранного аналитика
  bool _isAddingGroup = false; // Показ индикатора при добавлении паблика

  @override
  void initState() {
    super.initState();
    _loadAnalysts();
  }

  @override
  void dispose() {
    _groupIdController.dispose();
    super.dispose();
  }

  // Загрузка списка аналитиков для директора
  Future<void> _loadAnalysts() async {
    if (widget.token == null) return;
    setState(() {
      _isLoadingAnalysts = true;
    });

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
        // Обработка ошибки
        print('Ошибка при загрузке аналитиков: ${response.body}');
      }
    } catch (e) {
      print('Исключение: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAnalysts = false;
        });
      }
    }
  }

  // Загрузка пабликов для выбранного аналитика
  Future<void> _loadGroupsForAnalyst(int analystId) async {
    if (widget.token == null) return;
    setState(() {
      _isLoadingGroups = true;
      _groups = [];
    });

    // Допустим, у нас есть эндпоинт:
    // GET /directors/{analyst_id}/groups?token=...
    final url = Uri.parse('http://bigidulka2.ddns.net:8000/directors/$analystId/groups?token=${widget.token}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = _decodeResponse(response);
        if (decoded is List) {
          if (!mounted) return;
          setState(() {
            _groups = decoded;
          });
        }
      } else {
        print('Ошибка при загрузке пабликов: ${response.body}');
      }
    } catch (e) {
      print('Исключение: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGroups = false;
        });
      }
    }
  }

  // Добавление паблика выбранному аналитику
  Future<void> _addPublicToAnalyst() async {
    if (widget.token == null || _selectedAnalystId == null) return;
    final screenName = _groupIdController.text.trim();
    if (screenName.isEmpty) return;

    setState(() {
      _isAddingGroup = true;
    });

    // Допустим, у нас есть эндпоинт:
    // POST /directors/{analyst_id}/groups?token=...
    // Тело: { "screen_name": "..." }
    final url = Uri.parse(
      'http://bigidulka2.ddns.net:8000/directors/${_selectedAnalystId!}/groups?token=${widget.token}',
    );
    final body = {
      "screen_name": screenName,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final parsed = _decodeResponse(response);
        if (parsed is Map<String, dynamic>) {
          if (!mounted) return;
          setState(() {
            _groups.add(parsed); // Добавляем новую запись в список
          });
          // Очищаем поле ввода
          _groupIdController.clear();
          // Показываем диалог о новом паблике (можно взять логику из GroupsPage)
          final vkData = parsed["vk_data"] ?? {};
          _showNewGroupDialog(vkData);
        }
      } else {
        final errorText = response.body;
        _showStatusDialog("Ошибка", errorText);
      }
    } catch (e) {
      print('Исключение при добавлении паблика: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAddingGroup = false;
        });
      }
    }
  }

  // Удаление паблика у выбранного аналитика
  Future<void> _unlinkGroup(int groupId) async {
    if (widget.token == null || _selectedAnalystId == null) return;

    // Допустим, у нас есть эндпоинт:
    // DELETE /directors/{analyst_id}/groups/{group_id}?token=...
    final url = Uri.parse(
      'http://bigidulka2.ddns.net:8000/directors/${_selectedAnalystId!}/groups/$groupId?token=${widget.token}',
    );
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (!mounted) return;
        setState(() {
          _groups.removeWhere(
            (element) => element["db_data"]["id"] == groupId,
          );
        });
        Navigator.of(context).pop(); // Закрываем bottom sheet
      } else {
        print('Ошибка при отвязке: ${response.body}');
      }
    } catch (e) {
      print('Исключение при отвязке: $e');
    }
  }

  // Диалоговая форма для добавления паблика
  void _showAddPublicSheet() {
    if (_selectedAnalystId == null) {
      _showStatusDialog('Внимание', 'Сначала выбери аналитика из списка.');
      return;
    }
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
              Text(
                'Добавить паблик аналитику $_selectedAnalystName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _groupIdController,
                decoration: InputDecoration(
                  labelText: 'Введите screen_name или ID паблика',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _addPublicToAnalyst();
                },
                child: _isAddingGroup
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Добавить'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Диалог с сообщением
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

  // Диалог о новом паблике (примерно как в GroupsPage)
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
      builder: (_) => AlertDialog(
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
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(12)),
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
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, top: 8),
                        child: Text('Город: $cityTitle'),
                      ),
                    if (site.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, top: 8),
                        child: Text('Сайт: $site'),
                      ),
                    if (membersCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, right: 16.0, top: 8),
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
      ),
    );
  }

  // Показ "меню настроек" для каждого паблика (по аналогии с GroupsPage)
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
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12)),
                                  child: Image.network(
                                    coverUrl,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16.0),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Text(description),
                                ),
                              if (cityTitle.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16.0, right: 16.0, top: 8),
                                  child: Text('Город: $cityTitle'),
                                ),
                              if (site.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16.0, right: 16.0, top: 8),
                                  child: Text('Сайт: $site'),
                                ),
                              if (membersCount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16.0, right: 16.0, top: 8),
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

  // Декодируем UTF-8
  dynamic _decodeResponse(http.Response response) {
    Uint8List bytes = response.bodyBytes;
    String utf8Body = utf8.decode(bytes);
    return json.decode(utf8Body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Паблики (Директор)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddPublicSheet,
            tooltip: 'Добавить паблик',
          ),
        ],
      ),
      body: Column(
        children: [
          // Выбор аналитика
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _isLoadingAnalysts
                ? const Center(child: CircularProgressIndicator())
                : DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedAnalystId,
                    hint: const Text('Выбери аналитика'),
                    items: _analysts.map((analyst) {
                      final id = analyst['id'] as int?;
                      final name = analyst['name'] ?? 'Без имени';
                      final username = analyst['username'] ?? '';
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text('$name (логин: $username)'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final selected = _analysts.firstWhere(
                        (a) => a['id'] == value,
                        orElse: () => null,
                      );
                      setState(() {
                        _selectedAnalystId = value;
                        _selectedAnalystName = selected?['name'] ?? '';
                      });
                      _loadGroupsForAnalyst(value);
                    },
                  ),
          ),
          const Divider(),
          // Список пабликов выбранного аналитика
          Expanded(
            child: _selectedAnalystId == null
                ? const Center(
                    child: Text('Сначала выбери аналитика, чтобы увидеть паблики'),
                  )
                : _isLoadingGroups
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
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 32, horizontal: 24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.group,
                                          size: 64, color: Colors.blueAccent),
                                      const SizedBox(height: 16),
                                      Text(
                                        'У аналитика $_selectedAnalystName нет пабликов',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Добавь паблик, чтобы аналитик начал собирать метрики.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: _showAddPublicSheet,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Добавить паблик'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _groups.length,
                                itemBuilder: (_, index) {
                                  final item = _groups[index];
                                  final dbData = item["db_data"];
                                  final vkData = item["vk_data"];
                                  final title = vkData != null &&
                                          vkData["name"] != null
                                      ? vkData["name"]
                                      : (dbData["name"] ?? "Без названия");
                                  final screenName =
                                      dbData["screen_name"] ?? '';
                                  return Card(
                                    child: ListTile(
                                      title: Text(title),
                                      subtitle: Text(screenName),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.settings),
                                        onPressed: () => _showSettingsMenu(item),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
