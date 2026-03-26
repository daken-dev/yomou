import argparse

from .parser_common import (
    absolute_url,
    clean_block_text,
    clean_text,
    element_text,
    extract_episode_id,
    extract_story_id,
    extract_user_id,
    find_json_ld_item,
    get_soup,
    parse_int,
    parse_json_ld,
    parse_meta_tags,
    print_json,
)


META_KEY_MAP = {
    "初掲載日": "published_at",
    "最終更新日": "last_updated_at",
    "完結日": "completed_at",
    "文字数": "character_count",
    "読了目安時間": "read_time",
    "総エピソード数": "episode_count",
    "ブックマーク登録": "bookmark_count",
    "コメント": "comment_count",
    "スタンプ": "stamp_count",
    "ビビッと": "buzz_count",
    "いいね": "like_count",
    "応援ポイント": "support_point",
    "ノベラポイント": "novela_point",
    "応援レビュー": "review_count",
    "誤字報告": "typo_report_policy",
}


def parse_meta_table(soup) -> dict:
    data: dict[str, str | int | None] = {}
    for row in soup.select("table.storyMeta tr"):
        key = element_text(row.find("th"))
        value = clean_text(row.find("td").get_text(" ", strip=True) if row.find("td") else None)
        if not key:
            continue
        normalized_key = META_KEY_MAP.get(key, key)
        data[normalized_key] = value

    for key in [
        "character_count",
        "episode_count",
        "bookmark_count",
        "comment_count",
        "stamp_count",
        "buzz_count",
        "like_count",
        "support_point",
        "novela_point",
        "review_count",
    ]:
        if key in data:
            data[f"{key}_value"] = parse_int(str(data[key]))

    return data


def parse_entries(soup) -> list[dict]:
    entries: list[dict] = []
    for item in soup.select(".episodeList .episodeListItem"):
        classes = set(item.get("class", []))
        if "chapter" in classes:
            entries.append(
                {
                    "type": "chapter",
                    "title": element_text(item),
                }
            )
            continue

        title_link = item.select_one("a.episodeTitle[href]")
        episode_url = absolute_url(title_link.get("href")) if title_link else None
        meta_items = item.select(".episodeDate p, .episodeDate a.commentLink")
        meta_texts = [element_text(node) for node in meta_items]

        entries.append(
            {
                "type": "episode",
                "episode_no": parse_int(title_link.get("data-number")) if title_link else None,
                "id": extract_episode_id(episode_url),
                "title": element_text(title_link),
                "url": episode_url,
                "published_at": meta_texts[0] if len(meta_texts) >= 1 else None,
                "character_count": meta_texts[1] if len(meta_texts) >= 2 else None,
                "character_count_value": parse_int(meta_texts[1]) if len(meta_texts) >= 2 else None,
                "read_time": meta_texts[2] if len(meta_texts) >= 3 else None,
                "good_count": parse_int(meta_texts[3]) if len(meta_texts) >= 4 else None,
                "comment_count": parse_int(meta_texts[4]) if len(meta_texts) >= 5 else None,
            }
        )
    return entries


def parse_toc_page(url: str) -> dict:
    soup = get_soup(url)
    json_ld = parse_json_ld(soup)
    creative_work = find_json_ld_item(json_ld, "CreativeWork") or {}

    author_link = soup.select_one(".storyAuthor[href], .storyAuthor a[href], a.storyAuthor[href], .storyIndexHeader a[href*='/user/']")
    author_url = absolute_url(author_link.get("href")) if author_link else None

    state_lamp = [element_text(item) for item in soup.select(".state_lamp > *") if element_text(item)]
    meta_table = parse_meta_table(soup)
    entries = parse_entries(soup)
    latest_episode = next((entry for entry in reversed(entries) if entry["type"] == "episode"), None)

    tags = [
        {
            "label": element_text(tag),
            "url": absolute_url(tag.get("href")),
        }
        for tag in soup.select("table.storyMeta tr:first-child td a[href]")
        if element_text(tag)
    ]

    self_rating_row = next(
        (row for row in soup.select("table.storyMeta tr") if element_text(row.find("th")) == "セルフレイティング"),
        None,
    )
    self_ratings = []
    if self_rating_row is not None:
        self_rating_text = clean_text(
            self_rating_row.find("td").get_text(" ", strip=True) if self_rating_row.find("td") else None
        )
        if self_rating_text:
            self_ratings = [{"label": part, "url": None} for part in self_rating_text.split(" ") if part]

    return {
        "page_type": "toc",
        "url": url,
        "meta": parse_meta_tags(soup),
        "id": extract_story_id(url),
        "title": element_text(soup.select_one(".storyTitle")),
        "genre": state_lamp[0] if len(state_lamp) >= 1 else None,
        "length_type": state_lamp[1] if len(state_lamp) >= 2 else None,
        "serial_status": state_lamp[2] if len(state_lamp) >= 3 else None,
        "author": {
            "id": extract_user_id(author_url),
            "name": element_text(author_link),
            "url": author_url,
        },
        "author_comment": element_text(soup.select_one(".authorComment")),
        "catchphrase": creative_work.get("headline"),
        "introduction": clean_block_text(
            soup.select_one(".novel_synopsis").get_text("\n", strip=False) if soup.select_one(".novel_synopsis") else None
        ),
        "image": creative_work.get("image"),
        "work_url": absolute_url(url),
        "latest_episode_url": latest_episode.get("url") if latest_episode else None,
        "tags": tags,
        "self_ratings": self_ratings,
        "stats": meta_table,
        "entries": entries,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    args = parser.parse_args()
    print_json(parse_toc_page(args.url))


if __name__ == "__main__":
    main()
