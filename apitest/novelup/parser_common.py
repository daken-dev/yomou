import json
import re
import sqlite3
from pathlib import Path
from urllib.parse import parse_qs, urljoin, urlparse

from bs4 import BeautifulSoup
from curl_cffi import requests


BASE_URL = "https://novelup.plus"

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


def clean_block_text(value: str | None) -> str | None:
    if value is None:
        return None
    value = value.replace("\r\n", "\n").replace("\r", "\n").replace("\xa0", " ")
    lines = [line.rstrip() for line in value.splitlines()]

    normalized: list[str] = []
    blank_pending = False
    for line in lines:
        if line.strip():
            if blank_pending and normalized:
                normalized.append("")
            normalized.append(line)
            blank_pending = False
        else:
            blank_pending = True

    return "\n".join(normalized) or None


def element_text(element) -> str | None:
    if element is None:
        return None
    return clean_text(element.get_text(" ", strip=True))


def absolute_url(url: str | None, base_url: str = BASE_URL) -> str | None:
    if not url:
        return None
    return urljoin(base_url, url)


def parse_int(value: str | None) -> int | None:
    if value is None:
        return None
    digits = re.sub(r"[^\d-]", "", value)
    if not digits:
        return None
    return int(digits)


def parse_scaled_number(value: str | None) -> int | None:
    if value is None:
        return None
    text = value.replace(",", "").strip().upper()
    match = re.fullmatch(r"(\d+(?:\.\d+)?)([KM]?)", text)
    if not match:
        return parse_int(text)

    number = float(match.group(1))
    suffix = match.group(2)
    if suffix == "K":
        number *= 1_000
    elif suffix == "M":
        number *= 1_000_000
    return int(number)


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
        "robots": meta.get("robots"),
        "og:type": meta.get("og:type"),
        "og:title": meta.get("og:title"),
        "og:url": meta.get("og:url"),
        "og:description": meta.get("og:description"),
        "og:image": meta.get("og:image"),
        "og:site_name": meta.get("og:site_name"),
        "twitter:site": meta.get("twitter:site"),
        "twitter:card": meta.get("twitter:card"),
        "viewport": meta.get("viewport"),
    }


def parse_page_number(url: str, param: str = "p") -> int:
    query = parse_qs(urlparse(url).query)
    try:
        return int(query.get(param, ["1"])[-1])
    except ValueError:
        return 1


def extract_story_id(url: str | None) -> str | None:
    if not url:
        return None
    match = re.search(r"/story/(\d+)", urlparse(url).path)
    return match.group(1) if match else None


def extract_episode_id(url: str | None) -> str | None:
    if not url:
        return None
    match = re.search(r"/story/\d+/(\d+)", urlparse(url).path)
    return match.group(1) if match else None


def extract_user_id(url: str | None) -> str | None:
    if not url:
        return None
    match = re.search(r"/user/(\d+)/profile", urlparse(url).path)
    return match.group(1) if match else None


def build_story_url(story_id: str) -> str:
    return f"{BASE_URL}/story/{story_id}"


def build_episode_url(story_id: str, episode_id: str) -> str:
    return f"{BASE_URL}/story/{story_id}/{episode_id}"


def parse_json_ld(soup: BeautifulSoup) -> list[dict]:
    items: list[dict] = []
    for script in soup.select('script[type="application/ld+json"]'):
        text = script.string or script.get_text()
        if not text.strip():
            continue
        data = json.loads(text)
        if isinstance(data, dict) and isinstance(data.get("@graph"), list):
            items.extend(item for item in data["@graph"] if isinstance(item, dict))
        elif isinstance(data, list):
            items.extend(item for item in data if isinstance(item, dict))
        elif isinstance(data, dict):
            items.append(data)
    return items


def find_json_ld_item(items: list[dict], type_name: str) -> dict | None:
    for item in items:
        item_type = item.get("@type")
        if item_type == type_name:
            return item
        if isinstance(item_type, list) and type_name in item_type:
            return item
    return None


def print_json(data: dict) -> None:
    print(json.dumps(data, ensure_ascii=False, indent=2))
