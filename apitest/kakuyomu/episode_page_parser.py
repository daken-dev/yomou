import argparse

from .parser_common import (
    absolute_url,
    block_text,
    build_work_url,
    element_text,
    extract_episode_id,
    extract_work_id,
    get_soup,
    parse_meta_tags,
    print_json,
)
from .toc_page_parser import parse_toc_page


def _find_episode_metadata(entries: list[dict], episode_id: str | None) -> tuple[dict | None, dict | None]:
    current_chapter = None
    for entry in entries:
        if entry.get("type") == "chapter":
            current_chapter = entry
            continue
        if entry.get("id") == episode_id:
            return entry, current_chapter
    return None, current_chapter


def parse_episode_page(url: str) -> dict:
    soup = get_soup(url)
    canonical = soup.find("link", rel="canonical")
    canonical_url = canonical.get("href") if canonical else url
    work_id = extract_work_id(canonical_url)
    episode_id = extract_episode_id(canonical_url)
    work_url = build_work_url(work_id) if work_id else None

    toc = parse_toc_page(work_url) if work_url else None
    episode_meta, chapter_meta = _find_episode_metadata(toc["entries"], episode_id) if toc else (None, None)

    header = soup.select_one("#contentMain-header")
    work_title = element_text(header.select_one("#contentMain-header-workTitle")) if header else None
    author_name = element_text(header.select_one("#contentMain-header-author")) if header else None
    author_url = None
    if author_name and author_name.startswith("@"):
        author_url = absolute_url(f"/users/{author_name[1:]}")

    body = soup.select_one(".widget-episodeBody")
    prev_link = soup.select_one("#contentMain-readPrevEpisode")
    next_link = soup.select_one("#contentMain-readNextEpisode")
    rel_prev = soup.find("link", rel="prev")
    rel_next = soup.find("link", rel="next")

    body_html = body.decode_contents() if body else None
    sequence = None
    if episode_meta and toc:
        sequence = f'{episode_meta["episode_no"]} / {toc["public_episode_count"]}'

    return {
        "page_type": "episode",
        "url": canonical_url,
        "meta": parse_meta_tags(soup),
        "work_id": work_id,
        "episode_id": episode_id,
        "novel_title": work_title,
        "novel_url": work_url,
        "author_name": author_name,
        "author_url": author_url,
        "chapter_title": (
            element_text(header.select_one(".chapterTitle span")) if header else None
        )
        or (chapter_meta.get("title") if chapter_meta else None),
        "title": element_text(soup.select_one(".widget-episodeTitle")),
        "published_at": episode_meta.get("published_at") if episode_meta else None,
        "sequence": sequence,
        "sequence_current": episode_meta.get("episode_no") if episode_meta else None,
        "sequence_total": toc.get("public_episode_count") if toc else None,
        "body": block_text(body),
        "body_html": body_html,
        "navigation": {
            "toc_url": work_url,
            "prev_url": absolute_url(prev_link.get("href"), canonical_url)
            if prev_link
            else absolute_url(rel_prev.get("href"), canonical_url) if rel_prev else None,
            "next_url": absolute_url(next_link.get("href"), canonical_url)
            if next_link
            else absolute_url(rel_next.get("href"), canonical_url) if rel_next else None,
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    args = parser.parse_args()
    print_json(parse_episode_page(args.url))


if __name__ == "__main__":
    main()
