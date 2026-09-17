---
name: project-db-lane-failclosed-test-repair-2026-07-18
description: fail-closed DB契約化(07-16/17大統合)後のテストレーン修理パターン集。requires_db/per-test bootstrap/migration replay prereq/pinned SQL stale
metadata: 
  node_type: memory
  type: project
  originSessionId: bf24eae4-fa61-4218-b18d-6f1d801b64fa
---

大統合(07-16/17)で production が fail-closed 契約化され(`shared/db_contracts/assertions.py` の require_base_tables 等が「alembic 管理テーブルが既に存在」を assert、旧 init 関数の CREATE 動作は廃止)、DB テストが赤化。2026-07-18 に db-lane を修理した際の再利用パターン。

**基本ドクトリン**: production(tools/ shared/ db/)は変更禁止。テスト側で「契約が要求するテーブルを事前に用意する」形に直す。production 変更が要るものは停止して報告。

**修理パターン**:
- **フル baseline を当てる**: モジュール/テストに `pytestmark = pytest.mark.requires_db`(または per-test `@pytest.mark.requires_db`)。conftest の `pg_connection` が requires_db 時のみ `apply_local_gate_baseline`(db/baseline/postgres/*.sql フル)を適用。無印だと最小 reference baseline(`_PG_REFERENCE_BOOTSTRAP_SQL_FILES` = 5ファイルのみ)で契約テーブル不在。
- **file-local `pg_connection` override の罠**: テストが自前で `pg_connection`→`pg_transactional_connection`(最小 baseline) を返す override を持つと requires_db が効かない。override を消して conftest の pg_connection に束縛させる。
- **混在ファイルは per-test マーク**: DBテストと非DB(monkeypatch)テストが同居するファイルは module 全体マークを避け、DBテストだけ per-test マーク。非DBを fast lane に残す。
- **module 一括 bootstrap は「テーブル不在前提」テストを壊す**: 最初 disclosure conftest の module fixture に tdnet/large_holdings を一括 bootstrap したら、`tdnet_document_texts` 常設で `test_rebuild_event_store_handles_missing_tdnet_disclosure_feed_table`(不在前提)が破綻。→ **opt-in の per-test fixture** にして必要テストだけ取り込む(`tdnet_backfill_schema` / `large_holdings_schema`。`tests/fixtures/runtime_schema.bootstrap_runtime_schema_contract(conn, owner)` を get_connection 経由で呼ぶ→savepoint rollback で後始末)。
- **migration replay テストの prereq**: `tests/db/test_*_migration.py` の isolated_postgres 系は raw psycopg で単一 revision の upgrade() のみ実行するため、より前の revision が作るテーブルは自前で用意が必要。フル baseline を当てると revision 自身のオブジェクトと衝突(部分的にしか idempotent でない: 一部トリガが DROP IF EXISTS 無し→`DuplicateObject`)。→ `tests/db/_migration_prereqs.py` に relaxed stub(全カラム nullable・CHECK/view 無し)を作り upgrade 前に適用。20260711_10 は core.financial_facts_resolved_v2 / public.tdnet_earnings_summary / decision.earnings_quality_labels が prereq。
- **pinned SQL の stale**: `test_screening_custom_view.py` の赤は baseline 不足でなく、テストが読むゴールデン SQL が旧版(`_pinned_sql/94_mart_screening_custom.sql`)。revision が実際に適用する現行版(`109_..._net_debt_period_guard.sql`)に差し替え。golden テストは「revision が適用する pinned SQL」を読ませる。

**この時 production 側で判明した2バグ(親が修正)**:
- `shared/db/pool.py` `_normalize_sql` の `?`→`%s` 無差別置換が、CREATE FUNCTION 本体の JSONPath フィルタ `'$ ? (...)'` の `?` も破壊し SyntaxError。→ dollar-quote 素通し化で修正。[[project-hv-double-annualisation-fix-2026-07-18]] の jsonb `?` 演算子と同系。
- `db/alembic/versions/20260711_10_earnings_fact_integrity_ledger.py` の downgrade が unit 列付き view を `CREATE OR REPLACE VIEW` で列削除しようとして `cannot drop columns from view`。→ recreate 前に非CASCADE `DROP VIEW IF EXISTS mart.vw_financial_metric_panel_v2` 追加。migration downgrade で view の列を減らす時は DROP 先行が必須。
