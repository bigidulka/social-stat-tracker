import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'metrics_card_widget.dart';

class MetricsPage extends StatefulWidget {
  final String? token;
  const MetricsPage({Key? key, this.token}) : super(key: key);

  @override
  State<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  // -- Данные для списка групп
  List<dynamic> _userGroups = [];

  // -- Параметры фильтра / сортировки
  String? _selectedGroup;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _sortBy = 'date';        // date|likes|reposts|comments|views
  Set<String> _filters = {};      // { 'text', 'photo', 'video' }

  // -- Результат запроса /vk_rout/metrics
  Map<String, dynamic>? _metricsData;

  // -- Признак загрузки
  bool _isLoading = false;

  /// Запоминаем, какие посты развёрнуты (ID поста -> bool).
  /// Можно сделать иначе (например, сохраняя список expandedPostIds).
  Map<int, bool> _expandedPosts = {};

  @override
  void initState() {
    super.initState();
    _fetchUserGroups();
  }

  /// Загружаем список групп пользователя (/groups)
  Future<void> _fetchUserGroups() async {
    if (widget.token == null) return;
    final url = Uri.parse('http://bigidulka2.ddns.net:8000/groups');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${widget.token}'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      if (!mounted) return;
      setState(() {
        _userGroups = data;
      });
    }
  }

  /// Запрашиваем /vk_rout/metrics с параметрами
  Future<void> _fetchMetrics() async {
    if (widget.token == null || _selectedGroup == null) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _metricsData = null;
    });

    final queryParams = <String, String>{
      'group_name': _selectedGroup!,
      'sort_by': _sortBy,
    };

    // Если указаны даты – добавим их
    if (_dateFrom != null && _dateTo != null) {
      final fromTs = _dateFrom!.millisecondsSinceEpoch ~/ 1000;
      final toTs = _dateTo!.millisecondsSinceEpoch ~/ 1000;
      queryParams['date_from'] = fromTs.toString();
      queryParams['date_to'] = toTs.toString();
    }
    // Если заданы фильтры – собираем в строку 'text,photo,video'
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
        if (!mounted) return;
        setState(() {
          _metricsData = data;
        });
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Диалог выбора группы, периода, сортировки и фильтров
  void _showFilterDialog() {
    // Локальные копии параметров
    DateTime? localDateFrom = _dateFrom;
    DateTime? localDateTo = _dateTo;
    String? localSelectedGroup = _selectedGroup;
    String localSortBy = _sortBy;
    // Копируем, чтобы при отмене не перетереть
    Set<String> localFilters = {..._filters};

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            // Утилита для чекбоксов фильтров
            Widget buildFilterCheck(String label) {
              return CheckboxListTile(
                title: Text(label),
                value: localFilters.contains(label),
                onChanged: (val) {
                  setStateDialog(() {
                    if (val == true) {
                      localFilters.add(label);
                    } else {
                      localFilters.remove(label);
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
                    // -- Dropdown для выбора группы
                    DropdownButton<String>(
                      isExpanded: true,
                      value: localSelectedGroup,
                      hint: const Text('Выберите группу'),
                      items: _userGroups.map((grp) {
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
                          localSelectedGroup = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // -- Быстрые кнопки периода
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            final now = DateTime.now();
                            setStateDialog(() {
                              localDateFrom = now.subtract(const Duration(days: 7));
                              localDateTo = now;
                            });
                          },
                          child: const Text('Неделя'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final now = DateTime.now();
                            setStateDialog(() {
                              localDateFrom = DateTime(now.year, now.month - 1, now.day);
                              localDateTo = now;
                            });
                          },
                          child: const Text('Месяц'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final now = DateTime.now();
                            setStateDialog(() {
                              localDateFrom = DateTime(now.year - 1, now.month, now.day);
                              localDateTo = now;
                            });
                          },
                          child: const Text('Год'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    // -- Ручной выбор "от" "до"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('От:'),
                            TextButton(
                              onPressed: () async {
                                final initDate = localDateFrom ?? DateTime.now().subtract(const Duration(days: 30));
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: initDate,
                                  firstDate: DateTime(2010),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setStateDialog(() {
                                    localDateFrom = picked;
                                  });
                                }
                              },
                              child: Text(localDateFrom == null
                                  ? 'Выбрать'
                                  : '${localDateFrom!.day}.${localDateFrom!.month}.${localDateFrom!.year}'),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('До:'),
                            TextButton(
                              onPressed: () async {
                                final initDate = localDateTo ?? DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: initDate,
                                  firstDate: DateTime(2010),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setStateDialog(() {
                                    localDateTo = picked;
                                  });
                                }
                              },
                              child: Text(localDateTo == null
                                  ? 'Выбрать'
                                  : '${localDateTo!.day}.${localDateTo!.month}.${localDateTo!.year}'),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    // -- Сортировка
                    Row(
                      children: [
                        const Text('Сортировка:'),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: localSortBy,
                          items: const [
                            DropdownMenuItem(value: 'date', child: Text('По дате')),
                            DropdownMenuItem(value: 'likes', child: Text('По лайкам')),
                            DropdownMenuItem(value: 'reposts', child: Text('По репостам')),
                            DropdownMenuItem(value: 'comments', child: Text('По комментариям')),
                            DropdownMenuItem(value: 'views', child: Text('По просмотрам')),
                          ],
                          onChanged: (val) {
                            setStateDialog(() {
                              localSortBy = val ?? 'date';
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    // -- Фильтр по контенту (text, photo, video)
                    const Text('Фильтры (мультивыбор):'),
                    buildFilterCheck('text'),
                    buildFilterCheck('photo'),
                    buildFilterCheck('video'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Закрываем диалог без сохранения
                  },
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Применяем выбранные настройки и сразу загружаем
                    if (!mounted) return;
                    setState(() {
                      _selectedGroup = localSelectedGroup;
                      _dateFrom = localDateFrom;
                      _dateTo = localDateTo;
                      _sortBy = localSortBy;
                      _filters = localFilters;
                    });
                    Navigator.of(context).pop();
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

  /// Открывает диалог с просмотром изображений (PageView).
  void _showImageGallery(List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.all(8),
          child: GalleryViewer(imageUrls: imageUrls, initialIndex: initialIndex),
        );
      },
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
  title: const Text('Метрики'),
  actions: [
    if (_selectedGroup != null)
      IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Сбросить выбор',
        onPressed: () {
          setState(() {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _metricsData == null
              ? Center(
    child: Card(
      elevation: 4,
      margin: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 16),
            const Text(
              'Группа не выбрана',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Пожалуйста, выбери группу и период, чтобы загрузить метрики.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showFilterDialog,
              icon: const Icon(Icons.filter_alt),
              label: const Text('Выбрать'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    ),
  )

              : SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch, // добавляем!
    children: [
      // Растягиваем карточку на ширину
ExpansionTile(
  initiallyExpanded: false, // по умолчанию свернут
  title: const Text(
    'Метрики группы',
    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  ),
  children: [
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
      // Остальные виджеты
      _buildGroupHeader(_metricsData!["group_info"] ?? {}),
      _buildPostsList(_metricsData!["posts"] ?? []),
    ],
  ),
),
    );
  }

  /// Шапка группы (header) с расширенной информацией
Widget _buildGroupHeader(Map<String, dynamic> info) {
  if (info.isEmpty) return const Text('Нет данных о группе');

  // Обложка
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
                        Text(name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
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
                if (wikiPage.isNotEmpty)
                  Text('📄 Wiki: $wikiPage'),
                if (site.isNotEmpty)
                  Text('🔗 Сайт: $site'),
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

  int _calculateDaysCount() {
    if (_dateFrom == null || _dateTo == null) return 0;
    return _dateTo!.difference(_dateFrom!).inDays + 1;
  }


  /// Лента постов (с фото, текстом, статистикой)
  Widget _buildPostsList(List<dynamic> posts) {
    if (posts.isEmpty) {
      return const Text('Нет постов за выбранный период или их невозможно отобразить.');
    }
    return Column(
      children: posts.map((item) => _buildPostCard(item)).toList(),
    );
  }

  /// Карточка одного поста
  Widget _buildPostCard(Map<String, dynamic> post) {
    final postId = post["id"] ?? 0;  // для хранения expanded state
    final postText = post["text"] ?? '';
    final date = post["date"] != null
        ? DateTime.fromMillisecondsSinceEpoch(post["date"] * 1000)
        : null;

    final likes = post["likes"]?["count"] ?? 0;
    final reposts = post["reposts"]?["count"] ?? 0;
    final comments = post["comments"]?["count"] ?? 0;
    final views = post["views"]?["count"] ?? 0;

    // Решаем, какой объём текста показывать
    final bool isExpanded = _expandedPosts[postId] == true;
    // Ограничим текст для предпросмотра
    const maxPreviewLength = 100; // символов
    String shortText = postText.length > maxPreviewLength
        ? postText.substring(0, maxPreviewLength) + '...'
        : postText;

    // Собираем все фото (type=photo) чтобы отобразить их в Grid
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
          // Найдём самую большую по ширине
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
        // У видео может быть "photo_xxx" (превью).
        // Для упрощения — просто показ превью+иконки play
        final video = att["video"];
        if (video != null) {
          final title = video["title"] ?? 'Видео';
          final thumbList = video["image"] as List? ?? [];
          // Берём самую широкую
          var bestThumb = '';
          int bestWidth = 0;
          for (var t in thumbList) {
            final w = t["width"] ?? 0;
            if (w > bestWidth) {
              bestWidth = w;
              bestThumb = t["url"];
            }
          }
          Widget w;
          if (bestThumb.isNotEmpty) {
            w = Container(
              margin: const EdgeInsets.only(top: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(bestThumb),
                  const Icon(Icons.play_circle_fill,
                      size: 64, color: Colors.white70),
                ],
              ),
            );
          } else {
            w = Container(
              margin: const EdgeInsets.only(top: 8),
              color: Colors.black12,
              height: 200,
              child: Center(child: Text(title)),
            );
          }
          videoWidgets.add(w);
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
      // Можно добавить другие типы по желанию
    }

    // Строим GridView для всех фото
Widget photosWidget = const SizedBox.shrink();
if (photoUrls.isNotEmpty) {
  const maxPhotosToShow = 1;
  final bool hasExtra = photoUrls.length > maxPhotosToShow;
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
      itemBuilder: (ctx, index) {
        if (hasExtra && index == visiblePhotos.length) {
          final moreCount = photoUrls.length - maxPhotosToShow;
          return GestureDetector(
            onTap: () {
              _showImageGallery(photoUrls, maxPhotosToShow);
            },
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

        final imageUrl = visiblePhotos[index];
        return GestureDetector(
          onTap: () {
            _showImageGallery(photoUrls, index);
          },
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
        '${date.day}.${date.month}.${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
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
            // Дата поста
            // if (date != null)
            //   Text(
            //     '${date.day}.${date.month}.${date.year} '
            //     '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
            //     style: const TextStyle(fontSize: 12, color: Colors.grey),
            //   ),

            const SizedBox(height: 8),

            // Текст поста (с "Показать полностью")
            if (postText.isNotEmpty) ...[
              Text(
                isExpanded ? postText : shortText,
              ),
              // Если текст длинный — кнопка "Показать полностью / Скрыть"
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
                )
            ],

            // Фото (в виде сетки)
            photosWidget,

            // Видео
            ...videoWidgets,

            // Ссылки
            ...linkWidgets,

            // Статистика (лайки, репосты, комментарии, просмотры)
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    
  }
}


/// Виджет для просмотра изображений в PageView
class GalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const GalleryViewer({
    Key? key,
    required this.imageUrls,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<GalleryViewer> createState() => _GalleryViewerState();
}

class _GalleryViewerState extends State<GalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Заголовок с кнопкой "Закрыть"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Text(
              '${_currentIndex + 1} / ${widget.imageUrls.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 40), // пустое место (чтобы текст по центру)
          ],
        ),
        const Divider(height: 1),

        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (ctx, index) {
              final url = widget.imageUrls[index];
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
