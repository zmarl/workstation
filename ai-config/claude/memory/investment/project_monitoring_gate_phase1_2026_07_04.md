---
name: project-monitoring-gate-phase1-2026-07-04
description: 監視ゲート整備 Phase 1 (ingest-governance-audit 強化 + scheduler カバレッジ + health-pack NO_DATA)。実DB breach baseline と grandfather 設計
metadata: 
  node_type: memory
  type: project
  originSessionId: 8eca7815-00b8-4f60-b28f-29474a402de1
---

# 監視ゲート整備 Phase 1 (2026-07-04, feat/functional-uplift-p1, 未コミット)

正本ゲートを `ingest-governance-audit`（registry×SLA×runs×manifest×freshness probe の5面突合、breach→exit 1）に一本化する Phase 1。team-lead 委任で実装。

## 変更点（機能）
- **never-run 昇格**: active 登録ソースが観測窓に run ゼロ かつ fresh probe なし → breach（`active_sources_missing_runs`）。ただし偽陽性抑制2種: (1) registry `expected_frequency_hours` が観測窓超なら免除 (`expected_frequency_exceeds_window`)、(2) primary_ingest_task のスケジュールが stale 窓内に run を期待しないなら免除 (`outside_expected_schedule_window`)。抑制は drift.active_sources_missing_runs_suppressed に理由付きで残す
- **SLA sanity breach**: active data_freshness_sla 行で `max_lag_hours>0` かつ `warn_lag_hours<=max_lag_hours` 違反 → breach（`scripts/check_freshness_sla_coverage.py` L117-138 相当を移植。同スクリプトは手動プレフライトとして残置）
- **`--require-sla-coverage`**（既定 off）: missing SLA coverage を warning→breach 昇格
- **`--allow-sources <csv>`**: grandfather。指定ソースを全 breach カテゴリから除外し `allowed_breaches` に別記。ok 判定から外れる。options_flow のように複数カテゴリ跨ぎも正しく分離
- **scheduler-audit `--min-coverage-ratio <float>`**（既定 None）: coverage_ratio 未満で exit 1。manifest `scheduler-audit-daily` に `--min-coverage-ratio 0.85` 投入（段階導入）
- **health-pack NO_DATA 合成**: `--active-registry-only` 時、active registry - 観測 の差分を latest_started_at=None のスタブ IngestSourceInfo として注入→既存分類で NO_DATA。manifest `db-ingest-freshness-check-daily` の `--fail-on-health` に NO_DATA 追加（`--no-exit-on-health-fail` 維持で exit 1 にはせず、--enqueue-backlog 経由で failure inbox に乗せる）
- **新タスク** `db-ingest-governance-audit-daily`（args: ingest-governance-audit --json の観察モード、07:20 登録、bat=run_db_ingest_governance_audit_daily.bat、scheduled_task_name=DbIngestGovernanceAuditDaily）

## 実DB breach baseline (2026-07-04)
- registry active=83 / SLA active=83（**SLA coverage 完全**、sla_sanity 違反 0、missing_data_freshness_sla 0 → --require-sla-coverage は現状無影響）
- breaches: `manifest_missing_primary_ingest_task`=[jpx_listed_companies, options_flow] / `unhealthy_active_sources`=[disclosure_embedding_indexer(ERROR, disclosure-embedding-index-daily 連続失敗)] / `active_sources_missing_runs`=[egov_pubcom, law_tracker, options_flow, sector_kpi_foundation_audit]
- 抑制済み(正常): company_theme_classifier / sub_sector_classifier(週次スケジュール) / jpx_listed_companies(freq 720h>窓)
- grandfather 設計材料: 上記6ソースを --allow-sources に入れると ok=True。恒久除外でなく「既知未整備」を明示する運用を想定

## 検証
- pytest tests/tools/db_admin 188 passed、routine_runner scheduler 全 pass、ruff clean、check_manifest_cron_schema/mode_policy PASS
- **未コミット**（team-lead がまとめてコミット）。Windows タスク登録（DbIngestGovernanceAuditDaily）は password 要のため handover

関連: [[bff_endpoint_coverage]] [[freshness_sla_coverage]] [[project_functional_uplift_202607]]
