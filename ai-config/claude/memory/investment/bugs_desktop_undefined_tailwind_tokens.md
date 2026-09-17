---
name: bugs-desktop-undefined-tailwind-tokens
description: Desktop had ~11 families of undefined Tailwind semantic tokens rendering colorless across ~24 files; how to detect and the canonical replacements
metadata: 
  node_type: memory
  type: project
  originSessionId: 689143f6-cbb6-41e4-baa9-0b00a74cda56
---

# Desktop の未定義 Tailwind セマンティックトークン（無色描画バグ）

デザイン改革調査（2026-07-04）で発覚。`desktop/tailwind.config.ts` に**存在しない**色トークンが多数のコンポーネントで使われ、Tailwind がクラスを生成せず**無色（親色を継承）で描画**されていた。密度の高い投資UIで最重要な「情報階層（薄い副次テキスト）」「価格の上下色」「重要度色」が広範に壊れていた。TSも通り、lint も素通りするため長期間潜伏。

## 検出方法（決定的）
`tailwind.config.ts` を読むだけでは不十分。実際にビルドして生成クラスを確認する:
```
cd desktop
./node_modules/.bin/tailwindcss -i src/styles/globals.css -o /tmp/probe.css --minify
grep '\.text-fg-muted[,{ :]' /tmp/probe.css   # 無ければ無効(no-op)
```
`text-muted`/`text-warn`/`bg-panel-header`/`border-panel-border` は VALID、`text-fg-muted` 等は BROKEN。

## 無効トークン → 正しいトークン（全て一括 sed 済み、2026-07-04）
- `(bg|text|border|ring)-warning` → `-warn`（`warn` が正、`warning` は未定義）
- `text-fg-muted` → `text-muted`（`fg` はフラット色、`fg-muted` は無い）
- `bg-surface-2` / `bg-panel-alt` → `bg-panel-header`（surface は CSS var `--surface-2` のみ、Tailwind クラスは無い）
- `border-border` → `border-panel-border`（`border` という色は無い。正は 1551 箇所使われている `panel-border`）
- `(bg|text|border)-info` → `-semantic-info`（`info` は無く `semantic-info` が正。青）
- `(bg|text|border)-up` → `-ok` / `(bg|text|border)-down` → `-danger`（上下＝good/bad。`up`/`down` 単独色は無い。`ok`=--c-up 緑 / `danger`=--c-down 赤で同値）
- `(bg|text|border)-primary` → `-semantic-info`（`primary` は無い）
- `bg-bg-elev` / `bg-bg-elev-1`（二重プレフィックス）→ `bg-panel-header`

## 網羅チェック
使用中の色ルートを抽出→既定トークン集合と `comm -23` で差分。残差は既定パレット shade（`amber-100` 等＝Phase 4 の raw palette 掃除対象、無効ではない）か正規表現ノイズ（`text-base`=font-size 等）。`border-l-accent` は Tailwind v3 方向別ボーダー色で VALID。

## 教訓
- 新規セマンティックトークンを使う前に上記 probe ビルドで生成を確認する。design-guard の Rule 2 は「raw palette（red-500 等）」を検出するが、**未定義トークンは検出しない**（生成されないだけ）。将来 design-guard に「未定義クラス検出」ルールを足すと再発防止になる（Phase 4 Stage 8 の Rule 3 と併せて検討）。
- 関連: [[bugs]] [[project_design_reform_phase3]]
