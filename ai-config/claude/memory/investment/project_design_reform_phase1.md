---
name: project-design-reform-phase1
description: デザイン改革 Phase 1 着地 (2026-06-12)。色トークン単一ソース化 + 質感 + チャート脱オレンジ + 数値/テーブル統一。Phase 2-4 ロードマップと申し送りあり
metadata: 
  node_type: memory
  type: project
  originSessionId: 9771f53a-dd48-440f-895c-e03733e333e4
---

# デザイン改革 Phase 1 (2026-06-12 着地)

5 コミット (511371a6 / 9f5a448f / 60a40e6c / 8e35c0f2 / Step4) で共通基盤を磨き全 32 画面に波及。worklog: `docs/worklogs/20260612-design-reform-phase1.md`、プラン: `C:\Users\kazum\.claude\plans\abundant-dancing-pascal.md`

## 確立した規律（以後の UI 作業の前提）

- **色の単一ソース**: globals.css `:root` の `--c-*` チャンネル ⇔ `desktop/src/lib/design-tokens.ts`（parity test で同期強制）。canvas 系（lightweight-charts/cytoscape/recharts）は design-tokens.ts 経由のみ
- **オレンジ (#ff8a3d) = 操作中の場所専用**（アクティブタブ/選択/focus/primary ボタン）。データ系列には使わない（volume/MA25 は青系 #58a6ff へ移行済み）
- **ボーダー 3 階層**: `border-line-1`（行罫線 white6%）/ `line-2`（パネル境界 12%）/ `line-3`（強調 20%）
- **トーン 3 段レシピ**: subtle = bg/10+border/30、medium = bg/20+border/40+色文字、strong = ベタ。バッジ類は必ずここから
- **データ駆動色は `lib/heat-scale.ts` のみが供給源**（heatBg 4 段量子化 / divergingHeatColor）
- **緑赤は semantic-up/down に一本化**（emerald/red-500 raw palette 禁止）
- ホバーは bg white5% + 文字 muted→fg のみ、transform/scale 禁止。transition は `.interactive` 150ms 単一
- 受け入れカタログ: `/_dev/design-system`（Elevation/Border/トーン/Focus セクション + visual spec `design-system.spec.ts` 密度 3 モード）

## 技術知見

- Tailwind v3 CSS 変数化: function 形式 + `opacityValue.includes("var(")` で default alpha 分岐（panel-border の 0.12 等を保つ）。1,800 箇所の `/N` modifier 完全互換
- dev カタログページは `_dev/StartupOverlayBypass.tsx` を mount しないと起動オーバーレイ（Signal Horizon）がクリックを遮断する
- Playwright update-snapshots でも不安定セルは失敗する → セル高さ 2 連続一致 poll で安定化済み（business-model-catalog.spec.ts）

## Phase 2+ 申し送り

1. linux baseline 未更新 → CI workflow_dispatch update_snapshots=true 必要
2. win32 baseline は起動画面再設計の @fontsource 未コミット変更を含んだ状態で撮影（フォント revert で割れる）
3. Dashboard.tsx 掃き寄せ見送り（他作業の未コミット変更と衝突回避）
4. StatusBadge レシピ未適用（src/styles/tokens.ts が permission deny で Read 不可）
5. kb-\* 駆逐残: CompanyPL/BS/CF・FirstViewHero・Section.tsx・OpsHubPage、BuybackTracker zinc 29 箇所
6. Phase 2=高トラフィック画面 / Phase 3=外れページ Panel 化 (research/, sector-analysis/) / Phase 4=knowledge-base 統合 + raw color lint 恒久化
