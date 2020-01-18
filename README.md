# vim-v3m

v3m-v3m is a web browser interface plugin for Vim. See [help](doc/v3m.txt) for details.

## Requirements

* Vim 8.2 latest
* w3m
* curl
* prabirshrestha/async.vim


## TODO

* [WIP] Form
* UserAgent
* Cookie
* neovim
* :write

## Pros and Cons(Japanese)

### Pros

*    ページをバッファとして取扱うため、Vim　の操作がそのまま適用可能
     *    vimscript によるカスタマイズ。操作方法、ブックマーク管理など
     *    ウィンドウを使用したタイリング表示
*    非同期でのページ読み込み

#### Not implemented

*    markdown の表示。リンク遷移サポートも含む。pandoc などを使用した html への変換を想定
*    アーカイブファイル内の html 参照。リンク遷移サポートも含む
*    w3m から他のコマンドへの置き換え。ただし、w3m の halfdump 相当が必要。

### Cons
#### 対応可能?

*    cookie 未対応
*    ページのキャッシュ

#### 対応不可?

*    画像表示
*    ベーシック認証、ダイジェスト認証
*    フレームタグ対応。w3m halfdump が未サポート？

その他は、未検討

