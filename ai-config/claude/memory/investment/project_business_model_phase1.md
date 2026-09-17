---
name: Business Model Phase 1 (Wave H/I/J/N) 完了 + Wave C 完結 / Wave J 残 5 件統合
description: 2026-05-04 完了。SSOT YAML / BFF 分割 / Desktop プリミティブ統一 / whitelist lint。同日 Wave C 完結 + VerticalPyramid / LayeredFlow 5 件統合。Phase 2 着手指示
type: project
originSessionId: 56e18cff-78d0-476a-b422-1a6cd0fcf216
---
# Business Model Refactor Phase 1 完了 (2026-05-04)

C:\Users\kazum\.claude\plans\mellow-percolating-pike.md の Phase 1 全 4 Wave が完了。同日 Phase 2 の Wave C と Wave J 残り 5 件統合も完了。

**Why:** 業種別ビジネスモデル図解 (40 テンプレ) の保守性 / カバレッジ品質を Phase 2 残り (Wave D/E) に進める前に整える。
**How to apply:** Phase 2 残り着手時にこのサマリーを起点にする。各 Wave の worklog は docs/worklogs/ に保管。

## 完了 Wave

### Wave H — SSOT YAML 駆動化 (Phase 1+2+3+4)
- `db/seeds/business_model/template_definitions.yaml` を全 40 テンプレの SSOT に
- `tools/dev/template_codegen.py` が 4 kind (whitelist_only / whitelist_and_sector / sub_type_map / custom) に対応
- generated 3 ファイル: `_template_rules_generated.py` (486 行) / `_industry_template_generated.ts` / `_template_metadata_generated.ts`
- Makefile (codegen / codegen-check) + ci-test-lint.yml に template_codegen --check 統合済
- worklog: `20260504-wave-h-phase1-ssot-pilot.md` / `20260504-wave-h-phase3-4-ssot-complete.md`

### Wave I — BFF business_model.py 分割
- `tools/api/decision_api/serving/company/business_model.py` (4242 行) を `business_model/` ディレクトリ化
- 内訳: `_template_rules.py` / `_coverage.py` / `_supply_chain.py` / `_frameworks/{value_chain, five_forces, platform_marketplace, saas_metrics, ad_supported}.py` / `_industry_panels/{pharma_pipeline, telecom_layer, bank_funds, j_reit_sponsorship}.py` / `_ad_metrics.py` / `api.py`
- import path 後方互換維持 (`__init__.py` で re-export)
- 全 1601 テスト pass、ruff 全件 pass
- worklog: `20260504-wave-i-bff-split.md`

### Wave J — Desktop プリミティブ統一 (横並び 5 レーン + VerticalPyramid + LayeredFlow)
- `desktop/src/components/company/templates/primitives/HorizontalLanes.tsx` で 18 件統合済 (元 wave)
- 同日追加: `primitives/VerticalPyramid.tsx` 新設 → AutoOemPyramid / PharmaRdStructure を縮減 (各 145→24 / 161→23 行)
- 同日追加: `primitives/LayeredFlow.tsx` 新設 → ElectricUnbundling / TelecomThreeLayer / BankFundsFlow を縮減 (各 173→23 / 165→23 / 205→24 行)
- LayeredFlow は anchor 2 variant (`horizontal-band` / `fixed-slot`) と leftoverPolicy 3 種 (`balance-to-smallest` / `above-self-band` / `below-bottom-band`) で 3 テンプレを賄う
- 残り 17 件は構造特殊扱いで保留 (持ち越し)
- worklog: `20260504-wave-j-desktop-primitives.md` / `20260504-wave-c-template-health-and-wave-j-primitives.md`

### Wave N — whitelist YAML lint と薄テンプレ拡充
- `tools/dev/whitelist_lint.py` 新設 (`--check` / `--report`)。DB 不要、DDL から static に representative_codes 抽出
- `tools/analytics/business_model_graph_coverage/main.py expand-whitelist <name>` サブコマンド追加 (sub_sectors からの提案、`--apply` で書き換え)
- 薄テンプレ 7 件 (textile_fiber / paper_pulp / mining_extraction / petroleum_energy / tire_rubber / steel / metal_products) を 5〜9 銘柄に拡充
- airline は例外 (3 銘柄のまま)
- ci-test-lint.yml に whitelist_lint --check 統合済
- worklog: `20260504-wave-n-whitelist-lint.md`

### Wave C — Data Quality Foundation (2026-05-04 同日完了)
- `analytics.business_model_template_coverage` / `business_model_template_health` view 新設 (`db/alembic_revisions/20260504_007_template_coverage_view.sql` + `db/alembic/versions/20260504_07_*.py`)
- has_canvas/has_primary_edges/has_segments は backlog status と支援テーブル (canvas_llm_summaries / supply_chain_edges / segment_*) を OR 結合で derive
- BFF: `_business_model_coverage.py` 新設、`/api/v1/analytics/business-model/template-coverage` 一覧 + drill-down endpoint
- Desktop: `BusinessModelTemplateHealthPanel.tsx` 新設 (40 行マトリクス + drill-down モーダル、health_class 5 段色分け)
- CLI: `business_model_graph_coverage audit-overrides` サブコマンド (rule 再適用 vs backlog の drift 検出、CI gate 用 exit code 1、`--ignore-pending-backfill` フラグ)
- pytest 15/15 passed、vitest 177/177 passed
- 重要乖離: マスタープラン記載の `analytics.business_model_template_overrides` / `core.segment_groups` / `core.canvas_documents` は全て未実装 → view を OR 結合で derive、override audit を rule 再適用方式に縮退
- worklog: `20260504-wave-c-template-health-and-wave-j-primitives.md`

## Phase 2 残り着手指示 (Wave D / E)

マスタープラン C:\Users\kazum\.claude\plans\mellow-percolating-pike.md の以下セクションを参照:

- **Wave D** (行 526〜): KPI Auto Ingest。`tools/analytics/ad_kpi_extractor/` → `disclosure_kpi_extractor` リネーム + 9 packs YAML、4 銘柄 (4324 / 4751 / 9449 / 2433) × 4Q の DAU/MAU/CPM/ad_revenue 抽出 → `core.metric_observations` 投入、AdSupportedFunnelPanel ライブ表示
- **Wave E** (行 660〜): Supply Chain Tier 2-4 推定。`industry_tier_chains.yaml` + `tier_inferer.py` + J-PlatPat IPC 連携 + Wave 5 ingest 本番化、`supply-chain` endpoint に `tier_depth` 追加 (max 4)

## 持ち越し宿題

1. **Wave J 残り 17 件**: VerticalPyramid 派生候補は InsuranceThreeMargin、LayeredFlow 派生候補は Securities / OtherFinancial / RailwayNetwork / HotelLeisure。別プリミティブ必要なのは JReit 系 / TradingHouse / AdSupportedFunnel
2. **panel_type フィールドの BFF 側活用** (現状全件 "diagram")
3. **pre-commit framework 導入**
4. **Wave A-3** (`analytics.business_model_template_overrides` テーブル新設 + Desktop UI 経由の手動 override 機能) — Wave C-4 の audit を将来テーブル監査に格上げするための前提
