---
name: bugs-sronly-absolute-page-pan
description: "sr-only(absolute) が overflow 枠の外を基準に配置されページが横パンするバグ (2026-07-19 根治): スクロール枠に relative 必須"
metadata: 
  node_type: memory
  type: project
  originSessionId: 60cac97c-1a3b-4147-902c-8c047702f4fb
  modified: 2026-07-19T11:34:57.085Z
---

# sr-only による不可視ページ横パン (2026-07-19 根治)

- **問題**: /macro?view=sector・/sector がウィンドウごと 278〜331px 横パンする。表は overflow-auto 枠内で正しく
  クリップされているのに document.scrollingElement.scrollWidth だけが伸びる。
- **診断の罠**: 祖先チェーンの幅は全て viewport 以下 / sticky 無効化で不変 / thead 非表示で部分減（52px）——
  という不可解な計測になる。犯人は**テーブル内の sr-only（position:absolute）**。
- **原因**: absolute の包含ブロックは「最も近い positioned 祖先」。スクロール枠（overflow-auto div）が
  non-positioned だと sr-only の包含ブロックは枠より上（body 等）になり、**overflow クリップは包含ブロック
  チェーン上の祖先にしか効かない**ため、画面外の列に静的配置された sr-only がページのスクロール幅へ直接寄与する。
- **解決**: スクロールコンテナに `relative` を付ける（DataTable の overflow-auto wrapper / HeatMatrix の
  overflow-x-auto wrapper に適用済み）。全ての absolute 子孫（sr-only 含む）が枠内にクリップされ、パン 0 を実測確認。
- **規範**: **overflow スクロール枠を作るときは常に `relative` を併記する**（内部に sr-only や absolute 装飾を
  置く可能性が少しでもあれば必須）。
- 関連: [[project-desktop-design-reform-2026-07-19]]
