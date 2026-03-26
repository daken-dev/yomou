import json
import re
import sqlite3
from pathlib import Path
from urllib.parse import urljoin, urlparse

from bs4 import BeautifulSoup
from curl_cffi import requests


BASE_URL = "https://syosetu.org"

client = requests.Session(impersonate="chrome")
cache = sqlite3.connect(Path(__file__).resolve().parent.parent / "datas" / "cache.db")
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
        "keywords": meta.get("keywords"),
        "viewport": meta.get("viewport"),
        "theme-color": meta.get("theme-color"),
    }


def parse_page_number(url: str) -> int:
    match = re.search(r"[?&]page=(\d+)", urlparse(url).query and url or "")
    if not match:
        return 1
    return int(match.group(1))


def parse_int(value: str | None) -> int | None:
    if value is None:
        return None
    digits = re.sub(r"[^\d-]", "", value)
    if not digits:
        return None
    return int(digits)


def print_json(data: dict) -> None:
    print(json.dumps(data, ensure_ascii=False, indent=2))
