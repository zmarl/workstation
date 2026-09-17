---
name: 改革ロードマップ A+B+C 並列着地 (2026-05-11)
description: 改革 #11 Phase 2-B (db_capacity_audit --persist) + Wave D Phase 5 残 + FU-6 PBR 履歴 を S 粒度 3 並列着地。3 stream の知見集約
type: project
originSessionId: 832f5c59-0ad3-4876-b12c-9b8f85f8e6db
---
# 改革 A+B+C 並列着地 (2026-05-11)

直前 4 セッションの自然な続き 2 系統 + 新領域 1 系統を S 粒度で 3 並列着地 (案 A: 運用補強 + KPI)。
worklog: `docs/worklogs/20260511-reform-a-b-c-parallel.md`。

## Stream A: #11 Phase 2-B `db_capacity_audit --persist` (S 圧縮)

- **新設**: `ops.db_capacity_snapshots` (`db/greenfield_postgres/60_ops_quality.sql:953-` + alembic `20260511_07`)
- **DDL**: `snapshot_id BIGSERIAL PK / captured_at TIMESTAMPTZ / run_id UUID / schema_name + table_name / total_size_bytes + table_size_bytes + index_size_bytes / row_estimate / seq_scan + idx_scan + dead_rows / retention_policy_id + freshness_sla_id (NULL 確保のみ、Phase 2-C で governance 連動)`
- **CLI**: `tools.quality.db_capacity_audit.main --persist` で `_persist_snapshot()` を呼び `INSERT ... ON CONFLICT DO NOTHING` (qmark `?` 厳守)
- **scheduler**: `scripts/run_manifest.yaml` の `db-capacity-audit-daily.args` に `--persist` 追加 (前回 Phase 2-A scheduler 登録の自然な続き)
- **Verification**: pytest 19 passed (既存 9 + 新規 10) / scheduler integrity 32 passed / CLI 既存出力フォーマット維持
- **除外**: governance YAML 連動 / 承認 UI / source_freshness probe 登録 / foundation_postgres sync (Phase 2-C / 別 phase)

## Stream B: Wave D Phase 5 残 (検証再走 + worklog のみ、コード変更ゼロ)

- **6301 修復不要** Phase 6 followups Track D で確定済 (`bugs_segment_extractor_6301_komatsu.md`)
  - 真因: Komatsu の USGAAP ベース開示で EDINET XBRL に segment 別 revenue/operating_income なし
  - `OperatingSegmentsAxis` 付き 126 facts 全件 workforce/CapEx/R&D (`_SEGMENT_METRIC_MAP` 対象外)
  - `NetSales/OperatingIncome` 16 件全て `NonConsolidatedMember` (意図通り除外)
  - manual sample (Phase 6 投入済) が正解経路
- **5191 / 2412 deferred 別 issue 化**: 5191 は JPX master 同期パイプライン (713 件影響、`bugs_core_instruments_market_reform_stale.md`)、2412 は上場廃止確定で母集団除外 (N=19)
- **regression check 実測**:
  - 5 銘柄 segment_facts: 2127=5 / 3391=6 / 6301=**9** / 6310=5 / 7649=6 (Phase 6 投入そのまま永続)
  - 20 anchor probe available: **17/20 (= 17/19=89%)**、期待 ≥ 16/19 を上回る
  - raw EDINET `OperatingSegmentsAxis + NetSales` non-NonConsolidated facts: **0 件のまま** (root cause invariant 維持)
- **残作業**: segment_extractor 本走化 (Phase 8 以降)、5191 master 同期 (別 issue)、6301 sample 監査自動化 (Phase 9 以降)、5105 IR 構造変化待ち

## Stream C: FU-6 PBR 履歴 (S 粒度)

- **新設 view**: `mart.vw_pbr_timeseries` (`db/greenfield_postgres/90_marts.sql` + alembic `20260511_08`) — 既存 `mart.vw_daily_valuation` の薄いラッパ + `quality_flag` 付与 (`missing_bps` / `non_positive_bps` / `extreme_pbr` / `ok`)
- **新設 endpoint**: `GET /api/v1/company/{code}/metrics/pbr-history?range=1y|3y|5y|max` — Response に `as_of_date` / `bps_freshness_hint` / `source: "mart.vw_pbr_timeseries"` 含む。BFF は `pg_repository._query` 経由で 503 伝播、view-missing は空配列 fallback
- **新設 component**: `desktop/src/components/company/charts/PbrHistoryChart.tsx` — `FinancialChartBase.utils` 流用、NULL line break、`quality_flag='extreme_pbr'` warning marker
- **配置**: `CompanyFinancials.tsx` 末尾の独立 card (chartCards 配列に入れず、mode 切替の影響外)。**PerShareChart 拡張ではなく独立 chart 採用** (PerShareChart は fiscal-period 軸、PBR は daily で座標系が異なる)
- **設計判断**:
  - `WAVE10_READ_ROUTE_CONTRACT_SCHEMAS` に登録 (`peer-comparison-metrics` と対称性、RESIDUAL ではなく)
  - `queryKeys.company.pbrHistory(code, range)` ネスト (既存命名規則)
  - FastAPI 0.116+ で `regex=` deprecated → `pattern=` 使用
  - foundation_postgres mirror なし (mart 層は greenfield のみ管理)
- **Verification**: pytest 6 passed (asyncio×3 + trio×3) / Vitest 4 passed / contract sweep PASS (endpoints 439→440)
- **残作業**: 範囲セレクタ UI、12 銘柄 smoke probe、BPS 真 forward fill (Phase 2 で LATERAL JOIN)、PBR 5y percentile バッジ、ROE 履歴の同経路展開

## 統合検証

| 項目 | 結果 |
|---|---|
| `uv run ruff check .` | All checks passed |
| `uv run pytest` (全体) | **11623 passed, 333 skipped** (前回 11566 + 新規 ~57) |
| `cd desktop && npx tsc --noEmit` | clean |
| `cd desktop && npm run test` (全体) | **1801 passed** (前回 1793 + 新規 8) |
| `cd desktop && npm run build` | exit 0 (8.74s) |

## 学び

- **Plan agent 出力誤検知ガード**: ユーザー指示 path (`db/greenfield_postgres/40_ops_tables.sql` / `shared/freshness_sla/`) が **存在しない** と実態確認で発覚 → `60_ops_quality.sql` / `shared/source_freshness.py` に読み替え。Plan agent #2 の「6301 修復未解決」前提も既解決と判明 → Stream B コード変更ゼロに圧縮。**Plan agent 出力は方向性として参照、修正前にファイル単位で実態確認を徹底**
- **Vitest 統合で発覚 mock 不足**: 新規 `PbrHistoryChart` を `./charts` から re-export したが、`CompanyFinancials.test.tsx` の `vi.mock("./charts", ...)` には未追加 → 3 件 fail → 1 行追加で復旧。各 stream 内 verification では拾えない依存。**新規 chart 追加時は `./charts` mock 利用 test の存在を grep して同時更新**
- **alembic revision 番号事前確定**: 3 並列で alembic を触るとき、A=`_07` / C=`_08` を Plan で確定し、Stream C の `down_revision="20260511_07"` で chain を組むことで番号衝突を完全回避
- **薄いラッパ view 設計**: 既存 `mart.vw_daily_valuation` で PBR 計算済 → 新 view は SELECT ラッパ + `quality_flag` 付与のみで S 粒度に圧縮可能。BPS forward fill の厳密な実装は Phase 2 LATERAL JOIN で別途対応
