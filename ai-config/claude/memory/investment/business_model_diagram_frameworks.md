---
name: Business Model 図解フレームワーク・業種別パターン
description: ビジネスモデル図解機能のカバレッジ拡大時に参照する汎用フレームワーク 8 種 + 業種別パターン 10 種の要約とギャップ、ロードマップ参照先
type: project
originSessionId: 4f40e8f5-2aec-4ead-9940-5d6ab585109d
---
# Business Model Diagram Coverage Roadmap (2026-04-21 調査)

## 現行カバレッジ (正本: `desktop/src/components/company/business-model-types.ts`)

- ノード 12 種 / エッジ 9 種 / tier 5 種 (primary / stakeholder / meta / llm_inferred / text_inferred)
- SVG ベース手書きレイアウト、Mermaid 不使用
- データ源: `analytics.supply_chain_edges` (tier_source=primary のみ現在は書き込まれる) + `analytics.edinet_text_partners` (text_inferred v2+v3) + `analytics.peer_companies` + 業種マスタ
- P0-1 状態 (2026-04-21): `analytics.supply_chain_edges.tier_source VARCHAR(32)` スキーマと BFF 3-leg UNION / Desktop 3 tier 分岐は **保持**。ただし Qwen ローカル版 classifier (`tools/analytics/supply_chain_llm_classifier/`) は **同日廃止 (ADR docs/decisions/supply-chain-llm-tier.md)**。既存の `tier_source='llm_inferred'` 5 行は DELETE 済。現時点で llm_inferred tier への書き込み経路は存在せず、次セッション以降で Claude API / Codex 委任版の classifier を設計予定。

## 汎用フレームワーク 8 種 (調査済み)

1. Business Model Canvas 9 ブロック — Value Proposition / Revenue Streams / Cost Structure / Channels が未対応
2. Porter's Value Chain — 活動軸 (Inbound / Operations / Outbound / Marketing / Service + Support 4) が未対応
3. Porter's Five Forces — New Entrants / Substitutes ノード未対応
4. Platform Canvas / Two-Sided Market — プラットフォーム全般未対応
5. SaaS Metrics Map — MRR / ARR / Churn / CAC / LTV / Rule of 40 未対応
6. Subscription / Freemium Funnel — Landing → Free → Paid の変換構造未対応
7. Marketplace Model — Platform Fees (Take Rate) / Trust & Safety ノード未対応
8. Ad-Supported Model — User / Attention Inventory / Ad Network 未対応

## 業種別図解パターン 10 業種 (調査済み)

1. 自動車 (7203) — OEM Tier1-2-3 ピラミッド。affiliate TOP_N=3 で不足
2. 銀行 (8306) — 資金フロー (預金/貸出) + 手数料収益構成未対応
3. 通信 (9432) — Network / Device / Content 3 層モデル未対応
4. 小売 (Seven & i) — FC / 共同配送ハブ / PB-NB 未対応
5. 不動産 J-REIT — スポンサー / 資産運用会社 / 信託銀行の三角構造未対応
6. 電力 — 発電 / 送配電 / 小売 unbundling 未対応
7. 総合商社 — トレーディング + 事業投資 + 業種クラスタリング未対応
8. 海運 — 船種セグメント + 自社/傭船比率 (chips で補完可)
9. 製薬 (4568) — R&D Pipeline 5 Phase GANTT 未対応
10. 保険 (8766) — 保険料/準備金/運用資産 + 3 利源 (死差/利差/費差) 未対応

## ロードマップ (優先度) — v2 マスタープラン基準 2026-05-04 更新

**Why:** v1 (mellow-percolating-pike.md) 12 Wave の基盤層 (H/I/J Phase1/N) + Wave A + F Phase 1-2 + D Phase 1 が 2026-05-04 までに完了。同日 v2 並列 3 Wave (C / U / D Phase 2 設計) も完了。残 Wave を Phase 1〜5 で段階展開。

**How to apply:** 次セッションは Wave J Phase 2 (LayeredFlow / VerticalPyramid 等プリミティブ統合) または Wave E (Supply Chain Tier 2-4 推定) から着手可能。基盤完了済のため即実装可能。

### 完了済 (2026-05-04 時点)
- **Wave H** (テンプレ定義 YAML SSOT + codegen): Phase 1+2+3+4 完了 (40 件 YAML 駆動、business_model.py -612 行)
- **Wave I** (BFF business_model.py の機能別 9 module 分割)
- **Wave J Phase 1** (HorizontalLanes 18 テンプレ統合)
- **Wave N** (whitelist YAML lint + 薄領域拡充)
- **Wave A** (J-REIT specialized + Wholesale general 新設、whitelist 398 銘柄、手動切替 UI、coverage backlog DDL)
- **Wave F Phase 1-2** (AutoOemPyramid + TradingHouseCluster + EC / Semiconductor / Electric / Logistics / Shipping パネル、12 種詳細パネル)
- **Wave D Phase 1** (ad_kpi_extractor MVP、4751_cyberagent_2025q3.json サンプル投入)
- **Wave C** (analytics.business_model_template_coverage / template_health view + BFF + Desktop Health Panel + audit-overrides + business_model_template_overrides テーブル + 4 段階 health_class) — 2026-05-04 v2 並列セッションで完了
- **Wave U** (Sidebar/CommandPalette テンプレ override 導線 + default CTA + 推奨候補 3 件 + ui/badges/ ディレクトリ + 12 panel CompositeBadgeBar) — 2026-05-04 v2 並列セッションで完了
- **Wave D Phase 2** (disclosure_kpi_extractor リネーム + 10 packs YAML + packs_loader) — 2026-05-04 v2 並列セッションで設計完了 (観測値投入は D Phase 3)

### 残 Wave (Phase 1-5)

**Phase 1 (1-2 セッション)**
- **Wave J Phase 2**: VerticalPyramid (auto OEM / pharma) / LayeredFlow (telecom / electric / bank) / HubSpoke (J-REIT 双子) / RadialCluster (TradingHouse) プリミティブ統合 — 12 特殊テンプレ吸収、~1300 行縮減

**Phase 2 (3-7 セッション)**
- **Wave D Phase 3**: 半自動 IR PDF パイプライン本実装 (`tools/analytics/disclosure_text_parser` 拡張)、28 新規 metrics の core.metric_catalog 投入、4 銘柄 × 4 期 = 16 docs 投入計画
- **Wave E**: Supply Chain Tier 2-4 推定 (industry_tier_chains.yaml + tier_inferer.py、IPC 共起、Wave 5 ingest 月次 cron 化)
- **Wave F Phase 3**: 12 panel への metrics 配線 (`_industry_panels/*.py` に `_attach_metrics()` 追加)
- **Wave G**: 5 Forces レーダー / Value Chain SVG / SaaS Dashboard / CompanyRelationshipGraph 4 tier 統合

**Phase 4 (10-13 セッション)**
- **Wave K**: 観測 VIEW (`v_business_model_panel_health`) + `ops.client_errors` テーブル + telemetry endpoint + Desktop ErrorBoundary hook + Discord アラート (coverage 急落 / error 多発)
  - Wave U の console.debug ログを ops.client_events 永続化に切替
- **Wave L**: pixelmatch ベースのビジュアル回帰 (40 テンプレ × 3 銘柄 = 120 ケース) + smoke_bm_templates.sh の pytest 化 (Windows 環境互換)
- **Wave M**: Playwright + qwen3.5:9b narrative endpoint + 12 panel に AI 要約アコーディオン

**Phase 5 (任意)**
- **Wave Z**: business_model_coverage を Freshness SLA に登録、Claude classifier (Haiku 4.5 LLM Gateway 委任) 設計再開

### 旧 P0/P1/P2 (汎用フレームワーク 8 + 業種別 10 視点) のステータス
- **P0** 全完了 (P0-1 LLM 補完スキーマ/UI / P0-2 業種別 3 種テンプレ / P0-3 TOP_N 拡張)。Qwen 版 classifier は 2026-04-21 廃止、次期は Claude 版 (Wave Z)
- **P1** 製薬 Pipeline / 通信 / 銀行 / J-REIT 詳細 / Ad-Supported は完了 (Wave F Phase 1-2)
- **P2** Five Forces / SaaS Metrics / CompanyRelationshipGraph は Wave G で実装、Playwright は Wave M

詳細マスタープラン: `C:\Users\kazum\.claude\plans\polymorphic-inventing-widget.md` (v2)

## 重要な固定値

- `DiagramNodeTier`: `primary` / `stakeholder` / `meta` / `llm_inferred` / `text_inferred` (llm_inferred は将来の Claude/Codex 書き込み先として保持)
- `TOP_N_LIMITS.affiliates`: 10 (P0-3 で拡張済)
- BFF レスポンスの `meta.source`: `analytics.supply_chain_edges,analytics.edinet_text_partners` (3 leg UNION: primary/llm_inferred/text_inferred)
- BFF tier_priority: primary=1 / llm_inferred=2 / text_inferred=3 (整数、spec の 1.5 は実装で 2 に整数化)
- llm_inferred の想定 confidence threshold: 0.60、extraction_version: `llm_v1`
- 非上場 counterparty の fallback: `counterparty_sec_code='UNLISTED-<sha256[:12]>'`、`counterparty_entity_key='unlisted:<hash>'`
- EDINET 有報 text_inferred データは 2024-04-01 ~ 2025-09-30 でバックフィル済み、65,399 行
- 旧 Qwen 版 supply_chain_llm_classifier は 2026-04-21 に完全削除 (ADR `docs/decisions/supply-chain-llm-tier.md`)。`ops.ingest_source_registry` への登録は元から未実施、`run_manifest.yaml` / `tool_tiers.yaml` からも参照削除済み

## Playwright MCP 未接続メモ

2026-04-21 時点、webapp-testing skill は使えるが Playwright MCP ツールが接続されていないため、自動 screenshot は未実施。次セッションで MCP が追加されたら P2-7 (自動 screenshot regression) を着手可能。

## サプライチェーン調査テンプレート整合 (2026-04-29 追記)

ユーザー提示の「上場企業のサプライチェーン関係性調査・図解整理テンプレート」と現状実装の差分を整理（詳細: @./supply_chain_template_alignment.md / `docs/decisions/supply-chain-relationship-coverage.md`）。

**用語の罠**: `tier_source` (primary / text_inferred / llm_inferred) は **データ源層** を示すラベル。テンプレートの **Tier 1/2/3 (直接仕入先 / 中間材 / 原材料)** とは別概念。Tier 階層を表す `chain_tier SMALLINT` は未実装。

**関係区分の現状**: `relation_type` は customer / supplier / parent / subsidiary / affiliate の 5 種のみ。テンプレートが想定する Distributor / OEM / ODM / Logistics / R&D / JV / Public Procurement / Finance は未対応。Wave 1 で 10 区分への拡張を予定。

**確度 A/B/C/D**: 連続値 `confidence` のみで、Band ENUM は未実装。暗黙閾値は A:≥0.70 / B:0.50-0.70 / C:0.40-0.60 / D:<0.40。Wave 1 で派生列または VIEW 化予定。

## Phase 16 新規 8 framework (2026-05-17 追加)

[[project-business-model-phase16]] で着地した 8 framework。各 framework は
builder (`tools/api/decision_api/serving/company/business_model/_frameworks/<id>.py`)
+ pack YAML + sample JSON + alembic seed + aggregator 配線を Wave A で一括着地。

| Framework                | Anchor 銘柄                  | Desktop Panel                |
| ------------------------ | ---------------------------- | ---------------------------- |
| `apparel_brand`          | 8227 しまむら                | `ApparelBrandPanel`          |
| `airport_operator`       | 9706 日本空港ビルデング      | `AirportOperatorPanel`       |
| `it_services_integrator` | 9613 NTT データ              | `ItServicesIntegratorPanel`  |
| `fitness_amusement`      | 4680 ラウンドワン            | `FitnessAmusementPanel`      |
| `funeral_services`       | 6184 燦 HD                   | `FuneralServicesPanel`       |
| `nursing_care_services`  | 2374 セントケア HD           | `NursingCareServicesPanel`   |
| `bridal_services`        | 2418 ツカダ G HD             | `BridalServicesPanel`        |
| `printing_services`      | 7912 大日本印刷              | `PrintingServicesPanel`      |

8 framework の anchor 銘柄は Phase 16 終了時点で **全 partial** (available
0/8)。Phase 17 で `analytics.segment_financial_facts` 投入による available 化
が必要 (`has_segment_groups=True` 条件)。

## 複合業種 dispatch 基盤 (2026-05-17 Phase 16 Wave D)

SAMPLE_MAPPINGS schema を `dict[str, tuple]` → `dict[str, list[tuple]]` に
拡張。1 銘柄が複数 framework に sample を持つ構造をサポート。aggregator
(`serving/company/business_model/__init__.py`) は **元から多重 dispatch 対応
済み** で改修不要。

Phase 16 で実証した 3 銘柄:

- 3231 野村不動産 HD → `real_estate_developer` + `hospitality_lodging`
- 4680 ラウンドワン → `fitness_amusement` + `entertainment_facilities`
- 6752 パナソニック HD → `electric_equipment` + `home_appliances`

Phase 17 候補 8 銘柄: 7974 / 9433 / 9984 / 4755 / 8058 / 3382 / 4661 / 9020。
