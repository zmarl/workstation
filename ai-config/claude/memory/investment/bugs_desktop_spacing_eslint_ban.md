---
name: bugs-desktop-spacing-eslint-ban
description: "Desktop eslint no-restricted-syntax が大きめの余白 Tailwind 直書きを禁止 (gap-4+/p-6+/m-4+/space-y-4+/min-h-[300px+])"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 60cac97c-1a3b-4147-902c-8c047702f4fb
  modified: 2026-07-19T08:44:05.171Z
---

Desktop の `eslint.config.js` は `no-restricted-syntax` で className 直書きの大きめ余白ユーティリティを禁止する。
`--max-warnings 0` なので該当すると gate が赤になる。

禁止パターン（className 文字列 + テンプレートリテラル両方）:
- `gap-4`〜`gap-19`、`gap-x-4+` / `gap-y-4+`
- `space-x-4+` / `space-y-4+`
- `p-6+`、`px/py/pt/pr/pb/pl-6+`
- `m-4+`、`mt/mr/mb/ml/mx/my-4+`
- `min-h-[300px+]`（px 値 300 以上。rem 指定 `min-h-[4rem]` は対象外）

回避: Stack / Row / LayoutGrid / Panel primitives または `var(--panel-gap)` / `var(--panel-pad)` を使う。
小さい値（gap-1〜3、p-1〜5、space-y-1〜3、min-h の rem 指定）は許可。

実例 (A7, 2026-07-19): 新規 desktop コンポーネントで `grid gap-4` と footer の `gap-4` が warning → `gap-3` に変更で解消。
本デザイン改革プログラム (Phase A〜) は多数の新規コンポーネントを書くため再発必至。新規 tsx は
`gap-4`/`p-6`/`space-y-4` 以上を最初から避けること。関連: [[project-desktop-design-reform-2026-07-19]] [[bugs-desktop-undefined-tailwind-tokens]]
