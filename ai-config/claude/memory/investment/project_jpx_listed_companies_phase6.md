---
name: jpx-listed-companies-phase6
description: JPX 隣接拡張 Phase 6 着地。Stream A (ソース横断 audit) / B (sector_changed hook + peer 再計算) / C (廃止銘柄 90日 archive) / D (drift rolling 12M + 連続劣化アラート) / E (保護コード自動再評価) / F (scheduler SLA 6M) を 6 並列マルチエージェントで着地、alembic merge revision 20260516_03 で chain 統合 (2026-05-16)
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f9b06a4-540e-41cf-9b7c-169ce54a84cd
---

JPX 銘柄マスター同期 Phase 6 (隣接拡張) 完了 (2026-05-16)。Phase 1-5 完全着地後の隣接拡張として 6 ストリームを 1 セッションで並列着地。pytest 92/92 (Stream A 8 / B 22 / C 13 / D 24 / E 13 / F 12) / ruff clean / manifest_safe_semantics PASS (checked=306, violating=0) / alembic single head=20260516_03。

**Why:** Phase 5 着地後の繰越 3 件 (F1 admin / 06-08 weekly fire / 06-15 再評価) は全て時間トリガー or 手動領域で本セッションで前進不可。一方で隣接拡張機会が 6 カテゴリ抽出されており、ユーザー指示「最大限広めに / マルチエージェントで全力」に沿って 6 ストリーム並列着地で運用品質を底上げするフェーズ。

**How to apply:**
- Stream A (`tools/quality/instrument_master_cross_audit/`): 月次 cross-source audit。jpx=4449 / jquants=4686 / edinet=4441 / tdnet=4342、all_sources=3585 (live DB 確認)。bucket は 8 種で `quality.instrument_master_cross_audit_runs` (PK=(run_id, bucket)) に格納
- Stream B (`tools/market_data/jpx_listed_companies/sync.py` 拡張 + `tools/analytics/peer_group_recompute_hook/`): sync で `sector_code_33` / `sector_code_17` の diff を検知し `finding_type='sector_changed'` を `raw.jpx_instrument_sync_findings` に記録。peer 再計算は subprocess (`tools.decision_support.sub_sector_classifier.main classify-one --code <code> --apply`) で起動、dry_run=True 時は JSON ログ enqueue のみ
- Stream C (`tools/db_admin/inactive_instrument_archive/`): 90 日経過 (`is_active=FALSE` AND `updated_at <= today - 90d`) の core.instruments を `archive.instruments_archived` へ copy (DELETE しない、復活可能性維持)。core.instruments に `last_seen_active_at` 列はないため `updated_at` を grace 判定に使用。保護コード除外、dry-run default
- Stream D (`mart.jpx_drift_trend_monthly` view + `tools/notifications/jpx_drift_streak_alert/`): rolling 24M view から rolling 12M を Desktop に提供。`JpxDriftTrendChart.tsx` 独立 panel (recharts LineChart + `ReferenceLine y=0.99`)。2 月連続 hit_rate < 0.99 で Discord P1 配信
- Stream E (`tools/quality/jpx_protected_codes_auto_review/`): `config/jpx_protected_codes.yaml` の overdue entry を `tools.market_data.jpx_listed_companies.parser` 再利用 (`investigate_adapter.py`) で評価、`config/jpx_protected_codes_review_history.yaml` に append。3 ヶ月連続 extend で `escalate_jpx` 判定 → Discord P1。**本体 yaml は編集禁止 (運用者手動)**
- Stream F (`tools/quality/instrument_master_scheduler_sla/`): JPX 3 task の rolling 6M SLA (success_rate / sla_hit_rate=duration<=timeout 率)。`TASK_ID_ALIASES` で `jpx-true-monthly` / `jpx-listed-companies-monthly` を canonical `jpx-listed-companies-sync-monthly` に folding。BFF は DISTINCT ON + padding で常に 3 件返す

**alembic chain:**
- `20260514_13 → 20260514_19 (Stream A)` → `20 (Stream C)` → `21 (Stream D)`
- `20260514_13 → 20260516_01 → 20260516_02 (Stream F)` (並列 head になっていた)
- `merge 20260516_03 (Phase 6 mergepoint)` で統合 → single head=`20260516_03`
- Stream B / E は DDL 追加なし
- `uv run alembic upgrade head` を本番適用時に実行

**Scheduler:**
- `Update-InvestmentTask` は `-DayOfMonth` 未サポート → 全 Stream で **月曜週次 fallback** 採用
- 月次 cron は `scripts/run_manifest.yaml` の `schedule_type=monthly` メタデータとして残置 (将来 PowerShell 関数を拡張すれば自然に月次化可能)
- 追加 task 5 件: `instrument-master-cross-audit-monthly` / `inactive-instrument-archive-monthly-dryrun` (+ manual-only apply) / `jpx-drift-streak-alert-monthly` / `jpx-protected-codes-auto-review-monthly` / `instrument-master-scheduler-sla-monthly` / `peer-group-recompute-hook-monthly`

**Files of record:**
- 新規 quality tool: `tools/quality/{instrument_master_cross_audit,jpx_protected_codes_auto_review,instrument_master_scheduler_sla}/`
- 新規 analytics tool: `tools/analytics/peer_group_recompute_hook/`
- 新規 db_admin tool: `tools/db_admin/inactive_instrument_archive/`
- 新規 notifications tool: `tools/notifications/jpx_drift_streak_alert/`
- sync.py 拡張: `tools/market_data/jpx_listed_companies/sync.py` (`_load_jpx_snapshot_rows` 17 業種列対応 + `_detect_sector_changes` + `SyncSummary.sector_changed_count`)
- ADR: `docs/decisions/inactive-instrument-archive-policy.md`
- DDL: `db/greenfield_postgres/{quality/instrument_master_cross_audit_runs.sql,archive/instruments_archived.sql,mart/jpx_drift_trend_monthly.sql,quality/instrument_master_scheduler_sla_runs.sql}` + `db/foundation_postgres/` 同期
- alembic: `db/alembic/versions/{20260514_19,_20,_21,20260516_02,_03}*.py`
- 新規 history yaml: `config/jpx_protected_codes_review_history.yaml`
- 新規 Desktop panel: `desktop/src/components/panels/{InstrumentMasterCrossAuditPanel,JpxDriftTrendChart,InstrumentMasterSchedulerSlaPanel}.tsx` + `.test.tsx`
- BFF: `tools/api/decision_api/{ops_hub_repository.py, routers/ops.py}` 末尾 append (3 endpoint: `/api/v1/ops/instrument-master/cross-audit`, `/api/v1/ops/jpx/drift-trend`, `/api/v1/ops/instrument-master/scheduler-sla`)
- api-client: `desktop/src/lib/api-client.ts` 末尾 append + `types/{misc,system}.ts` 拡張
- scheduler: `scripts/run_manifest.yaml` + `register_schedules.ps1` 末尾 append、`scripts/run_*.bat` 6 本
- Plan: `C:/Users/kazum/.claude/plans/compiled-honking-kahan.md`

**Multi-agent execution:**
- Phase 1 (Orchestrator): 3 Explore agent 並列で現状調査、ユーザー 1 問でスコープ確定 (フル 6 ストリーム)
- Phase 2 (6 並列着地、初回): Stream A/C/D/E/F が着地、B が halt (現ブランチに Phase 3-5 ソース不在)
- Phase 3 (Orchestrator): feat/reform-phases-batch から `tools/market_data/jpx_listed_companies/` 等を checkout で取り込み、Stream B 再投入で 着地
- Phase 4: ユーザー側で別作業の reset が走り Stream A/C/D/E/F の成果物がディスクから消失 (origin 不明、おそらく並行セッション)
- Phase 5 (再 5 並列): Stream A/C/D/E/F をゼロから再着地 (Stream B は維持)
- Phase 6 (Orchestrator 最終): alembic multi-head (20260514_21 と 20260516_02) を merge revision 20260516_03 で統合、ruff/pytest/vitest/manifest_safe 全 PASS

**Smoke verification (2026-05-16):**
- `uv run ruff check ...` → All checks passed
- `uv run pytest tests/tools/{quality,analytics,db_admin,notifications}/... tests/tools/market_data/jpx_listed_companies/test_sync.py -q` → **92 passed**
- `uv run python scripts/check_manifest_safe_semantics.py` → PASS (checked=306, violating=0)
- `uv run alembic -c db/alembic/alembic.ini heads` → **20260516_03 (single head)**
- `uv run python -m tools.quality.instrument_master_cross_audit.main --dry-run` → live DB OK
- `uv run python -m tools.analytics.peer_group_recompute_hook.main --dry-run --since 2026-05-01` → sector_change_count=0 no-op
- `uv run python -m tools.db_admin.inactive_instrument_archive.main --dry-run` → protected_count=10, eligible_count=0
- `uv run python -m tools.notifications.jpx_drift_streak_alert.main --dry-run` → view 不在 partial (graceful)
- `uv run python -m tools.quality.jpx_protected_codes_auto_review.main --dry-run --today 2026-05-16` → overdue=0 success / `--today 2026-06-20` → overdue=10、全 extend
- `uv run python -m tools.quality.instrument_master_scheduler_sla.main --dry-run --months 6` → legacy `jpx_listed_companies` を canonical へ folding 確認

**Follow-ups (繰越):**
1. ~~Desktop OpsHub への新 panel 配線~~ **完了 (2026-05-17)**: `InstrumentMasterTab.tsx` に 4 panel (JpxDriftReport + JpxDriftTrendChart + CrossAudit + SchedulerSla) を配線、OpsHub タブ `jpx-drift` → `instrument-master` 置換、旧 `JpxDriftTab.tsx` 削除。BFF smoke test 8 ケース追加 (`tests/tools/api/test_ops_phase6_routers.py`)。ruff clean / pytest 2084 / typecheck 0 error。詳細: `docs/worklogs/20260517-jpx-phase6-followup-desktop-wiring.md`
2. `alembic upgrade head` の本番 DB 適用 (alembic chain 自体は通っているが DB 反映は別ジョブ)
3. ~~`Update-InvestmentTask` 関数の `-DayOfMonth` パラメータ拡張~~ **不要と判明 (2026-05-17)**: Phase 3 worklog (line 16) で `Update-InvestmentTask` helper は既に `DaysOfMonth` 完全対応 (line 616, 648-650 等) と確認済み。Phase 2/6 メモの「Weekly only」は誤認
4. Phase 5 繰越 3 件 (F1 admin 手動 / 06-08 weekly fire 観測 / 06-15 保護コード再評価) は引き続き継続
5. Stream F の `TASK_ID_ALIASES` は manifest の `source_name` が canonical へリネームされた時点で自然に解消
6. BFF endpoint: Phase 6 メモで「5 endpoint 追加」とあったが実は 3 endpoint のみコミット済み。`inactive_instrument_archive` / `jpx_protected_codes_auto_review` は tool 層のみで BFF 未配線、Desktop からの操作が必要になれば後続 PR で追加

**関連:**
- @./project_jpx_listed_companies_phase5.md
- @./project_jpx_listed_companies_phase4.md
- @./bugs_core_instruments_market_reform_stale.md
- @./reference_product_policy_adr.md
