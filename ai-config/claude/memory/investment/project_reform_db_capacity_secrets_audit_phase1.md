---
name: 改革ロードマップ #11 + #12 Phase 1 並列着地 (2026-05-10)
description: DB容量・索引・保持ルール (#11) と秘密情報・外部接続監査 (#12) を Phase 1 で並列着地。既存 _ops_catalog.py / Desktop OpsHub に乗せて新タブなし。
type: project
originSessionId: 6192aae2-c325-49fa-b360-68bc84f12fc7
---
# Reform #11 / #12 Phase 1 完了 (2026-05-10)

「先に判断したい」グループの 2 件を 既存基盤への乗せやすさ最優先 で並列着地。新タブ追加なし、既存 `_ops_catalog.py` / `DataOpsTab.tsx` / `DbRegistryTab.tsx` への拡張で完結。

**Why:** DB 肥大化 / 保持違反が運用画面で見えない、secret/external connection audit の history が残らない問題を解消。両提案とも `_ops_catalog.py` に既に静的監査ロジックがあり、それを tool に切り出して履歴永続化 + Desktop 強化が最小コスト。

**How to apply:**
- 容量 snapshot は `_build_db_capacity_retention_snapshot()` (line 160-330) を拡張: `unused_indexes` / `retention_violations` / `source_refs` / `summary.{unused_index_count, retention_violation_count, retention_critical_count}` を返す。`unavailable` 分岐でも空配列で返すこと
- secret audit は `_build_secret_external_audit()` (line 42-150) を `tools/quality/secrets_audit/auditor.py:build_audit_snapshot()` 委譲に置換。後方互換キー (`secret_count`, `configured_secret_count`, `external_connection_count`, `items`, `external_connections`, `value_policy`) は全温存
- TABLE_SPECS の `retention_policy_id` (代表 7 件のみ紐付け) で per-table の retention violation を判定。識別子は `_quote_pg_identifier` で whitelist 経由 quote、値は `?` プレースホルダ規約
- `ops.security_audit_events` は **実値カラム無し**。auditor finding に実値含めず、log scrubber で出力時にも遮断 (3 層)
- history endpoint `/api/v1/security/audit-history` は概要のみ (severity_counts / category_counts)、個別 finding は返さない
- Desktop は `useDataOperations` / `useSecurityAuditHistory` hook を `useOpsHubQueries.ts` に集約、既存 `DataOpsTab` / `DbRegistryTab` への列・サマリ追加のみ

## 既存ファイル変更
- 修正: `tools/api/decision_api/serving/_ops_catalog.py:42-330` (β-11 / β-12 で別領域、衝突なし)
- 修正: `tools/api/decision_api/{repository.py, serving_repository.py, routers/catalog.py, app.py}` (history endpoint 配線)
- 修正: `shared/db_status/{_models.py, _registry.py}` (TableSpec retention_policy_id 後方互換 optional + 代表 7 件紐付け)
- 修正: `shared/logger.py` (loguru filter で SECRET_NAME_HINTS マッチ値を `***REDACTED***` 置換、起動時 1 回 cache)
- 修正: `db/greenfield_postgres/60_ops_quality.sql` (末尾 27 行で `ops.security_audit_events` + 2 index)
- 修正: `desktop/src/lib/{api-client.ts, query-keys.ts}` + `desktop/src/lib/types/system.ts:1246-1306`
- 修正: `desktop/src/pages/ops-hub/hooks/useOpsHubQueries.ts` (`useDataOperations` / `useSecurityAuditHistory` 新設)
- 修正: `desktop/src/pages/ops-hub/tabs/{DbRegistryTab.tsx, DataOpsTab.tsx, DataOpsTab.test.tsx, CatalogTabs.test.tsx}`
- 修正: `desktop/src/i18n/ja.ts:515-517` (totalBytes / retention label)

## 新規ファイル
- `tools/quality/db_capacity_audit/{__init__.py, auditor.py, main.py, README.md}`
- `tests/tools/quality/db_capacity_audit/{__init__.py, test_auditor.py}`
- `tools/quality/secrets_audit/{__init__.py, auditor.py, main.py, README.md}`
- `tests/tools/quality/test_secrets_audit_{auditor,main}.py`
- `tests/tools/api/test_security_audit_history_endpoint.py`
- `tests/shared/test_logger_scrubber.py`
- `db/alembic/versions/20260510_22_security_audit_events.py` (down_revision = `20260511_04`)

## Verification
- `uv run ruff check .` clean
- `uv run pytest <新規ターゲット>` 68 passed
- `cd desktop && npx tsc --noEmit` exit 0
- `cd desktop && npm run test` 1763 passed (前回 1762 + 新規 1)
- `cd desktop && npm run build` exit 0

## 落とし穴・Tip
- 新 BFF endpoint を追加する場合、`tools/api/decision_api/response_models.py` に `XxxReadContractResponse(DomainReadContractBase)` を追加 + `READ_DOCS_ONLY_CONTRACT_MODELS` tuple 登録 + `app.py:RESIDUAL_READ_ROUTE_CONTRACT_SCHEMAS` 配線が**必須**。さもないと openapi で `ReadObjectContractResponse` にフォールバックして `tests/scripts/test_decision_api_endpoint_contracts.py::test_default_decision_api_docs_only_contract_rollup` と `tests/tools/api/test_decision_api_response_models.py::test_wave3_residual_openapi_contracts_remove_all_read_object_refs` が回帰する。endpoint 1 個追加で `response_level_counts["typed"]` が +2 (200 + 422) する点も両 test の期待値更新で対応
- alembic head は `20260511_04` (Phase 7 Track D tail) が現在 head。プラン想定の `20260510_21` より進行済 → down_revision は実際の `alembic heads` で確認すること
- `tests/tools/quality/__init__.py` は既存ファイル (重複作成しない)
- TABLE_SPECS の `date_column` を retention probe に流用 (既存信頼境界の whitelist として再利用、二重 whitelist 不要)
- `_fetch_last_audit_run()` は DB 失敗時に静かに `None` を返す → テスト環境で DB 不在でも snapshot 生成は破綻しない
- loguru の log scrubber: capsys/caplog 不可 → `logger.add(StringIO(), filter=...)` 専用 sink パターン
- `useDataOperations` と既存 DataOpsTab の同 queryKey が React Query で dedupe される → 2 surface 1 リクエスト

## 残 Follow-ups
- #11 Phase 2: scheduler 統合 (`run_manifest.yaml` 登録、retention 削除提案の自動実行は要承認)
- #11 Phase 3: TABLE_SPECS 全件への retention_policy_id 付与 (Phase 1 は代表 7 件)
- #12 Phase 2: secrets_audit を CI gate / scheduler 登録、log scrubber の rotation 対応 / extra・exception payload redaction
- worklog: `docs/worklogs/20260510-reform-11-12-db-secrets-audit-phase1.md`
- プラン: `~/.claude/plans/12-docs-roadmap-investment-app-reform-p-fizzy-dijkstra.md`
