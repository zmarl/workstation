---
name: JPX 公式 list 月次取り込み Phase 2 着地
description: jpx_listed_companies を月次自動取得 + DB 永続化 + drift 検知の運用ラインに格上げ (2026-05-11、4 並列マルチエージェント着地)
type: project
originSessionId: 4d9df458-a9d5-45d9-b712-894478d05359
---
JPX 公式 list 月次取り込み Phase 2 完了 (2026-05-11)。Phase 1 で in-memory + CSV までだった `tools.market_data.jpx_listed_companies` を、月次自動取得 + raw stage DB 永続化 + 履歴保持 + manifest 登録 + ingest_runs 連携 + drift 検知 + 通知の運用ラインに格上げ。Track A→B/C/D 並列着地、累積 15/15 pytest + ruff 0 errors。

**Why:** Phase 1 (`docs/worklogs/20260510-core-instruments-market-resync-phase1.md`) で「core.instruments 旧表記+is_active=False 728 件は全件正当廃止」と確定し、修正対象 0 件のため core 同期 ETL は不要となった。一方、JPX 公式 list を月次で取り込んで履歴化しないと、将来の市場再編・新規上場・上場廃止を運用で検知できない。Phase 2 はこのギャップを埋める「観測ライン構築」フェーズ。

**How to apply:**
- Phase 3 設計時はこの worklog をベースに「Desktop OpsHub への drift surface BFF endpoint」「core.instruments への自動同期 ETL」「True Monthly トリガー対応の register_schedules.ps1 拡張」を進める
- `raw.jpx_listed_companies_snapshots` は PK=(snapshot_date, code) の履歴型。同一日に複数実行されても UPSERT で吸収、日付が違えば追加 (Track B の `(snapshot_date, code)` 設計)
- ETF/REIT/PRO Market は raw 段階で **一切フィルタしない** (Phase 3 の core 同期 ETL で `instrument_policy` 経由でフィルタ。ADR: product-policy-etf-exclusion)
- sanity_hit_rate の閾値は 0.99、未達で `partial` + Discord P1 通知 (Track D 設計)。Phase 1 実測の 99.6% (4438/4455) を Phase 2 でも完全再現
- `Update-InvestmentTask` helper は Monthly 未対応のため Weekly 平日 (07:45) で先行登録、Monthly 切替は worklog セクション 5 の手動 PowerShell コマンドで 1 回実行
- alembic head: `20260512_01` (`raw.jpx_listed_companies_snapshots`)
- SLA registry: `ops.ingest_source_registry` source_tier='T2', expected_frequency_hours=720、`ops.data_freshness_sla` max=1080h / warn=840h
- drift_report 出力先: `tmp/drift_reports/jpx_listed_companies_<YYYYMMDD>.json` (本 repo 慣例、`data/operations/` 未存在)

**Files of record:**
- DDL: `db/greenfield_postgres/130_jpx_listed_companies.sql` + `db/foundation_postgres/78_jpx_listed_companies.sql` + `db/alembic/versions/20260512_01_raw_jpx_listed_companies_snapshots.py`
- Code: `tools/market_data/jpx_listed_companies/{repository,main}.py` 拡張
- Manifest/Scheduler: `scripts/run_manifest.yaml` (line 2909 近傍に entry 追加) + `scripts/run_jpx_listed_companies_monthly.bat` + `scripts/register_schedules.ps1` (line 1173 近傍に Update-InvestmentTask 追加)
- Drift: `scripts/check_jpx_listed_companies_drift.py` (再利用: `scripts.audit_core_instruments_market_resync._zero_pad`)
- Tests: `tests/tools/market_data/jpx_listed_companies/{test_repository,test_main_persist}.py` + `tests/scripts/test_check_jpx_listed_companies_drift.py`
- Worklog: `docs/worklogs/20260511-jpx-listed-companies-phase2.md` (Full)
- Plan: `C:/Users/kazum/.claude/plans/jpx-list-distributed-sprout.md`

**Phase 3 backlog (要対応):**
1. Desktop OpsHub に drift_report を surface する BFF endpoint (`GET /api/jpx-listed-companies/drift?date=...`)
2. core.instruments への自動同期 ETL (added/removed/segment_changed を反映、ETF/REIT/PRO Market フィルタ統合)
3. True Monthly (DaysOfMonth=1) トリガー対応の register_schedules.ps1 拡張
4. drift_check の月初自動実行を manifest に登録 (jpx-listed-companies-monthly 完了 2h 後)
5. sanity_hit_rate 残 0.4% (17 件 / active 4455) の証跡化 — Phase 1 結論との整合確認

**Multi-agent execution:**
- 4 並列マルチエージェント着地: Track A は Orchestrator 直接、Track B (sub-agent a8702b8e26ae062bf, 28 tools, 139s) / Track C (adfe7d0f30bc0a64e, 25 tools, 87s) / Track D (a9e3942153524d731, 17 tools, 108s) を並列起動
- Plan agent から 11 個の plan-vs-repo 差異を発見 (詳細 worklog セクション 3.2)。ユーザー 4 問質問で確定後 ExitPlanMode 承認
