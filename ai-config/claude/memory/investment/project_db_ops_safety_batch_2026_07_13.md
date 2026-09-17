---
name: project-db-ops-safety-batch-2026-07-13
description: "DB運用安全化バッチ完了 (2026-07-13, dbopt worktree)。ガードレール2層+スキーマ衛生DDL 3本本番適用+実バグ5系統修理+baseline適用不能の修理"
metadata: 
  node_type: memory
  type: project
  originSessionId: 88a5309c-e481-421b-8c2f-fa03fe409418
---

# DB運用安全化+スキーマ整理+コード改善バッチ (2026-07-13, feat/db-ops-optimization)

出典: 2026-07-12 統合バックログ + 3方向調査。worklog: docs/worklogs/20260713-db-ops-safety-batch.md

## 完了内容
- **監査台帳回収**: 20260712 監査4部作が book-knowledge worktree に未コミットで孤立 → docs/audits/ へ正式コミット（50項目バックログ含む）
- **pool ガードレール**: statement_timeout 900s / idle_in_tx 1800s / app_name ツール別化 / max_size 10→20 / retry_interval 1→10s（exit 65 の本丸は getconn timeout=max(1,interval) の1秒窓）/ per-call override `get_connection(statement_timeout_sec=)`
- **alembic ガードレール**: env.py が lock_timeout 5s + statement_timeout 10min を注入（ALEMBIC_* env override）。transaction_per_migration=True → 冒頭 `SET LOCAL statement_timeout='0'` がエスケープハッチ
- **timestamptz 方針**: 新規列必須 (>= 20260713_02)、check_alembic_timestamptz.py を CI 配線。既存504列は移行しない（ADR 20260713）
- **DDL 3本本番適用済み**: 02=law_updates/ratings に PK+自然キーUNIQUE（NULL id backfill）、03=死蔵 ops.ingest_runs/errors → legacy_archive、04=raw bak 2本 → legacy_archive。**DROP は次バッチ**
- **実バグ修理**: topix_tracker f-string欠落3箇所（読取系全滅だった）/ hidden_edge ON CONFLICT 列数不一致 / execution_quality・position_reconciliation の幽霊列INSERT（本番0行=全書込失敗）/ Decimal→float 精度 / calibration N+1
- **pool→bootstrap 再export 削除**（循環import源）。ensure_* は shared.db.bootstrap から直import（tdnet 6 + tradingview 1）

## 重要な落とし穴（再発防止）
- **[[bugs-apply-db-baseline-stamp-production]]**: apply_db_baseline の stamp が本番を汚染した実事故 → 詳細は別メモ
- **RESET ALL 罠**: psycopg_pool の reset callback で RESET ALL 後に session 設定を再適用しないと、configure で SET しても初回返却で消える → configure/reset が _apply_session_defaults を共有する設計
- **baseline trigger サイクル**: cross-schema trigger 関数（core→ops/ops→core）で per-schema ファイルが相互適用不能に → generate_db_baseline が TRIGGER を trailing NN_triggers.sql へ分離（2026-07-13〜）
- **孤児シーケンス**: bootstrap の CREATE SEQUENCE IF NOT EXISTS + CREATE TABLE IF NOT EXISTS no-op の組合せで未接続シーケンスが残る。revision は DROP IF EXISTS→CREATE で冪等化
- **frozen file-size budget**: import 1行分割でも抵触。複数行 import の1行化（line-length 120）が正当な返済手段

## 残課題
- statement_timeout 導入後1週間の誤殺監視（canceling statement ログ）
- legacy_archive 4テーブルの DROP（次バッチ）
- バックログ P0 群は未着手: screener 1行バグ / 計算バグ3件 / バックアップ実装ゼロ / EDINET 2/20凍結
- 巨大ファイル分割・スキーマ契約 ensure 集約は次バッチ候補
- 2026-05 stash 残骸が conflict 状態で worktree に混入する事象1回（jpx_listed_companies、HEAD 復元で解消、原因不明）
