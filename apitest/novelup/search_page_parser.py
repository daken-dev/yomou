import argparse
from urllib.parse import parse_qs, urlparse

from .parser_common import (
    absolute_url,
    clean_text,
    element_text,
    extract_story_id,
    extract_user_id,
    get_soup,
    parse_meta_tags,
    parse_page_number,
    parse_scaled_number,
    print_json,
)


def parse_story_card(card) -> dict:
    title_link = card.select_one(".story_name a[href*='/story/']")
    author_link = card.select_one(".story_author_name a[href*='/user/']")

    work_url = absolute_url(title_link.get("href")) if title_link else None
    author_url = absolute_url(author_link.get("href")) if author_link else None

    icons = []
    for icon in card.select(".story_icons i.ic.story"):
        icon_classes = [klass for klass in icon.get("class", []) if klass not in {"ic", "story"}]
        if icon_classes:
            icons.extend(icon_classes)

    tags = [
        {
            "label": element_text(tag),
            "url": absolute_url(tag.get("href")),
        }
        for tag in card.select(".story_tag a[href]")
        if element_text(tag)
    ]

    return {
        "id": extract_story_id(work_url),
        "title": element_text(title_link),
        "catchphrase": element_text(card.select_one(".story_comment")),
        "author": {
            "id": extract_user_id(author_url),
            "name": element_text(author_link),
            "url": author_url,
        },
        "genre": element_text(card.select_one(".story_genre")),
        "length_type": element_text(card.select_one(".story_short")),
        "episode_count": clean_text(element_text(card.select_one(".story_episode_count"))),
        "episode_count_value": parse_scaled_number(element_text(card.select_one(".story_episode_count"))),
        "character_count": clean_text(element_text(card.select_one(".story_length"))),
        "character_count_value": parse_scaled_number(element_text(card.select_one(".story_length"))),
        "updated_at": element_text(card.select_one(".story_update")),
        "introduction": element_text(card.select_one(".story_introduction")),
        "tags": tags,
        "self_ratings": [element_text(item) for item in card.select(".story_rating li") if element_text(item)],
        "read_time": element_text(card.select_one(".read_time")),
        "stats": {
            "good_count": parse_scaled_number(element_text(card.select_one(".count_good span"))),
            "support_point": parse_scaled_number(element_text(card.select_one(".story_point span"))),
            "novela_point": parse_scaled_number(element_text(card.select_one(".story_point_pay span"))),
        },
        "icons": icons,
        "work_url": work_url,
    }


def parse_sort_options(soup) -> list[dict]:
    options: list[dict] = []
    select = soup.select_one("select[name='sort']")
    if select is None:
        return options

    for option in select.select("option"):
        options.append(
            {
                "value": option.get("value"),
                "label": clean_text(option.get_text()),
                "selected": option.has_attr("selected"),
            }
        )
    return options


def parse_search_page(url: str) -> dict:
    soup = get_soup(url)
    query = {key: values[-1] for key, values in parse_qs(urlparse(url).query).items()}
    works = [parse_story_card(card) for card in soup.select("ul.searchResultList li.one_set .story_card")]

    header = soup.select_one(".searchResultHeader")
    total_count_text = element_text(header.select_one(".searchCount")) if header else None

    return {
        "page_type": "search",
        "url": url,
        "meta": parse_meta_tags(soup),
        "query": query,
        "page": parse_page_number(url),
        "keyword": element_text(header.select_one(".searchKeyword")) if header else None,
        "total_count_text": total_count_text,
        "total_count": parse_scaled_number(total_count_text),
        "sort_options": parse_sort_options(soup),
        "works": works,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    args = parser.parse_args()
    print_json(parse_search_page(args.url))


if __name__ == "__main__":
    main()
