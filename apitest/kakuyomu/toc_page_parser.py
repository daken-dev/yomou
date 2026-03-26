import argparse

from .parser_common import (
    absolute_url,
    build_episode_url,
    build_work_url,
    get_soup,
    parse_apollo_state,
    parse_meta_tags,
    print_json,
    ref_id,
    resolve_ref,
)


def parse_toc_page(url: str) -> dict:
    soup = get_soup(url)
    apollo = parse_apollo_state(soup)
    root = apollo["ROOT_QUERY"]

    work_key = next((key for key in root if key.startswith("work(")), None)
    if work_key is None:
        raise ValueError("Kakuyomu work page did not contain work data.")

    work = resolve_ref(apollo, root[work_key])
    if work is None:
        raise ValueError("Kakuyomu work page contained an invalid work reference.")

    author = resolve_ref(apollo, work.get("author"))
    author_name = author.get("name") if author else None

    entries: list[dict] = []
    episode_no = 0
    for toc_ref in work.get("tableOfContents", []):
        toc_chapter = resolve_ref(apollo, toc_ref)
        if toc_chapter is None:
            continue

        chapter = resolve_ref(apollo, toc_chapter.get("chapter"))
        chapter_title = chapter.get("title") if chapter else None
        chapter_level = chapter.get("level") if chapter else None

        entries.append(
            {
                "type": "chapter",
                "title": chapter_title,
                "level": chapter_level,
            }
        )

        for episode_ref in toc_chapter.get("episodeUnions", []):
            episode = resolve_ref(apollo, episode_ref)
            if episode is None:
                continue

            episode_no += 1
            entries.append(
                {
                    "type": "episode",
                    "episode_no": episode_no,
                    "id": episode.get("id"),
                    "title": episode.get("title"),
                    "url": build_episode_url(work["id"], episode["id"]),
                    "published_at": episode.get("publishedAt"),
                }
            )

    first_episode = resolve_ref(apollo, work.get("firstPublicEpisodeUnion"))

    return {
        "page_type": "toc",
        "url": url,
        "meta": parse_meta_tags(soup),
        "id": work.get("id"),
        "title": work.get("title"),
        "catchphrase": work.get("catchphrase"),
        "introduction": work.get("introduction"),
        "author": {
            "id": ref_id(work.get("author")),
            "name": author_name,
            "activity_name": author.get("activityName") if author else None,
            "url": absolute_url(f"/users/{author_name}") if author_name else None,
        },
        "genre": work.get("genre"),
        "serial_status": work.get("serialStatus"),
        "published_at": work.get("publishedAt"),
        "last_episode_published_at": work.get("lastEpisodePublishedAt"),
        "total_review_point": work.get("totalReviewPoint"),
        "total_followers": work.get("totalFollowers"),
        "total_read_count": work.get("totalReadCount"),
        "review_count": work.get("reviewCount"),
        "public_episode_count": work.get("publicEpisodeCount"),
        "total_character_count": work.get("totalCharacterCount"),
        "tags": work.get("tagLabels"),
        "flags": {
            "is_cruel": work.get("isCruel"),
            "is_violent": work.get("isViolent"),
            "is_sexual": work.get("isSexual"),
        },
        "work_url": build_work_url(work["id"]),
        "first_episode_url": (
            build_episode_url(work["id"], first_episode["id"]) if first_episode else None
        ),
        "entries": entries,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    args = parser.parse_args()
    print_json(parse_toc_page(args.url))


if __name__ == "__main__":
    main()
