# TODO

## Defect

### 読み込み中のウィンドウ削除
読込中にウィンドウかバッファを削除すると想定しない動作が起きている模様
別のバッファが書き換えられる現象が発生

### ロケーション表示のキーバインド
ロケーション表示に使用しているキーバインド CTRL-L は、画面の再描画と衝突する

### 折り返されたリンクでの遷移

折り返されたリンクの2行目以降で、call v3m#open_link() しても、ページが開かずにエラーとなる

### セッション復帰時のウィンドウ

セッション復帰時の読み込み時に、ウィンドウがなくなる。バッファはリストされる状態。まず、理由を確認

### :e (引数なし)を実行すると、コンテンツが消える。

期待動作は、 reload?。リロードの場合、再読み込みの場合、履歴も消す?

## Docs

### デフォルトマッピング定義

## Operations

### TAB キーによるフォームコントロールへの遷移

### リンクを開く。new 相当
キーバインド案
CTRL-W_]

### リンクを開く。edit 相当。
キーバインド案
CTRL-]
タグスタックを考慮

### リンクの URL を表示する方法の提供

### フラグメント遷移時のタグスタック対応
リンク遷移時もタグスタックに対応できるか検討
jumplist も検討

### カーソル下の URL をコピー
ノーマルモードで、カーソル下の URL をコピー

### [REOPEN] デフォルトマッピング定義

スペースによる、ページ up/down。ユーザが定義しているマッピングとかぶりそうなため、相応してデフォルト設定を検討

### 現在のバッファを使用して URL を開く

### カレントバッファを v3m で開くコマンド。

    案 v3m://buffer://18 など？

### 外部ブラウザでリンクを開く方法の提供

netrw の機能確認

### 外部ブラウザで現在のページを開く方法の提供

netrw の機能確認

## Features

### 履歴でフォームの入力内容保持
履歴に戻った際に、フォームの入力内容を復帰させる

### カーソル化の URL 表示
カーソル化の URL を表示する機能

### TAB キー、リンク遷移改善
ページ先頭や最後のリンクで、Shift+TAB, TAB を使用した際に
ベージ最後や先頭にリンクのフォーカスが遷移

### neovim 対応

*   [x] job 互換
    * [x] async.vim を使用
*   [x] vimscript 互換
    * [x] literal-Dict `#{}` を使用しない
    * [x] optional-function-argument を使用しない
*   [ ] textprop 互換

### support html5 entity name
https://dev.w3.org/html5/html-author/charref

### 一行目にタイトルを表示
オプション

### ページ一覧
* タイトルとバッファ名を表示
* 番号選択で、切り替えもサポート

### フォームに値を設定できるようにする。
input_alt type=text サポート

### フォームに設定された値の画面上への表示

### フォームのサブミット実施
intpu_alt type=submit サポート

### 履歴の改善
履歴の管理を位置で行う
履歴を戻っても、現在から戻る先までの間の履歴を消さない

### ソース取得機能
ただし、パフォーマンスを考慮し、通常のページ表示時にはソースを同時に取得しない。

### ContentType または、ファイル拡張子によるコンテンツ変換サポート

外部コマンドもしくは、関数による変換。

     例 md -> html など

### zip 内のページ参照。内部の url 解決も提供

### fragment のリスト表示と、番号選択による遷移

id は、ユーザが理解しにくい内容なので、該当箇所のテキスト要素などを表示することを検討

### [SUSPEND] ヘッダータグの階層表示と、番号選択による遷移

w3m のダンプには、ヘッダ情報がふくまれないので難しい


## Rendering

### `<u>` のサポート
### レンダリングに指定する最小幅を設定
デフォルト値をどうするか(スマホ向けページ等があるのでデフォルトなし?)

### リンクハイライト表示
カーソルがリンク上にある場合のリンクハイライト表示

### 行末の空白を消込モード
行末の空白を消し込む。モードとする。デフォルトは消込モード。コピーの際に邪魔となるため

### タグとハイライトグループの整理

## Implements

### リロードの高速化
キャッシュの利用

### コンテンツが多いページ読み込みのための実装改善
exit 後の data_out の度に、exit でタイマーに登録した終了処理を遅延させる

### history で戻った際のフォーム情報復元


### history 表示時のキャッシュ利用
ページ取得が遅いので、キャッシュを利用する

### ホームページは、履歴に含めない

### データ取得処理の分離
カスタマイズのため。 zip 内 html, md, キャッシュ処理など

### ロード時に、ページ読み込み時間の表示

### ページロード時のタイムアウト設定

### page 構築実装からの channel 隠蔽
多分、neovim 対応に役立つ

### v3m#back(), v3m#back_history() の整理

### vital.vim を利用した、 url エンコーディング・デコーディング
実体参照も検討

### url エンコーディング対応
url に関して、内部ではデコードした情報で保持。 一致確認などのため

### ページロードキャンセル処理
ロード仕掛中のページで、新たな操作をした場合に、仕掛中の結果を無視するようにする

### w3m プロセスの同時呼び出し数制限
w3m プロセスの同時呼び出し数を設定できるようにする。

## Test

### 各コマンドのテスト
### <Plug> 定義のテスト
### ダウンロードとなるリンク遷移時の動作

## others

### 任意バッファで、カーソル下にある URL を開く関数

## 機能要件を満たさない場合の通知に関して、他のプラグインでの動作を調べる

# DONE

## Defect

### URL の解決
解決時に、以下のようになる場合がある模様
http://xxxx/./yyy/zzz

期待値
http://xxxx/yyy/zzz

### コンテンツ量が多めのページの読み込みが途中までとなる
→
curl で読みむ場合も簡易的に後処理を遅延させる

### html 以外の URL を開いた際の処理
html 以外の URL を読み込んだ際に、html のソースとして処理使用とするので
様々な問題が発生

### タグ解析エラー 2020/01/11

タグが、> で閉じる前に改行されているとエラーが発生
現状、w3m がタグ内で改行を発生させる html が再現できていない
→
ローカルの html などを読み込む際に発生しやすい模様
同一ファイルでも、発生する場合としない場合あり
おそらく、タイミングによる問題発生。

``
 <test a=''
       b=''>
``

#### 原因
おそらく、job の out_cb がすべて呼び出される前に exit_cb が呼び出されているため
中途半端な読み込み状態で、パース処理が開始されている
close_cb の後であれば問題なさそう。
vim のドキュメントには、exit_cb が呼び出された後にも、コールバックが呼び出される可能性があるとも読み取れる記載あり

async.vim を修正することで対応可能かを検討

#### 対応
とりあえず、現象が発生する default_handler のみに簡易的な回避実装

### 相対URL 時のリダイレクト処理
リダイレクト時、Location ヘッダに相対パスが設定されている場合がある。
この URL を保存する際に、相対パスのみを保存している

### E303: Unable to open swap file
クエリ文字列を含むなどの非常に長い URL を開く際に以下のエラーが発生

'''
Error detected while processing function v3m#open_v3m[3]..v3m#open[29]..<SNR>119_configure_buffer:
line   12:
E303: Unable to open swap file for "v3m://https://xxxxxxxxxxxxxxx.com/articles/newsjp/xxxxxxxx-xxxxxx/?__cf_chl_jschl_tk__=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", recovery impossible

'''

#### 対応
setlocal noswapfile

#### 検討
バッファ名にクエリ文字列を含める必要があるか

### % を含む URL を開く
V3m コマンドで % を含む URLを開くとカレントファイル名に展開されてしまう。

#### 対応
URL を取り扱うための V3m とローカルファイルを取り扱うための V3mLocal を分ける

#### メモ
:command -complete=file を使用すると % が自動的に展開される模様

### スラッシュなしで開始する相対リンク。 
最初のパスセグメントがドメイン扱いとなっている
```
current: /xxxx/yyy/zzz
link: aaa/bbb.html
resolve: https://aaa/bbb.html
-> 
resolve: /xxxx/yyy/aaa/bbb.html
```
現在のページからの相対 URL を参照する
-> スキームが指定されていない場合の、URL 解決を修正

### 履歴の消込

履歴番号で遷移した場合、不要な履歴が消し込まれない。

消し込まずに、カーソルが移動する方式でも良いかも

### :e v3m://` で g:v3m#homepage が表示されない

一部のマシンで `:e v3m://` を実行した際に、g:v3m#homepage が設定されていてもページが表示されない場合がある
バッファ変数が正常に設定されていないことが原因となっている。このケースで bufload() は、エラーとなっていた。
-> バッファのリネーム処理の際の、リネーム前の名前を持つバッファ消込処理に問題があった。正しいバッファ番号が取得されていなかった

### 同一 URL を開く際のバッファ処理

一回開いたバッファで、"戻る"等などで同じ URL を再び開こうとすると、別のバッファが使用される。 :file で名前を変えると、
元の名前のバッファが unlisted で作成されるため

### fragment に遷移しないケースがある

     `<_id id="">` として解釈されるケースがある。
     `<h2 id="aaa">aaa</h2>`
     そもそも、fragment はアンカータグだけでない

## Docs
### 初期ドキュメント作成
### g:v3m#homepage

## Operations

### 現在のバッファでブックマークを開く
キーバインド案
\<S-B>

### 履歴の表示。番号付き
<Plug>(v3m-show-history)

### 履歴番号を使用した「戻る」
<Plug>(v3m-show-history)

### location bar の提供
現在の URL が確認可能。新規 URL を入力し、移動可能なこと -> <Plug>(v3m-show-locationbar)

### 現在ページの URL を表示する方法の提供
<Plug>(v3m-show-locationbar)

### file:// 対応
### リンクを開く
### リンクを新規タプで開く。
<Plug>(v3m-open-link-tab)

### 遷移履歴の保持
### 戻る機能
### TAB キーによるリンク遷移
### SHIFT-TAB キーによるリンク遷移
### LeftMouse によるリンク遷移

## Features

### リダイレクト先の URL を表示
curl を使用して、リダイレクトサポートしつつ、ヘッダ・ソースを取得

### 機能要件のチェック。 w3m, +job, +channel など
### デフォルトページサポート  -> g:v3m#homepage
### BufReadCmd 対応。 -> e v3m://{URL}

## Rendering

### レンダリングに指定する最大幅を設定
デフォルト値をどうするか(80 x 1.5 or 2 程度?)

## Implements

### ページパース時に、フォームの情報構築
form_int, input_alt タグ fid属性
```
fid*
  form_int
    method
    action
    name
  input_alt*
    type
    name
    value
    maxlength
    #displaylength
```

### フォーム関連タグの解析
fid で分類？

### User-Agent の決定
w3m -version で取得した値を使用。
v3m もつける？ 各ブラウザがどのように、User-Agent を使用しているか確認する。
→ curl を使用する場合、google の検索ページが curl の User-Agent を許可しないので、
w3m のバージョンから取得したものを使用

### 属性の実体参照デコード

     `id="&lt;init%gt;()"`

### fragment のマッチング時に、href の URL エンコーディング展開して比較

     `href="%3Cinit%3E()"`

### 専用のファイルタイプ作成
### キーマッピングをファイルタイプベースで設定できるようにする
### url 内の、相対パスアクセスの正規化。. ゃ ..
### 閉じタグなしへの対応
open タグに対応する閉じタグより前に、他の閉じタグが発生した場合 open タグも閉じる。

### id へのリンク対応。リロードしない。
### a タグの id サポート。リンク先の候補に含める。
### a タグのアンカーポイントとリンクを区別する。

## DISCARD

## Implements
### ファイルの連番を廃止
多分不要なため
-> :file  実行時、同名のファイルがあるとエラーになるため、必要

