import 'package:flutter/material.dart';
// Подключаем пакет для работы с диаграммами
import 'package:syncfusion_flutter_charts/charts.dart';

class SimpleMetricsCardTabs extends StatelessWidget {
  // Данные метрик
  final Map<String, dynamic> metricsData;
  // Период начала и конца
  final String periodStart;
  final String periodEnd;
  // Количество дней
  final int daysCount;

  const SimpleMetricsCardTabs({
    Key? key,
    required this.metricsData,
    required this.periodStart,
    required this.periodEnd,
    this.daysCount = 7,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Информация о сообществе
    final groupInfo = metricsData['group_info'] ?? {};
    final photoUrl = groupInfo['photo_100'] ?? '';
    final int subscribersCount = (groupInfo['members_count'] ?? 0) as int;

    // Список постов
    final List<dynamic> posts = metricsData['posts'] ?? [];

    // Подсчитываем суммарные реакции
    int totalLikes = 0;
    int totalShares = 0;
    int totalComments = 0;
    int totalViews = 0;

    for (final post in posts) {
      totalLikes += (post['likes']?['count'] ?? 0) as int;
      totalShares += (post['reposts']?['count'] ?? 0) as int;
      totalComments += (post['comments']?['count'] ?? 0) as int;
      totalViews += (post['views']?['count'] ?? 0) as int;
    }

    // Количество постов
    final postsCount = posts.length;

    // Средние значения
    final avgLikes = postsCount > 0 ? totalLikes / postsCount : 0.0;
    final avgShares = postsCount > 0 ? totalShares / postsCount : 0.0;
    final avgComments = postsCount > 0 ? totalComments / postsCount : 0.0;
    final avgViews = postsCount > 0 ? totalViews / postsCount : 0.0;

    // Engagement Rate: (лайки + репосты + комментарии) / подписчики * 100
    final totalEngagement = totalLikes + totalShares + totalComments;
    final engagementRate = (subscribersCount > 0)
        ? (totalEngagement / subscribersCount) * 100
        : 0.0;

    return SizedBox(
      width: double.infinity,
      child: DefaultTabController(
        // Три вкладки: Кратко, Детально, Графики
        length: 3,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 4, // более заметная тень
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Вкладки с кастомным стилем
                TabBar(
                  labelColor: Colors.blueAccent,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blueAccent,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  tabs: const [
                    Tab(text: 'Кратко'),
                    Tab(text: 'Детально'),
                    Tab(text: 'Графики'),
                  ],
                ),
                // Содержимое вкладок
                Container(
                  // Ограничиваем высоту
                  constraints: const BoxConstraints(maxHeight: 600),
                  child: TabBarView(
                    physics: const ClampingScrollPhysics(),
                    children: [
                      // Вкладка «Кратко»
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Шапка с аватаркой и периодом
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                if (photoUrl.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      photoUrl,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                Text(
                                  'Период: $periodStart - $periodEnd',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Основные метрики с иконками
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _buildMetricItem(
                                  icon: Icons.people,
                                  label: 'Подписчиков',
                                  value: '$subscribersCount',
                                ),
                                _buildMetricItem(
                                  icon: Icons.post_add,
                                  label: 'Постов',
                                  value: '$postsCount',
                                ),
                                _buildMetricItem(
                                  icon: Icons.calendar_today,
                                  label: 'Период (дней)',
                                  value: '$daysCount',
                                ),
                                _buildMetricItem(
                                  icon: Icons.insights,
                                  label: 'ER, %',
                                  value: engagementRate.toStringAsFixed(1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Суммарные реакции
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _buildMetricItem(
                                  icon: Icons.thumb_up,
                                  label: 'Лайки',
                                  value: '$totalLikes',
                                ),
                                _buildMetricItem(
                                  icon: Icons.share,
                                  label: 'Репосты',
                                  value: '$totalShares',
                                ),
                                _buildMetricItem(
                                  icon: Icons.comment,
                                  label: 'Комментарии',
                                  value: '$totalComments',
                                ),
                                _buildMetricItem(
                                  icon: Icons.visibility,
                                  label: 'Просмотры',
                                  value: '$totalViews',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Средние значения
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _buildMetricItem(
                                  icon: Icons.thumb_up_alt_outlined,
                                  label: 'Лайков в среднем',
                                  value: avgLikes.toStringAsFixed(1),
                                ),
                                _buildMetricItem(
                                  icon: Icons.repeat,
                                  label: 'Репостов в среднем',
                                  value: avgShares.toStringAsFixed(1),
                                ),
                                _buildMetricItem(
                                  icon: Icons.mode_comment_outlined,
                                  label: 'Комментариев в среднем',
                                  value: avgComments.toStringAsFixed(1),
                                ),
                                _buildMetricItem(
                                  icon: Icons.remove_red_eye,
                                  label: 'Просмотров в среднем',
                                  value: avgViews.toStringAsFixed(1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Вкладка «Детально»
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildDataTable(
                          photoUrl: photoUrl,
                          subscribersCount: subscribersCount,
                          totalLikes: totalLikes,
                          totalShares: totalShares,
                          totalComments: totalComments,
                          totalViews: totalViews,
                          avgLikes: avgLikes,
                          avgShares: avgShares,
                          avgComments: avgComments,
                          avgViews: avgViews,
                          engagementRate: engagementRate,
                        ),
                      ),
                      // Вкладка «Графики»
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: _buildChartsTab(
                          totalLikes: totalLikes,
                          totalShares: totalShares,
                          totalComments: totalComments,
                          totalViews: totalViews,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Виджет отдельной метрики с иконкой
  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.blueAccent),
        const SizedBox(width: 4),
        Text(
          '$value ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  // Таблица (детальная статистика)
  Widget _buildDataTable({
    required String photoUrl,
    required int subscribersCount,
    required int totalLikes,
    required int totalShares,
    required int totalComments,
    required int totalViews,
    required double avgLikes,
    required double avgShares,
    required double avgComments,
    required double avgViews,
    required double engagementRate,
  }) {
    final rows = [
      ['Подписчиков', '$subscribersCount'],
      ['Постов', '${metricsData['posts']?.length ?? 0}'],
      ['Всего лайков', '$totalLikes'],
      ['Всего репостов', '$totalShares'],
      ['Всего комментариев', '$totalComments'],
      ['Всего просмотров', '$totalViews'],
      ['Лайков в среднем', avgLikes.toStringAsFixed(1)],
      ['Репостов в среднем', avgShares.toStringAsFixed(1)],
      ['Комментариев в среднем', avgComments.toStringAsFixed(1)],
      ['Просмотров в среднем', avgViews.toStringAsFixed(1)],
      ['Engagement Rate, %', engagementRate.toStringAsFixed(1)],
      ['Период (дней)', '$daysCount'],
      ['Период', '$periodStart - $periodEnd'],
    ];

    return DataTable(
      headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
      headingTextStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        fontSize: 14,
      ),
      dataTextStyle: const TextStyle(
        fontSize: 14,
        color: Colors.black87,
      ),
      columns: const [
        DataColumn(label: Text('Параметр')),
        DataColumn(label: Text('Значение')),
      ],
      rows: rows.map(
        (row) {
          return DataRow(
            cells: [
              DataCell(Text(row[0].toString())),
              DataCell(Text(row[1].toString())),
            ],
          );
        },
      ).toList(),
    );
  }

  // Вкладка с графиками: создаём адаптивную сетку плиток с различными диаграммами
  Widget _buildChartsTab({
    required int totalLikes,
    required int totalShares,
    required int totalComments,
    required int totalViews,
  }) {
    // Подготавливаем данные для примера столбчатого графика
    final List<_ChartData> columnData = [
      _ChartData('Лайки', totalLikes),
      _ChartData('Репосты', totalShares),
      _ChartData('Коммент.', totalComments),
      _ChartData('Просм.', totalViews),
    ];

    // Пример линейного графика (например, тренд лайков)
    final List<_ChartData> lineData = [
      _ChartData('День 1', (totalLikes / 4).toInt()),
      _ChartData('День 2', (totalLikes / 3).toInt()),
      _ChartData('День 3', (totalLikes / 2).toInt()),
      _ChartData('День 4', totalLikes),
      _ChartData('День 5', (totalLikes * 1.2).toInt()),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        // Плитка со столбчатым графиком
        ChartTile(
          title: 'Активность по реакциям',
          subtitle: 'Суммарные данные за выбранный период',
          chart: SfCartesianChart(
            tooltipBehavior: TooltipBehavior(enable: true),
            primaryXAxis: CategoryAxis(),
            series: <CartesianSeries<_ChartData, String>>[
              ColumnSeries<_ChartData, String>(
                dataSource: columnData,
                xValueMapper: (data, _) => data.x,
                yValueMapper: (data, _) => data.y,
                name: 'Реакции',
                dataLabelSettings: const DataLabelSettings(isVisible: true),
              ),
            ],
          ),
        ),
        // Плитка с линейным графиком
        ChartTile(
          title: 'Тренд лайков',
          subtitle: 'Динамика роста лайков',
          chart: SfCartesianChart(
            tooltipBehavior: TooltipBehavior(enable: true),
            primaryXAxis: CategoryAxis(),
            series: <CartesianSeries<_ChartData, String>>[
              LineSeries<_ChartData, String>(
                dataSource: lineData,
                xValueMapper: (data, _) => data.x,
                yValueMapper: (data, _) => data.y,
                name: 'Лайки',
                dataLabelSettings: const DataLabelSettings(isVisible: true),
              ),
            ],
          ),
        ),
        // Можно добавить дополнительные плитки с другими типами графиков,
        // например, смешанные или по другим наборам данных.
      ],
    );
  }
}

// Виджет плитки с графиком, который поддерживает развёртывание, фильтр по дате и экспорт.
class ChartTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget chart;

  const ChartTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.chart,
  }) : super(key: key);

  @override
  _ChartTileState createState() => _ChartTileState();
}

class _ChartTileState extends State<ChartTile> {
  // Функция развёртывания графика на весь экран
  void _expandChart() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Свернуть',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
            body: Center(child: widget.chart),
          ),
        );
      },
    );
  }

  // Функция фильтрации по дате (stub)
  void _filterDate() {
    // Здесь можно реализовать выбор дат через showDateRangePicker
    print("Фильтр по дате");
  }

  // Функция экспорта графика (stub)
  void _exportChart() {
    // Здесь можно реализовать экспорт в PNG, CSV и т.д.
    print("Экспорт графика");
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 300, // фиксированная ширина плитки
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и элементы управления
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Заголовок и подзаголовок
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(widget.subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                // Иконки управления
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.fullscreen),
                      tooltip: 'Развернуть',
                      onPressed: _expandChart,
                    ),
                    IconButton(
                      icon: const Icon(Icons.date_range),
                      tooltip: 'Фильтр по дате',
                      onPressed: _filterDate,
                    ),
                    IconButton(
                      icon: const Icon(Icons.file_download),
                      tooltip: 'Экспорт',
                      onPressed: _exportChart,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Сам график
            SizedBox(
              height: 200,
              child: widget.chart,
            ),
          ],
        ),
      ),
    );
  }
}

// Класс для хранения данных графика
class _ChartData {
  final String x;
  final int y;
  _ChartData(this.x, this.y);
}
