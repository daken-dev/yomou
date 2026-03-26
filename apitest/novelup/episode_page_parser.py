import argparse

from .parser_common import (
    absolute_url,
    clean_block_text,
    element_text,
    extract_episode_id,
    extract_story_id,
    extract_user_id,
    get_soup,
    parse_json_ld,
    parse_meta_tags,
    print_json,
)
from .toc_page_parser import parse_toc_page


def _find_episode_metadata(entries: list[dict], episode_id: str | None) -> tuple[dict | None, dict | None]:
    chapter = None
    for entry in entries:
        if entry["type"] == "chapter":
            chapter = entry
            continue
        if entry.get("id") == episode_id:
            return entry, chapter
    return None, chapter


def parse_episode_page(url: str) -> dict:
    soup = get_soup(url)
    canonical = soup.select_one("link[rel=canonical]")
    canonical_url = canonical.get("href") if canonical else url
    story_id = extract_story_id(canonical_url)
    episode_id = extract_episode_id(canonical_url)
    story_url = absolute_url(f"/story/{story_id}") if story_id else None

    toc = parse_toc_page(story_url) if story_url else None
    episode_meta, chapter_meta = _find_episode_metadata(toc["entries"], episode_id) if toc else (None, None)

    story_title = element_text(soup.select_one(".episodeHeader .storyTitle"))
    header_meta = soup.select_one(".episodeHeaderData_meta")
    content = soup.select_one("#js-scroll-area .content")
    foreword = soup.select_one(".novel_foreword")
    afterword = soup.select_one(".novel_afterword")
    move_links = soup.select(".move_set a[href]")

    prev_url = None
    toc_url = None
    next_url = None
    for link in move_links:
        label = element_text(link)
        href = absolute_url(link.get("href"), canonical_url)
        if label == "目次":
            toc_url = href
        elif label == "次へ":
            next_url = href
        elif label == "前へ":
            prev_url = href

    json_ld = parse_json_ld(soup)
    creative_work = next((item for item in json_ld if item.get("url") == canonical_url), None) or {}
    author = creative_work.get("author") if isinstance(creative_work.get("author"), dict) else {}

    return {
        "page_type": "episode",
        "url": canonical_url,
        "meta": parse_meta_tags(soup),
        "story_id": story_id,
        "episode_id": episode_id,
        "novel_title": story_title,
        "novel_url": story_url,
        "author_name": author.get("name"),
        "author_url": author.get("url"),
        "author_id": extract_user_id(author.get("url")),
        "chapter_title": chapter_meta.get("title") if chapter_meta else None,
        "title": element_text(soup.select_one("h1")),
        "published_at": episode_meta.get("published_at") if episode_meta else None,
        "read_time": element_text(header_meta.select_one(".readTime")) if header_meta else None,
        "sequence": element_text(header_meta.select_one(".totalEpisode")) if header_meta else None,
        "sequence_current": episode_meta.get("episode_no") if episode_meta else None,
        "sequence_total": toc["stats"].get("episode_count_value") if toc else None,
        "body": clean_block_text(content.get_text("\n", strip=False) if content else None),
        "body_html": content.decode_contents() if content else None,
        "foreword": clean_block_text(foreword.get_text("\n", strip=False) if foreword else None),
        "afterword": clean_block_text(afterword.get_text("\n", strip=False) if afterword else None),
        "navigation": {
            "toc_url": toc_url,
            "prev_url": prev_url,
            "next_url": next_url,
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    args = parser.parse_args()
    print_json(parse_episode_page(args.url))


if __name__ == "__main__":
    main()
