---
name: Business Model 9/9 available 達成 (2026-05-08)
description: Wave F Phase 3 partial 3/9 残課題 (4568/8001/6920) を解消し 9/9 available を確定。コード変更ゼロ、既存 backfill ツール再実行のみ
type: project
originSessionId: a41e14db-9e94-4705-9e83-07b969694510
---
# Business Model 9/9 available 達成 (2026-05-08)

直近 Wave G follow-up (2026-05-06) で `available 6/9, partial 3/9` で着地していた状態を解消。

**Why:** Wave F Phase 3 の集約マイルストーン。9/9 が後続 Wave (L pixelmatch / M qwen narrative / 実機検証) の前提。

**How to apply:** 4568 / 8001 / 6920 の partial 状態は段階的 partial、segment_groups 未投入が原因。再発時 (DB リセット等) は `tools.market_data.business_model_segment_backfill` を 3 銘柄で再 apply するだけで復旧。

## 達成

- 既存ツール `tools/market_data/business_model_segment_backfill/main.py` を 3 銘柄で apply (rows_planned=17、catalog 17 / facts 33)
- 9 銘柄全て `has_segment_groups=True` を direct call (`_get_company_overview_segments` + `_build_company_overview_segment_groups`) で確認
- ruff: All checks passed / pytest test_company_business_model_frameworks.py: 45 passed in 1.80s
- worklog: `docs/worklogs/20260508-business-model-9of9-available.md` (Lite)

## 知見

### probe スクリプトの BFF aggregator ハング

`scripts/probe_business_model_frameworks.py` および `get_company_business_model_frameworks` / `get_company_overview` を CLI から直接呼ぶケースで 5 分以上応答せずハング。aggregator (canvas + business_model + supply_chain + issuer_facts + kpis 統合) のどこかでブロック。

- SQL 直接 / `_get_company_overview_segments` 等の helper 単独呼び出しは速い
- FastAPI サーバー起動状態 (BFF) では問題ない可能性 (warm-up 済)
- 検証は SQL 直接 + helper direct call で代替可能

別 issue 化。CLI 直接呼び出しで時間がかかるなら、helper レベルで代替検証を組み立てる。

### `_segment_labels` の構造ミスマッチ

`_frameworks/_common.py:_segment_labels` は `business_model.segment_groups[].segment_name` を見るが、`_build_company_overview_segment_groups` の出力は top-level に `segment_name` を持たず、`items[].segment_name` に segment 名を持つ構造。`has_segment_groups=True` 判定 (`bool(...)`) には影響しないが、UI slot ラベルが空になる可能性あり。

### 8001 の facts 行数

dry-run の `rows_planned=8` は segment_catalog レベル (8 segments)。実際の `core.segment_financial_facts` は 8 segments × 3 metrics (revenue / gross_profit / operating_income) = 24 行。Plan agent の見積もり (24 行) は正しかった。

## 次セッション候補

1. **probe スクリプトハング修復**: aggregator のどこでブロックしているかを特定し、CLI からも probe が成立するように修正
2. **`_segment_labels` 修正**: items まで掘り下げて segment 名を取得するように
3. **Wave D Phase 3 IR 正規値化**: 10 銘柄 sample JSON を IR 数値で上書き、confidence ≥ 0.85
4. **Desktop 12 panel 一括検証 catalog ページ** (Wave L/M の前提)
5. **`run_business_model_segment_backfill_initial.bat`** で長期安定化

## 関連ファイル

- 実行: `tools/market_data/business_model_segment_backfill/main.py` + `segment_facts.json`
- 検証: SQL `core.segment_catalog × core.segment_financial_facts` JOIN
- 検証 (helper): `tools/api/decision_api/serving/company/overview.py:1085 _get_company_overview_segments`
- builder: `tools/api/decision_api/serving/company/business_model/_frameworks/pharma_rd.py:160-178` (available 判定)
- worklog: `docs/worklogs/20260508-business-model-9of9-available.md`
