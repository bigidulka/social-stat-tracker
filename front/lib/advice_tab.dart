import 'package:flutter/material.dart';

/// Класс, описывающий одну секцию рекомендаций,
/// у которой есть заголовок и список "пунктов" (советов).
class AdviceSection {
  final String title;
  final List<String> bulletPoints;

  AdviceSection({required this.title, required this.bulletPoints});
}

/// Виджет с подробными рекомендациями, оформленными в несколько "секций".
class AdviceTab extends StatelessWidget {
  // Параметры, на основе которых формируются советы:
  final double engagementRate; // ER = (лайки + репосты + комментарии) / подписчики * 100
  final double avgLikes;       // Среднее кол-во лайков на пост
  final double avgReposts;     // Среднее кол-во репостов на пост
  final double avgComments;    // Среднее кол-во комментариев на пост
  final double avgViews;       // Среднее кол-во просмотров на пост
  final int subscribersCount;  // Количество подписчиков
  final int postsCount;        // Количество постов за период

  const AdviceTab({
    Key? key,
    required this.engagementRate,
    required this.avgLikes,
    required this.avgReposts,
    required this.avgComments,
    required this.avgViews,
    required this.subscribersCount,
    required this.postsCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Составляем список секций рекомендаций
    final List<AdviceSection> adviceSections = _generateAdviceSections();

    // Возвращаем ListView, где каждая секция оформлена как карточка + ExpansionTile (по желанию).
    // Можно сделать и без ExpansionTile, просто выводить списки.
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: adviceSections.length,
      itemBuilder: (context, index) {
        final section = adviceSections[index];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            // Заголовок секции
            title: Text(
              section.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            // Список пунктов в секции
            children: section.bulletPoints.map((bullet) {
              return ListTile(
                leading: const Icon(Icons.circle, size: 8, color: Colors.blueAccent),
                title: Text(bullet, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Генерируем список AdviceSection, чтобы потом отрисовать в UI.
  List<AdviceSection> _generateAdviceSections() {
    // Подбираем рекомендации на основе ER и средних показателей
    final List<AdviceSection> sections = [];

    // 1. Оценка ER
    sections.add(AdviceSection(
      title: 'Оценка Engagement Rate (ER)',
      bulletPoints: _buildErAdvice(), // отдельный метод
    ));

    // 2. Средние показатели (лайки, репосты, комментарии, просмотры)
    sections.add(AdviceSection(
      title: 'Средние показатели на пост',
      bulletPoints: _buildAveragesAdvice(),
    ));

    // 3. Частота и регулярность публикаций
    sections.add(AdviceSection(
      title: 'Регулярность публикаций',
      bulletPoints: _buildFrequencyAdvice(),
    ));

    // 4. Дополнительные советы
    sections.add(AdviceSection(
      title: 'Дополнительные советы',
      bulletPoints: _buildExtraAdvice(),
    ));

    return sections;
  }

  // ---------------------------
  // Методы для формирования списков bullet-пунктов
  // ---------------------------

  /// Выдаём рекомендации по ER
  List<String> _buildErAdvice() {
    final advice = <String>[];
    if (engagementRate < 1) {
      advice.add(
        'Ваш ER ниже 1%. Скорее всего, аудитория слабо реагирует на контент. '
        'Попробуйте анализировать тематику и формат постов, добавляйте интерактивы (опросы, квизы), '
        'поощряйте комментарии, задавая вопросы в конце поста.',
      );
    } else if (engagementRate < 3) {
      advice.add(
        'Ваш ER находится в диапазоне 1–3%. Это неплохой показатель, но ещё есть куда расти. '
        'Можно расширить контент-стратегию: добавлять больше фото/видео, кейсов, историй успеха. '
        'Персонализируйте сообщения, обращайтесь к аудитории на «ты/вы», рассказывайте о закулисье.',
      );
    } else {
      advice.add(
        'Ваш ER выше 3%. Отличный уровень вовлечённости! '
        'Продолжайте в том же духе: регулярно публикуйте контент, активно взаимодействуйте с аудиторией '
        '(опросы, прямые эфиры, конкурсы), поддерживайте высокий уровень активности.',
      );
    }
    return advice;
  }

  /// Рекомендации по средним показателям
  List<String> _buildAveragesAdvice() {
    final advice = <String>[
      'Лайков в среднем: ${avgLikes.toStringAsFixed(1)}',
      'Репостов в среднем: ${avgReposts.toStringAsFixed(1)}',
      'Комментариев в среднем: ${avgComments.toStringAsFixed(1)}',
      'Просмотров в среднем: ${avgViews.toStringAsFixed(1)}',
    ];

    // — Пример рекомендаций по лайкам
    if (avgLikes < 5 && subscribersCount > 1000) {
      advice.add(
        'Лайков маловато по отношению к числу подписчиков. '
        'Возможно, постам не хватает эмоциональной окраски или прямого призыва к действию («Поставьте лайк, если…»).',
      );
    }

    // — Пример рекомендаций по комментариям
    if (avgComments < 2) {
      advice.add(
        'Среднее число комментариев низкое. Завершайте пост вопросом, чтобы стимулировать обсуждение, '
        'проводите регулярные рубрики, создайте опрос для «завлекания» к дискуссиям.',
      );
    } else if (avgComments >= 5) {
      advice.add(
        'Высокое число комментариев! Поддерживайте активность, отвечайте оперативно, '
        'задавайте уточняющие вопросы – пусть диалог продолжается.',
      );
    }

    // — Пример рекомендаций по репостам
    if (avgReposts < 1 && subscribersCount > 1000) {
      advice.add(
        'Репостов крайне мало. Попробуйте придумывать контент, которым хочется делиться: '
        'полезные инструкции, чек-листы, инфографика. Можно добавлять призывы «Поделись с друзьями».',
      );
    }

    return advice;
  }

  /// Рекомендации по частоте публикаций
  List<String> _buildFrequencyAdvice() {
    final advice = <String>[];
    if (postsCount < 2) {
      advice.add(
        'За выбранный период опубликовано слишком мало постов. '
        'Попробуйте увеличить частоту хотя бы до 2–3 постов в неделю, '
        'чтобы аудитория не теряла интерес и привыкла к регулярным обновлениям.',
      );
    } else if (postsCount > 20) {
      advice.add(
        'Очень много постов за короткий период. '
        'Следите, чтобы это не перегружало ленту подписчиков. '
        'Иногда лучше сократить количество и повысить качество.',
      );
    } else {
      advice.add(
        'Частота постинга выглядит сбалансированной. '
        'Продолжайте придерживаться контент-плана и наблюдайте, в какие дни/часы отклик больше всего.',
      );
    }
    return advice;
  }

  /// Дополнительные советы, не зависящие напрямую от метрик
  List<String> _buildExtraAdvice() {
    return [
      'Используйте встроенную статистику соцсети, чтобы определить лучшее время для публикаций.',
      'Экспериментируйте с разными форматами: короткие тексты, лонгриды, видео, Stories, прямые эфиры, опросы.',
      'Изучайте контент конкурентов или смежных сообществ: делайте аналитику, вдохновляйтесь идеями.',
      'Создавайте узнаваемый фирменный стиль (обложки, шаблоны, бренд-цвета).',
      'Оценивайте не только лайки, но и «глубину вовлечённости»: просмотры видео до конца, сохранения постов (если платформа это позволяет).',
      'Регулярно проводите конкурсы и коллаборации с другими пабликами/брендами, чтобы привлечь новую аудиторию.',
    ];
  }
}
