---
name: Wave J Phase 2 Phase 1+2 + Wave D Phase 3 着地完了 (2026-05-05)
description: LayeredFlow primitive を 6 props 追加で拡張し Railway/Hotel/Insurance 統合 (~276 行縮減)。並走で 4751 ad_supported metrics 4 件投入し AdSupportedFunnelPanel が live 数値表示する経路の稼働確認。残: HubSpoke / RadialCluster / 観測値追加 / Wave F Phase 3
type: project
originSessionId: bcc52aac-09c0-4053-82f0-c0f421f9e6c9
---
# Wave J Phase 2 Phase 1+2 + Wave D Phase 3 着地完了 (2026-05-05)

`C:\Users\kazum\.claude\plans\idempotent-sprouting-engelbart.md` の主・副スコープを 1 セッションで完遂。

**Why:** マスタープラン v2 (`polymorphic-inventing-widget.md`) の Wave J Phase 2 5 段階のうち Phase 1+2 を進めて 12 特殊テンプレ統合の主要部分を吸収しつつ、disclosure_kpi_extractor の `core.metric_observations` 着地を BFF→Desktop 経路で実証する。

**How to apply:** 次セッションで Wave J Phase 2 Phase 4+5 (HubSpoke + RadialCluster) または Wave F Phase 3 (12 panel への metrics 配線) に着手するときの起点。

## Wave J Phase 2 Phase 1+2 完了

### LayeredFlow primitive 拡張 (3 ファイル分離)

`desktop/src/components/company/templates/primitives/` 配下:
- `LayeredFlow.tsx` (38 行 component-only)
- `LayeredFlow.types.ts` (~140 行: LayerAnchor 派生 / SecondaryBandConfig / StaticMarker 等)
- `LayeredFlow.layout.ts` (~280 行: layeredLayout + 各種 placeXxx ヘルパー)

**追加した 6 props 機能**:
1. horizontal-band anchor に `cx?` (Insurance operating の左寄せ band 用)
2. fixed-slot anchor に `centered?` (Insurance asset の verticalSlots 中心配置用)
3. LayerDef に `stubKind?` / `nodeKindOverride?` (Insurance asset の segment→finance 変換用)
4. LeftoverPolicy に `"right-rail-stack"` + `rightRailConfig` (Hotel/Railway leftover 用)
5. `secondaryBands?` (Hotel/Railway の上下 band: customer / distributor)
6. `staticMarkers?` + `additionalRows?` (Insurance 3 利源 / Railway logistics 別行)

### 3 テンプレ wrapper 化 (~276 行縮減)

| テンプレ | 旧 | 新 wrapper | 新 utils | 合計 |
|---------|-----|-----------|----------|------|
| RailwayNetwork.tsx | 214 | 22 | +132 (railway-network-utils.ts) | -60 |
| HotelLeisure.tsx | 226 | 22 | +131 (hotel-leisure-utils.ts) | -73 |
| InsuranceThreeMargin.tsx | 292 | 22 | +127 (insurance-three-margin-utils.ts 新設) | -143 |
| **計** | **732** | **66** | **+390** | **-276** |

各テンプレの CONFIG (declarative) を `*-utils.ts` に切り出し、wrapper TSX は `<LayeredFlow {...CONFIG} />` のみ。Bank/Telecom/Electric の既存パターンと統一。

### vitest 拡充

- `LayeredFlow.test.tsx` 新設 9 ケース (cx 上書き / centered fixed-slot / secondaryBands / staticMarkers / right-rail-stack / additionalRows / DOM 描画)
- `*.layout.test.tsx` 3 新設 6 snapshot ケース (Wave L 簡易代替: Placed[] の cx/cy/w/h 配列を toMatchSnapshot)

### 検証結果

- vitest: 全テンプレ 188 件 + LayeredFlow 9 件 + BusinessModel{Diagram,CanvasView} 20 件 全通過
- typecheck: 0 errors
- lint: 0 errors / 0 warnings
- 既存 LayeredFlow 利用 3 テンプレ (Bank/Telecom/Electric 15 件) regression なし
- worklog: `docs/worklogs/20260505-wave-j-phase2-layered-flow-extension.md`

### 設計判断

- **Insurance を完全 LayeredFlow 化** (メモリ `project_business_model_phase2_d_f.md` の「独自継続を文書化」を覆す): 6 props 追加で 4 layer + 3 利源 + 4 stakeholder rail を全表現可能と判明
- **`__testOnlyLayeredLayout` を export しない**: react-refresh ESLint 警告回避のため `LayeredFlow.layout.ts` から `layeredLayout` を直 export
- **layout snapshot ベース回帰**: Wave L (pixelmatch) 不在の中、座標配列レベルの snapshot で Insurance topLeftCorner の x=120 → x=110 ずれを検出して修正できた

## Wave D Phase 3 着地検証 完了

### 投入手順 (1 サンプル)

```
uv run alembic -c db/alembic/alembic.ini current   # 20260504_08 (head)
uv run python -m tools.analytics.disclosure_kpi_extractor.main init-db --pack ad_supported   # 8 keys
uv run python -m tools.analytics.disclosure_kpi_extractor.main import-json \
  --input tools/analytics/disclosure_kpi_extractor/samples/4751_cyberagent_2025q3.json \
  --pack ad_supported   # imported metrics=4
```

### DB 着地確認

`core.metric_observations` 4 行投入 (`extract_method='external_structured'`):
- ad_revenue: 92500 百万円 / confidence=0.900 / auto_accepted
- advertisers: 5200 社 / confidence=0.600 / review_pending
- dau: 1850 万人 / confidence=0.700 / review_pending
- mau: 3100 万人 / confidence=0.700 / review_pending

`core.issuer_metric_profile` 4 行 (`source_basis='ad_kpi_extractor'`)。

### BFF 経路稼働確認

- `get_company_kpis('4751', limit=200)` 4 行返却
- `get_company_business_model_frameworks('4751').frameworks.ad_supported`:
  - `status='available'`
  - `confidence=0.85`
  - `metrics` 配列 4 件 (live data)
  - `freshness='stale'` (as_of=2025-08-15 から 263 日経過、240 日 stale 閾値超え) — 想定通り、新四半期で fresh 化

### Desktop 経路 (実機目視は次セッション)

`AdSupportedFunnelPanel.tsx` は live 数値経路 (`frameworks.ad_supported.metrics`) を実装済。BFF 応答が乗ったので Desktop 起動時に 4 metrics の数値カードが表示されるはず (実機目視は次 closeout)。

## 次セッション候補

1. **Wave J Phase 2 Phase 4** (HubSpoke 新規プリミティブ → JReitSponsorship + JReitSpecialized 統合、~200 行縮減見込み)
2. **Wave J Phase 2 Phase 5** (RadialCluster 新規プリミティブ → TradingHouseCluster 統合、~150 行縮減見込み)
3. **Wave D Phase 3 観測値追加投入** (4324/9449/2433 × 4Q + 4751 残期分。prompt_template.md に従って Claude Code 対話で IR 資料 → JSON 化)
4. **Wave F Phase 3 metrics 配線** (`_industry_panels/*.py` に `_attach_metrics()` 統一 helper、12 panel に live data 注入。EC + Semiconductor をパイロットで Plan agent 設計済)
5. **Desktop 実機検証** (4751 を開いて AdSupportedFunnelPanel が 4 metrics を live で表示することを目視)
6. **Wave L (ビジュアル回帰)** (pixelmatch ベース 40 テンプレ × 3 銘柄)

## 関連ファイル

- LayeredFlow primitive: `desktop/src/components/company/templates/primitives/LayeredFlow.{tsx,types.ts,layout.ts,test.tsx}`
- 3 テンプレ wrapper: `desktop/src/components/company/templates/{InsuranceThreeMargin,HotelLeisure,RailwayNetwork}.tsx`
- 3 テンプレ CONFIG: `desktop/src/components/company/templates/{insurance-three-margin-utils,hotel-leisure-utils,railway-network-utils}.ts`
- 3 layout snapshot: `desktop/src/components/company/templates/{InsuranceThreeMargin,HotelLeisure,RailwayNetwork}.layout.test.tsx`
- ad_kpi sample: `tools/analytics/disclosure_kpi_extractor/samples/4751_cyberagent_2025q3.json`
- BFF live 経路: `tools/api/decision_api/serving/_company.py:198-242` (get_company_kpis) → `serving/company/business_model/_ad_metrics.py:_find_ad_metrics` → `_frameworks/ad_supported.py`
