import argparse
from urllib.parse import parse_qs, urlparse

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


def parse_search_page(url: str) -> dict:
    soup = get_soup(url)
    apollo = parse_apollo_state(soup)
    root = apollo["ROOT_QUERY"]

    connection_key = next((key for key in root if key.startswith("searchWorks(")), None)
    if connection_key is None:
        raise ValueError("Kakuyomu search page did not contain searchWorks data.")

    connection = root[connection_key]
    page_info = connection.get("pageInfo", {})
    query = {key: values[-1] for key, values in parse_qs(urlparse(url).query).items()}
    page = int(query.get("page", "1"))

    works: list[dict] = []
    for node in connection.get("nodes", []):
        work = resolve_ref(apollo, node)
        if work is None:
            continue

        author = resolve_ref(apollo, work.get("author"))
        first_episode = resolve_ref(apollo, work.get("firstPublicEpisodeUnion"))
        author_name = author.get("name") if author else None

        works.append(
            {
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
                "total_character_count": work.get("totalCharacterCount"),
                "public_episode_count": work.get("publicEpisodeCount"),
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
            }
        )

    return {
        "page_type": "search",
        "url": url,
        "meta": parse_meta_tags(soup),
        "query": query,
        "page": page,
        "has_next_page": page_info.get("hasNextPage"),
        "has_previous_page": page_info.get("hasPreviousPage"),
        "total_count": connection.get("totalCount"),
        "works": works,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    args = parser.parse_args()
    print_json(parse_search_page(args.url))


if __name__ == "__main__":
    main()
