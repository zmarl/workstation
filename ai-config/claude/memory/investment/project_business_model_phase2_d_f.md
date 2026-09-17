---
name: Business Model Phase 2 — Wave D Phase 1 + Wave F Phase 1 + Wave J residual 完了
description: 2026-05-04 完了。ad_kpi_extractor MVP / AdSupportedFunnelPanel 4 段化 / AutoOemPyramidPanel + TradingHouseClusterPanel 新設 / Wave J 残り 4 テンプレは独自継続を文書化
type: project
originSessionId: 68d7bc72-6e25-4376-9637-8e68811c5dea
---
# Business Model 続編 Phase A/B/C 完了 (2026-05-04)

`C:\Users\kazum\.claude\plans\glimmering-hopping-kitten.md` の Phase A/B/C をすべて 1 セッションで完遂。マスタープラン `mellow-percolating-pike.md` の Wave D Phase 1 + Wave F Phase 1 + Wave J Phase 1 持ち越し判断に対応。

**Why:** Phase 1 (Wave H/I/J/N) + Wave C / A / B-1〜B-4.P2 + Phase 1-4 完了 (40 テンプレ稼働、業種別詳細パネル 5 種) の上に、AdSupportedFunnelPanel をライブ表示化 / 業種別パネル 5→7 / 残テンプレ統合判断、を追加してビジネスモデル図解の「絵だけ」状態を脱却する。

**How to apply:** 次セッションで実機検証 + 残サンプル投入 + Wave F-3〜F-7 / Wave D-3-2 (KPI packs YAML) / Wave E (Supply Chain Tier 2-4) を着手するときの起点。

## Phase A: Wave D Phase 1 — `ad_kpi_extractor` MVP

### 完成ファイル
- `tools/analytics/ad_kpi_extractor/` (新設、main.py / repository.py / schema.py / prompt_template.md / README.md / samples/_template.json + 4751_cyberagent_2025q3.json)
- `tools/api/decision_api/serving/company/business_model/_frameworks/ad_supported.py` (status 判定拡張、freshness 付与)
- `desktop/src/components/company/AdSupportedFunnelPanel.tsx` (4 段ファネル化)
- `desktop/src/lib/types/company.ts` (`BusinessModelMetricFreshness` / `meta` フィールド追加)
- pytest 25 件 + framework regression 10 件 + vitest 4 件すべて通過

### 設計判断
- **`extract_method='external_structured'`** を repository.py で固定既定。`get_company_kpis` (`serving/_company.py:232`) が同 SQL filter で固定なため、これ以外で書くと AdSupportedFunnelPanel に表示されない
- **`source_basis='ad_kpi_extractor'`** で `core.issuer_metric_profile` を独自管理。`manual` / `edinet_db` / `ir_ops_collector` の他 source_basis は触らない
- `confidence_score >= 0.85` → `adoption_status='auto_accepted'` (DELETE+INSERT)
- BFF status 切替: `metrics_count >= 2 AND has_segment_groups` → `available`、`metrics_count == 1` → `partial`、`is_candidate` のみ → `partial`
- Freshness 閾値: 120 日以内 fresh / 240 日以内 aging / それ以上 stale (mart.vw_sector_stat_signal_latest より緩め)
- Confidence 3 段: 4+ → 0.85 / 3 → 0.75 / 2 → 0.7
- worklog: `docs/worklogs/20260504-wave-d-phase1-ad-kpi-extractor.md`

## Phase B: Wave F Phase 1 — AutoOemPyramidPanel + TradingHouseClusterPanel

### 完成ファイル
- `desktop/src/components/company/AutoOemPyramidPanel.tsx` (4 ティア: OEM / parts / finance / other)
- `desktop/src/components/company/TradingHouseClusterPanel.tsx` (7 cluster: 金属 / エネルギー / 機械 / 化学 / 食料 / 生活 / 金融)
- `desktop/src/components/company/templates/auto-oem-panel-utils.ts` (segment_name → tier classifier)
- `desktop/src/components/company/templates/trading-house-panel-utils.ts` (segment_name → cluster classifier、SVG 用 keyword と整合)
- `desktop/src/lib/company-tabs.ts` (`bm-auto-oem` / `bm-trading-house` SnapshotTab 追加 + 4 マップ全同期)
- `desktop/src/components/company/BusinessModelCanvasView.tsx` (`auto_oem` / `trading_house` BusinessModelTabId 追加 + 2 ゲート + dispatcher)
- `desktop/src/pages/CompanySnapshot.tsx` (preload + dispatch 2 タブ)
- vitest 10 件 + 既存 59 件 + 全体 982 件 regression なし

### 設計判断
- **BFF 改修なし**: BankFundsFlowPanel と同パターンで client-side 分類。`segment_groups` のみ使用
- **AutoOemPyramidPanel** は Tier 1/2/3 supply_chain 推定なし版。Tier 2/3 は **Wave E (Supply Chain Tier 2-4 推定)** で別扱いと panel footer で明記
- **TradingHouseClusterPanel** の keyword は `trading-house-cluster-utils.ts` (SVG 用) と意図的に同一。drift 防止は JSDoc コメントで運用
- 既存 `templates/AutoOemPyramid.tsx` / `templates/TradingHouseCluster.tsx` (SVG 図) は Diagram タブで継続表示。Panel は table + 集計の併設パターン (Bank/Pharma 同型)
- worklog: `docs/worklogs/20260504-wave-f-phase1-auto-trading-panels.md`

## Phase C: Wave J 残り 4 テンプレ — 独自継続を文書化

### 結論
Railway / HotelLeisure / InsuranceThreeMargin / TradingHouseCluster の 4 テンプレすべて **独自実装継続**。3 プリミティブ (LayeredFlow / VerticalPyramid / HorizontalLanes) の API surface に綺麗に乗らないことを実装で検証して文書化。

### 各テンプレの判断
- **Railway**: customer (kind="customer") が y=180 で self と segments の間に horizontal-band として配置されており、LayeredFlow の `bottomRow.kinds` 相当の `topBand.kinds` 機能なし。LayeredFlow 拡張は API 表面肥大化のため見送り
- **HotelLeisure**: distributor (kind="distributor") が y=180、customer (kind="customer") が y=460 で同種の問題。Railway と同パターン
- **InsuranceThreeMargin**: 4 layer は LayeredFlow fixed-slot で配置可能。ただし 3 利源 (死差/利差/費差) の **synthetic chip 3 つを左レーン静的配置** が本テンプレ最大の付加価値で、汎用化メリット低
- **TradingHouseCluster**: 放射状アーク layout はマスタープラン通り独自継続

### Wave J Phase 2 候補 (将来別セッション)
1. `LayeredFlow` に `secondaryBand` 拡張 → Railway / Hotel 統合 (~250 行縮減)
2. `LayeredFlow` / `VerticalPyramid` に `staticMarkers` 拡張 → Insurance の 3 利源吸収 (~80 行縮減)
3. `primitives/RadialCluster.tsx` 新設 → TradingHouse 統合 (~150 行縮減)

新テンプレ追加時に同パターンが再来したら着手判断。

worklog: `docs/worklogs/20260504-wave-j-residual-templates-decision.md`

## Outstanding (次セッション候補)

### 投入運用 (高優先)
1. **残り 7 ad_kpi サンプル JSON 投入**: 4324 電通 / 9449 GMO / 2433 博報堂 × 2-4 四半期。`prompt_template.md` を見ながら Claude Code 対話で IR 資料 → JSON
2. **alembic upgrade head + import-json 実機**: 4751_cyberagent_2025q3.json 投入 → BFF が status='available' を返すこと → AdSupportedFunnelPanel が live 数値を出すことを目視

### Wave 拡張 (中優先)
3. **Wave F-3〜F-7**: EcMarketplace / SemiconductorSupply / ElectricUnbundling / LogisticsHub / ShippingFleet パネル化。Phase B と同パターン
4. **Wave D-3-2 (汎用化)**: `ad_kpi_extractor` → `disclosure_kpi_extractor` リネーム + 9 packs YAML
5. **Wave E**: industry_tier_chains.yaml + tier_inferer.py + supply-chain endpoint に tier_depth 追加

### 関連
- TradingHouseCluster 詳細パネルが扱える「取扱高」(現状 segment 開示にない) は別 Wave で検討
- panel_type フィールドの BFF 側活用 (現状全件 "diagram") は Wave K で
