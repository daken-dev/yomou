import json
import re
import sqlite3
from pathlib import Path
from urllib.parse import parse_qs, urljoin, urlparse

from bs4 import BeautifulSoup
from curl_cffi import requests


BASE_URL = "https://ncode.syosetu.com"

client = requests.Session(impersonate="chrome")
cache = sqlite3.connect(Path(__file__).parent / "datas" / "cache.db")
cache.execute(
    """
    CREATE TABLE IF NOT EXISTS cache (
        url TEXT PRIMARY KEY,
        content BLOB NOT NULL
    )
    """
)


def get(url: str) -> bytes:
    cached = cache.execute("SELECT content FROM cache WHERE url = ?", (url,)).fetchone()
    if cached:
        return cached[0]

    response = client.get(url)
    response.raise_for_status()
    content = response.content
    cache.execute(
        "INSERT OR REPLACE INTO cache (url, content) VALUES (?, ?)",
        (url, content),
    )
    cache.commit()
    return content


def get_soup(url: str) -> BeautifulSoup:
    return BeautifulSoup(get(url), "html.parser")


def clean_text(value: str | None) -> str | None:
    if value is None:
        return None
    text = re.sub(r"\s+", " ", value.replace("\xa0", " ")).strip()
    return text or None


def element_text(element) -> str | None:
    if element is None:
        return None
    return clean_text(element.get_text(" ", strip=True))


def block_text(element) -> str | None:
    if element is None:
        return None

    text = element.get_text("\n", strip=False).replace("\xa0", " ")
    lines = [line.rstrip() for line in text.splitlines()]
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()

    normalized: list[str] = []
    blank_pending = False
    for line in lines:
        stripped = line.strip()
        if stripped:
            if blank_pending and normalized:
                normalized.append("")
            normalized.append(stripped)
            blank_pending = False
        else:
            blank_pending = True

    if not normalized:
        return None
    return "\n".join(normalized)


def absolute_url(url: str | None, base_url: str = BASE_URL) -> str | None:
    if not url:
        return None
    return urljoin(base_url, url)


def parse_meta_tags(soup: BeautifulSoup) -> dict:
    meta: dict[str, str] = {}
    for tag in soup.find_all("meta"):
        key = tag.get("property") or tag.get("name")
        value = tag.get("content")
        if key and value:
            meta[key] = value

    return {
        "title_tag": clean_text(soup.title.string if soup.title else None),
        "description": meta.get("description"),
        "og:type": meta.get("og:type"),
        "og:title": meta.get("og:title"),
        "og:url": meta.get("og:url"),
        "og:description": meta.get("og:description"),
        "og:image": meta.get("og:image"),
        "og:site_name": meta.get("og:site_name"),
        "twitter:site": meta.get("twitter:site"),
        "twitter:card": meta.get("twitter:card"),
        "twitter:creator": meta.get("twitter:creator"),
        "WWWC": meta.get("WWWC"),
        "viewport": meta.get("viewport"),
    }


def parse_page_number(url: str) -> int:
    query = parse_qs(urlparse(url).query)
    return int(query.get("p", ["1"])[0])


def parse_last_page_number(soup: BeautifulSoup, current_url: str) -> int:
    pager_last = soup.select_one(".c-pager__item--last")
    if pager_last and pager_last.get("href"):
        return parse_page_number(absolute_url(pager_last.get("href"), current_url) or current_url)
    return parse_page_number(current_url)


def print_json(data: dict) -> None:
    print(json.dumps(data, ensure_ascii=False, indent=2))
