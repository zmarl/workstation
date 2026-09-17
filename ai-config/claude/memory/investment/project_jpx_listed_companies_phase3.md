---
name: jpx-core-instruments-phase-3
description: 自動同期 ETL + Desktop OpsHub 可視化 + scheduler 配線で観測ライン+自動修復ライン+可視化レーンの 3 段運用を完成 (2026-05-14、3 並列マルチエージェント着地)
metadata: 
  node_type: memory
  type: project
  originSessionId: 9c7d6788-2cc7-4292-8d2b-af15aa354759
---

JPX 公式 list × core.instruments 銘柄マスター同期 Phase 3 完了 (2026-05-14)。Phase 2 で完成した観測ライン（月次取り込み + drift 検知）の上に、自動修復ライン（`core.instruments` 自動同期 ETL）と可視化レーン（Desktop OpsHub "銘柄マスター同期" タブ）を上乗せして閉ループ化。Track A/B/C を 3 並列マルチエージェントで着地、Track D は orchestrator 直接実装。累積 ruff 0 errors / pytest 42 件 all pass / alembic head=`20260514_03` / sanity_hit_rate=0.996184 (Phase 1/2 と完全一致)。

**Why:** Phase 2 (`docs/worklogs/20260511-jpx-listed-companies-phase2.md`) で観測ラインが完成したが、JPX list の事実が `core.instruments` に自動反映されない・drift_report が OpsHub に出ていない 2 つのギャップが残っていた。Phase 3 はこの 2 つを埋めて閉ループ化するフェーズ。

**How to apply:**
- Phase 4 以降で「market 再編 / 上場廃止 / 新規上場の運用検知」を語るときは Phase 3 を起点にする。スケジューラ → sync ETL → core.instruments → BFF → Desktop の経路がカノニカル
- `is_active=FALSE` 行は **絶対に TRUE に flip しない**（Phase 1 で確定した 728 件正当廃止と整合）。R1 regression test `test_sync_never_flips_is_active_false_back_to_true` が永続ガード
- jquants との競合は `instrument_sync.py` の AND ロジックで恒久解消（順序非依存）
- 旧表記 → 新表記は初回 sync 一括 `legacy_label_resync` で migration、P1 通知抑止。以降は通常 segment_changed
- alembic revision は `20260514_03`（plan の `_01` から変更。`_01` `_02` は earnings_agent_evaluations / company_kpi_trend_assessments で先取り済み）
- drift_check の manifest module は `tools.quality.jpx_listed_companies_drift_check.main` （薄い委譲ラッパー）。`scripts.*` 直接記述は `check_manifest_safe_semantics.py` の `^tools\.` で reject される
- Phase 2 worklog の「`Update-InvestmentTask` Weekly only」記述は誤認。実際は DaysOfMonth 完全対応 (`register_schedules.ps1:610-820`)。Monthly 登録は admin PowerShell で `register_schedules.ps1` 実行のみ

**Files of record:**
- DDL: `db/greenfield_postgres/131_jpx_instrument_sync_findings.sql` + `db/foundation_postgres/79_jpx_instrument_sync_findings.sql` + `db/alembic/versions/20260514_03_raw_jpx_instrument_sync_findings.py`
- ETL: `tools/market_data/jpx_listed_companies/{diff_query,sync,main,repository}.py`
- jquants patch: `tools/market_data/financial_unifier/instrument_sync.py` 1 行 (AND ロジック)
- drift refactor: `scripts/check_jpx_listed_companies_drift.py`（diff_query 経由）
- BFF: `tools/api/decision_api/routers/ops.py` (`GET /api/v1/ops/jpx-drift-report`) + `tools/api/decision_api/ops_hub_repository.py` (`get_jpx_drift_report`)
- Desktop: `desktop/src/components/panels/JpxDriftReportPanel.tsx` + `desktop/src/pages/ops-hub/tabs/InstrumentMasterTab.tsx` + OpsHubPage タブ追加
- Manifest: `scripts/run_manifest.yaml` (`jpx-listed-companies-sync-monthly` 07:50 + `jpx-listed-companies-drift-check-monthly` 09:45) + `.bat` × 2 + `register_schedules.ps1` 2 行
- Drift wrapper: `tools/quality/jpx_listed_companies_drift_check/{__init__,main}.py`
- Worklog: `docs/worklogs/20260514-jpx-listed-companies-phase3.md` (Full)
- Plan: `C:/Users/kazum/.claude/plans/zippy-petting-quilt.md`

**Smoke test (live DB, 2026-05-14):**
- snapshot_date=2026-05-11、would_add=9 / would_remove=533 / would_segment_change=176 / would_legacy_label_resync=1 / fund_like_excluded=518 / would_finding=1237
- would_active_false_but_in_jpx=0（R1 違反なし、既存 is_active=FALSE 行への誤復活なし）
- BFF: sanity_hit_rate=0.996184 (Phase 1/2 と完全一致)

**Follow-ups（残課題）:**
1. F1 live Task Scheduler 実登録: admin PowerShell で `register_schedules.ps1` 実行のみ（高優先）
2. F2 `sync --apply` 初回本番実行: dry-run で would_remove=533 確認済、Phase 1 728 件正当廃止と整合性レビュー後（中優先）
3. F3 Vitest 既存 regression `KpiDriverPanel.test.tsx`: Phase 3 無関係、commit d60165ee 由来（低）
4. F4 manifest tool_tiers 残 4 件: Phase 3 無関係の既存違反（低）
5. F5 BFF Panel の `prev_value`/`new_value` JSONB キー名再確認: `sync --apply` 実投入後に検証（低）

**Multi-agent execution:**
- 3 並列 + Orchestrator: Track A (`a3bdc47a8a39c5297`, 71 tools, 584s) / Track B (`a06bce2a8009ca947`, 99 tools, 799s) / Track C (`aa9df30b521c7ee37`, 83 tools, 531s) / Track D (Orchestrator 直接実装)
- Plan agent から 3 つの計画差異を事前発見: (1) alembic id 衝突 → `_03` に変更、(2) `module: scripts.*` 不可 → 委譲ラッパー新設、(3) `Update-InvestmentTask` 実は DaysOfMonth 対応済 → backlog #3 は実装ではなく検証で完了
