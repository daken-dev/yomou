import argparse
import re

from parser_common import (
    absolute_url,
    block_text,
    build_info_url,
    clean_text,
    element_text,
    get_soup,
    parse_last_page_number,
    parse_meta_tags,
    parse_page_number,
    print_json,
)


def parse_short_story_info(url: str) -> dict | None:
    info_url = build_info_url(url)
    if not info_url:
        return None

    from info_page_parser import parse_info_page

    return parse_info_page(info_url)


def parse_short_story_entry(url: str, title: str | None, info_fields: dict[str, str], page_number: int) -> dict:
    return {
        "type": "episode",
        "episode_no": 1,
        "title": title,
        "url": url,
        "published_at": info_fields.get("掲載日"),
        "revised_at": info_fields.get("最終更新日"),
        "index_page": page_number,
        "single_episode": True,
    }


def parse_result_stats(soup) -> dict | None:
    stats = element_text(soup.select_one(".c-pager__result-stats"))
    if not stats:
        return None

    match = re.search(r"エピソード\s*(\d+)\s*～\s*(\d+)\s*を表示中", stats)
    if not match:
        return None

    return {
        "raw": stats,
        "from_episode": int(match.group(1)),
        "to_episode": int(match.group(2)),
    }


def build_prev_page_url(url: str) -> str | None:
    page = parse_page_number(url)
    if page <= 1:
        return None

    parsed = re.sub(r"([?&])p=\d+", "", url)
    parsed = parsed.rstrip("?&")
    if page - 1 == 1:
        return parsed
    separator = "&" if "?" in parsed else "?"
    return f"{parsed}{separator}p={page - 1}"


def find_inherited_chapter(url: str) -> str | None:
    prev_url = build_prev_page_url(url)
    while prev_url:
        soup = get_soup(prev_url)
        eplist = soup.select_one(".p-eplist")
        if eplist:
            for child in reversed(eplist.find_all(recursive=False)):
                classes = set(child.get("class", []))
                if "p-eplist__chapter-title" in classes:
                    return element_text(child)
        prev_url = build_prev_page_url(prev_url)
    return None


def parse_episode_entry(sublist, url: str, page_number: int) -> dict:
    subtitle = sublist.select_one(".p-eplist__subtitle")
    update = sublist.select_one(".p-eplist__update")

    revised_at = None
    if update:
        revised = update.find("span")
        if revised and revised.get("title"):
            revised_at = clean_text(revised["title"].replace(" 改稿", ""))

    href = subtitle.get("href") if subtitle else None
    episode_no = None
    if href:
        match = re.search(r"/([0-9]+)/?$", href)
        if match:
            episode_no = int(match.group(1))

    return {
        "type": "episode",
        "episode_no": episode_no,
        "title": block_text(subtitle),
        "url": absolute_url(href, url),
        "published_at": clean_text(update.contents[0] if update and update.contents else None),
        "revised_at": revised_at,
        "index_page": page_number,
    }


def parse_toc_page(url: str) -> dict:
    soup = get_soup(url)
    page_number = parse_page_number(url)
    inherited_chapter = find_inherited_chapter(url) if page_number > 1 else None

    title = element_text(soup.select_one(".p-novel__title"))
    author_link = soup.select_one(".p-novel__author a")
    summary_element = soup.select_one("#novel_ex, .p-novel__summary")
    latest_episode_published = element_text(soup.select_one(".p-novel__date-published"))
    pager_last = soup.select_one(".c-pager__item--last")
    result_stats = parse_result_stats(soup)
    has_body = soup.select_one(".p-novel__body") is not None
    short_story_info = None
    info_fields: dict[str, str] = {}

    entries: list[dict] = []
    current_chapter = inherited_chapter
    inserted_inherited = False

    eplist = soup.select_one(".p-eplist")
    if eplist:
        for child in eplist.find_all(recursive=False):
            classes = set(child.get("class", []))
            if "p-eplist__chapter-title" in classes:
                current_chapter = element_text(child)
                entries.append(
                    {
                        "type": "chapter",
                        "title": current_chapter,
                        "inherited": False,
                        "index_page": page_number,
                    }
                )
                inserted_inherited = True
                continue

            if "p-eplist__sublist" not in classes:
                continue

            if current_chapter and not inserted_inherited:
                entries.append(
                    {
                        "type": "chapter",
                        "title": current_chapter,
                        "inherited": True,
                        "index_page": page_number,
                    }
                )
                inserted_inherited = True

            entries.append(parse_episode_entry(child, url, page_number))

    if not entries and has_body:
        short_story_info = parse_short_story_info(url)
        info_fields = short_story_info.get("fields", {}) if short_story_info else {}
        entries.append(parse_short_story_entry(url, title, info_fields, page_number))

    summary = block_text(summary_element)
    summary_html = summary_element.decode_contents() if summary_element else None
    if summary is None and short_story_info:
        summary = info_fields.get("あらすじ")

    return {
        "page_type": "toc",
        "url": url,
        "page": page_number,
        "meta": parse_meta_tags(soup),
        "is_single_episode": bool(not eplist and has_body),
        "title": title,
        "author": {
            "name": element_text(author_link),
            "url": absolute_url(author_link.get("href")) if author_link else None,
        },
        "summary": summary,
        "summary_html": summary_html,
        "latest_episode_published": latest_episode_published,
        "result_stats": result_stats,
        "last_page": parse_last_page_number(soup, url),
        "last_page_url": absolute_url(pager_last.get("href"), url) if pager_last else None,
        "entries": entries,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    args = parser.parse_args()
    print_json(parse_toc_page(args.url))


if __name__ == "__main__":
    main()
