import argparse
import re
from html import unescape
from urllib.parse import parse_qs, urlparse

from .parser_common import (
    absolute_url,
    clean_text,
    element_text,
    get_soup,
    parse_int,
    parse_meta_tags,
    parse_page_number,
    print_json,
)


def parse_select_options(select_html: str) -> list[dict]:
    options: list[dict] = []
    pattern = re.compile(
        r"<option(?P<attrs>[^>]*)value=\"(?P<value>[^\"]*)\"[^>]*>(?P<label>.*?)(?=<option|\Z)",
        re.DOTALL,
    )
    for match in pattern.finditer(select_html):
        attrs = match.group("attrs")
        value = unescape(match.group("value"))
        label = clean_text(re.sub(r"<[^>]+>", " ", unescape(match.group("label"))))
        if label is None:
            continue
        options.append(
            {
                "value": value,
                "label": label,
                "selected": "selected" in attrs,
            }
        )
    return options


def parse_search_type_options(soup) -> list[dict]:
    select = soup.select_one('select[name="search_type"]')
    return parse_select_options(str(select)) if select else []


def parse_gensaku_options(soup) -> list[dict]:
    select = soup.select_one('select[name="gensaku"]')
    options = parse_select_options(str(select)) if select else []
    for option in options:
        value = option["value"]
        option["is_custom"] = False
        if value.startswith("原作："):
            option["is_custom"] = True
    return options


def parse_sort_options(soup) -> list[dict]:
    select = soup.select_one('select[name="type"]')
    return parse_select_options(str(select)) if select else []


def normalize_summary(text: str | None) -> str | None:
    if not text:
        return None
    normalized = text.replace("【あらすじ】", "", 1).replace("▼", "\n").strip()
    lines = [line.strip() for line in normalized.splitlines()]
    lines = [line for line in lines if line]
    return "\n".join(lines) or None


def parse_rating_distribution(section) -> dict[int, int]:
    distribution: dict[int, int] = {}
    for row in section.select(".blo_bunpu tr"):
        cells = row.find_all("td")
        if not cells:
            continue
        label = element_text(cells[0])
        if not label:
            continue
        match = re.search(r"☆(\d+):(\d+)", label)
        if not match:
            continue
        distribution[int(match.group(1))] = int(match.group(2))
    return distribution


def parse_stats_line(section) -> dict:
    stats_line = clean_text(element_text(section.select("div.all_keyword")[-1]))
    if not stats_line:
        return {}

    stats: dict[str, int | str | None] = {"raw": stats_line}
    match = re.search(r"UA\(通算/今週/先週\)：([\d,]+)/([\d,]+)/([\d,]+)", stats_line)
    if match:
        stats["ua_total"] = parse_int(match.group(1))
        stats["ua_this_week"] = parse_int(match.group(2))
        stats["ua_last_week"] = parse_int(match.group(3))

    for key, pattern in {
        "favorites": r"お気に入り：([\d,]+)",
        "reviews": r"感想：([\d,]+)",
        "voters": r"投票者：([\d,]+)",
        "average_characters_per_episode": r"平均：([\d,]+)\s*字",
    }.items():
        metric_match = re.search(pattern, stats_line)
        if metric_match:
            stats[key] = parse_int(metric_match.group(1))

    return stats


def parse_title_meta(section, page_url: str) -> dict:
    block = section.select_one(".blo_title_base")
    title_link = block.select_one("a[href*='/novel/']") if block else None
    meta_links = block.select(".blo_title_sak a") if block else []
    author_link = meta_links[-1] if meta_links else None

    original = element_text(meta_links[0]) if len(meta_links) >= 1 else None
    setting = element_text(meta_links[1]) if len(meta_links) >= 2 else None
    genre = element_text(meta_links[2]) if len(meta_links) >= 3 else None

    return {
        "title": element_text(title_link),
        "url": absolute_url(title_link.get("href"), page_url) if title_link else None,
        "original": original,
        "setting": setting,
        "genre": genre,
        "author": {
            "name": element_text(author_link),
            "url": absolute_url(author_link.get("href"), page_url) if author_link else None,
        },
    }


def parse_serial_meta(section, page_url: str) -> dict:
    block = section.select_one(".blo_wasuu_base")
    status = block.find("span") if block else None
    latest_episode_link = block.select_one("a[href*='/novel/']") if block else None
    total_characters = block.select_one('div[title="総文字数"]') if block else None

    return {
        "serial_status": element_text(status),
        "serial_status_title": clean_text(status.get("title") if status else None),
        "episode_count": parse_int(element_text(latest_episode_link)),
        "latest_episode_url": (
            absolute_url(latest_episode_link.get("href"), page_url) if latest_episode_link else None
        ),
        "total_characters": parse_int(element_text(total_characters)),
    }


def parse_score_meta(section) -> dict:
    block = section.select_one(".blo_hyouka")
    adjusted_average = None
    if block:
        match = re.search(r"調整平均：([0-9.]+)", element_text(block.select_one(".blo_mix")) or "")
        if match:
            adjusted_average = float(match.group(1))

    image = block.select_one("img") if block else None
    grade = clean_text(image.get("title") if image else None)

    return {
        "adjusted_average": adjusted_average,
        "grade": None if grade == "-.--" else grade,
    }


def parse_updated_at(section) -> str | None:
    block = section.select_one(".blo_date")
    if block is None:
        return None

    date_text = clean_text(block.contents[0] if block.contents else None)
    time_text = element_text(block.find("div"))
    if date_text and time_text:
        return f"{date_text} {time_text}"
    return date_text or time_text


def parse_tags(section, page_url: str) -> dict:
    blocks = section.select("div.all_keyword")
    if len(blocks) < 2:
        return {"warning_tags": [], "tags": []}

    block = blocks[0]
    warning_tags: list[dict] = []
    normal_tags: list[dict] = []
    for tag in block.select("a[href]"):
        entry = {
            "label": element_text(tag),
            "url": absolute_url(tag.get("href"), page_url),
        }
        if "alert_color" in (tag.get("class") or []):
            warning_tags.append(entry)
        else:
            normal_tags.append(entry)

    return {"warning_tags": warning_tags, "tags": normal_tags}


def parse_detail_links(section, page_url: str) -> dict:
    detail_link = section.select_one(".blo_infom a[href*='mode=ss_detail']")
    popup_links = {
        element_text(link): absolute_url(link.get("href"), page_url)
        for link in section.select(".pop_info a[href]")
        if element_text(link)
    }

    return {
        "detail_url": absolute_url(detail_link.get("href"), page_url) if detail_link else None,
        "pdf_url": popup_links.get("PDF"),
        "review_url": popup_links.get("感想ページへ (0件)") or popup_links.get("感想ページへ"),
        "analyze_url": popup_links.get("アクセス解析"),
        "favorite_url": popup_links.get("お気に入りの追加"),
    }


def parse_work(section, page_url: str) -> dict:
    nid = section.get("id", "").removeprefix("nid_") or None
    title_meta = parse_title_meta(section, page_url)
    serial_meta = parse_serial_meta(section, page_url)
    score_meta = parse_score_meta(section)
    tags = parse_tags(section, page_url)
    detail_links = parse_detail_links(section, page_url)
    summary_raw = element_text(section.select_one(".blo_inword"))

    return {
        "id": nid,
        **title_meta,
        **serial_meta,
        **score_meta,
        "updated_at": parse_updated_at(section),
        "summary_raw": summary_raw,
        "summary": normalize_summary(summary_raw),
        "rating_distribution": parse_rating_distribution(section),
        **tags,
        "stats": parse_stats_line(section),
        **detail_links,
    }


def parse_heading(soup) -> dict:
    heading_node = soup.select_one(".section.normal.autopagerize_page_element .heading h2")
    heading = None
    if heading_node:
        heading = clean_text(
            "".join(
                str(node).strip()
                for node in heading_node.contents
                if getattr(node, "get", lambda *_args, **_kwargs: None)("class") != ["button_menu"]
            )
        )
    total_count = None
    display_query = heading
    if heading:
        match = re.search(r"^(.*)\(([\d,]+)件\)$", heading)
        if match:
            display_query = clean_text(match.group(1))
            total_count = parse_int(match.group(2))

    return {"heading": heading, "display_query": display_query, "total_count": total_count}


def parse_paging(soup, page_url: str) -> dict:
    paging = soup.select_one(".paging")
    if paging is None:
        page = parse_page_number(page_url)
        return {
            "page": page,
            "current_page": page,
            "last_page": page,
            "next_page_url": None,
            "previous_page_url": None,
        }

    current_page = None
    last_page = None
    next_page_url = None
    previous_page_url = None

    for strong in paging.select("strong"):
        current_page = parse_int(element_text(strong)) or current_page

    for link in paging.select("a[href]"):
        label = element_text(link)
        href = absolute_url(link.get("href"), page_url)
        page_no = parse_int(label)
        if page_no is not None:
            last_page = max(last_page or page_no, page_no)
        if label == "NEXT >>":
            next_page_url = href
        elif label == "<< PREV":
            previous_page_url = href

    return {
        "page": current_page or parse_page_number(page_url),
        "current_page": current_page or parse_page_number(page_url),
        "last_page": last_page or current_page or parse_page_number(page_url),
        "next_page_url": next_page_url,
        "previous_page_url": previous_page_url,
    }


def parse_search_page(url: str) -> dict:
    soup = get_soup(url)
    query = {key: values[-1] for key, values in parse_qs(urlparse(url).query).items()}
    heading = parse_heading(soup)
    paging = parse_paging(soup, url)
    works = [parse_work(section, url) for section in soup.select("div.section3")]

    return {
        "page_type": "search",
        "site": "hameln",
        "url": url,
        "meta": parse_meta_tags(soup),
        "query": query,
        "heading": heading["heading"],
        "display_query": heading["display_query"],
        "total_count": heading["total_count"] if heading["total_count"] is not None else len(works),
        **paging,
        "search_form": {
            "search_type_options": parse_search_type_options(soup),
            "gensaku_options": parse_gensaku_options(soup),
            "sort_options": parse_sort_options(soup),
        },
        "works": works,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    args = parser.parse_args()
    print_json(parse_search_page(args.url))


if __name__ == "__main__":
    main()
