# services/vk_data.py

import time
import vk_api

token = "vk1.a.Qz1JCyUhO85hO2JKbxDuDoch69_SbI2RjZVSBp5H20fGDUgT0M-_W-SHG6BireiYd3qSbeOpElOYdq5S6CYCZ2RmU_7IDr_rWFoo90762_TtlS_EjKkiU7yNFfTUfGRwurbhSjHZwuAXo58hK7RokUl5GKCbar9hRz7vSNFJhY2z32VATfwCR_bEU8YvNhk1Pgeskj1INknEdMt94AAYqg"

def get_group_info(group_name: str) -> dict:
    """
    Возвращает информацию о группе (groups.getById).
    """
    vk_session = vk_api.VkApi(token=token)
    vk = vk_session.get_api()

    all_fields = ",".join([
        "activity","ban_info","can_post","can_see_all_posts","city","contacts",
        "counters","country","cover","description","finish_date","fixed_post",
        "links","market","members_count","place","site","start_date","status",
        "verified","wiki_page"
    ])

    group_info = vk.groups.getById(group_id=group_name, fields=all_fields)
    if not group_info:
        raise ValueError(f"Группа '{group_name}' не найдена. Проверь короткое имя/ID.")

    return group_info[0]


def get_posts_data(owner_id: int, date_from: int = None, date_to: int = None) -> list:
    """
    Получаем все посты сообщества (wall.get) порционно.
    Не прерываемся сразу при первом неподходящем посте, а чекаем весь список.
    """
    vk_session = vk_api.VkApi(token=token)
    vk = vk_session.get_api()

    all_posts = []
    offset = 0
    count = 100  # максимум 100 за раз

    while True:
        response = vk.wall.get(owner_id=owner_id, offset=offset, count=count)
        items = response.get("items", [])
        if not items:
            break

        # Получаем статистику reach порциями по 30 ID
        post_ids = [item["id"] for item in items]
        post_stats_all = []
        for i in range(0, len(post_ids), 30):
            chunk = post_ids[i:i+30]
            try:
                stats_chunk = vk.stats.getPostReach(
                    owner_id=owner_id,
                    post_ids=",".join(map(str, chunk))
                )
            except vk_api.ApiError:
                stats_chunk = [{} for _ in chunk]
            post_stats_all.extend(stats_chunk)
        # Вклеиваем stats_post_reach
        for post_item, stat_item in zip(items, post_stats_all):
            post_item["stats_post_reach"] = stat_item

        filtered_batch = []
        for p in items:
            p_date = p.get("date", 0)
            if date_to and p_date > date_to:
                # Если слишком свежий, просто пропускаем
                continue
            if date_from and p_date < date_from:
                # Если этот пост старше нужного периода — 
                # велика вероятность, что и все следующие в списке тоже старше,
                # но мы сначала проверим их, чтобы не упустить что-то непоследовательное
                continue
            filtered_batch.append(p)

        # Добавляем то, что попало в диапазон
        all_posts.extend(filtered_batch)

        # Дополнительно можно понять, что если последний (самый старый) пост этой порции 
        # всё ещё свежее, чем date_from, — значит, имеет смысл грузить дальше.
        # Но если он уже «старше date_from», можно прерываться.
        # При условии, что wall.get возвращает записи в порядке от новых к старым:
        last_in_portion_date = items[-1].get("date", 0)
        # Если он меньше date_from — значит и всё следующее ещё старее.
        if date_from and last_in_portion_date < date_from:
            break

        # Если достали меньше 100 — значит посты кончились
        total_count = response.get("count", 0)
        if offset + count >= total_count:
            break

        offset += count
        time.sleep(0.3)

    return all_posts


def get_photos_data(owner_id: int, date_from: int = None, date_to: int = None) -> list:
    """
    Получаем все фото (photos.getAll), порционно. 
    Фильтруем по дате, не прерывая цикл слишком рано.
    """
    vk_session = vk_api.VkApi(token=token)
    vk = vk_session.get_api()

    all_photos = []
    offset = 0
    count = 100

    while True:
        response = vk.photos.getAll(
            owner_id=owner_id,
            extended=1,
            offset=offset,
            count=count
        )
        items = response.get("items", [])
        if not items:
            break

        # Фильтруем по date
        filtered_batch = []
        for ph in items:
            ph_date = ph.get("date", 0)
            if date_to and ph_date > date_to:
                # Слишком «новое» фото
                continue
            if date_from and ph_date < date_from:
                # Слишком старое
                continue
            filtered_batch.append(ph)

        all_photos.extend(filtered_batch)

        # Если последний фото-объект уже старше date_from,
        # значит дальше всё ещё старее — можно прерваться
        last_date = items[-1].get("date", 0)
        if date_from and last_date < date_from:
            break

        total_count = response.get("count", 0)
        if offset + count >= total_count:
            break

        offset += count
        time.sleep(0.3)

    return all_photos


def get_videos_data(owner_id: int, date_from: int = None, date_to: int = None) -> list:
    """
    Получаем все видео (video.get), порционно. 
    Фильтруем по дате, не прерывая цикл слишком рано.
    """
    vk_session = vk_api.VkApi(token=token)
    vk = vk_session.get_api()

    all_videos = []
    offset = 0
    count = 100

    while True:
        try:
            response = vk.video.get(
                owner_id=owner_id,
                offset=offset,
                count=count,
                extended=1
            )
        except vk_api.ApiError:
            break

        items = response.get("items", [])
        if not items:
            break

        filtered_batch = []
        for v in items:
            v_date = v.get("date", 0)
            if date_to and v_date > date_to:
                # Слишком новое
                continue
            if date_from and v_date < date_from:
                # Слишком старое
                continue
            filtered_batch.append(v)

        all_videos.extend(filtered_batch)

        last_date = items[-1].get("date", 0)
        if date_from and last_date < date_from:
            break

        total_count = response.get("count", 0)
        if offset + count >= total_count:
            break

        offset += count
        time.sleep(0.3)

    return all_videos
