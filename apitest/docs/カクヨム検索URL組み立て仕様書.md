# カクヨム検索URL組み立て仕様書

本ドキュメントは、Web小説サイト「カクヨム」の検索機能（`https://kakuyomu.jp/search`）におけるURLパラメータの構造と、関連リソースのURL形式についてまとめたものです。スクレイピングや自動化処理におけるURLの動的生成に利用することを目的としています。

## 1. 検索ベースURL

カクヨムの検索機能の基本となるエンドポイントは以下の通りです。

> `https://kakuyomu.jp/search`

すべての検索条件はこのベースURLに対してクエリパラメータを付与することで構成されます。

## 2. 主要クエリパラメータ一覧

検索ページで使用される主要なパラメータを以下の表にまとめます。

| パラメータ名                  | 説明            | 指定形式・例                                                   |
| :---------------------------- | :-------------- | :------------------------------------------------------------- |
| `q`                           | 検索キーワード  | URLエンコードされた文字列（例: `%E7%95%B0%E4%B8%96%E7%95%8C`） |
| `ex_q`                        | 除外キーワード  | 検索結果から除外したい単語。複数指定はカンマ区切り             |
| `order`                       | 並び順          | 後述の「並び順オプション」を参照                               |
| `genre_name`                  | ジャンル        | 後述の「ジャンルID」を参照。複数指定はカンマ区切り             |
| `serial_status`               | 連載状態        | `ongoing`（連載中）、`completed`（完結済）                     |
| `total_review_point_range`    | ★の数（評価点） | `最小値-最大値` の形式（例: `100-` は100以上）                 |
| `total_character_count_range` | 文字数          | `最小値-最大値` の形式（例: `100000-` は10万字以上）           |
| `page`                        | ページ番号      | 1から始まる整数値                                              |

## 3. 詳細なパラメータ仕様

### 3.1 並び順（order）

検索結果の表示順序を指定します。デフォルトは `weekly_ranking` です。

| 値                          | 説明                   |
| :-------------------------- | :--------------------- |
| `weekly_ranking`            | 週間ランキング順       |
| `total_ranking`             | 累計ランキング順       |
| `last_episode_published_at` | 最新エピソードの更新順 |
| `published_at`              | 作品の公開順           |
| `stars_count`               | ★の数順                |
| `review_count`              | レビュー数順           |

### 3.2 ジャンル（genre_name）

ジャンルを指定するための内部IDです。複数のジャンルを対象にする場合は、`sf,horror` のようにカンマで繋ぎます。

| ジャンル名                 | ID (`genre_name`)           |
| :------------------------- | :-------------------------- |
| 異世界ファンタジー         | `fantasy`                   |
| 現代ファンタジー           | `contemporary_fantasy`      |
| SF                         | `sf`                        |
| 恋愛                       | `romance`                   |
| ラブコメ                   | `love_comedy`               |
| 現代ドラマ                 | `contemporary_drama`        |
| ホラー                     | `horror`                    |
| ミステリー                 | `mystery`                   |
| エッセイ・ノンフィクション | `essay_nonfiction`          |
| 歴史・時代・伝奇           | `history_period_legend`     |
| 創作論・評論               | `creation_theory_criticism` |
| 詩・童話・その他           | `poetry_fairy_tale_others`  |
| 魔法のiらんど              | `maho_no_iland`             |
| 二次創作                   | `derivative_work`           |

## 4. 関連リソースのURL形式

検索結果から得られる各リソース（作品、エピソード、ユーザー）へのアクセスURLは以下の規則に従います。

| リソース種別             | URLパターン                                                 |
| :----------------------- | :---------------------------------------------------------- |
| **作品詳細ページ**       | `https://kakuyomu.jp/works/{work_id}`                       |
| **エピソードページ**     | `https://kakuyomu.jp/works/{work_id}/episodes/{episode_id}` |
| **ユーザープロフィール** | `https://kakuyomu.jp/users/{user_id}`                       |

> ※ `{work_id}` および `{episode_id}` は通常20桁程度の数値、`{user_id}` は英数字の文字列（スクリーンネーム）です。

## 5. URL組み立て例

**例：キーワード「異世界」を含み、ジャンルが「SF」または「ホラー」で、かつ「完結済」の作品を「★の数順」で検索する（2ページ目）**

```text
https://kakuyomu.jp/search?q=%E7%95%B0%E4%B8%96%E7%95%8C&genre_name=sf,horror&serial_status=completed&order=stars_count&page=2
```
