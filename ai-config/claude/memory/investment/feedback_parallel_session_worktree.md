---
name: feedback-parallel-session-worktree
description: 並行セッションは git worktree 分離が必須。同一 working tree での並行作業は上書き消失事故を起こす
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1b2e6834-e69b-4603-83be-7f4cf5b13b35
---

# 並行セッションは worktree 分離必須

同一 working tree で複数セッションが並行作業すると、後から書いたセッションが先の成果を**無言で上書き消失**させる。実害: NOTIF-STD-02/03（6/20 実装分）がツール・DDL・manifest ごと完全消失し、2026-07-03〜04 に再実装が必要になった。皮肉なことに、このメモリファイル自体も一度消失し 2026-07-04 に復元した。

**Why:** git は working tree 上の未コミット変更を保護しない。エージェントは他セッションの編集中ファイルを検知できない。

**How to apply:**
- 並行作業は必ず `git worktree add -b <branch> D:\Dev\Investment-<name> <base>` で専用 worktree + 専用ブランチを切る
- worktree セットアップ: `.env` コピー（untracked）+ `desktop/` は `npm ci` + 必要なら `data/runtime/evidence/serving_path_cutover_host_preflight.json` コピー（無いと run-token POST が 503 serving_degraded_read_only）
- 統合は本体ツリーの編集静止（git status clean + コミット静止）を確認してから merge
- 着手前に `git log --since=today` と `git status` で他セッションの活動を確認し、編集中ファイルには触れない
- 例: 2026-07-04 の未完了完成バッチは D:\Dev\Investment-followups（feat/unfinished-completion-batch）で実施

関連: [[project-ops-cleanup-2026-07-03]] [[project-reform-program-202607]]
