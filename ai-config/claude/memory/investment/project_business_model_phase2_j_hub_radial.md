---
name: Wave J Phase 2 Phase 4+5 + Wave D Phase 3 横展開 着地完了 (2026-05-06)
description: HubSpoke / RadialCluster 新規 primitive 2 種を 3 ファイル分離で追加し JReitSponsorship/JReitSpecialized/TradingHouseCluster の 3 テンプレを wrapper 化 (合計 -404 行 wrapper 比較)。並走で 4324/9449/2433 の ad_supported 各 4 metrics 投入し BFF が 4324/9449 で `available`、2433 で `partial` を返却することを確認
type: project
originSessionId: 754bef8b-3ce5-4506-a81d-3eea7de9441d
---
# Wave J Phase 2 Phase 4+5 + Wave D Phase 3 横展開 着地完了 (2026-05-06)

`C:\Users\kazum\.claude\plans\vast-finding-phoenix.md` の主・副スコープを 1 セッションで完遂。

**Why:** マスタープラン v2 (`polymorphic-inventing-widget.md`) Wave J Phase 2 5 段階のうち Phase 1+2 は前セッション (2026-05-05) で完了済み。残りの 3 段階 (Phase 3 = VerticalPyramid 拡張、Phase 4 = HubSpoke 新設、Phase 5 = RadialCluster 新設) のうち Phase 4+5 を本セッションで一括完了し、放射状トポロジ系のテンプレ統合を完了させる。並走で disclosure_kpi_extractor の `core.metric_observations` 着地を 3 銘柄に水平展開し、BFF→Desktop 経路の堅牢性を確認する。

**How to apply:** 次セッションで Wave J Phase 2 Phase 3 (VerticalPyramid 拡張で AutoOemPyramid / PharmaRdStructure 統合) または Wave F Phase 3 (12 panel への metrics 配線) に着手するときの起点。

## Wave J Phase 2 Phase 4 (HubSpoke) 完了

### HubSpoke primitive (3 ファイル分離)

`desktop/src/components/company/templates/primitives/`:
- `HubSpoke.tsx` (45 行 component-only export + type re-export)
- `HubSpoke.types.ts` (95 行: HubSpokeProps / SpokeConfig / SpokeLayoutMode 3 種 / TopBarConfig / SideCornerConfig / BottomBarConfig)
- `HubSpoke.layout.ts` (210 行: hubSpokeLayout + 6 file-private helpers)

**SpokeLayoutMode 3 種**:
- `horizontal-slots`: nodes が `horizontalSlots(n, cx, spacing)` で水平配置 (Sponsorship affiliate cy=530)
- `vertical-slots-centered`: `verticalSlots(n, baseY, gap)` で baseY 中心に縦配置 (subsidiary / affiliate 縦列)
- `fixed-stack`: `cy = baseY + i * gap` で縦積み (finance 信託銀行 cy=420 / 510)

### JReit 2 テンプレ wrapper 化

| テンプレ | 旧 | 新 wrapper | utils 追加 | 純減 |
|---------|----|-----------|-----------|-----|
| JReitSponsorship.tsx | 138 | 23 | +51 (j-reit-sponsorship-utils.ts に CONFIG 追記) | -64 |
| JReitSpecialized.tsx | 167 | 50 (badge JSX 含) | +75 (j-reit-specialized-utils.ts 新設、JREIT_SUB_TYPE_LABEL/JREIT_SUB_TYPE_PORTFOLIO_LABEL/CONFIG) | -42 |

**Specialized の sub_type badge 保持パターン**: HubSpoke の `prepend` prop に `<div data-testid="j-reit-sub-type-badge" ...>` JSX を渡す。SVG の前面に出現するため既存 `getByTestId` テストは無変更で通る。

### 旧 layout 等価性確認 (snapshot 値の手計算照合)

旧 jReitLayout / jReitSpecializedLayout の出力は verticalSlots / horizontalSlots / 純粋な数値配置で構成されているため、snapshot の (cx, cy, sublabel) を旧コードのリテラルと逐一突き合わせて px 単位の等価性を確認:
- Sponsorship: parent@(480,80) / regulator@(120,320) / market_operator@(840,80) / subsidiary cx=840 cy=320 sublabel=資産運用会社 / affiliate cx=480 cy=530 / finance cx=120 cy=420,490 / investor@(480,610) / peer@(480,610) すべて完全一致
- Specialized: parent@(480,80) sublabel=Sponsor / regulator@(130,80) / market_operator@(830,80) / subsidiary cx=130 cy=320 sublabel=Asset Manager / affiliate cx=830 cy=320 sublabel=Custodian / finance cx=830 cy=510 sublabel=信託銀行 / investor@(480,600) すべて完全一致

## Wave J Phase 2 Phase 5 (RadialCluster) 完了

### RadialCluster primitive (3 ファイル分離)

`desktop/src/components/company/templates/primitives/`:
- `RadialCluster.tsx` (33 行 wrapper)
- `RadialCluster.types.ts` (60 行: RadialClusterProps / RadialClusterDef / FixedRailConfig)
- `RadialCluster.layout.ts` (210 行: radialLayout + 6 file-private helpers)

**snake 配置数学を厳密再現**:
```
distance = stride * Math.floor(i/2)
lateral = (i%2===0 ? 1 : -1) * lateralOffset * Math.ceil(i/2)
dx = cos(angle)*distance + cos(angle+π/2)*lateral
dy = sin(angle)*distance + sin(angle+π/2)*lateral
```
固定値: anchorRadius=250, stride=70, lateral=38, angleStartRad=π/3, angleSweepRad=4π/3 (これらを props 化、N-cluster 一般化)。`Math.max(1, n-1)` で n=1 時の除算を回避。

### TradingHouseCluster wrapper 化

194 行 → 22 行 (-89%)。`trading-house-cluster-utils.ts` に TRADING_HOUSE_CONFIG + TRADING_HOUSE_CLUSTER_DEFS を追加 (~50 行)。`TRADING_CLUSTER_KEYWORDS` / `classifyTradingCluster` / `TradingCluster` 既存 export は不変 (TradingHouseClusterPanel との drift 防御維持)。

### 設計判断: classifier を関数として props inject

`RadialClusterDef` に keywords を含めず、classifier を `(node) => string | null` で渡す設計。これにより keyword 辞書の所在は呼び出し側 (utils) に残り、SVG-side / panel-side の二重管理 (drift 防御) が壊れない。Single Source 化は別 PR で扱う。

### TradingHouse snapshot 値検算

7 cluster anchor の極座標を手計算で検証:
- s-metal → metals (i=0)、angle=π/3 (60°)、anchor=(605, 546.506)、snake i=0 で (605, 546.506) ✓
- s-energy → energy (i=1)、angle≈100°、anchor=(436.59, 576.20) ✓
- s-food → food (i=4)、angle=π/3+8π/9 (220°)、anchor=(288.49, 169.30) ✓
- s-fin → finance (i=6)、angle=5π/3 (300°)、anchor=(605, 113.49) ✓

すべて旧 tradingLayout と 4 桁精度一致。

## Wave D Phase 3 横展開 完了

### 投入 3 銘柄

`tools/analytics/disclosure_kpi_extractor/samples/`:
- `4324_dentsu_2025q3.json` (period_end=2025-09-30, 12月期Q3)
- `9449_gmo_2025q3.json` (period_end=2025-09-30, 12月期Q3)
- `2433_hakuhodo_2025q3.json` (period_end=2025-12-31, 3月期Q3)

各銘柄 4 metrics: ad_revenue / advertisers / dau / mau。confidence_score=0.5〜0.55 で `review_pending` 扱い (副スコープ要件「概略値で代替、人間が IR 数値提示時に再投入」)。

### BFF 経路稼働確認

`get_company_business_model_frameworks(code)` で frameworks.ad_supported を確認:
- 4324: status=`available`, confidence=0.85, metrics_count=4
- 9449: status=`available`, confidence=0.85, metrics_count=4
- 2433: status=`partial`, confidence=0.55, metrics_count=4 (segment_groups 不在で partial 止まり)
- 4751 (前セッション regression): status=`available`, confidence=0.85, metrics_count=4 維持

### 2433 partial の理由と follow-up

`_build_ad_supported_framework` は `metrics_count >= 2 AND has_segment_groups` で available 判定する。2433 博報堂は business_model.segment_groups が未整備のため partial 止まり。`tools/api/decision_api/serving/company/business_model/_segment_groups.py` 経路で segment_groups を投入すれば available に昇格可能 (別タスク)。

## 検証結果

- vitest: 全 54 ファイル 237 ケース PASS (regression 0)
- 私の変更ファイル lint: 0 errors / 0 warnings (既存 2 errors は本タスク無関係)
- vitest 新規: HubSpoke 13 + RadialCluster 10 + JReit/TradingHouse layout snapshot 6 = 29 件全 PASS、snapshot 9 件 baseline 取得
- pytest disclosure_kpi_extractor: 42 件全 PASS

## 次セッション候補

1. **Wave J Phase 2 Phase 3** (VerticalPyramid 拡張で AutoOemPyramid / PharmaRdStructure 統合、~300 行縮減見込み)
2. **Wave F Phase 3 metrics 配線** (12 panel に `_attach_metrics()` 統一 helper でライブデータ注入、disclosure_kpi_extractor の 10 packs YAML を消費)
3. **2433 segment_groups 投入** で `partial → available` 昇格
4. **Wave D Phase 3 IR 数値再投入** (4324/9449/2433/4751 の概略値を IR 資料から正規値に上書き、confidence ≥ 0.85 化)
5. **Wave L (pixelmatch ビジュアル回帰)** で layout snapshot を補完
6. **Desktop 実機検証** (4324/9449/2433 で AdSupportedFunnelPanel が live 数値表示、8951 で HubSpoke の見た目 regression 0 を目視確認)
7. **TradingHouseClusterPanel keyword Single Source 化** (drift 防御強化)

## 関連ファイル

- HubSpoke primitive: `desktop/src/components/company/templates/primitives/HubSpoke.{tsx,types.ts,layout.ts,test.tsx,layout.test.tsx}`
- RadialCluster primitive: `desktop/src/components/company/templates/primitives/RadialCluster.{tsx,types.ts,layout.ts,test.tsx}`
- JReit wrapper: `desktop/src/components/company/templates/{JReitSponsorship,JReitSpecialized}.tsx` + `j-reit-{sponsorship,specialized}-utils.ts`
- JReit layout snapshot: `desktop/src/components/company/templates/{JReitSponsorship,JReitSpecialized}.layout.test.tsx`
- TradingHouse wrapper: `desktop/src/components/company/templates/TradingHouseCluster.tsx` + `trading-house-cluster-utils.ts` (TRADING_HOUSE_CONFIG / TRADING_HOUSE_CLUSTER_DEFS 追加)
- TradingHouse layout snapshot: `desktop/src/components/company/templates/TradingHouseCluster.layout.test.tsx`
- 副スコープ samples: `tools/analytics/disclosure_kpi_extractor/samples/{4324_dentsu,9449_gmo,2433_hakuhodo}_2025q3.json`
- worklog: `docs/worklogs/20260506-wave-j-phase2-hub-radial.md`
