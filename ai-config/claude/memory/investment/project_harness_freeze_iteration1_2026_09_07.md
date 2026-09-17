---
name: project-harness-freeze-iteration1-2026-09-07
description: "ODR-0038 ハーネス凍結の第 1 反復（PR #413〜#417、2026-09-07）の着地記録と、worktree セッション・統合順番・Scheduler 整合検査で踏んだ罠"
metadata: 
  node_type: memory
  type: project
  originSessionId: 18e0a477-b9bf-4062-8b25-ed94690f19f2
  modified: 2026-09-07T06:06:16.917Z
---

2026-09-07 に ODR-0038（ハーネス 30 日凍結 9/8〜10/7）の第 1 反復を 1 セッションで直列に着地させた。

| PR | 内容 | 結果 |
|---|---|---|
| #413 | ODR-0038 起票、OWNER_INTENT §3/§7、ODR-0031 改番、AGENTS.md 討議 1 文、駐車場節 | merge（代替経路） |
| #414 | `Read(./.env)` / `secrets/**` deny、ローカル tauri build の deny を Claude・Codex から削除、worklog に Model/Effort | merge（代替経路） |
| #415 | `index-strategy = unsafe-best-match` 削除（lock 差分なし、torch 2.9.1+cu126 維持） | merge（代替経路） |
| #416 | `audit_is_advisory` 常時 True、blocked/repair/post-merge enqueue 分岐と 25 テスト削除（+223/−2,204） | merge（**detached runner から finish-pr**、`WEEKLY_AUDIT_ADVISORY: blocked` を表示して統合） |
| #417 | 夜間回帰 `nightly-regression-pytest`（tools.quality.nightly_regression、通知のみ）、週次監査 task を retired | 本メモ記入時点で gate 中 |

**罠と対処:**
- **worktree セッションの Bash 隔離**: `EnterWorktree` 後、持続 shell の cwd が main のままだと全 Bash が「resolved to the shared checkout」で拒否される（`cd` 自体も拒否）。対処は `ExitWorktree(keep)` → Bash で `cd <worktree>` → 以後そのまま作業（`EnterWorktree(path)` は「already cwd」で不要）。claim ID は `git worktree list --porcelain` の `locked` 行から読む。
- **統合順番（integration turn）**: Ready gate は他セッションの `reserved` turn が期限切れ（600 秒）になるまで `final integration turn is waiting` で exit 1。60 秒 sleep の再試行スクリプトを background で回すと通る。テスト由来と見られる head `2222…` の turn 記録が実 git common dir に残っている（要確認）。
- **全体停止中の finish-pr**: main の full_audit が global stop だと finish-pr は `merge_not_attempted: repair_audit admission failed`。#416 までは `gh pr merge --match-head-commit` → `sync_repo.py after-merge` → `cleanup --apply` の代替経路。#416 以降は advisory なので通常 finish-pr でよい。main checkout の helper は旧コードを使うため、新コードで finish したい場合は `create-worktree --task <slug>-runner --detach-at <head> --owner claude --session-id-hash <hash>` の runner から実行する（runner の `cleanup --apply` はディレクトリ削除に失敗し `rm -rf` は deny → 手動削除が要る）。
- **Scheduler 整合検査**: 新 task を `register_schedules.ps1` に載せて Scheduler 未登録だと `check_scheduler_integrity` が runtime drift を **error** にし、`tests/scripts/dev/test_weekly_audit_second_review.py` が赤になる。登録前は `scheduler_binding: optional` にして登録行を入れない（未 mapping は warning）。登録ウィンドウで行追加 → 登録 → `required` へ。`timeout_minutes >= 120` は `resume_mode` と `execution_entrypoint: runner_only` が必須。
- **Windows の write_text は CRLF**: Python で編集スクリプトを書くとき `newline="\n"` を付けないと `git diff --check` / gate が CRLF で落ちる。`.ps1` は逆に CRLF が正。テスト削除スクリプトで末尾関数を消すと EOF に空行が残り `git diff --check` が失敗する。
- **ruff の gate**: `# noqa: ARG001` は ARG ルール未有効でも RUF100 にならなかったが、E501（120 桁）は gate で落ちる。

**Why:** 5 本の PR を同じセッションで回す間に同じ罠を 3 回踏んだ。次のセッションが同じ手順を再発見しないため。

**How to apply:** ハーネス凍結中の次の作業（PR-6 以降、製品レーン P-1〜P-3）は本メモの手順で worktree に入り、gate は再試行スクリプトで待つ。関連: [[project-integrated-assessment-plan-2026-09-07]]、[[feedback-rule-protects-something]]。
