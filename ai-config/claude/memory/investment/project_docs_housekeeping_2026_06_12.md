---
name: project-docs-housekeeping-2026-06-12
description: 2026-06-12 Docs 整理バッチ着地 — worklog 768件アーカイブ・残課題台帳正本化・tool-count CI ゲート新設・申し送り（WIP コミット時に drift gate が fail する想定）
metadata: 
  node_type: memory
  type: project
  originSessionId: f3815c9c-defa-449a-a7e4-7dea0708360a
---

2026-06-12 に docs housekeeping バッチを `docs/20260612-housekeeping` ブランチ → `feat/reform-phases-batch` merge（`b19014e3`）で着地。worklog: `docs/worklogs/20260612-docs-housekeeping-batch.md`。

- **worklog アーカイブ**: 新規恒久スクリプト `scripts/archive_worklogs.py`（14 日ルール、git mv、dirty 自動スキップ、`--rewrite-links`）。768 件を archive/2026-{04,05}/ へ移動、参照 449 箇所書換。月次運用コマンドは docs/README.md ガバナンスサイクル表に記載
- **残課題正本**: `docs/backlog/次アクション管理台帳.md` に 11 TaskID 新規登録（EGOV-01 / KANPO-01 / SUPPLY-W2 / EARN-W3/W4 / DESK-SMOKE-01 / EOT-DB-01 / BMPW-REG-01 / DTB-09 / SFF-P2-01 / BMPH-REG-01）。roadmap の「PR #11/#12 stuck」は誤りで実際は 2026-05-14 マージ済み（`f441ceda`）と是正済み
- **CI ゲート**: `scripts/check_tool_count_drift.py` + framework-docs-quality.yml に docs リンクチェックと drift チェックを追加。2026-06-12 計測: tool 293 / manifest active 315
- **申し送り（重要）**: 別セッション WIP（earnings_outcome_tracker main.py、manifest +2 task）がコミットされると tool 294 / active 317 になり drift gate が CI fail する → README.md / CLAUDE.md / docs/README.md / docs/current/{README,05-tools-scheduler}.md の数値を再計測更新すれば解消（想定動作）
- **残ステップ**: scheduler 未登録 8 タスク（BusinessModelProbeWeekly / Earnings 系 2 / Reg 系 3 / Shingikai 系 2）の `register_schedules.ps1 -OnlyTaskNames ...` 実行はパスワード入力が必要でユーザー実行待ち。完了後 EOT-DB-01 / BMPW-REG-01 を done 化
- **ハマり**: `register_schedules.ps1` は既定 BackgroundPassword モードで `Read-Host` パスワード入力を要求 → バックグラウンド実行すると無言ハングする。必ずフォアグラウンドでユーザーに実行してもらう。[[feedback-terminal-commands]]
- 古い open PR #5/#6/#7 は `wip/restore-main-pre-sync-20260211`（`1c545ec6`）取り込み済み確認のうえ close 済み
