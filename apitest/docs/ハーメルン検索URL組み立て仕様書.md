# ハーメルン検索URL組み立て仕様書

本ドキュメントは、ハーメルンの検索ページ `https://syosetu.org/search/?mode=search` で実際に観測できたクエリ構造をメモしたものです。

## ベースURL

`https://syosetu.org/search/?mode=search`

## 主なクエリ

| パラメータ | 例 | 意味 |
| --- | --- | --- |
| `mode` | `search` | 通常検索 |
| `word` | `テスト` | 検索テキスト |
| `search_type` | `0` | 検索範囲。`0=小説`, `1=各話本文`, `2=小説・各話本文` |
| `gensaku` | `原作：オリジナル` | 原作。検索フォームの `select[name="gensaku"]` から動的取得可能 |
| `type` | `0` | 並び順 |
| `page` | `2` | ページ番号 |

## 並び順 `type`

ハーメルンでは新着・期間別ランキングも通常検索の `type` で切り替えられます。

| 値 | 意味 |
| --- | --- |
| `0` | 最終更新日時(新しい順) = 新着 |
| `28` | 総合評価 |
| `29` | 日間総合評価 |
| `30` | 週間総合評価 |
| `31` | 月間総合評価 |
| `32` | 四半期総合評価 |
| `33` | 年間総合評価 |

## 代表URL例

### 新着 + テキスト + 原作

```text
https://syosetu.org/search/?mode=search&word=テスト&gensaku=原作：オリジナル&search_type=0&type=0
```

### 各話本文検索 + 原作 + 日間

```text
https://syosetu.org/search/?mode=search&word=剣&gensaku=原作：Fate/&search_type=1&type=29
```

### 小説・各話本文 + 原作 + 年間

```text
https://syosetu.org/search/?mode=search&word=転生&gensaku=原作：オリジナル&search_type=2&type=33
```

## 実装メモ

- 原作一覧はフォーム HTML の `select[name="gensaku"]` に埋め込まれているため、静的定義せず毎回取得できる。
- 一覧カードから作品 URL、タイトル、作者、原作/舞台/ジャンル、話数、総文字数、最終更新、あらすじ、タグ、UA/お気に入り/感想などを抽出できる。
- 詳細ポップアップ内に `PDF`、`感想ページ`、`アクセス解析` などのリンクも含まれる。
