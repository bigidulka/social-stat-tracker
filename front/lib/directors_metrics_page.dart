import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'metrics_card_widget.dart';

// Импортируем файл, где определён SimpleMetricsCardTabs
// import 'metrics_card_widget.dart';

class DirectorsMetricsPage extends StatefulWidget {
  final String? token;

  const DirectorsMetricsPage({Key? key, this.token}) : super(key: key);

  @override
  State<DirectorsMetricsPage> createState() => _DirectorsMetricsPageState();
}

class _DirectorsMetricsPageState extends State<DirectorsMetricsPage> {
  // Список аналитиков
  List<dynamic> _analysts = [];
  bool _isLoadingAnalysts = false;
  int? _selectedAnalystId;
  String _selectedAnalystName = '';

  // Группы выбранного аналитика
  List<dynamic> _analystGroups = [];
  bool _isLoadingGroups = false;
  String? _selectedGroup;

  // Параметры для /vk_rout/metrics
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _sortBy = 'date';
  Set<String> _filters = {};

  // Результат ответа /vk_rout/metrics
  Map<String, dynamic>? _metricsData;
  bool _isLoadingMetrics = false;

  // Для управления раскрытием постов
  Map<int, bool> _expandedPosts = {};

  @override
  void initState() {
    super.initState();
    _loadAnalysts();
  }

  // Функция для вычисления количества дней в выбранном периоде
  int _calculateDaysCount() {
    if (_dateFrom == null || _dateTo == null) {
      return 0;
    }
    return _dateTo!.difference(_dateFrom!).inDays + 1;
  }

  // Загрузка аналитиков
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
          setState(() {
            _analysts = decoded;
          });
        }
      }
    } catch (e) {
      // Обработка ошибок
      print('Ошибка при загрузке аналитиков: $e');
    } finally {
      setState(() {
        _isLoadingAnalysts = false;
      });
    }
  }

  // Загрузка групп выбранного аналитика
  Future<void> _loadGroupsForAnalyst(int analystId) async {
    if (widget.token == null) return;
    setState(() {
      _isLoadingGroups = true;
      _analystGroups = [];
      _metricsData = null;
      _selectedGroup = null;
    });

    final url = Uri.parse('http://bigidulka2.ddns.net:8000/directors/$analystId/groups?token=${widget.token}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = _decodeResponse(response);
        if (decoded is List) {
          setState(() {
            _analystGroups = decoded;
          });
        }
      }
    } catch (e) {
      print('Ошибка при загрузке групп аналитика: $e');
    } finally {
      setState(() {
        _isLoadingGroups = false;
      });
    }
  }

  // Запрос метрик
  Future<void> _fetchMetrics() async {
    if (widget.token == null || _selectedGroup == null) return;
    setState(() {
      _isLoadingMetrics = true;
      _metricsData = null;
    });

    final queryParams = <String, String>{
      'group_name': _selectedGroup!,
      'sort_by': _sortBy,
    };

    if (_dateFrom != null && _dateTo != null) {
      final fromTs = _dateFrom!.millisecondsSinceEpoch ~/ 1000;
      final toTs = _dateTo!.millisecondsSinceEpoch ~/ 1000;
      queryParams['date_from'] = fromTs.toString();
      queryParams['date_to'] = toTs.toString();
    }
    if (_filters.isNotEmpty) {
      queryParams['filters'] = _filters.join(',');
    }

    final uri = Uri.http('bigidulka2.ddns.net:8000', '/vk_rout/metrics', queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          _metricsData = data;
        });
      }
    } catch (e) {
      print('Ошибка при загрузке метрик: $e');
    } finally {
      setState(() {
        _isLoadingMetrics = false;
      });
    }
  }

  // Диалог для настроек фильтра
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Функция для чекбоксов
            Widget buildFilterCheck(String label) {
              return CheckboxListTile(
                title: Text(label),
                value: _filters.contains(label),
                onChanged: (val) {
                  setStateDialog(() {
                    if (val == true) {
                      _filters.add(label);
                    } else {
                      _filters.remove(label);
                    }
                  });
                },
              );
            }

            return AlertDialog(
              title: const Text('Настройки выборки'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Аналитики
                    DropdownButton<int>(
                      isExpanded: true,
                      value: _selectedAnalystId,
                      hint: const Text('Выбери аналитика'),
                      items: _analysts.map((a) {
                        final id = a['id'] as int?;
                        final name = a['name'] ?? 'Без имени';
                        final username = a['username'] ?? '';
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text('$name (логин: $username)'),
                        );
                      }).toList(),
                      onChanged: (val) async {
                        if (val == null) return;
                        setStateDialog(() {
                          _selectedAnalystId = val;
                          final foundAnalyst = _analysts.firstWhere(
                            (x) => x['id'] == val,
                            orElse: () => null,
                          );
                          _selectedAnalystName = foundAnalyst?['name'] ?? '';
                          _analystGroups.clear();
                          _selectedGroup = null;
                          _metricsData = null;
                        });
                        await _loadGroupsForAnalyst(val);
                        setStateDialog(() {});
                      },
                    ),
                    const SizedBox(height: 12),

                    // Группы
                    _isLoadingGroups
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedGroup,
                            hint: const Text('Выбери группу'),
                            items: _analystGroups.map((grp) {
                              final dbData = grp["db_data"] ?? {};
                              final vkData = grp["vk_data"] ?? {};
                              final groupName = vkData["name"] ?? dbData["name"] ?? 'Группа';
                              final screenName = dbData["screen_name"] ?? '';
                              return DropdownMenuItem<String>(
                                value: screenName,
                                child: Text(groupName),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setStateDialog(() {
                                _selectedGroup = val;
                                _metricsData = null;
                              });
                            },
                          ),
                    const SizedBox(height: 12),

                    // Кнопки быстрого периода
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            final now = DateTime.now();
                            setStateDialog(() {
                              _dateFrom = now.subtract(const Duration(days: 7));
                              _dateTo = now;
                            });
                          },
                          child: const Text('Неделя'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final now = DateTime.now();
                            setStateDialog(() {
                              _dateFrom = DateTime(now.year, now.month - 1, now.day);
                              _dateTo = now;
                            });
                          },
                          child: const Text('Месяц'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final now = DateTime.now();
                            setStateDialog(() {
                              _dateFrom = DateTime(now.year - 1, now.month, now.day);
                              _dateTo = now;
                            });
                          },
                          child: const Text('Год'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Ручной выбор дат
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            const Text('От:'),
                            TextButton(
                              onPressed: () async {
                                final initDate = _dateFrom ?? DateTime.now().subtract(const Duration(days: 30));
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: initDate,
                                  firstDate: DateTime(2010),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setStateDialog(() {
                                    _dateFrom = picked;
                                  });
                                }
                              },
                              child: Text(
                                _dateFrom == null
                                    ? 'Выбрать'
                                    : '${_dateFrom!.day}.${_dateFrom!.month}.${_dateFrom!.year}',
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('До:'),
                            TextButton(
                              onPressed: () async {
                                final initDate = _dateTo ?? DateTime.now();
                                final picked = await showDatePicker(
                                  context: ctx,
                                  initialDate: initDate,
                                  firstDate: DateTime(2010),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setStateDialog(() {
                                    _dateTo = picked;
                                  });
                                }
                              },
                              child: Text(
                                _dateTo == null
                                    ? 'Выбрать'
                                    : '${_dateTo!.day}.${_dateTo!.month}.${_dateTo!.year}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Сортировка
                    Row(
                      children: [
                        const Text('Сортировка:'),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: _sortBy,
                          items: const [
                            DropdownMenuItem(value: 'date', child: Text('По дате')),
                            DropdownMenuItem(value: 'likes', child: Text('По лайкам')),
                            DropdownMenuItem(value: 'reposts', child: Text('По репостам')),
                            DropdownMenuItem(value: 'comments', child: Text('По комментариям')),
                            DropdownMenuItem(value: 'views', child: Text('По просмотрам')),
                          ],
                          onChanged: (val) {
                            setStateDialog(() {
                              _sortBy = val ?? 'date';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Фильтры
                    const Text('Фильтры (мультивыбор):'),
                    buildFilterCheck('text'),
                    buildFilterCheck('photo'),
                    buildFilterCheck('video'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _fetchMetrics();
                  },
                  child: const Text('Загрузить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Построение главного экрана
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Метрики (директор)'),
        actions: [
          if (_selectedAnalystId != null || _selectedGroup != null)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Сбросить выбор',
              onPressed: () {
                setState(() {
                  _selectedAnalystId = null;
                  _selectedAnalystName = '';
                  _analystGroups.clear();
                  _selectedGroup = null;
                  _metricsData = null;
                  _dateFrom = null;
                  _dateTo = null;
                  _filters.clear();
                });
              },
            ),
        ],
      ),
      body: _isLoadingAnalysts
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterDialog,
        child: const Icon(Icons.filter_alt),
      ),
    );
  }

  Widget _buildBody() {
    if (_selectedAnalystId == null || _selectedGroup == null) {
      return Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.assessment, size: 64, color: Colors.blueAccent),
                SizedBox(height: 16),
                Text(
                  'Выбери аналитика и паблик',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Через кнопку в правом нижнем углу укажи\nаналитика, паблик, даты и другие параметры.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoadingMetrics) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_metricsData == null) {
      return const Center(
        child: Text('Выберите настройки и нажмите "Загрузить"'),
      );
    }

    // Добавляем SimpleMetricsCardTabs внутрь ExpansionTile для групповых метрик
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Пример: ExpansionTile с SimpleMetricsCardTabs
          ExpansionTile(
            initiallyExpanded: false,
            title: const Text(
              'Метрики группы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: [
              // Сам виджет SimpleMetricsCardTabs
              SimpleMetricsCardTabs(
                metricsData: _metricsData!,
                periodStart: _dateFrom == null
                    ? '—'
                    : '${_dateFrom!.day}.${_dateFrom!.month}.${_dateFrom!.year}',
                periodEnd: _dateTo == null
                    ? '—'
                    : '${_dateTo!.day}.${_dateTo!.month}.${_dateTo!.year}',
                daysCount: _calculateDaysCount(),
              ),
            ],
          ),

          _buildGroupHeader(_metricsData!["group_info"] ?? {}),
          _buildSummaryMetrics(),
          _buildPostsList(_metricsData!["posts"] ?? []),
        ],
      ),
    );
  }

  // Шапка группы
  Widget _buildGroupHeader(Map<String, dynamic> info) {
    if (info.isEmpty) {
      return const Text('Нет информации о группе');
    }

    String? coverUrl;
    if (info["cover"] != null && info["cover"]["images"] != null) {
      final images = info["cover"]["images"] as List;
      if (images.isNotEmpty) {
        coverUrl = images.last["url"];
      }
    }

    final photoUrl = info["photo_200"] ?? '';
    final city = info["city"]?["title"] ?? '';
    final members = info["members_count"]?.toString() ?? '';
    final name = info["name"] ?? '';
    final screenName = info["screen_name"] ?? '';
    final description = info["description"] ?? '';
    final activity = info["activity"] ?? '';
    final site = info["site"] ?? '';
    final wikiPage = info["wiki_page"] ?? '';
    final counters = info["counters"] ?? {};

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (coverUrl != null && coverUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
              child: Image.network(coverUrl, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundImage: NetworkImage(photoUrl),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('vk.com/$screenName',
                              style: const TextStyle(color: Colors.blueGrey)),
                          if (activity.isNotEmpty) Text('📌 $activity'),
                          if (city.isNotEmpty) Text('📍 $city'),
                          if (members.isNotEmpty) Text('👥 Подписчиков: $members'),
                        ],
                      ),
                    ),
                  ],
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(description),
                ],
                if (site.isNotEmpty || wikiPage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  if (wikiPage.isNotEmpty) Text('📄 Wiki: $wikiPage'),
                  if (site.isNotEmpty) Text('🔗 Сайт: $site'),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (counters["photos"] != null)
                      Text('📷 Фото: ${counters["photos"]}'),
                    if (counters["videos"] != null)
                      Text('🎥 Видео: ${counters["videos"]}'),
                    if (counters["albums"] != null)
                      Text('🖼 Альбомы: ${counters["albums"]}'),
                    if (counters["articles"] != null)
                      Text('📝 Статьи: ${counters["articles"]}'),
                    if (counters["docs"] != null)
                      Text('📄 Документы: ${counters["docs"]}'),
                    if (counters["topics"] != null)
                      Text('💬 Темы: ${counters["topics"]}'),
                    if (counters["clips"] != null)
                      Text('🎬 Клипы: ${counters["clips"]}'),
                    if (counters["clips_views"] != null)
                      Text('👁 Клипы (просм.): ${counters["clips_views"]}'),
                    if (counters["clips_likes"] != null)
                      Text('❤️ Клипы (лайки): ${counters["clips_likes"]}'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Короткая сводка метрик
  Widget _buildSummaryMetrics() {
    final data = _metricsData!["summary"] ?? {};
    final postsCount = data["posts_count"] ?? 0;
    final likes = data["sum_likes"] ?? 0;
    final reposts = data["sum_reposts"] ?? 0;
    final comments = data["sum_comments"] ?? 0;
    final views = data["sum_views"] ?? 0;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        title: const Text('Сводка'),
        subtitle: Text(
          'Постов: $postsCount\n'
          'Лайков: $likes, Репостов: $reposts, Комментариев: $comments, Просмотров: $views',
        ),
      ),
    );
  }

  // Список постов
  Widget _buildPostsList(List<dynamic> posts) {
    if (posts.isEmpty) {
      return const Text('Нет постов за выбранный период или их невозможно отобразить.');
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (ctx, i) {
        final post = posts[i] as Map<String, dynamic>;
        return _buildPostCard(post);
      },
    );
  }

  // Одна карточка поста
  Widget _buildPostCard(Map<String, dynamic> post) {
    final postId = post["id"] ?? 0;
    final postText = post["text"] ?? '';
    final date = post["date"] != null
        ? DateTime.fromMillisecondsSinceEpoch(post["date"] * 1000)
        : null;

    final likes = post["likes"]?["count"] ?? 0;
    final reposts = post["reposts"]?["count"] ?? 0;
    final comments = post["comments"]?["count"] ?? 0;
    final views = post["views"]?["count"] ?? 0;

    final bool isExpanded = _expandedPosts[postId] == true;
    const maxPreviewLength = 100;
    final shortText = postText.length > maxPreviewLength
        ? '${postText.substring(0, maxPreviewLength)}...'
        : postText;

    final attachments = post["attachments"] as List? ?? [];
    final List<String> photoUrls = [];
    final List<Widget> videoWidgets = [];
    final List<Widget> linkWidgets = [];

    for (var att in attachments) {
      final type = att["type"];
      if (type == "photo") {
        final photo = att["photo"];
        if (photo != null) {
          final sizes = photo["sizes"] as List? ?? [];
          String bestUrl = '';
          int bestWidth = 0;
          for (var sz in sizes) {
            final w = sz["width"] ?? 0;
            if (w > bestWidth) {
              bestWidth = w;
              bestUrl = sz["url"];
            }
          }
          if (bestUrl.isNotEmpty) {
            photoUrls.add(bestUrl);
          }
        }
      } else if (type == "video") {
        final video = att["video"];
        if (video != null) {
          final title = video["title"] ?? 'Видео';
          final thumbList = video["image"] as List? ?? [];
          String bestThumb = '';
          int bestWidth = 0;
          for (var t in thumbList) {
            final w = t["width"] ?? 0;
            if (w > bestWidth) {
              bestWidth = w;
              bestThumb = t["url"];
            }
          }
          if (bestThumb.isNotEmpty) {
            videoWidgets.add(
              Container(
                margin: const EdgeInsets.only(top: 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.network(bestThumb),
                    const Icon(Icons.play_circle_fill, size: 64, color: Colors.white70),
                  ],
                ),
              ),
            );
          } else {
            videoWidgets.add(
              Container(
                margin: const EdgeInsets.only(top: 8),
                color: Colors.black12,
                height: 200,
                child: Center(child: Text(title)),
              ),
            );
          }
        }
      } else if (type == "link") {
        final link = att["link"];
        if (link != null) {
          final title = link["title"] ?? 'Ссылка';
          final url = link["url"] ?? '';
          linkWidgets.add(
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(url),
                ],
              ),
            ),
          );
        }
      }
    }

    Widget photosWidget = const SizedBox.shrink();
    if (photoUrls.isNotEmpty) {
      const maxPhotosToShow = 2;
      final hasExtra = photoUrls.length > maxPhotosToShow;
      final visiblePhotos = hasExtra ? photoUrls.sublist(0, maxPhotosToShow) : photoUrls;

      photosWidget = Container(
        margin: const EdgeInsets.only(top: 8),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: hasExtra ? visiblePhotos.length + 1 : visiblePhotos.length,
          itemBuilder: (ctx, idx) {
            if (hasExtra && idx == visiblePhotos.length) {
              final moreCount = photoUrls.length - maxPhotosToShow;
              return GestureDetector(
                onTap: () => _showImageGallery(photoUrls, maxPhotosToShow),
                child: Container(
                  color: Colors.black26,
                  child: Center(
                    child: Text(
                      '+ ещё $moreCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }
            final imageUrl = visiblePhotos[idx];
            return GestureDetector(
              onTap: () => _showImageGallery(photoUrls, idx),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            );
          },
        ),
      );
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (date != null)
                  Text(
                    '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                const Spacer(),
                const Icon(Icons.favorite, size: 16, color: Colors.redAccent),
                Text(' $likes  '),
                const Icon(Icons.share, size: 16, color: Colors.blueGrey),
                Text(' $reposts  '),
                const Icon(Icons.comment, size: 16, color: Colors.green),
                Text(' $comments  '),
                const Icon(Icons.visibility, size: 16, color: Colors.grey),
                Text(' $views'),
              ],
            ),
            const SizedBox(height: 8),
            if (postText.isNotEmpty) ...[
              Text(isExpanded ? postText : shortText),
              if (postText.length > maxPreviewLength)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _expandedPosts[postId] = !isExpanded;
                      });
                    },
                    child: Text(isExpanded ? 'Скрыть' : 'Показать полностью'),
                  ),
                ),
            ],
            photosWidget,
            ...videoWidgets,
            ...linkWidgets,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Открытие галереи изображений
  void _showImageGallery(List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(8),
        child: _GalleryViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  // Декодирование ответа (UTF-8)
  dynamic _decodeResponse(http.Response response) {
    final bytes = response.bodyBytes;
    final utf8Body = utf8.decode(bytes);
    return json.decode(utf8Body);
  }
}

// Виджет для просмотра набора фотографий
class _GalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _GalleryViewer({
    Key? key,
    required this.imageUrls,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<_GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<_GalleryViewer> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Text('${_currentIndex + 1} / ${widget.imageUrls.length}'),
            const SizedBox(width: 40),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (ctx, i) {
              final url = widget.imageUrls[i];
              return InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              );
            },
          ),
        ),
      ],
    );
  }
}
