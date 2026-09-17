---
name: Wave J Phase 2 Phase 3 + Wave F Phase 3 パイロット 着地完了 (2026-05-07)
description: VerticalPyramid を 3 ファイル分離規範に揃えて layout snapshot 9 件 baseline 取得、副スコープで AutoOemPyramidPanel に live metrics 経路パイロット (7203/7267 各 3 metrics で `frameworks.auto_oem.status='available'`)。Wave J Phase 2 全 5 段階完了
type: project
originSessionId: 3e1b1db0-333e-407c-87e9-eb018e0b2446
---
# Wave J Phase 2 Phase 3 + Wave F Phase 3 パイロット 着地完了 (2026-05-07)

`C:\Users\kazum\.claude\plans\keen-finding-stream.md` の主・副スコープを 1 セッションで完遂。

**Why:** マスタープラン v2 (`polymorphic-inventing-widget.md`) Wave J Phase 2 5 段階のうち Phase 1+2+4+5 は前 2 セッションで完了済み。残る Phase 3 を本セッションで完遂し Wave J Phase 2 全体を Done 状態に到達させる。並走で Wave F Phase 3 (12 panel への live metrics 配線) のパイロットとして AutoOemPyramidPanel に metrics 経路を新設し、`disclosure_kpi_extractor` の `core.metric_observations` 着地を BFF `_frameworks/auto_oem.py` 経由で Desktop 表示まで貫通させる。

**How to apply:** 次セッションで Wave F Phase 3 本体 (残 11 panel の metrics 配線水平展開) または Wave D Phase 3 IR 数値再投入、Wave L (pixelmatch ビジュアル回帰)、Wave C / Wave U 着手の起点。

## 主 Phase 3 完了 (実態と当初指示の差分対応)

### Discovery: AutoOem/Pharma は既に Wave J-1 で wrapper 化済

当初指示「VerticalPyramid 拡張で AutoOemPyramid / PharmaRdStructure 統合 + ~300 行縮減」は実態と齟齬:

- **AutoOemPyramid.tsx (28 行) / PharmaRdStructure.tsx (29 行) は既に薄 wrapper**。Wave J-1 で完了済。`AUTO_OEM_PYRAMID_CONFIG` / `PHARMA_RD_STRUCTURE_CONFIG` も `*-utils.ts` に分離済。
- **VerticalPyramid.tsx 自身が単一ファイル 277 行**。LayeredFlow / HubSpoke / RadialCluster 規範 (3 ファイル分離) に未準拠。

→ AskUserQuestion で方針確定: **「VerticalPyramid 3 分離 + 全 layout snapshot 整備」**。Phase 3 の真のゴールは「primitive 規範統一 + layout 回帰検出基盤完成」。

### VerticalPyramid 3 ファイル分離

`desktop/src/components/company/templates/primitives/`:
- `VerticalPyramid.tsx` (~45 行 component-only export + types re-export)
- `VerticalPyramid.types.ts` (~92 行: VerticalPyramidProps / RailConfig / ColumnConfig / BandConfig / RadialArcConfig)
- `VerticalPyramid.layout.ts` (~190 行: pyramidLayout + 3 file-private helpers, VIEW_W/VIEW_H 再 export)

CONFIG 2 ファイル (`auto-oem-pyramid-utils.ts` / `pharma-rd-structure-utils.ts`) の `import type { VerticalPyramidProps } from "./VerticalPyramid"` を `from "./VerticalPyramid.types"` に微調整。

### 新設テスト 4 ファイル (snapshot 9 件 baseline)

- `VerticalPyramid.test.tsx` (10 ケース): self / topBand / leftRails default+override x / rightRails default x / midColumns linear / bottomRow flatten / jvRow / radialArc viewHeight 拡張 / investor / peers 抑止 / コンポーネント描画
- `VerticalPyramid.layout.test.tsx` (4 snapshot): empty / AUTO_OEM フル model / PHARMA フル model / radialArc 22 affiliates 大量配置
- `AutoOemPyramid.layout.test.tsx` (2 snapshot): Toyota 風 19 nodes / 最小モデル
- `PharmaRdStructure.layout.test.tsx` (2 snapshot): 第一三共 風 21 nodes / 最小モデル

`asProjection()` ヘルパーは LayeredFlow / HubSpoke / RadialCluster 規範 (`Number(p.cx.toFixed(4))` で浮動小数点誤差吸収、`id ソート` で描画順序非依存)。

### snapshot baseline は M-1 リファクタ "後" に取得

ファイル分割は logic 不変の純粋リファクタで、既存 AutoOemPyramid.test.tsx (149 行 / 2 ケース) + PharmaRdStructure.test.tsx (76 行 / 2 ケース) の text-presence assertion で等価性が保証される。Pre/Post の二重 baseline は冗長と判断。

## 副 Wave F Phase 3 パイロット 完了

### サンプル JSON 投入 (S-1)

`tools/analytics/disclosure_kpi_extractor/samples/`:
- `7203_toyota_2025q3.json` (period_end=2025-12-31, 3 metrics: unit_sales=2,600,000台 / asp=3,000,000円 / segment_op=1,000,000百万円)
- `7267_honda_2025q3.json` (同 period, 3 metrics: unit_sales=900,000台 / asp=2,800,000円 / segment_op=280,000百万円)

`confidence_score=0.50〜0.55` で `review_pending` 扱い (概略推測値、後日 IR 数値で再投入予定)。

### alembic 20260507_01 適用

`db/alembic/versions/20260507_01_auto_oem_metrics_catalog.py` で `core.metric_catalog` に 3 metric_key seed (unit_sales / asp / segment_op)。20260504_08 → 20260507_01 適用、Wave F Phase 3 本体着手時に Pharma / Logistics 等の他 pack も同パターンで追加。

### BFF `_frameworks/auto_oem.py` 新設 (ad_supported.py 規範)

```python
if metrics_count >= 2 and has_segment_groups:
    status = "available"; confidence = 0.85 if metrics_count >= 3 else 0.7
elif metrics_count >= 1:
    status = "partial"; confidence = 0.55
elif is_candidate:
    status = "partial"; confidence = 0.45
else:
    status = "unavailable"; confidence = None
```

`_AUTO_OEM_KEYWORDS` 14 語 (自動車 / OEM / 完成車 / Tier1 / 二輪 / 四輪 / vehicle 等) + sector_code 3700/5050。`_AUTO_OEM_METRIC_ALIASES` は 3 metric_key 各 5 alias。`_find_auto_oem_metrics` は kpi_name 正規化マッチと metric_key 直接マッチ両方サポート。`_ad_metrics.py` の `_normalize_metric_name` / `_as_optional_float` と `ad_supported.py` の `_enrich_metrics_with_freshness` を再利用。

### 7203 / 7267 とも `available` 判定

プラン書き出し時の予想 (segment_groups 不在で `partial`) は誤り。Toyota / Honda は既にセグメント情報投入済で `metrics_count=3 AND has_segment_groups → available, confidence=0.85` 判定が走る。

### Desktop AutoOemPyramidPanel 改修

既存 4 ティア segment table (`AutoTierRowGroup`) は完全に無改変。新規 `AutoOemMetricsSection` を panel header 直下に挿入:
- `framework.status === 'unavailable'` または `metrics.length === 0` で完全非表示
- 表示時は `md:grid-cols-3` で 3 metric card (label + value + unit + period + freshness + yoy_pct + ConfidenceBadge)
- `data-testid="auto-oem-metrics-section"` / `auto-oem-metric-{key}` / `auto-oem-metrics-count` でテスト可能

### TypeScript 型対応

`BusinessModelAutoOemFramework` 型を `desktop/src/lib/types/company.ts` に新設、`CompanyBusinessModelFrameworksResponse.frameworks` に `auto_oem` フィールドを **required** で追加。`as unknown as` cast を使わない 4 件の test fixture (AdSupportedFunnel / BusinessModelCanvasView / BusinessModelSupplyChainPanel / CompanyBusinessModelCoverageChips) に minimal `auto_oem` 既定値 (`status='unavailable'`) を追加。残 10 件は `as unknown as` cast でバイパス済 (修正不要)。

## 検証結果

- vitest: 341 files / **1543 ケース** PASS (regression 0)
- vitest 重点: VerticalPyramid 系 19 + AutoOemPyramidPanel 7 (新規 2 含む)
- Desktop typecheck: 0 errors
- ESLint (本タスク 9 ファイル): 0 errors / 0 warnings
- Python ruff (5 ファイル): All checks passed
- pytest BFF frameworks: 10/10 PASS
- pytest disclosure_kpi_extractor: 42/42 PASS
- BFF probe 7203/7267: `frameworks.auto_oem.status='available'`, metrics_count=3, confidence=0.85

## Wave J Phase 2 全 5 段階完了

| Phase | 内容 | 完了セッション |
|---|---|---|
| Phase 1+2 | LayeredFlow secondaryBands+staticMarkers (Railway/Hotel/Insurance 統合) | 2026-05-05 |
| Phase 4+5 | HubSpoke + RadialCluster 新設 (JReit×2 + TradingHouseCluster 統合) | 2026-05-06 |
| **Phase 3** | **VerticalPyramid 3 分離 + AutoOem/Pharma layout snapshot 整備** | **2026-05-07 (本セッション)** |

## 次セッション候補

1. **Wave F Phase 3 本体** (残 11 panel への metrics 配線水平展開: pharma / telecom / bank / j_reit / trading_house / semiconductor / ec / electric_unbundling / logistics / shipping / ad_supported_existing)。各 panel に対し `_frameworks/<X>.py` 規範で BFF builder 新設 + Desktop metrics セクション追加。disclosure_kpi_extractor の 10 packs YAML を消費
2. **Wave D Phase 3 IR 数値再投入** (4324/9449/2433/4751/7203/7267 の概略値を IR 資料から正規値に上書き、confidence ≥ 0.85 化)
3. **Wave L (pixelmatch ビジュアル回帰)** で primitive 4 種 (LayeredFlow / HubSpoke / RadialCluster / VerticalPyramid) の SVG レンダリング baseline を補完
4. **Wave C** (Data Quality Foundation: template_coverage view + Health Panel + override audit)
5. **Wave U** (UI/UX 完成度: Sidebar / CommandPalette テンプレ override 導線)
6. **Desktop 実機検証** (7203 / 7267 で AutoOemPyramidPanel に metrics セクション live 表示、4324 / 8951 / 7203 で見た目 regression 0 を目視確認)
7. **2433 segment_groups 投入** で `frameworks.ad_supported partial → available` 昇格

## 関連ファイル

- VerticalPyramid 3 分離: `desktop/src/components/company/templates/primitives/VerticalPyramid.{tsx,types.ts,layout.ts,test.tsx,layout.test.tsx}` + `__snapshots__/VerticalPyramid.layout.test.tsx.snap`
- layout snapshot: `desktop/src/components/company/templates/{AutoOemPyramid,PharmaRdStructure}.layout.test.tsx` + `__snapshots__/`
- BFF auto_oem framework: `tools/api/decision_api/serving/company/business_model/_frameworks/auto_oem.py` + `__init__.py` 配線
- BFF label: `tools/api/decision_api/serving/company/business_model/_frameworks/_common.py` (`_BUSINESS_FRAMEWORK_LABELS["auto_oem"]="Auto OEM"`)
- Desktop type: `desktop/src/lib/types/company.ts` (`BusinessModelAutoOemFramework`)
- Desktop Panel: `desktop/src/components/company/AutoOemPyramidPanel.{tsx,test.tsx}`
- alembic seed: `db/alembic/versions/20260507_01_auto_oem_metrics_catalog.py`
- サンプル: `tools/analytics/disclosure_kpi_extractor/samples/{7203_toyota,7267_honda}_2025q3.json`
- worklog: `docs/worklogs/20260507-wave-j-phase2-vertical-pyramid.md`
