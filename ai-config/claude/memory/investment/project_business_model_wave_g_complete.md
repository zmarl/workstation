---
name: Wave G Desktop UI 4 種 完了 (2026-05-05)
description: 5 Forces レーダー (recharts) / Value Chain SVG / SaaS Dashboard / RelationshipGraph 4 tier の Desktop UI を 1 セッションで実装。recharts ^3.8.1 導入、Phase 3 着地確認 (alembic upgrade + 10 銘柄 probe) も完了
type: project
originSessionId: wave-g-desktop-ui-4-session
---

# Wave G Desktop UI 4 種 完了 (2026-05-05)

`C:\Users\kazum\.claude\plans\rippling-discovering-scott.md` のフルスコープを 1 セッションで完遂。

**Why:** マスタープラン v2 (`polymorphic-inventing-widget.md`) Phase 2 集約層。前セッション (Wave F Phase 3 横展開) で 12 業界別パネル全てに live metrics 経路が完成、後続 Wave L (ビジュアル回帰) / Wave M (Playwright + LLM narrative) は Wave G 4 種 UI を検証対象として要求するため。

**How to apply:** 次セッション着手は (a) Wave D Phase 3 IR 数値再投入 (sample JSON を core.metric_observations に DB ロード), (b) Wave E Tier 2-4 推定 (Wave G の 4 tier graph に live data 流し込み), (c) Wave L pixelmatch ビジュアル回帰 baseline 取得, (d) 8951 J-REIT の company surface 修正、のいずれか。

## 完了範囲

### Phase 0: Phase 3 着地確認
- alembic `20260507_01 → 20260508_02` 適用 (33 metric_key seed)
- 10 銘柄 probe: 9 銘柄で各 framework が `partial` 0.45、8951 のみ `outside_current_listed_company_surface` (要 follow-up)

### Phase 1: 基盤導入
- `recharts ^3.8.1` 追加 (vendor-charts gzip ~56 KB)
- `_business-model-framework-utils.ts` (`forceSignalToScore` / `metricToYoyTone` / `narrowChainTier` / `formatSaasMetricValue` / `formatYoyPct`)
- `ChainTier = 1|2|3|4`、`DiagramNodeTier` に `tier_2/3/4` 追加
- `_business-model-framework-shared.tsx` で ConfidenceBadge / StatusBadge / FrameworkEmpty / EvidenceList / SlotCard を共通化

### Phase 2: 4 UI 実装
- **G-1 FiveForcesMap.tsx**: recharts.RadarChart で 5 軸 0-5、左 320×280 + 右 5 ForceCard、hover で aria-current。`BoundedRadar` で jsdom テスト時の `ResponsiveContainer` 0×0 問題回避
- **G-2 ValueChainMap.tsx**: SVG primary 5 chevron + support 4 tile、edge count バッジ、hover で右側 detail aside
- **G-3 SaasMetricsMap.tsx**: 4 funnel + 6 KPI grid (ARR/MRR/ARPU/Churn/NRR/Rule of 40)、YoY バッジ (up/down/flat/unknown)、is_candidate CTA
- **G-4 CompanyRelationshipGraphDiagram**: `retagNodesByTier()` で edge.chainTier に基づき node.tier を tier_2/3/4 に再マップ。`BusinessModelSvg` の `resolveTierVariant` 拡張 + `strokeForNode()` で Tier 別 stroke 色 (Tier1=#ff8a3d / Tier2=#58a6ff / Tier3=#bc8cff / Tier4=#586069)。Tier 凡例追加

### Phase 3: BusinessModelCanvasView 結線
- inline 11 関数を import に置換
- 1144 → 875 行 (-269 行)
- 旧 testid (`five-forces-map` 等) を新コンポーネントに併記して段階移行

## 検証結果

- ruff: All checks passed
- pytest tests/tools/api/test_company_business_model_frameworks.py: **43 passed**
- desktop typecheck: 0 errors
- desktop vitest src/components/company/: **152 files / 681 tests passed** (+38 新規ケース、regression 0)
- desktop build: built in 8.66s (BusinessModelCanvasView.js 555 KB / 149 KB gzip)
- desktop lint: 私の変更による errors / warnings 0、ChartFrameSelector.tsx に事前存在 5 warning

## 設計判断

- **recharts vs SVG 自前**: recharts ^3.8.1 採用。React 19 互換 OK、bundle gzip +56 KB は許容範囲、tree-shake で必要 module のみ
- **BoundedRadar ラッパ**: jsdom テスト時 `ResponsiveContainer` が 0×0 を返すため、固定 width/height で `<RadarChart>` を直接 render する代替を export (`responsive` prop=false default)
- **CompanyRelationshipGraph の SVG 拡張 (cytoscape 不採用)**: `BusinessModelGraphV2Panel` (cytoscape ベース) と `CompanyRelationshipGraphDiagram` (SVG ベース) を分離維持。Tier 4 styling は SVG 側のみ拡張、cytoscape 側は touch せず (Wave U で UX 統合判断)
- **chainTier の 1|2|3|4|null narrowing**: `business-model-builder.ts` の `asChainTier` で BFF 由来の `number | null` を narrow。`null || 1` は backward compat (Wave E 未完時の Tier 1 only 動作)
- **inline 関数の shared 化**: `ConfidenceBadge` / `StatusBadge` 等の小さい helper を `_business-model-framework-shared.tsx` に集約、新 4 コンポーネントから再利用。重複削減 + 後続 panel 追加時の再利用基盤

## 次セッション必須

1. **8951 J-REIT 修正**: BFF の company surface に J-REIT を含める or 専用 surface 追加 (probe で `outside_current_listed_company_surface` ブロック)
2. **sample JSON の DB ロード**: 16 sample JSON を `core.metric_observations` に import (Wave D Phase 3 で 計画済)

## 次セッション候補

1. **Wave D Phase 3 IR 数値再投入** (10 銘柄 sample JSON を IR 資料の正規値に上書き、confidence ≥ 0.85 化、DB ロード自動化)
2. **Wave E Tier 2-4 推定** (`industry_tier_chains.yaml` + `tier_inferer.py`、Wave G の 4 tier graph に live data 流し込み)
3. **Wave L (pixelmatch ビジュアル回帰)** で 5 Forces レーダー / Value Chain SVG / SaaS Dashboard / Tier 4 graph の baseline 取得
4. **Wave M (Playwright + qwen3.5:9b narrative endpoint)**
5. **PeerComparisonOverlay.tsx 実装** (FiveForcesMap.peerForces prop で 3 peer を α=0.4/0.25 重ね描画)
6. **BusinessModelGraphV2Panel と CompanyRelationshipGraphDiagram の UX 統合** (Wave U)

## 関連ファイル

- 新規: `desktop/src/components/company/{FiveForcesMap,ValueChainMap,SaasMetricsMap}.tsx` + `.test.tsx`
- 新規: `desktop/src/components/company/_business-model-framework-{utils,shared}.{ts,tsx}` + utils.test.ts
- 修正: `desktop/src/components/company/{BusinessModelCanvasView,CompanyRelationshipGraphDiagram,BusinessModelSvg}.tsx` + テスト
- 修正: `desktop/src/components/company/{business-model-types,business-model-svg-utils,business-model-builder}.ts`
- 修正: `desktop/package.json` (recharts ^3.8.1)
- 適用: `db/alembic/versions/20260508_01_business_model_packs_metrics_catalog.py` + `20260508_02_telecom_bank_jreit_metrics_catalog.py`
- worklog: `docs/worklogs/20260505-wave-g-desktop-ui-4.md`
