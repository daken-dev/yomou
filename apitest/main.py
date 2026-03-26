import argparse

from hameln import parse_search_page as parse_hameln_search_page
from kakuyomu import (
    parse_episode_page as parse_kakuyomu_episode_page,
    parse_search_page as parse_kakuyomu_search_page,
    parse_toc_page as parse_kakuyomu_toc_page,
)
from narou import parse_episode_page, parse_info_page, parse_toc_page
from narou.parser_common import print_json
from novelup import (
    parse_episode_page as parse_novelup_episode_page,
    parse_ranking_page as parse_novelup_ranking_page,
    parse_search_page as parse_novelup_search_page,
    parse_toc_page as parse_novelup_toc_page,
)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "site",
        nargs="?",
        default="narou",
        choices=["narou", "kakuyomu", "hameln", "novelup"],
    )
    parser.add_argument("page_type", choices=["info", "search", "toc", "episode", "ranking"])
    parser.add_argument("url")
    args = parser.parse_args()

    if args.site == "narou":
        if args.page_type == "info":
            data = parse_info_page(args.url)
        elif args.page_type == "toc":
            data = parse_toc_page(args.url)
        elif args.page_type == "episode":
            data = parse_episode_page(args.url)
        else:
            raise ValueError("Narou parser does not support search page parsing.")
    elif args.site == "kakuyomu":
        if args.page_type == "search":
            data = parse_kakuyomu_search_page(args.url)
        elif args.page_type == "toc":
            data = parse_kakuyomu_toc_page(args.url)
        elif args.page_type == "episode":
            data = parse_kakuyomu_episode_page(args.url)
        else:
            raise ValueError("Kakuyomu parser does not support info page parsing.")
    else:
        if args.site == "hameln":
            if args.page_type == "search":
                data = parse_hameln_search_page(args.url)
            else:
                raise ValueError("Hameln parser currently supports only search page parsing.")
        else:
            if args.page_type == "search":
                data = parse_novelup_search_page(args.url)
            elif args.page_type == "toc":
                data = parse_novelup_toc_page(args.url)
            elif args.page_type == "episode":
                data = parse_novelup_episode_page(args.url)
            elif args.page_type == "ranking":
                data = parse_novelup_ranking_page(args.url)
            else:
                raise ValueError("NovelUp parser does not support info page parsing.")

    print_json(data)


if __name__ == "__main__":
    main()
