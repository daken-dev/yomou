import argparse
from urllib.parse import urlparse

from .parser_common import absolute_url, get_soup, parse_meta_tags, parse_page_number, print_json
from .search_page_parser import parse_story_card, parse_sort_options


def parse_ranking_page(url: str) -> dict:
    soup = get_soup(url)
    works: list[dict] = []

    for index, item in enumerate(soup.select("#infinite-scroll-container > li.infinite-scroll-item"), start=1):
        card = item.select_one(".story_card")
        if card is None:
            continue
        entry = parse_story_card(card)
        rank_text = item.select_one(".story_rank img")
        entry["rank"] = index + (parse_page_number(url) - 1) * len(
            soup.select("#infinite-scroll-container > li.infinite-scroll-item")
        )
        entry["rank_label"] = rank_text.get("alt") if rank_text else None
        works.append(entry)

    next_button = soup.select_one(".infinite-scroll-more[href]")
    path_parts = [part for part in urlparse(url).path.split("/") if part]

    ranking_category = path_parts[1] if len(path_parts) >= 2 else None
    ranking_period = path_parts[2] if len(path_parts) >= 3 else None

    return {
        "page_type": "ranking",
        "url": url,
        "meta": parse_meta_tags(soup),
        "page": parse_page_number(url),
        "title": soup.select_one("h1").get_text(" ", strip=True) if soup.select_one("h1") else None,
        "category": ranking_category,
        "period": ranking_period,
        "next_page_url": absolute_url(next_button.get("href")) if next_button else None,
        "sort_options": parse_sort_options(soup),
        "works": works,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    args = parser.parse_args()
    print_json(parse_ranking_page(args.url))


if __name__ == "__main__":
    main()
