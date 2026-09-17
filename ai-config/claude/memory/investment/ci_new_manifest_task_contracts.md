---
name: ci-new-manifest-task-contracts
description: Adding a scheduled task to run_manifest.yaml trips 3 CI gates that must be updated in the same commit
metadata: 
  node_type: memory
  type: project
  originSessionId: db4670bd-5918-4c2b-abfa-f006083adc6c
---

新しい scheduled task を `scripts/run_manifest.yaml` の `tasks:`/`disabled_tasks:` に追加すると、以下 3 ゲートが CI で連鎖失敗する。同一 PR で全て更新すること（Functional uplift P1 統合で再発、2026-07-05）:

1. **manifest-contracts / `check_manifest_tool_tiers.py`**: 新 task_id を `scripts/tool_tiers.yaml` の tier1〜4 に分類必須（fail-closed、allowlist は空運用）。scope は `tasks + disabled_tasks` のみ（`manual_only_tasks` は非カウント）。task を manual_only へ移すと tool_tiers 側が stale になるので tool_tiers から削除する。EDINET/data 取得系 daily は tier2、weekly/monthly analysis は tier3 が慣例。
2. **docs-contracts / `check_tool_count_drift.py`**: manifest 4 区分数 (active/disabled/retired/manual-only) が `CLAUDE.md` / `README.md` / `docs/README.md` の記載と一致必須。task 追加で active が +1 したら 3 ファイルの数値を更新。tool_count (297 等) 自体は `tools/**/main.py` 入口数で別軸。
3. **quality-gates**: 上記 2 ジョブへの依存カスケード（自身に原因なし、1・2 を直せば緑）。

`lint` ジョブ内の "Verify file size budget" ステップ = `check_file_size_budget.py`。lint 失敗 = budget 失敗のことがある。budget は shrink-only ratchet で、凍結値超過は「該当ファイルを凍結値以下へ trim（logic-invariant: 空行/冗長コメント圧縮・安全な行結合、大幅超過はモジュール抽出）」で対応。baseline を上げてはいけない。関連: [[feedback_parallel_session_worktree]]
