import argparse
import re

from .parser_common import absolute_url, block_text, element_text, get_soup, parse_meta_tags, print_json
from .toc_page_parser import parse_toc_page


def find_body_sections(soup):
    container = soup.select_one(".p-novel__body")
    if not container:
        return None, None, None

    preface = container.select_one(":scope > .p-novel__text--preface")
    afterword = container.select_one(":scope > .p-novel__text--afterword")

    body = None
    for candidate in container.select(":scope > .p-novel__text"):
        classes = set(candidate.get("class", []))
        if "p-novel__text--preface" in classes or "p-novel__text--afterword" in classes:
            continue
        body = candidate
        break

    return preface, body, afterword


def find_chapter_title(url: str, sequence_current: int | None) -> str | None:
    if sequence_current is None:
        return None

    novel_match = re.match(r"^(https://ncode\.syosetu\.com/[^/]+/)", url)
    if not novel_match:
        return None

    novel_url = novel_match.group(1)
    toc_page = ((sequence_current - 1) // 100) + 1
    toc_url = novel_url if toc_page == 1 else f"{novel_url}?p={toc_page}"

    current_chapter = None
    for entry in parse_toc_page(toc_url)["entries"]:
        if entry["type"] == "chapter":
            current_chapter = entry["title"]
            continue
        if entry.get("episode_no") == sequence_current:
            return current_chapter

    return None


def parse_episode_page(url: str) -> dict:
    soup = get_soup(url)
    page_title = element_text(soup.select_one(".p-novel__title"))
    number = element_text(soup.select_one(".p-novel__number"))

    navigation = {
        "toc_url": None,
        "prev_url": None,
        "next_url": None,
    }
    for link in soup.select(".c-pager--center a.c-pager__item"):
        label = element_text(link)
        href = absolute_url(link.get("href"), url)
        if label == "目次":
            navigation["toc_url"] = href
        elif label == "前へ":
            navigation["prev_url"] = href
        elif label == "次へ":
            navigation["next_url"] = href

    announce = None
    for candidate in soup.select(".c-announce-box .c-announce"):
        links = candidate.find_all("a")
        if len(links) >= 2 and links[0].get("href", "").startswith("/"):
            announce = candidate
            break

    announce_links = announce.find_all("a") if announce else []
    novel_link = announce_links[0] if announce_links else None
    author_link = announce_links[1] if len(announce_links) > 1 else None
    fallback_author_link = soup.select_one(".p-novel__author a")

    preface, body, afterword = find_body_sections(soup)
    is_single_episode = number is None and navigation["prev_url"] is None and navigation["next_url"] is None and body is not None

    sequence_current = None
    sequence_total = None
    if number:
        match = re.search(r"(\d+)\s*/\s*(\d+)", number)
        if match:
            sequence_current = int(match.group(1))
            sequence_total = int(match.group(2))
    elif is_single_episode:
        number = "1 / 1"
        sequence_current = 1
        sequence_total = 1
        navigation["toc_url"] = url

    return {
        "page_type": "episode",
        "url": url,
        "meta": parse_meta_tags(soup),
        "is_single_episode": is_single_episode,
        "novel_title": element_text(novel_link) or page_title,
        "novel_url": absolute_url(novel_link.get("href"), url) if novel_link else (url if is_single_episode else None),
        "author_name": element_text(author_link or fallback_author_link),
        "author_url": absolute_url((author_link or fallback_author_link).get("href"), url)
        if (author_link or fallback_author_link)
        else None,
        "chapter_title": find_chapter_title(url, sequence_current),
        "sequence": number,
        "sequence_current": sequence_current,
        "sequence_total": sequence_total,
        "title": page_title,
        "preface": block_text(preface),
        "preface_html": preface.decode_contents() if preface else None,
        "body": block_text(body),
        "body_html": body.decode_contents() if body else None,
        "afterword": block_text(afterword),
        "afterword_html": afterword.decode_contents() if afterword else None,
        "navigation": navigation,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    args = parser.parse_args()
    print_json(parse_episode_page(args.url))


if __name__ == "__main__":
    main()