---
name: project-ops-cleanup-2026-07-03
description: 運用清算バッチ (2026-07-03)。watchdog/bridge スケジューラ配線・契約レジストリ乖離根絶・NOTIF-STD-02 消失発見→再実装。Windows 登録3タスクが持ち越し
metadata: 
  node_type: memory
  type: project
  originSessionId: 9f7b3013-0350-4c83-96ab-dfd07bcd2c35
---

# 運用残タスク清算バッチ (2026-07-03)

worklog: `docs/worklogs/20260703-ops-cleanup-batch.md`

- **db-connectivity-watchdog-15m** を manifest/tiers/.bat/register_schedules に配線 (15分間隔/timeout5分/manual、dry-run reachable 確認)
- **契約レジストリ乖離根絶**: `ops.ingest_contract_profiles` 16 profile を実スキーマに整合 (metric_key→metric_name ×12、estat=date/as_of_date、financial_unifier=run_id/source_id/record_hash、jpx_margin/jpx_short_ratio のスパース列は required→nullable)。監査実走 **132/132 pass** で毎晩 01:20 の偽 failed run は根絶。変更前スナップショット: docs/worklogs/20260703-ops-cleanup-contract-registry-snapshot.json
- **重大発見**: NOTIF-STD-02 (ingest_failure_bridge) と NOTIF-STD-03 (failure inbox) の 6/20 実装分が**並行セッション上書きで完全消失**していた (ツール/DDL/manifest とも現ツリー無し。台帳の「コミット済み」報告と乖離)。ブリッジは同日再実装完了 — dedup は DB テーブルでなく `data/runtime/ingest_failure_bridge_state.json` (並行の DB 統治作業と DDL 衝突回避)。dry-run 実DB検証: 26h で 52 失敗→13 ソース critical46/warning6。digest_dispatcher の manifest 未配線も同時解消 (notification-digest-dispatch-daily)
- **NOTIF-STD-04**: baseline 55.1% (163/296) を計測。展開第1弾は T20 burn-down 並行セッションが tools/*/main.py 一斉編集中のため衝突回避で次バッチ
- **hook 衛生**: `.claude/hooks/post-edit-lint.sh` の tsc 出力を編集ファイル関連のみに限定 (他セッションの作業中エラーの洪水を止めた)
- **持ち越し (全解消済み)**: Windows タスク登録 3 件は 2026-07-04 にユーザーが登録完了（三者一致達成、debt-repayment-closeout worklog 記録）。NOTIF-STD-03 (Desktop failure inbox) と NOTIF-STD-04 Wave 1 は 2026-07-04 の未完了完成バッチで再構築・実施済み → [[project-unfinished-completion-batch-2026-07-04]]
