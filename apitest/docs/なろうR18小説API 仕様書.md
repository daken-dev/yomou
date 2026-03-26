# なろうR18小説API 仕様書

なろうR18小説APIでは、ノクターンノベルズ、ムーンライトノベルズおよびミッドナイトノベルズに掲載されている18歳未満閲覧禁止のR18作品情報を取得できます。

> **警告:** 本APIで取得した情報を18歳未満に閲覧させてはいけません。

## 概要

なろうR18小説APIはHTTPリクエストに対し、JSON、JSONP、YAML、またはPHPのserialize形式で応答します。作品データの修正がAPIに反映されるまで、平均5分程度（最大2時間）の誤差があります。

---

## 基本仕様

### 出力形式

- **形式:** JSON, JSONP, YAML, PHP serialize, Atom
- **デフォルト:** YAML
- **文字コード:** UTF-8

### APIのURL

`https://api.syosetu.com/novel18api/api/`

- **メソッド:** GETのみ（POSTは不可）
- **注意:** マルチバイト文字送信時はUTF-8でURLエンコードしてください。

---

## 出力GETパラメータ

| パラメータ | 値           | 説明                                                               |
| :--------- | :----------- | :----------------------------------------------------------------- |
| **gzip**   | int(1～5)    | gzip圧縮して返します。レベル1～5を指定可能。転送量軽減のため推奨。 |
| **out**    | string       | 出力形式を指定（yaml, json, php, atom, jsonp）。                   |
| **of**     | string       | 出力項目を個別に指定。複数指定はハイフン(-)区切り。                |
| **lim**    | int(1～500)  | 最大出力数（デフォルト20件）。                                     |
| **st**     | int(1～2000) | 表示開始位置。                                                     |
| **order**  | string       | 出力順序を指定。                                                   |

### order（出力順序）の値

- `new`: 新着更新順（デフォルト）
- `favnovelcnt`: R18ブックマーク数の多い順
- `reviewcnt`: レビュー数の多い順
- `hyoka`: 総合ポイントの高い順
- `hyokacnt`: 評価者数の多い順
- `lengthdesc`: 作品本文の文字数が多い順
- `dailypoint`: 日間ポイントの高い順
- `weeklypoint`: 週間ポイントの高い順
- `monthlypoint`: 月間ポイントの高い順
- `quarterpoint`: 四半期ポイントの高い順
- `yearlypoint`: 年間ポイントの高い順
- `weekly`: 週間ユニークユーザの多い順（毎週水曜早朝リセット）
- `lengthasc`: 作品本文の文字数が少ない順
- `old`: 更新が古い順

---

## パラメータ詳細

### out（出力形式）

- `yaml`: YAML形式（デフォルト）
- `json`: JSON形式
- `php`: PHPの `serialize()`
- `atom`: Atomフィード
- `jsonp`: JSONP形式（`callback`パラメータが必要）

#### JSONPの利用

- `callback`: コールバック関数名（正規表現 `/^$?[a-zA-Z0-9\[\]\.\_]+$/` に一致する必要あり）
- 例: `?out=jsonp&callback=call`

#### YAMLライブラリの指定（libtype）

| パラメータ  | 値  | 説明                                                                        |
| :---------- | :-- | :-------------------------------------------------------------------------- |
| **libtype** | int | 2以上を指定すると新ライブラリを使用（型指定の厳格化、エスケープ処理あり）。 |

#### Atomフィードの指定（updatetype）

| パラメータ     | 値  | 説明                                                                          |
| :------------- | :-- | :---------------------------------------------------------------------------- |
| **updatetype** | int | 2を指定すると `general_lastup` を日付として出力。未指定は `novelupdated_at`。 |

---

## 条件抽出GETパラメータ

### 検索単語指定

| パラメータ  | 値     | 説明                                |
| :---------- | :----- | :---------------------------------- |
| **word**    | string | 検索単語。スペース区切りでAND検索。 |
| **notword** | string | 除外単語。                          |

### 抽出対象の範囲（word/notwordの対象）

指定しない場合は全項目が対象となります。

- `title=1`: タイトル
- `ex=1`: あらすじ
- `keyword=1`: キーワード
- `wname=1`: 作者名

### 掲載サイト指定（nocgenre / notnocgenre）

ハイフン(-)区切りで複数指定可能。

- `1`: ノクターンノベルズ(男性向け)
- `2`: ムーンライトノベルズ(女性向け)
- `3`: ムーンライトノベルズ(BL)
- `4`: ミッドナイトノベルズ(大人向け)

### 属性指定

- **XID:** `xid`（ハイフン区切りでOR検索可能）
- **Nコード:** `ncode`（ハイフン区切りでOR検索可能）
- **作品ピックアップ:** `ispickup=1` で対象作品のみ抽出
  - 注: R18のピックアップは「最終掲載日から60日以内」かつ「短編・完結済・10万字以上の連載」が対象。

### 作品タイプ・要素

| パラメータ    | 説明 (1を指定で抽出) | 除外用パラメータ |
| :------------ | :------------------- | :--------------- |
| **isbl**      | ボーイズラブ         | **notbl**        |
| **isgl**      | ガールズラブ         | **notgl**        |
| **iszankoku** | 残酷な描写あり       | **notzankoku**   |
| **istensei**  | 異世界転生           | **nottensei**    |
| **istenni**   | 異世界転移           | **nottenni**     |
| **istt**      | 転生または転移       | -                |

#### 作品タイプ（type）

- `t`: 短編
- `r`: 連載中
- `er`: 完結済連載作品
- `re`: すべての連載作品
- `ter`: 短編と完結済連載作品

### 文字数・読了時間・会話率

- **文字数:** `minlen`, `maxlen`, `length`（範囲指定は `min-max`）
- **会話率(%):** `kaiwaritu`（範囲指定可能）
- **挿絵数:** `sasie`（範囲指定可能）
- **読了時間(分):** `mintime`, `maxtime`, `time`（文字数指定と併用不可）

### 文体・連載状態

- **文体（buntai）:** `1`, `2`, `4`, `6`（ハイフン区切りでOR検索可能）
- **連載停止（stop）:** `1`（長期連載停止中を除く）, `2`（長期連載停止中のみ）

### 日付指定

`lastup`（最終掲載日）または `lastupdate`（最終更新日）に以下の値を指定可能。

- `thisweek`, `lastweek`, `sevenday`, `thismonth`, `lastmonth`
- **UNIXタイムスタンプ:** `開始-終了` で範囲指定。

---

## 出力要素一覧

最初の要素には `allcount`（全作品数）が含まれます。

| 要素名                                                           | 説明                             |
| :--------------------------------------------------------------- | :------------------------------- |
| **allcount**                                                     | 全作品出力数                     |
| **title**                                                        | 作品名                           |
| **ncode**                                                        | Nコード                          |
| **writer**                                                       | 作者名                           |
| **story**                                                        | あらすじ                         |
| **nocgenre**                                                     | 掲載サイト（数値: 1-4）          |
| **keyword**                                                      | キーワード                       |
| **general_firstup**                                              | 初回掲載日 (YYYY-MM-DD HH:MM:SS) |
| **general_lastup**                                               | 最終掲載日 (YYYY-MM-DD HH:MM:SS) |
| **novel_type**                                                   | 連載: 1, 短編: 2                 |
| **end**                                                          | 完結済・短編: 0, 連載中: 1       |
| **general_all_no**                                               | 全掲載エピソード数               |
| **length**                                                       | 作品文字数                       |
| **time**                                                         | 読了時間（分）                   |
| **isstop**                                                       | 長期連載停止中: 1, その他: 0     |
| **isbl** / **isgl** / **iszankoku** / **istensei** / **istenni** | 各要素の有無（有: 1, 無: 0）     |
| **global_point**                                                 | 総合評価ポイント                 |
| **daily_point**                                                  | 日間ポイント                     |
| **weekly_point**                                                 | 週間ポイント                     |
| **monthly_point**                                                | 月間ポイント                     |
| **quarter_point**                                                | 四半期ポイント                   |
| **yearly_point**                                                 | 年間ポイント                     |
| **fav_novel_cnt**                                                | R18ブックマーク数                |
| **impression_cnt**                                               | 感想数                           |
| **review_cnt**                                                   | レビュー数                       |
| **all_point**                                                    | 評価ポイント                     |
| **all_hyoka_cnt**                                                | 評価者数                         |
| **sasie_cnt**                                                    | 挿絵の数                         |
| **kaiwaritu**                                                    | 会話率                           |
| **novelupdated_at**                                              | 作品の更新日時                   |
| **updated_at**                                                   | システム用データ更新日時         |

---

## ofパラメータ（出力項目の絞り込み）

`of` パラメータで使用する略称一覧です。

| 略称    | 項目名                                 | 略称    | 項目名         |
| :------ | :------------------------------------- | :------ | :------------- |
| **t**   | title                                  | **n**   | ncode          |
| **w**   | writer                                 | **s**   | story          |
| **ng**  | nocgenre                               | **k**   | keyword        |
| **gf**  | general_firstup                        | **gl**  | general_lastup |
| **nt**  | noveltype (注: 出力キーは `noveltype`) | **e**   | end            |
| **ga**  | general_all_no                         | **l**   | length         |
| **ti**  | time                                   | **i**   | isstop         |
| **ibl** | isbl                                   | **igl** | isgl           |
| **izk** | iszankoku                              | **its** | istensei       |
| **iti** | istenni                                | **gp**  | global_point   |
| **dp**  | daily_point                            | **wp**  | weekly_point   |
| **mp**  | monthly_point                          | **qp**  | quarter_point  |
| **yp**  | yearly_point                           | **f**   | fav_novel_cnt  |
| **imp** | impression_cnt                         | **r**   | review_cnt     |
| **a**   | all_point                              | **ah**  | all_hyoka_cnt  |
| **sa**  | sasie_cnt                              | **ka**  | kaiwaritu      |
| **nu**  | novelupdated_at                        | **ua**  | updated_at     |

---

## オプション・制限事項

### オプション項目（opt）

- `opt=weekly`: 週間ユニークユーザ（`weekly_unique`）を追加。

### 利用制限（現在休止中）

- 1日 80,000リクエスト または 転送量 400MB まで。
- 制限を超えると接続不可となる確率が上がります。
- キャッシュの利用（最長2週間）が推奨されます。

### 遅延について

- マスタ・スレーブ間の同期: 10秒以内。
- APIへの反映: 平均5分（最大2時間）。
- 統計項目（ポイント、ブックマーク数等）: さらに15分〜2時間の遅れ。

### Atomフィードの制限

`out=atom` 指定時は、タイトル、URL、あらすじ、最終掲載日、作者名（コメント内）のみが出力されます。
