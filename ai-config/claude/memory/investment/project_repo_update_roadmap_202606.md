---
name: project_repo_update_roadmap_202606
description: リポジトリアップデート 10 テーマロードマップ (2026-06-12)。T2 通知標準化バッチ1完了、T1 EDINET が次
metadata: 
  node_type: memory
  type: project
  originSessionId: 7f9a7805-4c22-4abb-902a-78f9f25b1e23
---

2026-06-12、アプリ全体の機能ギャップ調査（Explore×3 + Plan×1）から 10 テーマのアップデートロードマップを策定し、ユーザーが「データ信頼性最優先」を選択。正本: `docs/roadmap/repo-update-proposals-202606.md`、TaskID は `docs/backlog/次アクション管理台帳.md` に 30 件登録済み。

**最重要発見**: (1) EDINET 抽出データの系統的破損（年度オフバイワン 33,118 行 + bogus Q4 1,777 行 + フランケン集約 53,655 件）が 7203 で偽サプライズ -51% を発生させ判断材料を汚染中。(2) ingest 失敗の通知カバレッジが全 296 ツール中 163 (55.1%)、uncovered 133。

**進捗**:
- T2 通知標準化バッチ1（NOTIF-STD-01/02）= **done (2026-06-12)**。runlog→alert ブリッジ `tools/notifications/ingest_failure_bridge` + `ops.ingest_failure_alert_dispatch` (alembic 20260613_04) + digest_dispatcher の manifest 配線。dry-run で実 DB の失敗 23 件 (critical 18/warning 5) 検出。実機 scheduler 登録のみ残（register_schedules.ps1 マッピング追加済、Admin 実行待ち）。
- 次推奨: **T1 EDINET-FIX**（最優先）。Phase 0+1 guard は alembic 20260613_03 で適用済。EDINET-FIX-02（汚染行削除→再抽出）は**破壊的操作で明示承認が必要**。worklog: `docs/worklogs/20260612-edinet-extraction-corruption-fix.md`
- 残: T3 TDNET-KPI / T4 学習ループ(DECIDE-R2..) / T5 FLOW-UI / T6 STATE-STD / T7 BFF-GOV / T8 LLM-EXP / T9 DESIGN-P2.. / T10 小粒

**Why:** WIP=1 ルール。`in_progress` は着手バッチのみ。**How to apply:** 「続き」を求められたら台帳の優先度順で次バッチへ。破壊的（大量削除・再抽出）は着手前に承認を取る。関連: [[dev_execution_plan_progress]] [[bugs_posttooluse_hook_stdout_corruption]]
