## なろうR18小説API

なろうR18小説APIではノクターンノベルズ、ムーンライトノベルズおよびミッドナイトノベルズに掲載されている18歳未満閲覧禁止のR18作品情報を取得できます。

このページで取り扱う情報には、18歳未満が取り扱うのにふさわしくない情報が含まれています。  
本APIで取得した情報を18歳未満に閲覧させてはいけません。

なろうR18小説APIはHTTPでのリクエストに対してJSON形式、JSONP形式、YAML形式またはPHPのserializeで応答します。  
実際に作品のデータが修正されてからなろうAPIに反映されるまで平均5分程度(最大2時間)の誤差があります。

APIを使うためにはJavaScriptあるいはPerl/PHP/Ruby/Java/C言語などでプログラミングが必要です。

### 出力形式

JSON形式、JSONP形式またはYAML形式、PHPのserialize  
標準はYAML形式となっていますが、outパラメータで変更できます。  
文字コードはUTF-8です。

### APIのURL

https://api.syosetu.com/novel18api/api/

GETで送信。POSTでは受信できません。  
日本語などマルチバイト文字送信時は文字コードをUTF-8にし、URLエンコードしてください。

### 出力GETパラメータ

パラメータ

値

説明

gzip

int(1～5)

gzip圧縮してgzipファイルとして返します。  
gzip圧縮レベルを1～5で指定できます。  
転送量上限を減らすためにも推奨

out

string

出力形式をyamlまたはjsonまたはphpを指定。  
未指定時はYAMLになる。[outパラメータの詳細](#out-detail)

of

string

出力する項目を個別に指定できます。未指定時は全項目出力されます。  
転送量軽減のため、このパラメータの使用が推奨されます。  
複数項目を出力する場合は-で区切ってください。詳しくは[出力](#output)の項目をご覧ください。

lim

int(1～500)

最大出力数を指定できます。最低1、最高500です。  
半角数字で指定してください。  
指定しない場合は20件になります。

st

int(1～2000)

表示開始位置の指定です。半角数字で指定してください。  
たとえば全部で10作品あるとして、3作品目以降の作品情報を取得したい場合は3と指定してください。

order

string

出力順序を指定できます。  
指定しない場合は新着更新順となります。

- new

  新着更新順

- favnovelcnt

  R18ブックマーク数の多い順

- reviewcnt

  レビュー数の多い順

- hyoka

  総合ポイントの高い順

- hyokacnt

  評価者数の多い順

- lengthdesc

  作品本文の文字数が多い順

- dailypoint

  日間ポイントの高い順

- weeklypoint

  週間ポイントの高い順

- monthlypoint

  月間ポイントの高い順

- quarterpoint

  四半期ポイントの高い順

- yearlypoint

  年間ポイントの高い順

- weekly

  週間ユニークユーザの多い順  
  毎週水曜日早朝リセット  
  (前週の日曜日から土曜日分)

- lengthasc

  作品本文の文字数が少ない順

- old

  更新が古い順

### outパラメータの詳細

出力形式を指定できます。  
jsonまたはyamlまたはphpで指定してください。

- yaml

  YAML形式(デフォルト)

- json

  JSON形式

- php

  PHPのserialize()

- atom

  Atomフィード

- jsonp

  JSONP形式

#### JSONPの使い方

JSONPを利用することでJavaScriptから直接、APIを利用できるようになります。

- callback

  コールバック関数名。コールバック関数名には半角英数字など/^$?\[a-zA-Z0-9\\\[\\\]\\.\\\_\]+$/ (perl) の正規表現に一致する関数名を指定してください。

https://api.syosetu.com/novel18api/api/?out=jsonp&callback=call

JSONP形式でコールバック関数名をcallにしたい場合のURLです。

#### YAML形式の出力に関する動作について

出力形式にYAMLを指定した場合、パラメータを指定する事で利用するライブラリを変更できます。

パラメータ

値

説明

libtype

int

利用するライブラリを指定できます。  
未指定もしくは1以下の値を指定した場合、従来通りのライブラリを利用します。  
2以上の値を指定すると、新ライブラリを利用します。  
新ライブラリでは以下の点が従来のライブラリと異なります。

- 文字列と数値の型指定が厳格化します。
- マルチバイト文字や一部の制御文字がエスケープ処理されます。

https://api.syosetu.com/novel18api/api/?libtype=1

従来通りのライブラリで出力を行ないます。  
作品名や作者名等、文字列が格納されるエピソードが数値で構成されている場合でも、数値はダブルクォートで囲まれません。

https://api.syosetu.com/novel18api/api/?libtype=2

新ライブラリで出力を行ないます。  
作品名や作者名等、文字列が格納されるエピソードが数値で構成されている場合、数値がダブルクォートで囲まれます。

#### Atomフィード形式の出力に関する動作について

Atomフィードの出力内容をパラメータを指定することで変更できます。

パラメータ

値

説明

updatetype

int

日付として出力する項目を指定できます。  
2の値を指定すると、最終掲載日general_lastupを日付として出力します。  
未指定の場合、作品の更新日時novelupdated_atを日付として出力します。

https://api.syosetu.com/novel18api/api/?out=atom

作品の更新日時novelupdated_atを日付として出力します。

https://api.syosetu.com/novel18api/api/?out=atom&updatetype=2

最終掲載日general_lastupを日付として出力します。

### 条件抽出GETパラメータ

#### 検索単語指定

パラメータ

値

説明

word

string

単語を指定できます。文字コードはUTF-8でURLエンコードしてください。  
半角または全角スペースで区切るとAND抽出になります。部分一致でHITします。

notword

string

含みたくない単語を指定できます。文字コードはUTF-8でURLエンコードしてください。  
スペースで区切ることにより含ませない単語を増やせます。部分一致で除外されます。

#### 抽出対象の範囲

パラメータ

値

説明

title

int

1の場合はタイトルをwordとnotwordの抽出対象にします。

ex

int

1の場合はあらすじをwordとnotwordの抽出対象にします。

keyword

int

1の場合はキーワードをwordとnotwordの抽出対象にします。

wname

int

1の場合は作者名をwordとnotwordの抽出対象にします。

上記4項目すべて指定しない場合は全項目抽出対象と扱います。  
wordがNコードと判断される文字列の場合、抽出対象はすべて無視され、Nコードから作品を探します。

#### 掲載サイト指定

パラメータ

値

説明

nocgenre

int  
string

掲載サイトを指定できます。ハイフン(-)記号で区切れば複数の掲載サイトを一括抽出できます。

- 1

  ノクターンノベルズ(男性向け)

- 2

  ムーンライトノベルズ(女性向け)

- 3

  ムーンライトノベルズ(BL)

- 4

  ミッドナイトノベルズ(大人向け)

https://api.syosetu.com/novel18api/api/?nocgenre=1

掲載サイトがノクターンノベルズ(男性向け)となっている作品の作品情報を取得するURLです。

https://api.syosetu.com/novel18api/api/?nocgenre=1-3

掲載サイトがノクターンノベルズ(男性向け)またはムーンライトノベルズ(BL)となっている作品の作品情報を取得するURLです。

#### 掲載サイト除外指定

パラメータ

値

説明

notnocgenre

int  
string

掲載サイトを除外検索できます。ハイフン(-)記号で区切れば含ませたくない掲載サイトを増やせます。

- 1

  ノクターンノベルズ(男性向け)

- 2

  ムーンライトノベルズ(女性向け)

- 3

  ムーンライトノベルズ(BL)

- 4

  ミッドナイトノベルズ(大人向け)

https://api.syosetu.com/novel18api/api/?notnocgenre=1

掲載サイトがノクターンノベルズ(男性向け)となっている作品以外の作品情報を取得するURLです。

https://api.syosetu.com/novel18api/api/?notnocgenre=2-3

掲載サイトがムーンライトノベルズ(女性向け、BL)となっている作品以外の作品情報を取得するURLです。

#### XID指定

パラメータ

値

説明

xid

int  
string

XIDで抽出可能。ハイフン(-)記号で区切ればXIDのOR検索ができます。

#### 作品に含まれる要素指定

パラメータ

値

説明

isbl

int

1を指定した場合、作品に含まれる要素に「ボーイズラブ」が含まれている作品のみを抽出します。

isgl

int

1を指定した場合、作品に含まれる要素に「ガールズラブ」が含まれている作品のみを抽出します。

iszankoku

int

1を指定した場合、作品に含まれる要素に「残酷な描写あり」が含まれている作品のみを抽出します。

istensei

int

1を指定した場合、作品に含まれる要素に「異世界転生」が含まれている作品のみを抽出します。

istenni

int

1を指定した場合、作品に含まれる要素に「異世界転移」が含まれている作品のみを抽出します。

istt

int

1を指定した場合、作品に含まれる要素に「異世界転生」または「異世界転移」が含まれている作品のみを抽出します。

#### 作品に含まれる要素除外指定

パラメータ

値

説明

notbl

int

1を指定した場合、作品に含まれる要素に「ボーイズラブ」が含まれている作品を除外し抽出します。

notgl

int

1を指定した場合、作品に含まれる要素に「ガールズラブ」が含まれている作品を除外し抽出します。

notzankoku

int

1を指定した場合、作品に含まれる要素に「残酷な描写あり」が含まれている作品を除外し抽出します。

nottensei

int

1を指定した場合、作品に含まれる要素に「異世界転生」が含まれている作品を除外し抽出します。

nottenni

int

1を指定した場合、作品に含まれる要素に「異世界転移」が含まれている作品を除外し抽出します。

#### 文字数指定

パラメータ

値

説明

minlen

int

抽出する作品の最小文字数を指定できます。  
文字数とは作品から一部タグ記号(改ページ等)、ルビ、ルビのふりがな部分、みてみんの画像挿入コード、スペース、改行を抜いた値です。

maxlen

int

抽出する作品の最大文字数。文字数とは作品から一部タグ記号(改ページ等)、ルビ、ルビのふりがな部分、みてみんの画像挿入コード、スペース、改行を抜いた値です。

length

int  
string

抽出する作品の文字数を指定できます。minlenまたはmaxlenと併用はできません。  
文字数とは作品から一部タグ記号(改ページ等)、ルビ、ルビのふりがな部分、みてみんの画像挿入コード、スペース、改行を抜いた値です。  
範囲指定する場合は、最小文字数と最大文字数をハイフン(-)記号で区切ってください。

https://api.syosetu.com/novel18api/api/?length=10000

文字数が1万文字ちょうどの作品の作品情報を取得するURLです。

https://api.syosetu.com/novel18api/api/?length=2000-3000

文字数が2000文字から3000文字の作品の作品情報を取得するURLです。

https://api.syosetu.com/novel18api/api/?length=10000-

文字数が10000文字以上の作品の作品情報を取得するURLです。

https://api.syosetu.com/novel18api/api/?length=-15000

文字数が15000文字以下の作品の作品情報を取得するURLです。

#### 会話率指定

パラメータ

値

説明

kaiwaritu

int  
string

抽出する作品の[会話率](/man/kaiwa/)を%単位で指定できます。  
範囲指定する場合は、最低数と最大数をハイフン(-)記号で区切ってください。

https://api.syosetu.com/novel18api/api/?kaiwaritu=10-50

会話率が10%～50%までの作品を抽出します。

https://api.syosetu.com/novel18api/api/?kaiwaritu=0-50

会話率が0%～50%までの作品つまり50%以下の作品を抽出します。

https://api.syosetu.com/novel18api/api/?kaiwaritu=50-

会話率が50%以上の作品を抽出します。

https://api.syosetu.com/novel18api/api/?kaiwaritu=30

会話率が30%ちょうどの作品を抽出します。

#### 挿絵数指定

パラメータ

値

説明

sasie

int  
string

抽出する作品の挿絵の数を指定できます。  
範囲指定する場合は、最小数と最大数を-(ハイフン)記号で区切ってください。

https://api.syosetu.com/novel18api/api/?sasie=1-

挿絵が1以上存在する作品を抽出します。

https://api.syosetu.com/novel18api/api/?sasie=1-5

挿絵が1つから5つまでの作品を抽出します。

https://api.syosetu.com/novel18api/api/?sasie=3

挿絵が3つの作品を抽出します。

#### 読了時間指定

読了時間は文字数(minlen、maxlen、length)と併用はできません。

パラメータ

値

説明

mintime

int

抽出する作品の最低読了時間を分単位で指定できます。  
読了時間は作品文字数÷500を切り上げした数字です。

maxtime

int

抽出する作品の最大読了時間を分単位で指定できます。  
読了時間は作品文字数÷500を切り上げした数字です。

time

int  
string

抽出する作品の読了時間を指定できます。mintimeまたはmaxtimeと併用はできません。  
読了時間は作品文字数÷500を切り上げした数字です。  
範囲指定する場合は、最小文字数と最大文字数をハイフン(-)記号で区切ってください。

https://api.syosetu.com/novel18api/api/?time=10

読了時間が10分ちょうどの作品の作品情報を取得するURLです。

https://api.syosetu.com/novel18api/api/?time=30-100

読了時間が30分～100分の作品の作品情報を取得するURLです。

https://api.syosetu.com/novel18api/api/?time=10-

読了時間が10分以上の作品の作品情報を取得するURLです。

https://api.syosetu.com/novel18api/api/?time=-10

読了時間が10分以内の作品の作品情報を取得するURLです。

#### Nコード指定

パラメータ

値

説明

ncode

string

Nコードで抽出可能。ハイフン(-)記号で区切ればNコードのOR検索ができます。  
開示設定が「検索除外中です」となっている作品は抽出できません。

https://api.syosetu.com/novel18api/api/?ncode=n0001a-n1111b-n9999d

N0001A,N1111B,N9999Dを取得するURLです。

#### 作品タイプ指定

パラメータ

値

説明

type

string

作品タイプを指定できます。

- t

  短編

- r

  連載中

- er

  完結済連載作品

- re

  すべての連載作品(連載中および完結済)

- ter

  短編と完結済連載作品

#### 文体指定

パラメータ

値

説明

buntai

int  
string

文体を指定できます。ハイフン(-)記号で区切ればOR検索できます。

- 1

  字下げされておらず、連続改行が多い作品

- 2

  字下げされていないが、改行数は平均な作品

- 4

  字下げが適切だが、連続改行が多い作品

- 6

  字下げが適切でかつ改行数も平均な作品

本機能は試験提供機能です。マージンを設けてあるため、適切な結果でない場合があります。

https://api.syosetu.com/novel18api/api/?buntai=4-6

字下げが適切に行われている作品

#### 連載停止中指定

パラメータ

値

説明

stop

int

連載停止中作品に関する指定ができます。

- 1

  長期連載停止中を除きます

- 2

  長期連載停止中のみ取得します

長期連載停止中の定義

未完結の連載中作品で最終掲載日から63日以上経過しているものをさします。  
検索結果に反映されるまで約15分～2時間の遅れがあります。

https://api.syosetu.com/novel18api/api/?stop=1

長期連載停止中を除外するURLです。

#### 最終掲載日指定

パラメータ

値

説明

lastup

string

最終掲載日general_lastupで抽出できます。以下の文字列を指定できます。

- thisweek

  今週(日曜日の午前0時はじまり)

- lastweek

  先週

- sevenday

  過去7日間(7日前の午前0時はじまり)

- thismonth

  今月

- lastmonth

  先月

- タイムスタンプ

  開始日と終了日をハイフン(-)記号で区切ることで[UNIXタイムスタンプ](http://ja.wikipedia.org/wiki/UNIX%E6%99%82%E9%96%93 "Wikipediaを参照")で抽出できます。  
  UNIXタイムスタンプとは1970年1月1日からの通算秒数のことです。

https://api.syosetu.com/novel18api/api/?lastup=thisweek

今週新規投稿または次話投稿された作品の一覧です。

https://api.syosetu.com/novel18api/api/?lastup=1262271600-1264949999

2010年1月1日0時0分0秒から2010年1月31日23時59分59秒までに新規投稿または次話投稿された作品を抽出できます。UNIXタイムスタンプで指定しています。

#### 最終更新日指定

パラメータ

値

説明

lastupdate

string

最終更新日novelupdated_atで抽出できます。以下の文字列を指定できます。

- thisweek

  今週(日曜日の午前0時はじまり)

- lastweek

  先週

- sevenday

  過去7日間(7日前の午前0時はじまり)

- thismonth

  今月

- lastmonth

  先月

- タイムスタンプ

  開始日と終了日をハイフン(-)記号で区切ることで[UNIXタイムスタンプ](http://ja.wikipedia.org/wiki/UNIX%E6%99%82%E9%96%93 "Wikipediaを参照")で抽出できます。  
  UNIXタイムスタンプとは1970年1月1日からの通算秒数のことです。

https://api.syosetu.com/novel18api/api/?lastupdate=thisweek

今週中に内容が更新された作品の一覧です。

https://api.syosetu.com/novel18api/api/?lastupdate=1262271600-1264949999

2010年1月1日0時0分0秒から2010年1月31日23時59分59秒までに内容が更新された作品を抽出できます。UNIXタイムスタンプで指定しています。

#### ピックアップ指定

パラメータ

値

説明

ispickup

int

1を指定した場合、最終掲載日general_lastupから60日以内でなおかつ「短編または完結済または10万文字以上の連載中」を抽出します。

ノクターンノベルズ、ムーンライトノベルズおよびミッドナイトノベルズのピックアップはispickupが1でさらに作品評価が高い順100件です。  
ノクターンノベルズ、ムーンライトノベルズおよびミッドナイトノベルズのピックアップと同一結果を取得したい場合はispickupが1であるかを確認し、さらに総合評価で並べ替えその結果を100件取得する必要があります。

https://api.syosetu.com/novel18api/api/?ispickup=1&order=hyoka&lim=100

ノクターンノベルズ、ムーンライトノベルズおよびミッドナイトノベルズで使っている小説ピックアップの情報を取得するURLです。

### 出力

APIサーバが出力する文字コードはUTF-8です。デフォルトはYAML形式です。  
outパラメータでJSON形式などにも変更できます。  
最初の要素には全作品出力数が入り、以降、一作品ずつ情報が入っています。

要素

説明

allcount

全作品出力数です。

title

作品名

ncode

Nコード

writer

作者名

story

作品のあらすじ

nocgenre

掲載サイト

- 1

  ノクターンノベルズ(男性向け)

- 2

  ムーンライトノベルズ(女性向け)

- 3

  ムーンライトノベルズ(BL)

- 4

  ミッドナイトノベルズ(大人向け)

gensaku

現在未使用項目(常に空文字が返ります)

keyword

キーワード

general_firstup

初回掲載日  
YYYY-MM-DD HH:MM:SSの形式

general_lastup

最終掲載日  
YYYY-MM-DD HH:MM:SSの形式

novel_type

連載の場合は1、短編の場合は2

end

短編作品と完結済作品は0となっています。連載中は1です。

general_all_no

全掲載エピソード数です。短編の場合は1です。

length

作品文字数です。スペースや改行は文字数としてカウントしません。

time

読了時間(分単位)です。読了時間は作品文字数÷500を切り上げした数値です。

isstop

長期連載停止中なら1、それ以外は0です。

isbl

作品に含まれる要素に「ボーイズラブ」が含まれる場合は1、それ以外は0です。

isgl

作品に含まれる要素に「ガールズラブ」が含まれる場合は1、それ以外は0です。

iszankoku

作品に含まれる要素に「残酷な描写あり」が含まれる場合は1、それ以外は0です。

istensei

作品に含まれる要素に「異世界転生」が含まれる場合は1、それ以外は0です。

istenni

作品に含まれる要素に「異世界転移」が含まれる場合は1、それ以外は0です。

global_point

総合評価ポイント  
(R18ブックマーク数×2)+評価ポイント

daily_point

日間ポイント  
ランキング集計時点から過去24時間以内で新たに登録されたブックマークや評価が対象

weekly_point

週間ポイント  
ランキング集計時点から過去7日以内で新たに登録されたブックマークや評価が対象

monthly_point

月間ポイント  
ランキング集計時点から過去30日以内で新たに登録されたブックマークや評価が対象

quarter_point

四半期ポイント  
ランキング集計時点から過去90日以内で新たに登録されたブックマークや評価が対象

yearly_point

年間ポイント  
ランキング集計時点から過去365日以内で新たに登録されたブックマークや評価が対象

fav_novel_cnt

R18ブックマーク数

impression_cnt

感想数

review_cnt

レビュー数

all_point

評価ポイント

all_hyoka_cnt

評価者数

sasie_cnt

挿絵の数

kaiwaritu

[会話率](/man/kaiwa/)

novelupdated_at

作品の更新日時

updated_at

最終更新日時  
システム用で作品更新時とは関係ありません

#### ofパラメータ

出力する項目を個別に指定できます。未指定時は全項目出力されます。転送量軽減のため、このパラメータの使用が推奨されます。  
複数項目を出力する場合はハイフン(-)記号で区切ってください。

- t

  title

- n

  ncode

- w

  writer

- s

  story

- ng

  nocgenre

- k

  keyword

- gf

  general_firstup

- gl

  general_lastup

- nt

  noveltype  
  ※novel_typeではございません

- e

  end

- ga

  general_all_no

- l

  length

- ti

  time

- i

  isstop

- ibl

  isbl

- igl

  isgl

- izk

  iszankoku

- its

  istensei

- iti

  istenni

- gp

  global_point

- dp

  daily_point

- wp

  weekly_point

- mp

  monthly_point

- qp

  quarter_point

- yp

  yearly_point

- f

  fav_novel_cnt

- imp

  impression_cnt

- r

  review_cnt

- a

  all_point

- ah

  all_hyoka_cnt

- sa

  sasie_cnt

- ka

  kaiwaritu

- nu

  novelupdated_at

- ua

  updated_at

https://api.syosetu.com/novel18api/api/?of=t-w&ncode=n0001a

N0001Aのタイトルと作者名を取得するURLです。tとnを指定しています。

https://api.syosetu.com/novel18api/api/?of=ga&ncode=n0001a

N0001Aの全掲載エピソード数を取得するURLです。

ntを指定した場合、novel_typeではなくnoveltypeと\_(アンダーバー)無しで出力される仕様となっております。ご注意下さい。

#### オプション項目

optパラメータに以下の文字列を指定するとオプション項目を取得できます。

- weekly

  週間ユニークユーザ\[項目名:weekly_unique\]が追加されます。  
  週間ユニークユーザは前週の日曜日から土曜日分のユニークの合計です。  
  毎週水曜日早朝に更新されます。

https://api.syosetu.com/novel18api/api/?opt=weekly

週間ユニークユーザを含めて出力します。

https://api.syosetu.com/novel18api/api/?sasie=1-&opt=weekly

挿絵が1枚以上存在する作品を、週間ユニークユーザを含めて出力します。

Atomフィードの特例

out=atomを選択された場合のみ、出力制限があります。  
タイトルとURL、あらすじ、最終掲載日、コメントの中に作者名のみが出力されています。その他の項目(評価ポイントやキーワードなど)は出力しません。

### 時刻の注意

なろうR18小説APIにはさまざまな時刻項目があります。

項目

説明

general_firstup

初回掲載日です。最初に作品を掲載した日時となっております。原則として初回掲載日が変わることはありません。

general_lastup

作品最終掲載日です。作品を公開した時点で反映されます。  
上のgeneral_firstupと違い連載作品の場合、次話投稿時にも反映されます。ただし編集の場合は反映されません。

novelupdated_at

作品の更新時刻  
最後に作品データが更新された時刻です。

updated_at

データ更新時刻  
最後にデータが更新された時刻です。なろう小説APIの場合、総合評価ポイントが変わった場合なども反映されます。  
作品の更新時刻ではありません。

### 利用制限

利用制限は現在、休止しています。  
負荷状況により今後、導入されることがあるためキャッシュの導入など、利用制限を想定したシステム設計をお願いします。ただし、古い情報を誤って掲載しないよう一定期間(長くても２週間)でキャッシュの更新・削除をお願いします。

IPアドレスごとに利用制限を行います。  
1日の利用上限は80,000または転送量上限400MByteです。  
利用制限は初回アクセスから24時間が適用範囲です。  
初回のアクセスから24時間後に回数と転送量を記録していたカウンタと初回アクセス時刻をリセットします。  
なお、1日の利用上限を超えた場合、エラーの発生確率が増します。  
混雑状況にもよりますが、リクエスト回数または転送量が利用上限の120%を超えるとほとんど接続できなくなります。

備考：利用制限カウンタは厳密ではなく多少のマージンを設けてあります。  
転送量は圧縮することで減らせます。

転送量制限の回避方法

- gzip=5を指定し、gzipファイルで受信する。  
  デメリットとして受け取り側で解凍する手間は発生するが、かなりの転送量を削減できる。
- YAML形式を使う。一番容量が小さいため。
- [ofパラメータ](#output-of-parammeter)を使い、必要な項目のみを出力する。

### 遅延について

データベースサーバは日本国内の複数拠点に分散されていることがあります。  
APIから小説データベースに接続した場合、原則としてスレーブサーバにつながります。  
マスタサーバとスレーブサーバ間は10秒以内にデータを同期しています。

しかし、何らかのネットワーク障害が発生した場合、遅延が発生し、サーバによってデータにばらつきが生じることがあります。  
また、実際に作品のデータが修正されてからなろうAPIに反映されるまで平均5分程度(最大2時間)の誤差があります。

stopパラメータ、global_point、fav_novel_cnt、review_cnt、all_point、all_hyoka_cnt項目に関してはキャッシュの都合上、さらに15分から2時間の遅れがあります。

目次

[出力形式](#ouput-style)

[APIのURL](#api-url)

[出力GETパラメータ](#get-parameter)

[outパラメータの詳細](#out-detail)

[条件抽出GETパラメータ](#extraction-condition)

[出力](#output)

[時刻の注意](#time-parameter)

[利用制限](#limit)

[遅延について](#delay)
