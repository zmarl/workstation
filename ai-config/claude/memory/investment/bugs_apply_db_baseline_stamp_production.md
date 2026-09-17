---
name: bugs-apply-db-baseline-stamp-production
description: apply_db_baseline.py の stamp head が --dsn でなく ambient POSTGRES_DSN（=本番）を stamp する事故 (2026-07-13 実発生・修正済み)
metadata: 
  node_type: memory
  type: project
  originSessionId: 88a5309c-e481-421b-8c2f-fa03fe409418
---

## apply_db_baseline の stamp が本番 alembic_version を汚染

- **問題**: `scripts/apply_db_baseline.py --dsn <scratch> --stamp-head` の stamp サブプロセスが
  env override なしで `alembic stamp head --purge` を実行。env.py は POSTGRES_DSN を環境から
  解決するため、**scratch でなく本番を stamp**。2026-07-13 に本番が未適用 revision の head に
  stamp される実事故（--purge で version 行も消えてから書き換わる）。
- **症状**: `alembic upgrade head` が「適用済み」と判断して DDL をスキップ。適用検証
  （制約・テーブル移動の実在確認）で発覚。
- **復旧**: 本番の実状態に対応する revision へ `alembic stamp <実際に適用済みのrev>` で巻き戻し
  → upgrade head で実適用。
- **修正**: stamp_alembic_head(dsn) が subprocess env に POSTGRES_DSN=dsn を固定（2026-07-13）。
- **教訓**: alembic をサブプロセスで呼ぶスクリプトは必ず対象 DSN を env で固定する。
  DDL 適用後は alembic_version でなく**実オブジェクトの存在**で検証する。

関連: [[project-db-ops-safety-batch-2026-07-13]]
