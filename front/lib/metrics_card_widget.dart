import 'package:flutter/material.dart';
import 'charts_tab.dart';
import 'advice_tab.dart';

/// Виджет, который показывает метрики в удобных вкладках
/// Название класса оставляем неизменным (SimpleMetricsCardTabs),
/// чтобы было можно легко интегрировать в любой проект.
class SimpleMetricsCardTabs extends StatelessWidget {
  final Map<String, dynamic> metricsData;
  final String periodStart;
  final String periodEnd;
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
    final groupInfo = metricsData['group_info'] ?? {};
    final photoUrl = groupInfo['photo_100'] ?? '';
    final int subscribersCount = (groupInfo['members_count'] ?? 0) as int;
    final List<dynamic> posts = metricsData['posts'] ?? [];

    int totalLikes = 0;
    int totalReposts = 0;
    int totalComments = 0;
    int totalViews = 0;
    for (final post in posts) {
      totalLikes += (post['likes']?['count'] ?? 0) as int;
      totalReposts += (post['reposts']?['count'] ?? 0) as int;
      totalComments += (post['comments']?['count'] ?? 0) as int;
      totalViews += (post['views']?['count'] ?? 0) as int;
    }

    final postsCount = posts.length;
    final avgLikes = postsCount > 0 ? totalLikes / postsCount : 0.0;
    final avgShares = postsCount > 0 ? totalReposts / postsCount : 0.0;
    final avgComments = postsCount > 0 ? totalComments / postsCount : 0.0;
    final avgViews = postsCount > 0 ? totalViews / postsCount : 0.0;
    final totalEngagement = totalLikes + totalReposts + totalComments;
    final engagementRate = (subscribersCount > 0)
        ? (totalEngagement / subscribersCount) * 100
        : 0.0;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: DefaultTabController(
        length: 4, // у нас теперь 4 вкладки: Сводка, Подробно, Графики, Рекомендации
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              labelColor: Colors.blueAccent,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blueAccent,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Сводка'),
                Tab(text: 'Подробно'),
                Tab(text: 'Графики'),
                Tab(text: 'Реком.'),
              ],
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 600),
              child: TabBarView(
                physics: const ClampingScrollPhysics(),
                children: [
                  // 1) СВОДКА
                  _buildSummaryTab(
                    photoUrl: photoUrl,
                    subscribersCount: subscribersCount,
                    postsCount: postsCount,
                    totalLikes: totalLikes,
                    totalReposts: totalReposts,
                    totalComments: totalComments,
                    totalViews: totalViews,
                    avgLikes: avgLikes,
                    avgShares: avgShares,
                    avgComments: avgComments,
                    avgViews: avgViews,
                    engagementRate: engagementRate,
                  ),
                  // 2) ПОДРОБНО
                  _buildDetailTab(
                    subscribersCount: subscribersCount,
                    postsCount: postsCount,
                    totalLikes: totalLikes,
                    totalReposts: totalReposts,
                    totalComments: totalComments,
                    totalViews: totalViews,
                    avgLikes: avgLikes,
                    avgShares: avgShares,
                    avgComments: avgComments,
                    avgViews: avgViews,
                    engagementRate: engagementRate,
                  ),
                  // 3) ГРАФИКИ
                  ChartsTab(
                    totalLikes: totalLikes,
                    totalReposts: totalReposts,
                    totalComments: totalComments,
                    totalViews: totalViews,
                    totalSubscribers: subscribersCount,
                  ),
                  // 4) РЕКОМЕНДАЦИИ (подключаем AdviceTab)
                  AdviceTab(
                    engagementRate: engagementRate,
                    avgLikes: avgLikes,
                    avgReposts: avgShares,
                    avgComments: avgComments,
                    avgViews: avgViews,
                    subscribersCount: subscribersCount,
                    postsCount: postsCount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Вкладка "Сводка" - короткая обзорная информация для быстрого просмотра
  Widget _buildSummaryTab({
    required String photoUrl,
    required int subscribersCount,
    required int postsCount,
    required int totalLikes,
    required int totalReposts,
    required int totalComments,
    required int totalViews,
    required double avgLikes,
    required double avgShares,
    required double avgComments,
    required double avgViews,
    required double engagementRate,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            if (photoUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photoUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Период: $periodStart - $periodEnd\nВсего дней: $daysCount',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Карточка общей статистики
        _buildMetricCard(
          title: 'Общее',
          items: [
            _metricRow('Подписчиков', '$subscribersCount'),
            _metricRow('Постов', '$postsCount'),
            _metricRow('Суммарный ER (%)', engagementRate.toStringAsFixed(1)),
          ],
        ),
        const SizedBox(height: 16),
        // Карточка по реакциям
        _buildMetricCard(
          title: 'Реакции (суммарно)',
          items: [
            _metricRow('Лайки', '$totalLikes'),
            _metricRow('Репосты', '$totalReposts'),
            _metricRow('Комментарии', '$totalComments'),
            _metricRow('Просмотры', '$totalViews'),
          ],
        ),
        const SizedBox(height: 16),
        // Карточка по средним показателям
        _buildMetricCard(
          title: 'Средние значения (на пост)',
          items: [
            _metricRow('Лайки', avgLikes.toStringAsFixed(1)),
            _metricRow('Репосты', avgShares.toStringAsFixed(1)),
            _metricRow('Комментарии', avgComments.toStringAsFixed(1)),
            _metricRow('Просмотры', avgViews.toStringAsFixed(1)),
          ],
        ),
      ],
    );
  }

  /// Вкладка "Подробно" - например, таблица со всеми данными
  Widget _buildDetailTab({
    required int subscribersCount,
    required int postsCount,
    required int totalLikes,
    required int totalReposts,
    required int totalComments,
    required int totalViews,
    required double avgLikes,
    required double avgShares,
    required double avgComments,
    required double avgViews,
    required double engagementRate,
  }) {
    // Список пар "Название - Значение"
    final List<List<String>> rows = [
      ['Подписчиков', '$subscribersCount'],
      ['Постов', '$postsCount'],
      ['Лайков (всего)', '$totalLikes'],
      ['Репостов (всего)', '$totalReposts'],
      ['Комментариев (всего)', '$totalComments'],
      ['Просмотров (всего)', '$totalViews'],
      ['ER, %', engagementRate.toStringAsFixed(1)],
      ['Лайков (среднее)', avgLikes.toStringAsFixed(1)],
      ['Репостов (среднее)', avgShares.toStringAsFixed(1)],
      ['Комментариев (среднее)', avgComments.toStringAsFixed(1)],
      ['Просмотров (среднее)', avgViews.toStringAsFixed(1)],
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.blue[50]),
          columns: const [
            DataColumn(label: Text('Параметр')),
            DataColumn(label: Text('Значение')),
          ],
          rows: rows
              .map(
                (r) => DataRow(
                  cells: [
                    DataCell(Text(r[0])),
                    DataCell(Text(r[1])),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    );
  }


  /// Простой метод для построения "карточки" с блоком метрик
  Widget _buildMetricCard({
    required String title,
    required List<Widget> items,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: items,
            ),
          ],
        ),
      ),
    );
  }

  /// Единичный элемент метрики в виде "Значение + подпись"
  Widget _metricRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 6),
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
}
