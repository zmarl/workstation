---
name: feedback-shared-worktree-multiagent-commits
description: 共有worktreeでサブエージェント並走中は git add -A 禁止（WIP巻き込み）・git stash も禁止
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 46e0558c-1a18-417e-8a2d-37fcf19f9af2
---

共有worktreeで背景サブエージェントがファイル編集中に、オーケストレータが `git add -A` でコミットすると**エージェントの作業途中ファイルを巻き込む**（2026-07-11 に canslim/models.py・stock_stage.py を A1 コミットへ誤混入。最終状態は全緑で実害なしだが履歴の帰属が崩れた）。

**Why:** エージェントは数十分単位でファイルを書き続けるため、`-A` はスナップショットタイミングの運任せになる。

**How to apply:**
- エージェント並走中のコミットは**明示パス指定**で `git add <paths>` する
- `git stash`/`stash pop` も並走中は使わない（エージェントのWIPごと退避される。HEAD検証が必要なら別cloneか、エージェント完了後に行う）
- エージェントには「git commit 禁止、最終報告で台帳行を返す」と明示指示し、オーケストレータが差分レビュー後にコミットする（この方式自体は有効だった）

関連: [[feedback-parallel-session-worktree]]
