import argparse

from narou import parse_episode_page, parse_info_page, parse_toc_page
from narou.parser_common import print_json


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("site", nargs="?", default="narou", choices=["narou"])
    parser.add_argument("page_type", choices=["info", "toc", "episode"])
    parser.add_argument("url")
    args = parser.parse_args()

    if args.page_type == "info":
        data = parse_info_page(args.url)
    elif args.page_type == "toc":
        data = parse_toc_page(args.url)
    else:
        data = parse_episode_page(args.url)

    print_json(data)


if __name__ == "__main__":
    main()
