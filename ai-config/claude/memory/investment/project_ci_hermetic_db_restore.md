---
name: project_ci_hermetic_db_restore
description: CI-HERMETIC-01 — CI に PostgreSQL service + baseline を導入し隔離テストを復帰させた着地と再利用ノウハウ
metadata: 
  node_type: memory
  type: project
  originSessionId: db4670bd-5918-4c2b-abfa-f006083adc6c
---

CI-HERMETIC-01 着地 (2026-07-04、PR #17、branch feat/ci-hermetic-db)。`requires_local_infra` 44 テストを分類し、DB があれば通る 38 を新マーカー `requires_db` へ付替え CI 復帰、実 Ollama/ffmpeg 依存 6 は継続除外。

**再利用ポイント (CI で本番相当スキーマを使う時)**
- `db/baseline/postgres/*.sql` を空 DB へ適用する共通 CLI = `scripts/apply_db_baseline.py`（`--dsn` / `--create-db`(scratch `_` 始まりのみ) / `--stamp-head`）。multi-pass apply 本体は `scripts/ddl_baseline_parity_lib.apply_sql_files_multipass`（parity checker と共有）。
- CI service image は **`pgvector/pgvector:pg16` 必須**。stock `postgres:16` だと `00_schemas.sql` の `CREATE EXTENSION vector` で全 schema 作成が全滅する（pg_trgm/pgcrypto は contrib で可、vector のみ不足）。
- `alembic stamp head` は生成 baseline が本番側 `alembic_version`（並行ブランチ revision）を載せるため素では `Can't locate revision` で落ちる → **`stamp head --purge`** で回避（BASELINE-REGEN-01 ドリフト）。
- CI の pytest `-m` は `not db` を捨てて `(not db or requires_db)` にする。広い db フィクスチャ群は除外維持しつつ requires_db だけ通す。
- マーカー付替えは同一行数置換にすると file-size-budget ラチェット(frozen 大型テスト)を不変に保てる。
- conftest 既定テスト DB 名は `investment_test`。service の POSTGRES_DB をそれに合わせる。

**分類の勘所**: `requires_local_infra` でも大半は完全 mock で実インフラ不要。真の local-only は「低レベル mock 漏れ」で実サービスに到達するケース (tdnet ollama は `_call_json_endpoint` だけ mock で後段 `_fetch_model_sizes()` が実 `127.0.0.1:11434/api/tags` を叩く / audio は `_check_ffmpeg()` subprocess)。

関連: [[project_structure_guardrails_roadmap]] (file-size budget ゲート)、BASELINE-REGEN-01 は別 Task。
