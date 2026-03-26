import argparse

from .parser_common import absolute_url, block_text, element_text, get_soup, parse_meta_tags, print_json


def parse_info_page(url: str) -> dict:
    soup = get_soup(url)
    data: dict[str, str] = {}
    info = soup.select_one(".p-infotop-data")
    if info:
        for title, value in zip(info.find_all("dt"), info.find_all("dd"), strict=False):
            data[element_text(title) or ""] = block_text(value) or ""

    author_link = None
    if info:
        author_dt = info.find("dt", string=lambda x: x and "作者名" in x)
        if author_dt:
            author_dd = author_dt.find_next_sibling("dd")
            if author_dd:
                author_link = author_dd.find("a")

    kasasagi_link = soup.select_one(".p-infotop-kasasagi__analytics a")
    work_link = soup.select_one(".p-infotop-towork__button")
    qr_image = soup.select_one(".p-infotop-towork__qr img")

    return {
        "page_type": "info",
        "url": url,
        "meta": parse_meta_tags(soup),
        "title": element_text(soup.select_one(".p-infotop__title, h1")),
        "author_url": absolute_url(author_link.get("href")) if author_link else None,
        "fields": data,
        "kasasagi_url": absolute_url(kasasagi_link.get("href")) if kasasagi_link else None,
        "work_url": absolute_url(work_link.get("href")) if work_link else None,
        "qrcode_url": qr_image.get("src") if qr_image else None,
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    args = parser.parse_args()
    print_json(parse_info_page(args.url))


if __name__ == "__main__":
    main()