# -*- coding: utf-8 -*-
import vk_api
import json
import time

def get_group_stats_by_name(token, group_name):
    """
    Функция собирает максимально подробную статистику о сообществе ВКонтакте по его короткому имени (group_name).
    Получаем:
    1) Информацию о группе (groups.getById).
    2) Общую статистику сообщества (stats.get).
    3) Все посты стены (wall.get, постранично).
    4) Статистику по каждому посту (stats.getPostReach).
    5) Все видеозаписи (video.get, постранично).
    6) Все фотографии (photos.getAll, постранично).
    * Клипам в официальном API отдельного метода нет, чаще это обычные короткие видео. 
    Все результаты сохраняем в один словарь и возвращаем. 
    """

    vk_session = vk_api.VkApi(token=token)
    vk = vk_session.get_api()
    
    all_fields = ",".join([
        "activity",
        "ban_info",
        "can_post",
        "can_see_all_posts",
        "city",
        "contacts",
        "counters",
        "country",
        "cover",
        "description",
        "finish_date",
        "fixed_post",
        "links",
        "market",
        "members_count",
        "place",
        "site",
        "start_date",
        "status",
        "verified",
        "wiki_page"
    ])

    # -------------------------
    # 1) Получаем информацию о группе по короткому имени (group_name)
    # -------------------------
    group_info = vk.groups.getById(group_id=group_name, fields=all_fields)
    if not group_info:
        raise ValueError("Группа не найдена, проверь group_name.")
    
    group = group_info[0]
    group_id = group["id"]  # Числовой ID сообщества
    # У сообществ в API owner_id указывается со знаком "-", например -123456
    group_owner_id = -group_id

    # -------------------------
    # 2) Получаем общую статистику сообщества (stats.get)
    # -------------------------
    # Обратите внимание, что stats.get доступен только для сообществ ≥ 100 участников.
    # Также нужен токен пользователя, который является редактором/админом в группе.
    # С датами/таймстампами можно поиграться при желании, здесь для примера – без них.

    try:
        group_stats = vk.stats.get(group_id=group_id, intervals_count=10, extended=1)
    except vk_api.ApiError as e:
        # Если нет прав или нет 100+ участников, может вернуться ошибка
        group_stats = {"error": str(e)}

    # -------------------------
    # 3) Получаем все посты на стене сообщества (wall.get)
    #    и 4) Статистику по каждому посту (stats.getPostReach)
    # -------------------------
    all_posts = []
    offset = 0
    count = 100  # Максимум 100 записей за раз
    while True:
        response_posts = vk.wall.get(owner_id=group_owner_id, offset=offset, count=count)
        items = response_posts.get("items", [])
        all_posts.extend(items)

        # Для каждого поста попробуем получить stats.getPostReach
        # (метод вернет статистику для постов не старее 2015 года и только для 300 последних)
        # В реальности часто лимит 300 постов, поэтому осторожно.
        # Если пост в списке один, отправляем один id, если несколько – список id
        # Тут пример, как это можно сделать постранично
        post_ids = [item["id"] for item in items]
        post_stats_all = []

        # Разбиваем на чанки по 30 ID
        for i in range(0, len(post_ids), 30):
            chunk_ids = post_ids[i:i+30]
            try:
                stats_chunk = vk.stats.getPostReach(owner_id=group_owner_id, post_ids=",".join(map(str, chunk_ids)))
            except vk_api.ApiError as e:
                stats_chunk = [{"error": str(e)}] * len(chunk_ids)
            post_stats_all.extend(stats_chunk)

        # Складываем полученные чанки внутрь постов
        for post_item, stats_item in zip(items, post_stats_all):
            post_item["stats_post_reach"] = stats_item

        # Проверяем, есть ли ещё посты
        total_count = response_posts.get("count", 0)
        if offset + count >= total_count:
            break
        offset += count
        time.sleep(0.3)  # Небольшая пауза, чтобы не упереться в лимиты

    # -------------------------
    # 5) Получаем все видеозаписи (video.get)
    # -------------------------
    all_videos = []
    offset = 0
    count = 100  # Максимум 100 за раз
    while True:
        try:
            response_videos = vk.video.get(owner_id=group_owner_id, offset=offset, count=count, extended=1)
        except vk_api.ApiError as e:
            # Если вдруг нет прав или видео отключены, ловим ошибку
            break
        items = response_videos.get("items", [])
        all_videos.extend(items)

        total_count = response_videos.get("count", 0)
        if offset + count >= total_count:
            break
        offset += count
        time.sleep(0.3)

    # -------------------------
    # 6) Получаем все фотографии (photos.getAll)
    # -------------------------
    all_photos = []
    offset = 0
    count = 100  # Максимум 200, но безопаснее 100, чтобы не упереться в лимиты
    while True:
        try:
            response_photos = vk.photos.getAll(owner_id=group_owner_id, extended=1, offset=offset, count=count)
        except vk_api.ApiError as e:
            # Если вдруг нет прав или фото отключены, ловим ошибку
            break
        items = response_photos.get("items", [])
        all_photos.extend(items)

        total_count = response_photos.get("count", 0)
        if offset + count >= total_count:
            break
        offset += count
        time.sleep(0.3)

    # -------------------------
    # Собираем все данные в один словарь
    # -------------------------
    result = {
        "group_info": group,
        "group_stats": group_stats,
        "posts_data": all_posts,
        "videos_data": all_videos,
        "photos_data": all_photos,
    }

    return result


if __name__ == "__main__":
    # Замените 'YOUR_ACCESS_TOKEN' на ваш действующий токен пользователя,
    # у которого есть права администратора или редактора в нужном сообществе.
    token = "vk1.a.Qz1JCyUhO85hO2JKbxDuDoch69_SbI2RjZVSBp5H20fGDUgT0M-_W-SHG6BireiYd3qSbeOpElOYdq5S6CYCZ2RmU_7IDr_rWFoo90762_TtlS_EjKkiU7yNFfTUfGRwurbhSjHZwuAXo58hK7RokUl5GKCbar9hRz7vSNFJhY2z32VATfwCR_bEU8YvNhk1Pgeskj1INknEdMt94AAYqg"
    group_name = "synaptik_it"  # Например, "durov"
    
    data = get_group_stats_by_name(token, group_name)

    # Формируем примерный результат — берём только первый элемент из каждого списка
    example_result = {
        "group_info": data["group_info"],
        "group_stats": data["group_stats"],
        "posts_data": data["posts_data"][:1] if data["posts_data"] else [],
        "videos_data": data["videos_data"][:1] if data["videos_data"] else [],
        "photos_data": data["photos_data"][:1] if data["photos_data"] else [],
    }

    # Сохраняем в JSON
    with open("result_example.json", "w", encoding="utf-8") as f:
        json.dump(example_result, f, ensure_ascii=False, indent=2)

    print("Сохранён пример с одним элементом каждого типа в result_example.json")
