// charts_tab.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// Класс вкладки с графиками
class ChartsTab extends StatefulWidget {
  // Входные данные (примерные, подставь свои реальные)
  final int totalSubscribers; // Всего подписчиков
  final int totalLikes;       // Сумма лайков
  final int totalReposts;     // Сумма репостов
  final int totalComments;    // Сумма комментариев
  final int totalViews;       // Сумма просмотров

  const ChartsTab({
    Key? key,
    required this.totalSubscribers,
    required this.totalLikes,
    required this.totalReposts,
    required this.totalComments,
    required this.totalViews,
  }) : super(key: key);

  @override
  State<ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends State<ChartsTab> {
  // Макетные данные для разных графиков (тут можно подставить реальные)
  late double engagementRate; // (лайки + репосты + комм.) / просмотры
  late List<PieData> reactionDistribution; // Для круговой диаграммы реакций
  late List<ChartData> coverageData;       // График просмотров
  late List<FunnelData> funnelData;        // Воронка подписчики → просмотры → лайки → репосты → комм.
  late List<ChartData> ctrData;            // CTR: просмотры / подписчики
  late List<ChartData> postsByDay;         // Число постов по дням недели
  late List<ChartData> postsByHour;        // Число постов по часам
  late List<PieData> attachmentTypes;      // Типы вложений
  late List<ChartData> resolutionData;     // Размеры фото
  late List<ChartData> hashtagFreq;        // Число вхождений хэштегов
  late List<ChartData> attachmentsCount;   // Сколько вложений в посте
  late List<ChartData> textLengthData;     // Длина текста
  late List<ChartData> rolesData;          // Сколько контактов по разным ролям
  late List<ChartData> membersGrowth;      // Рост участников
  late List<ChartData> mediaCount;         // Кол-во альбомов, фото, видео...
  late List<PieData> clipsCoverage;        // Круговая по клипам (просмотры/лайки/подписчики)
  late List<ChartData> likesToViews;       // Лайки/просмотры для поста
  late List<ChartData> repostsVsLikes;     // Репосты vs лайки
  late List<FunnelData> postEfficiency;    // Воронка конкретного поста (просм. → лайк → репост...)
  
  @override
  void initState() {
    super.initState();

    // Пример вычисления Engagement Rate
    engagementRate = widget.totalViews == 0
        ? 0
        : (widget.totalLikes + widget.totalReposts + widget.totalComments) /
            widget.totalViews;

    // Круговая диаграмма реакции
    reactionDistribution = [
      PieData('Лайки', widget.totalLikes),
      PieData('Репосты', widget.totalReposts),
      PieData('Комм.', widget.totalComments),
    ];

    // График просмотров
    coverageData = [
      ChartData('Пост 1', 300),
      ChartData('Пост 2', 600),
      ChartData('Пост 3', 900),
      ChartData('Пост 4', widget.totalViews), 
    ];

    // Воронка подписчики → просмотры → лайки → репосты → комм.
    funnelData = [
      FunnelData('Подписчики', widget.totalSubscribers),
      FunnelData('Просмотры', widget.totalViews),
      FunnelData('Лайки', widget.totalLikes),
      FunnelData('Репосты', widget.totalReposts),
      FunnelData('Комм.', widget.totalComments),
    ];

    // CTR: (Просмотры / Подписчики)
    ctrData = [
      ChartData('CTR', widget.totalSubscribers == 0
          ? 0
          : (widget.totalViews * 100 ~/ widget.totalSubscribers)),
    ];

    // Число постов по дням недели (макет)
    postsByDay = [
      ChartData('Пн', 4),
      ChartData('Вт', 6),
      ChartData('Ср', 3),
      ChartData('Чт', 5),
      ChartData('Пт', 7),
      ChartData('Сб', 2),
      ChartData('Вс', 1),
    ];

    // Распределение постов по часу
    postsByHour = [
      ChartData('09:00', 2),
      ChartData('12:00', 5),
      ChartData('15:00', 3),
      ChartData('18:00', 4),
      ChartData('21:00', 6),
    ];

    // Типы вложений (макет)
    attachmentTypes = [
      PieData('Фото', 10),
      PieData('Видео', 2),
      PieData('Статьи', 1),
      PieData('Ссылки', 3),
    ];

    // Разрешения фото (макет)
    resolutionData = [
      ChartData('640x640', 30),
      ChartData('1280x720', 15),
      ChartData('1920x1080', 5),
    ];

    // Частота хэштегов (макет)
    hashtagFreq = [
      ChartData('#КомандаПрофи43', 5),
      ChartData('#Краснаякеда', 3),
      ChartData('#ВяткаМолодая', 2),
    ];

    // Кол-во вложений на пост (макет)
    attachmentsCount = [
      ChartData('0 влож.', 4),
      ChartData('1 влож.', 10),
      ChartData('2+ влож.', 6),
    ];

    // Длина текста (макет, шт.)
    textLengthData = [
      ChartData('Короткие', 8),
      ChartData('Средние', 6),
      ChartData('Длинные', 2),
    ];

    // Роли (макет)
    rolesData = [
      ChartData('Замдир', 2),
      ChartData('Психолог', 1),
      ChartData('Студсовет', 2),
      ChartData('Клуб', 1),
    ];

    // Рост участников (макет)
    membersGrowth = [
      ChartData('Янв', 7200),
      ChartData('Фев', 7300),
      ChartData('Мар', 7350),
      ChartData('Апр', widget.totalSubscribers),
    ];

    // Медиа (макет)
    mediaCount = [
      ChartData('Альбомы', 52),
      ChartData('Фото', 4101),
      ChartData('Видео', 9),
      ChartData('Документы', 1271),
      ChartData('Статьи', 2),
    ];

    // Покрытие клипов (макет)
    clipsCoverage = [
      PieData('Просмотры', 2441),
      PieData('Лайки', 26),
      PieData('Подписчики клипов', 7374),
    ];

    // Лайки vs просмотры (макет)
    likesToViews = [
      ChartData('Лайки', widget.totalLikes),
      ChartData('Просмотры', widget.totalViews),
    ];

    // Репосты vs лайки (макет)
    repostsVsLikes = [
      ChartData('Репосты', widget.totalReposts),
      ChartData('Лайки', widget.totalLikes),
    ];

    // Эффективность поста (воронка)
    postEfficiency = [
      FunnelData('Просмотры', 1244),
      FunnelData('Лайки', 8),
      FunnelData('Репосты', 3),
      FunnelData('Комм.', 0),
    ];
  }

  // Метод сборки плиток (каждая диаграмма отдельной плиткой)
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          // 1. График вовлечённости (просто выводим значение в столбике для примера)
          ChartTile(
            title: 'Вовлечённость',
            subtitle: 'ER = ${(engagementRate * 100).toStringAsFixed(1)}%',
            chart: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ChartSeries>[
                ColumnSeries<ChartData, String>(
                  dataSource: [ChartData('ER', (engagementRate * 100).round())],
                  xValueMapper: (data, _) => data.x,
                  yValueMapper: (data, _) => data.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 2. Круговая: распределение реакций
          ChartTile(
            title: 'Типы реакций',
            subtitle: 'Круговая: лайки, репосты, комменты',
            chart: SfCircularChart(
              legend: Legend(isVisible: true),
              series: <PieSeries<PieData, String>>[
                PieSeries<PieData, String>(
                  dataSource: reactionDistribution,
                  xValueMapper: (data, _) => data.x,
                  yValueMapper: (data, _) => data.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 3. График охвата (просмотры)
          ChartTile(
            title: 'Охват постов',
            subtitle: 'Количество просмотров',
            chart: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ChartSeries>[
                LineSeries<ChartData, String>(
                  dataSource: coverageData,
                  xValueMapper: (data, _) => data.x,
                  yValueMapper: (data, _) => data.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 4. Воронка подписчики → просмотры → лайки → репосты → комм.
          ChartTile(
            title: 'Воронка сообщества',
            subtitle: 'Подписчики → Просмотры → Лайки → Репосты → Комм.',
            chart: SfFunnelChart(
              legend: Legend(isVisible: true),
              series: FunnelSeries<FunnelData, String>(
                dataSource: funnelData,
                xValueMapper: (d, _) => d.x,
                yValueMapper: (d, _) => d.y,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
              ),
            ),
          ),
          // 5. CTR подписчиков (просмотры/подписчики)
          ChartTile(
            title: 'CTR Подписчиков',
            subtitle: 'Просмотры / Подписчики * 100%',
            chart: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ChartSeries>[
                ColumnSeries<ChartData, String>(
                  dataSource: ctrData,
                  xValueMapper: (data, _) => data.x,
                  yValueMapper: (data, _) => data.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 6. Частота публикаций по дням
          ChartTile(
            title: 'Посты по дням недели',
            subtitle: 'Сколько постов в Пн, Вт, Ср и т.д.',
            chart: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ChartSeries>[
                ColumnSeries<ChartData, String>(
                  dataSource: postsByDay,
                  xValueMapper: (data, _) => data.x,
                  yValueMapper: (data, _) => data.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 7. Время публикаций
          ChartTile(
            title: 'Время публикаций',
            subtitle: 'В какие часы чаще всего',
            chart: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ChartSeries>[
                ColumnSeries<ChartData, String>(
                  dataSource: postsByHour,
                  xValueMapper: (data, _) => data.x,
                  yValueMapper: (data, _) => data.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 8. Типы вложений (круговая)
          ChartTile(
            title: 'Типы вложений',
            subtitle: 'Фото, видео, статьи, ссылки и т.д.',
            chart: SfCircularChart(
              legend: Legend(isVisible: true),
              series: <PieSeries<PieData, String>>[
                PieSeries<PieData, String>(
                  dataSource: attachmentTypes,
                  xValueMapper: (d, _) => d.x,
                  yValueMapper: (d, _) => d.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 9. Разрешения фото
          ChartTile(
            title: 'Разрешения фото',
            subtitle: 'Пример: 640x640, 1280x720',
            chart: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ChartSeries>[
                ColumnSeries<ChartData, String>(
                  dataSource: resolutionData,
                  xValueMapper: (d, _) => d.x,
                  yValueMapper: (d, _) => d.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 10. Хэштеги
          ChartTile(
            title: 'Частотность хэштегов',
            subtitle: '#КомандаПрофи43, #Краснаякеда и т.д.',
            chart: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ChartSeries>[
                ColumnSeries<ChartData, String>(
                  dataSource: hashtagFreq,
                  xValueMapper: (d, _) => d.x,
                  yValueMapper: (d, _) => d.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 11. Кол-во вложений на пост
          ChartTile(
            title: 'Вложения на пост',
            subtitle: 'Сколько постов с 0, 1, 2+ влож.',
            chart: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ChartSeries>[
                ColumnSeries<ChartData, String>(
                  dataSource: attachmentsCount,
                  xValueMapper: (d, _) => d.x,
                  yValueMapper: (d, _) => d.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 12. Длина текста
          ChartTile(
            title: 'Длина текста постов',
            subtitle: 'Короткие / Средние / Длинные',
            chart: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ChartSeries>[
                ColumnSeries<ChartData, String>(
                  dataSource: textLengthData,
                  xValueMapper: (d, _) => d.x,
                  yValueMapper: (d, _) => d.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 13. Роли
          ChartTile(
            title: 'Контакты по ролям',
            subtitle: 'Замдир, Психолог, Студсовет...',
            chart: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ChartSeries>[
                ColumnSeries<ChartData, String>(
                  dataSource: rolesData,
                  xValueMapper: (d, _) => d.x,
                  yValueMapper: (d, _) => d.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 14. Рост участников
          ChartTile(
            title: 'Рост участников',
            subtitle: 'Динамика подписчиков по месяцам',
            chart: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ChartSeries>[
                LineSeries<ChartData, String>(
                  dataSource: membersGrowth,
                  xValueMapper: (d, _) => d.x,
                  yValueMapper: (d, _) => d.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 15. Сравнительная гистограмма: альбомы, фото, видео...
          ChartTile(
            title: 'Кол-во разных медиа',
            subtitle: 'Альбомы, фото, видео, доки, статьи',
            chart: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ChartSeries>[
                ColumnSeries<ChartData, String>(
                  dataSource: mediaCount,
                  xValueMapper: (d, _) => d.x,
                  yValueMapper: (d, _) => d.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 16. Покрытие клипов
          ChartTile(
            title: 'Охват клипов',
            subtitle: 'Просмотры / Лайки / Подписчики клипов',
            chart: SfCircularChart(
              legend: Legend(isVisible: true),
              series: <PieSeries<PieData, String>>[
                PieSeries<PieData, String>(
                  dataSource: clipsCoverage,
                  xValueMapper: (d, _) => d.x,
                  yValueMapper: (d, _) => d.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 17. Лайки к просмотрам
          ChartTile(
            title: 'Лайки к просмотрам',
            subtitle: 'Сравнение',
            chart: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ChartSeries>[
                ColumnSeries<ChartData, String>(
                  dataSource: likesToViews,
                  xValueMapper: (d, _) => d.x,
                  yValueMapper: (d, _) => d.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 18. Репосты vs лайки
          ChartTile(
            title: 'Репосты vs Лайки',
            subtitle: 'Сравнение',
            chart: SfCartesianChart(
              primaryXAxis: CategoryAxis(),
              series: <ChartSeries>[
                ColumnSeries<ChartData, String>(
                  dataSource: repostsVsLikes,
                  xValueMapper: (d, _) => d.x,
                  yValueMapper: (d, _) => d.y,
                  dataLabelSettings: const DataLabelSettings(isVisible: true),
                ),
              ],
            ),
          ),
          // 19. Эффективность поста (воронка)
          ChartTile(
            title: 'Эффективность поста',
            subtitle: 'Просмотры → Лайки → Репосты → Комм.',
            chart: SfFunnelChart(
              legend: Legend(isVisible: true),
              series: FunnelSeries<FunnelData, String>(
                dataSource: postEfficiency,
                xValueMapper: (d, _) => d.x,
                yValueMapper: (d, _) => d.y,
                dataLabelSettings: const DataLabelSettings(isVisible: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Виджет плитки с графиком
class ChartTile extends StatefulWidget {
  final String title;    // Заголовок
  final String subtitle; // Подзаголовок
  final Widget chart;    // Сам график

  const ChartTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.chart,
  }) : super(key: key);

  @override
  State<ChartTile> createState() => _ChartTileState();
}

class _ChartTileState extends State<ChartTile> {
  // Разворачивание графика в диалог
  void _expandChart() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
          body: Center(child: widget.chart),
        ),
      ),
    );
  }

  // Заглушка для фильтра по дате
  void _filterDate() {
    // Здесь можно реализовать showDateRangePicker
  }

  // Заглушка для экспорта
  void _exportChart() {
    // Сюда можно добавить экспорт в PNG, CSV и т.д.
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок, подзаголовок, иконки
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Текстовая часть
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.subtitle,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                // Кнопки управления
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.fullscreen),
                      onPressed: _expandChart,
                    ),
                    IconButton(
                      icon: const Icon(Icons.date_range),
                      onPressed: _filterDate,
                    ),
                    IconButton(
                      icon: const Icon(Icons.file_download),
                      onPressed: _exportChart,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(height: 200, child: widget.chart),
          ],
        ),
      ),
    );
  }
}

// Класс для данных линейных / столбчатых диаграмм
class ChartData {
  final String x;
  final int y;
  ChartData(this.x, this.y);
}

// Класс для данных круговых диаграмм
class PieData {
  final String x;
  final int y;
  PieData(this.x, this.y);
}

// Класс для данных воронки
class FunnelData {
  final String x;
  final int y;
  FunnelData(this.x, this.y);
}
