---
name: Cloud S3 廃止（filesystem正本化, 2026-04-17）
description: Durable object store の正本は filesystem 固定。Cloud S3 は廃止済み、再導入は新ADR必須。
type: project
originSessionId: 0f2999e1-7e70-4e6e-99b6-2167d1f58f61
---
Cloud S3 は 2026-04-17 に durable object store として廃止済み。正本は filesystem 固定（`OBJECT_STORE_BACKEND=filesystem`）。

**Why:** ユーザー方針（S3 運用は廃止）。契約・テスト・コードが `s3` を強制していたため、`.env` の `filesystem` 設定と齟齬があり `test_remote_ready_stack_contract_defaults_are_loaded` が失敗していた。filesystem を正本として全面整合を取る方向で 2026-04-17 に契約切替を実施。

**How to apply:**
- `shared/config.py` の `object_store_backend` 既定値は `"filesystem"`（`# filesystem (fixed contract; s3 deprecated)` コメント）。
- `shared/object_store.py` は `FilesystemObjectStore` が唯一の実装。`S3ObjectStore` は削除済み。`get_object_store(backend)` は `"filesystem"` 以外で `ValueError`。
- `.env` / `.env.example` は `OBJECT_STORE_BACKEND=filesystem`、`OBJECT_STORE_ROOT=data/object_store`、`OBJECT_STORE_BUCKET_RAW/LAKE/ARTIFACTS` を使う。`S3_BUCKET_*` は legacy 互換のため残しているが空文字列運用。
- `scripts/check_s3_contract_compliance.py` / `scripts/check_runtime_env_contract.py` は filesystem 基準で契約を強制（`ALLOWED_OBJECT_STORE_BACKENDS=("filesystem",)`）。
- `tools/api/decision_api/main.py` の startup validator は `object_store_backend != "filesystem"` でエラー追加。
- `docs/データ基盤構築計画.md` §1 / §2.1 / §3.3 / §5.1 / §6 / §7 と `docs/decisions/postgres-sole-write-target.md` §Contract Update 5 は filesystem 正本 + S3 廃止を明記済み。
- S3 を再導入する場合は新規 ADR 発行が必須。既存の `docs/decisions/postgres-sole-write-target.md` と `docs/データ基盤構築計画.md` §7 禁止事項に違反する。
