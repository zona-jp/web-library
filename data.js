/* ==========================================================
   CREATE HUB ─ 静的公開用データファイル（フォールバック）
   ----------------------------------------------------------
   ★ 共有データベース（Supabase）を設定している場合、
     通常このファイルは使われません。
     データベースに接続できないときの「予備データ」として働きます。

   ★ 手書きしないでください。
     管理画面の EXPORT で出力した JSON を、下の
     window.CREATE_HUB_DATA = [ の次の行から ]; の前までに
     「配列の中身だけ」貼り付けます。
     （EXPORT結果の先頭の [ と末尾の ] は貼り付けない）

   ★ 保存したら必ず構文チェックしてください：
        node --check data.js
     何も表示されなければ正常です。
   ========================================================== */
window.CREATE_HUB_DATA = [
  {
    "id": "hub-sample-05",
    "title": "RIALAホームページ",
    "description": "データ可視化ダッシュボードのUIコンセプトデザイン。モジュラーグリッドとアクセントカラーによる情報設計の提案です。",
    "category": "WEB",
    "type": "WEB SITE",
    "tags": [],
    "thumbnail": "",
    "url": "https://riala.jp/",
    "created": "2026-04-11",
    "updated": "2026-05-12",
    "published": true,
    "featured": false,
    "accentColor": "purple",
    "order": 0
  },
  {
    "id": "hub-sample-03",
    "title": "sanmpe",
    "description": "",
    "category": "TOOLS",
    "type": "WEB SITE",
    "tags": [],
    "thumbnail": "images/RIALA-logo.png",
    "url": "https://riala.jp/",
    "created": "2026-02-08",
    "updated": "2026-04-22",
    "published": true,
    "featured": false,
    "accentColor": "yellow",
    "order": 3
  }
];
