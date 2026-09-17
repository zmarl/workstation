---
name: project-db-ops-volume-check-persist-2026-07-12
description: "volume_check_mode registry override + cross-audit --persist enablement (dbopt worktree, 2026-07-12)"
metadata: 
  node_type: memory
  type: project
  originSessionId: ae24642f-3458-49e6-bcbf-c3d78398485f
---

**DB ops quality gates 配線 (2026-07-12, feat/hidden-asset-screener の worktree D:\Dev\Investment-dbopt)**。DDL revision `20260712_01_db_ops_quality_gates_ddl` は本番適用済み(別担当)。本バッチはその配線+シード+persist有効化。

## volume anomaly の registry override
- `ops.ingest_source_registry.volume_check_mode` (off/warn/fail) と `min_expected_records_out` で source 別上書き。`tools/db_admin/status/volume_baseline.py` の `evaluate_source` が mode を受ける: off=検知スキップ(status="off")/warn=既定/fail=検出時 severity="fail" に昇格(dataclasses.replace)。floor は history 不足でも直近成功日 < floor で発火(detector="min-floor")。
- override 読取は `_load_volume_check_overrides()`(registry 不達なら {} で warn 既定に degrade)。`collect_volume_anomalies(overrides=...)` に注入可(テスト用)。
- 配線: `cmd_ingest.py` の `_attach_volume_anomalies` が fail severity anomaly を見たら `payload["ok"]=False` + `volume_anomaly_fail_sources`。warn は従来どおり ok 不変。

## off-seed (ノイズ抑制)
- `shared/db_contracts/ops.py` の `sync_ops_ingest_governance_defaults` 末尾で `_seed_volume_check_off_modes` 実行。定数 `_VOLUME_CHECK_OFF_SEED_SOURCES`(ops.py 内、5件: capital_policy_scorer/event_study_engine/expectation_gap_analyzer/ipo_pipeline/nlp_sentiment)。
- **warn の行のみ off へ UPDATE**(手動 fail/off は保護)。registry 非存在は insert せず report のみ。返り値 key: volume_check_off_updated/already_off/skipped_manual/absent。
- 定数を frozen file `_ops_governance_defaults.py`(budget 1570 固定)に置くと file-size-budget FAIL → ops.py 側に置く。
- 実DB効果: `ingest-governance-audit` の volume_anomalies 18→11、seed 5 source 全消滅を確認。

## cross-audit persist
- `scripts/manifest/quality_audit.yaml` の financial-facts-cross-audit-daily args に `--persist` 追加 → `build_run_manifest.py --write` 再生成(引数は `--write`/`--check` 必須)。
- 1回実行で `raw.financial_facts_cross_audit` に 25883 行(match除外して非match全部)。resolution_status 既定 'open'。6619 source_year_label_shift(5) + 7202 concept_basis_mismatch(1) を `false_positive` へ UPDATE(2026-07-11 裁定)。

## 落とし穴
- `tests/tools/quality/financial_facts_cross_audit/test_main.py` の `_install_datasets` は fetch_theirs/fetch_ours を mock するが **fetch_ours_label_backed を mock 漏れ** → `main.run()` が実DBを叩く隠れ依存。DB健全時は緑、pool 劣化時に PoolTimeout で偽 fail。`lambda: set()` を追加して純 unit 化(空集合なら Rule A 未発火で year_offset assertion 維持)。
- **psycopg_pool の cold-start 詰まり**: 接続確立が遅い時間帯(~8s/conn)は pool.getconn 既定 1s timeout で PoolTimeout 連発、direct psycopg.connect は成功。env `POSTGRES_POOL_RETRY_INTERVAL_SEC=20 POSTGRES_POOL_RETRY_MAX_ATTEMPTS=4 POSTGRES_POOL_MIN_SIZE=1` で pool 経由 CLI を通せる。bare pool でも worker thread が stuck → server/threading 由来の環境 transient(コード無関係)。
