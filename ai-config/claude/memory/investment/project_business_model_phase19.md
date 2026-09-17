---
name: project-business-model-phase19
description: Business Model Phase 19 (2026-05-17) J-REIT プロジェクト全体からの完全除外。code 完全削除 + DB row はソフト除外 + ETF/ETN ADR を fund-like 統合版にリネーム
metadata:
  type: project
  originSessionId: phase19
---

# Business Model Phase 19 (2026-05-17)

ユーザー指示「J-REIT は完全に除外。Project から完全に除外して。全体から」を受け、`feedback_reit_etf_exclusion.md` の確定方針 (REIT/ETF/投信は全機能で恒久除外、入口 filter 必須) と実装の乖離を解消した。3 並列 Wave + 直列検証で 1 セッション完走。

## ユーザー確定方針

- **DB row 扱い**: ソフト除外 (instrument_policy で全 product 入口で弾く、row は保持)
- **コード扱い**: 完全削除 (framework / Desktop component / template / sample / test)
- **ADR**: 既存 ETF/ETN ADR にリネーム統合 (`product-policy-fund-like-exclusion.md`)

## 着地サマリ

| 指標 | Phase 18 完了 | Phase 19 完了 |
| ---- | -------------- | -------------- |
| Business Model framework 数 | 71 | **70** (j_reit 除外) |
| loader_smoke.imported | 172 | **171** (8951 sample 削除) |
| loader_smoke.failed | 0 | **0** (維持) |
| audit `needs_action` | 0 | **0** (維持) |
| Desktop 削除ファイル | — | **12** (JReitSponsorship/Specialized panel + utils + tests + snapshot) |
| BFF / pack 削除 | — | **2** (j_reit.py / j_reit.yaml) + sample 2 + test 1 |
| 修正ファイル合計 | — | **30 強** (BFF / Desktop / DB / docs / ADR) |
| ADR | ETF/ETN 専用 | **fund-like 統合** (ETF/ETN/REIT/投信/インフラファンド) |
| `core.metric_catalog` J-REIT 行 | 4 | **1** (`noi_yield` は FK 保護で残存) |

## Wave 構成

- **Wave A (BFF/Framework)**: 削除 2 + 修正 7。framework / pack YAML / aggregator / template rules / template_definitions / audit。`_template_rules_generated.py` は codegen で対応する申し送り
- **Wave B (Desktop UI)**: 削除 10 + 修正 18。Panel / template / utils / type / lib 配線 / catalog dev page / 関連 test fixture。typecheck 0 error 達成
- **Wave C (DB / Policy / Sample / Test / Docs / ADR)**: `shared/instrument_policy.py` キーワード補強 + SQL view `is_jreit` 廃止 + alembic DELETE migration + 8951 sample / test 削除 + docs 14 ファイル + ADR リネーム
- **Wave E (検証 + 文書)**: codegen 再生成 / alembic upgrade head / audit 再走 / pytest 633 件 pass / ruff / typecheck / BFF コメント整理 / catalog `(12)→(11)` 修正

## 重要な発見

- **`noi_yield` 1 行は FK guard で残存**: observation がすでに入っており削除しない方が安全。Phase 19 方針 (row 保持・入口 filter で弾く) と整合
- **`raw.jpx_universe_exclusion_overrides` の `'jreit'` enum 値**: CHECK ALTER 不可で残置。新規 row は `'fund'` を使用する旨を SQL コメントと ADR で明記
- **template codegen が再発防止に有効**: `_template_rules_generated.py` / `_industry_template_generated.ts` / `_template_metadata_generated.ts` を手で編集せず Wave E で `tools/dev/template_codegen.py` 再実行 → 3 ファイル全てから j_reit が機械的に消える。Phase 16 Wave A 以降の codegen 規約が機能していることを再確認
- **既存違反は Phase 19 で背負わない**: `LatestEarnings.tsx:850` typecheck 1 件 + `earnings_evaluation_assistant` ruff 3 件は Phase 19 前から存在。Phase 19 verification では別 issue 扱い

## Phase 19 申し送り

1. `LatestEarnings.tsx` line 850 `source_review_errors` 型不整合 (Phase 19 前) は別 issue
2. `earnings_evaluation_assistant` の ruff E501 3 件 (Phase 19 前) は別 issue
3. `noi_yield` metric_catalog 残存と、observation 含め全削除する場合は別 issue
4. Phase 17 申し送り #3〜#8 (cosmetics 命名統合 / yoshinoya 重複 / IndustryFrameworkTabStrip 50+ / probe ハング / 複合 dispatch 実機検証) は Phase 20 候補
5. Phase 18 申し送り #2 (alembic head sanity audit) は Phase 20 候補

## 触ったファイル (主要)

### 削除
- `tools/api/decision_api/serving/company/business_model/_frameworks/j_reit.py`
- `tools/analytics/disclosure_kpi_extractor/packs/j_reit.yaml`
- `tools/analytics/disclosure_kpi_extractor/samples/{,official/}8951_*.json` (2 ファイル)
- `tests/data/test_jreit_extraction.py`
- Desktop: `JReitSponsorship.tsx` (+ tests + layout test) / `JReitSpecialized.tsx` (+ tests + layout test) / `j-reit-{sponsorship,specialized}-utils.ts` / `JReitSponsorshipPanel.tsx` (+ test) + snapshot 2 (計 12)

### リネーム
- `docs/decisions/product-policy-etf-exclusion.md` → `product-policy-fund-like-exclusion.md` (本文書き換え)

### 新規
- `db/alembic/versions/20260518_21_phase19_remove_jreit_metrics.py` (J-REIT 4 metric DELETE + FK guard)

### 修正 (主要)
- `shared/instrument_policy.py` (キーワード + docstring)
- `db/foundation_postgres/79_mart_jpx_universe.sql` / `db/greenfield_postgres/99_mart_jpx_universe.sql`
- `tools/api/decision_api/serving/company/business_model/{_frameworks/__init__.py, _frameworks/_common.py, __init__.py, _template_rules.py}`
- `db/seeds/business_model/template_definitions.yaml`
- `tools/quality/business_model_catalog_audit/auditor.py`
- Desktop 18 ファイル (`types/company.ts` / `template-suggestions.ts` / `company-tabs.ts` / `_business-model-framework-utils.ts` / `BusinessModelCanvasView.tsx` / `BusinessModelDiagram.tsx` 等)
- docs 14 ファイル (CLAUDE.md / `business-model/*` / `known_issues.md` / `decisions/*` / `contracts/cycle_analyzer_input.md` / `scripts/run_manifest.yaml`)

## 関連 memory

- [[project-business-model-phase18]] — 前フェーズ着地サマリ
- [[feedback-reit-etf-exclusion]] — Phase 19 で実装統合された確定方針
- [[reference-product-policy-adr]] — fund-like ADR の所在 (今後は `product-policy-fund-like-exclusion.md`)

## Worklog

`docs/worklogs/20260517-phase19-jreit-full-exclusion.md`
