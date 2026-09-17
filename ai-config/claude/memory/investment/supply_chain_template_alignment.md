---
name: サプライチェーン調査テンプレートと現状実装の対応表
description: ユーザー提示のサプライチェーン関係性調査テンプレート 30 章 ↔ Investment 実装ステータス対応表。関係区分10種・Tier1-3・確度A-D・情報源・逆引きの実装可否を 1 箇所で参照。
type: reference
originSessionId: 1caa47eb-ea5e-4328-8fdc-89992ba05ecc
---
ユーザーは「上場企業のサプライチェーン関係性調査・図解整理テンプレート」を SSOT として運用したい意向。テンプレートと現状実装の対応は以下の通り。実装変更の議論時は本メモリと `docs/decisions/supply-chain-relationship-coverage.md` を参照する。

## 関係区分 10 種 × 現 enum

| テンプレート区分 | 現 `relation_type` | 状態 |
|---|---|---|
| Customer | `customer` | ✅ 実装済 |
| Supplier | `supplier` | ✅ 実装済 |
| Group (Parent/Subsidiary/Affiliate) | `parent` / `subsidiary` / `affiliate` | ✅ `/related-parties` API のみ |
| Distributor / 代理店 | — | ❌ 未実装 |
| OEM / ODM | — | ❌ 未実装 |
| Logistics / フォワーダー | — | ❌ 未実装 |
| R&D / 技術提携 | — | ❌ 未実装（特許 J-PlatPat 未取込） |
| JV / 合弁 | — | ❌ 未実装 |
| Public Procurement | — | ❌ 未実装 |
| Finance / 取引銀行 | — | ❌ 未実装 |

Wave 1 で `relation_type` CHECK 制約を 10 区分に拡張する方針 (ADR `supply-chain-relationship-coverage.md`)。

## Tier 階層（重要な用語の罠）

**警告**: DB の `tier_source` (primary / text_inferred / llm_inferred) は **データソース層** を表すラベル。テンプレートの **Tier 1/2/3 (直接仕入先 / 中間材 / 原材料)** とは別概念。混同しないこと。

サプライチェーンの Tier 1/2/3 階層を表現するカラムは未実装。Wave 3 で `chain_tier SMALLINT` 追加を検討。

## 確度 Band ↔ confidence 閾値（Wave 1 確定 2026-04-29）

実装は Desktop 既存 TS union と一致する 5 band 構成。テンプレートの A/B/C/D は調査メソッド側の概念区分。

| 調査確度 | 実装 band | 現 confidence 範囲 | 現 tier_source 目安 | UI 表現 |
|---|---|---|---|---|
| A | `high` | ≥ 0.80 | primary | 実線 |
| B | `medium` | 0.65 - 0.80 | text_inferred / interactive_llm | 破線 |
| C | `low` | 0.50 - 0.65 | canvas / wikidata | 点線（薄） |
| D | `very_low` | < 0.50 | reference_candidate | 点線（極薄・細） |
| - | `unknown` | NULL | - | 点線（灰） |

実装場所: `tools/api/decision_api/serving/company/common.py::compute_confidence_band`（`relations.py` / `business_model.py` から共有）。Desktop 表現は `BusinessModelGraphV2Panel.tsx` の Cytoscape `.band-{name}-edge` selector と `CompanyMajorPartners.tsx` のバッジ。

## 情報源 11 種別の実装ステータス

| ソース | 種別 | 実装 | 補足 |
|---|---|---|---|
| EDINET 関連当事者取引 | 一次/構造化 | ✅ | `tools/market_data/disclosure_supply_chain/` |
| EDINET MD&A 本文 | 一次/テキスト | ✅ | `tools/market_data/edinet_partners_text/` |
| TDnet partnership | 一次 | ✅ | `tools/market_data/tdnet_partnership_extractor/` |
| IR PDF 抽出 | 一次 | ✅ | `tools/market_data/ir_pdf_scraper/` |
| Wikidata SPARQL | 二次/公開 | ✅ | `tools/market_data/wikidata_company_relationships/` |
| Business Model Canvas | 推定 | ✅ | `tools/analytics/canvas_to_supply_chain/`（テンプレ確度では C 相当） |
| Claude 対話抽出 | 推定/手動 | ✅ | `tools/analytics/supply_chain_extractor/`（manual-only） |
| 信用調査 (TDB / TSR / 日経テレコン / G-Search) | 二次/有料 | 🚫 | **永続スコープ外** (2026-04-29) |
| 貿易データ (Panjiva / ImportGenius / Datamyne / 財務省統計商用部) | 一次〜推定 | 🚫 | **永続スコープ外** (同上) |
| 有料 SC DB (Bloomberg SPLC / FactSet / S&P CIQ / LSEG / Orbis / D&B / SPEEDA / INITIAL) | 二次/有料 | 🚫 | **永続スコープ外** (同上) |
| 公共調達 (調達ポータル / JETRO / 自治体) | 一次/公開 | ❌ | jGrants 起点で Wave 2 着手可能 |
| 特許 J-PlatPat | 一次/公開 | ⚠️ | `tools/market_data/jplatpat_patents/` ディレクトリのみで未完成、Wave 2 |
| ニュース取引先抽出 | 二次 | ❌ | `news_detector` は記事収集のみ。取引先抽出は未実装 |
| 会社サイト導入事例 | 一次 | ❌ | Claude 対話パターンで半自動化可能、Wave 2 |

## 逆引き調査（counterparty side）

**未実装**。`analytics.supply_chain_edges` の `WHERE counterparty_sec_code = ?` で SQL レベルでは可能だが、BFF endpoint と UI 視点切替トグルは未整備。Wave 3 で `GET /company/{code}/supply-chain-reverse` を新設予定。

## 重要リスク区分のカバレッジ

| リスク | 対応カラム | 状態 |
|---|---|---|
| 特定顧客依存 | `dependency_ratio` (未存在) | ❌ Wave 3 |
| 特定サプライヤー依存 | 同上 | ❌ Wave 3 |
| 原材料価格 | — | ❌ |
| 地政学 | counterparty の region/country | ❌ entity_master JOIN で導出可能、Wave 3 |
| 物流リスク | logistics relation 必要 | ❌ Wave 1 enum 拡張後 |
| OEM/ODM 集中 | oem/odm relation 必要 | ❌ Wave 1 enum 拡張後 |
| 規制リスク | — | ❌ |
| 人権・ESG | — | ❌ |

## 実装ロードマップ

- **Wave 1**: 完了 (2026-04-29)。relation_type 13 区分 CHECK 制約追加、`confidence_band` BFF レスポンス拡張、UI band 別 edge スタイル + 取引額 tooltip、`tools/analytics/supply_chain_reclassifier/` 新設。
- **Wave 1 配線抜け修正**: 完了 (2026-04-29 後半)。BFF SELECT 句に `chain_tier` / `dependency_ratio` / `region` / `country_code` を反映（半完成バグ修正）、`BusinessModelLegend` の `showTierSource`/`showChainTier` を有効化、`TierBadgeLegend` に「テンプレート Tier 1/2/3 とは別概念」注釈追加、`CompanyMajorPartners` に chain_tier (T1-T3) / country_code / 13 区分サブタイプバッジを追加、`supply_chain_reclassifier` を週次 scheduler 統合。
- **Wave 2**: 完了 (2026-04-29 完全終了)。
  - `tools/market_data/jplatpat_patents/`: J-PlatPat 公式 CSV エクスポートの **import-csv 方式**で実装。`extract` サブコマンドは placeholder（J-PlatPat は React SPA で JS rendering 必須なので Playwright 不採用方針と整合せず）。
  - `tools/market_data/jgrants_public_procurement/`: jGrants / GEPS の **import-csv 方式**で実装（API 不安定 / GEPS API 非提供のため）。
  - `tools/analytics/news_partner_extractor/`: 既存 `news_detector` が蓄積した `raw.news_items` から、heuristic キーワード辞書で 13 区分関係を抽出 → text_inferred 投入。日次 scheduler 登録済み。
  - `tools/analytics/case_study_extractor/`: 会社 Web の導入事例ページから Claude 対話パターン (init-db / collect-inputs / import-json / list) で customer edges を抽出。manual-only。
- **Wave 3 (chain_tier 自動推定)**: 完了 (2026-04-29)。`supply_chain_reclassifier` に `infer-chain-tier` サブコマンドを追加。relation_type が `supplier`/`oem`/`odm`/`logistics` のレコードに `chain_tier=1` を埋める。Tier 2/3 はテキスト推定不能のため触らない。
- **Wave 3 残**: 地政学リスク詳細 UI（region/country の集計 view）、人権・ESG 抽出（サステナビリティ報告書 LLM 解析）は別 ADR 予定。
- **chain_tier Tier 2/3 推定方針**: `docs/decisions/supply-chain-tier-2-3-inference.md` (Proposed, 2026-04-29) で 4 段階フェーズ計画確定。Phase 1=業界別ルール表 (industry_tier_chains.yaml), Phase 2=有報品目キーワード抽出 (disclosure_tier_inferer 新設予定), Phase 3=J-PlatPat IPC 連携, Phase 4=Claude 対話 + 取引額統計。Phase 1 で Tier 1 90%+Tier 2 30-40%+Tier 3 20-30% 充足見込み。
- **永続スコープ外（旧 Wave 4）**: 有料 DB（Bloomberg SPLC / FactSet / S&P CIQ / LSEG / Orbis / D&B / TDB / TSR / Panjiva / ImportGenius / Datamyne / SPEEDA / INITIAL）は **採用しない方針確定**（2026-04-29）。ROI が個人投資ツールに見合わず、無料ソース（EDINET / TDnet / J-PlatPat CSV / jGrants CSV / Wikidata / Claude 対話 / ニュース抽出 / 会社サイト事例）で代替する。

## Wave 2 完了時の正本ツール（2026-04-29 完全終了）

| ツール | サブコマンド | 主用途 |
|---|---|---|
| `tools/market_data/jplatpat_patents/` | `import-csv` | J-PlatPat 公式 CSV エクスポート → `relation_type=rnd_partner` |
| `tools/market_data/jgrants_public_procurement/` | `import-csv` | jGrants / GEPS CSV エクスポート → `relation_type=public_procurement` |
| `tools/analytics/news_partner_extractor/` | `extract` | `raw.news_items` から heuristic で 13 区分関係抽出 → text_inferred |
| `tools/analytics/case_study_extractor/` | `init-db` `collect-inputs` `import-json` `list` | 会社サイト導入事例 Claude 対話 → `relation_type=customer` |
| `tools/analytics/supply_chain_reclassifier/` | `run` `infer-chain-tier` | 確度低 edge の relation_type 再分類 + chain_tier=1 自動推定 |

scheduler 登録 (manifest + register_schedules.ps1):
- `supply-chain-reclassifier-weekly` (毎週日曜 12:00, dry-run)
- `jplatpat-co-filing-monthly` (毎週日曜 13:00, placeholder)
- `jgrants-public-procurement-monthly` (毎週日曜 13:30, placeholder)
- `news-partner-extract-daily` (平日 23:40, dry-run)

manual-only （scheduler 未登録）:
- `case_study_extractor` （Claude 対話パターンのため、人手契機での実行）

## Wave 1 配線抜け修正の正本ファイル（2026-04-29 後半）

- `tools/api/decision_api/serving/company/relations.py` — get_company_supply_chain / _reverse / get_company_related_parties の SELECT 句に `chain_tier, dependency_ratio, region, country_code` を追加（edinet_text_partners UNION 側は NULL キャスト）
- `desktop/src/components/company/BusinessModelGraphV2Panel.tsx` — `<BusinessModelLegend showTierSource showChainTier>` 有効化
- `desktop/src/components/company/BusinessModelSupplyChainPanel.tsx::TierBadgeLegend` — データ源 vs Tier 1/2/3 注釈
- `desktop/src/components/company/CompanyMajorPartners.tsx` — `relationSubtypeLabel` / `chainTierBadgeClass` ヘルパ + PartnerRow バッジ表示
- `tests/tools/api/test_company_serving_supply_chain_tier.py` — `test_supply_chain_tier_ratio_region_passthrough` / `test_supply_chain_reverse_passes_chain_tier` / `test_related_parties_passes_chain_tier` リグレッション
- `desktop/src/components/company/CompanyMajorPartners.test.tsx` — chain_tier / country_code / relation_type サブタイプバッジテスト
- `scripts/run_manifest.yaml` — `supply-chain-reclassifier-weekly` / `jplatpat-co-filing-monthly` / `jgrants-public-procurement-monthly` 登録
- `scripts/register_schedules.ps1` / `scripts/tool_tiers.yaml` — 同 3 タスク登録（実 Task Scheduler 反映には `register_schedules.ps1` 手動再実行が必要）

詳細: `docs/decisions/supply-chain-relationship-coverage.md` / `docs/guides/supply-chain-research-template.md`
