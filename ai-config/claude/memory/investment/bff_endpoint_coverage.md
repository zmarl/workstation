---
name: BFF endpoint カバレッジ (Desktop 配線状況)
description: 366 endpoints / 185 used / 181 未配線。Router 33本構成と未配線 endpoint TOP リスト。Desktop Control Tower のギャップ把握用
type: project
originSessionId: 06a37e34-9804-430a-aa3a-f36ce72a0a61
---
調査日: 2026-04-28。実装は急速に動くため、絶対数より「どの領域に未配線が偏っているか」を読み取る用。

## 全体カウント

| 区分 | 数値 |
|---|---|
| BFF endpoint 定義 (`tools/api/decision_api/`) | **366** |
| Desktop で実際に呼ばれている | **185** |
| **定義はあるが未配線** | **181** |
| BFF Router 数 | **33** |

## Router 一覧 (33 本)

decision / company / market / portfolio / research / hypothesis / candidates / analyst_extras / alerts / audit / catalog / desktop / disclosure / ideas / ipo_pipeline / jobs / knowledge_base / news / ops / regulation / routines / scenarios / scoring / screening_routes / simulation / stakeholders / stakeholders_activist / system / tasks / thesis ほか

## 未配線 endpoint の偏り (181 本の内訳概要)

### Company 系 (50+ 本未配線)
特に CompanySnapshot に統合可能だが Desktop 未呼び出し:
- `/api/v1/company/{code}/overview` (aggregate)
- `/api/v1/company/{code}/business-model/graph` (capital + transactional unified, wikidata source)
- `/api/v1/company/{code}/financial-lineage`
- `/api/v1/company/{code}/alt-data-trend`
- `/api/v1/company/{code}/institutional-ownership`
- `/api/v1/company/{code}/management-tone`
- `/api/v1/company/{code}/ml-predictions`
- `/api/v1/company/{code}/margin-short`
- `/api/v1/company/{code}/event-study`
- `/api/v1/company/{code}/liquidity-profile`
- `/api/v1/company/{code}/earnings-prep-pack`
- `/api/v1/company/{code}/what-changed` (Wave-3 change tracking)
- `/api/v1/company/{code}/margin-bridge` / `/expectation-gap`
- `/api/v1/company/{code}/market-maintenance-opportunity`

### Market 系 (23 本未配線、Wave 1+2 候補)

- `/api/v1/market/situation` (市場局面)
- `/api/v1/market/anomaly-signals` (異常検知、EnvironmentTab で部分使用済み)
- `/api/v1/market/volatility-regime`
- `/api/v1/market/leading-indicators` + `/leading-composite`
- `/api/v1/market/regime-history` + `/cycle-phase`
- `/api/v1/market/consensus-revision-momentum`
- `/api/v1/market/calendar-seasonality`
- `/api/v1/market/sector-rrg`
- `/api/v1/market/theme-cards`
- `/api/v1/market/options-flow`
- `/api/v1/market/alt-data`
- `/api/v1/market/breadth`
- `/api/v1/market/macro-statistics`
- `/api/v1/market/risk-events` + `/event-predictions`
- `/api/v1/market/indicator-context`
- `/api/v1/market/scenario-lookup`
- `/api/v1/market/cyclical-clusters`
- `/api/v1/market/cross-market-signals`
- `/api/v1/market/narrative/{id}/runway`
- `/api/v1/market/supply-demand/*` (3種)

### Workflow 系
- `/api/v1/agent/actions/{id}/approve|reject` (HITL ワークフロー)
- `/api/v1/candidates/{candidate_id}/promote|status`
- `/api/v1/analytics/backtest/runs/{run_id}` (Backtest.tsx 未リンク)

### API 未定義 (実装すべき)
- supply_chain_edges → 既存 `/api/v1/company/{code}/supply-chain` でカバー済み (primary/llm_inferred/text_inferred 3 tier UNION)
- business_model_coverage_snapshots → `/api/v1/analytics/business-model-coverage` を 2026-04-28 新設

## 2026-04-28 解消済み Wave 3 配線

CompanySnapshot に追加配線:
- `/api/v1/company/{code}/liquidity-profile` → `CompanyLiquidityProfilePanel` (ownership グループ)
- `/api/v1/company/{code}/financial-lineage` → `CompanyFinancialLineagePanel` (financial グループ)

これにより Wave 3 の Company endpoint 11 本はすべて Desktop で表示可能になった (event-study/what-changed/ml-predictions/management-tone/earnings-prep-pack/institutional-ownership/alt-data-trend/margin-short/business-model-graph/liquidity-profile/financial-lineage)。

## 利用シーン

- 「この機能を Desktop に出したい」とき、まずここの未配線リストを確認
- 新規 API endpoint を作る前に、既存の未配線 endpoint で代用できないか確認
- Wave 単位で実装進捗を見るとき、本メモリのリストから消し込み
