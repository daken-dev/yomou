import json
import re
import sqlite3
from pathlib import Path
from urllib.parse import urljoin, urlparse

from bs4 import BeautifulSoup
from curl_cffi import requests


BASE_URL = "https://kakuyomu.jp"

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


def block_text(element) -> str | None:
    if element is None:
        return None

    paragraphs: list[str] = []
    blank_pending = False
    for child in element.find_all(["p", "div"], recursive=False):
        classes = set(child.get("class", []))
        if "blank" in classes:
            blank_pending = True
            continue

        text = child.get_text("", strip=False).replace("\xa0", " ")
        text = text.rstrip()
        if not text.strip():
            blank_pending = True
            continue

        if blank_pending and paragraphs:
            paragraphs.append("")
        paragraphs.append(text)
        blank_pending = False

    if not paragraphs:
        text = element.get_text("\n", strip=False).replace("\xa0", " ")
        lines = [line.rstrip() for line in text.splitlines()]
        while lines and not lines[0].strip():
            lines.pop(0)
        while lines and not lines[-1].strip():
            lines.pop()
        if not lines:
            return None
        return "\n".join(lines)

    return "\n".join(paragraphs)


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


def parse_next_data(soup: BeautifulSoup) -> dict:
    script = soup.find("script", id="__NEXT_DATA__")
    if script is None or script.string is None:
        raise ValueError("Kakuyomu page did not contain __NEXT_DATA__.")
    return json.loads(script.string)


def parse_apollo_state(soup: BeautifulSoup) -> dict:
    next_data = parse_next_data(soup)
    return next_data["props"]["pageProps"]["__APOLLO_STATE__"]


def ref_id(value) -> str | None:
    if isinstance(value, dict):
        return value.get("__ref")
    return None


def resolve_ref(apollo: dict, value):
    key = ref_id(value)
    if key is None:
        return None
    return apollo.get(key)


def extract_work_id(url: str) -> str | None:
    match = re.search(r"/works/([0-9]+)", urlparse(url).path)
    if not match:
        return None
    return match.group(1)


def extract_episode_id(url: str) -> str | None:
    match = re.search(r"/episodes/([0-9]+)", urlparse(url).path)
    if not match:
        return None
    return match.group(1)


def build_work_url(work_id: str) -> str:
    return f"{BASE_URL}/works/{work_id}"


def build_episode_url(work_id: str, episode_id: str) -> str:
    return f"{BASE_URL}/works/{work_id}/episodes/{episode_id}"


def print_json(data: dict) -> None:
    print(json.dumps(data, ensure_ascii=False, indent=2))
