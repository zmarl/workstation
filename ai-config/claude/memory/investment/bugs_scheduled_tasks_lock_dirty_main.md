---
name: bugs-scheduled-tasks-lock-dirty-main
description: .claude/scheduled_tasks.lock の誤追跡で main checkout が常時 dirty → merge-pr 全停止 (2026-07-19 根治)
metadata: 
  node_type: memory
  type: project
  originSessionId: 60cac97c-1a3b-4147-902c-8c047702f4fb
  modified: 2026-07-19T04:01:50.780Z
---

# .claude/scheduled_tasks.lock が merge-pr を止める (2026-07-19 根治済み)

- **問題**: `sync_repo.py merge-pr` が「main checkout has uncommitted changes」で失敗。dirty の正体は
  `.claude/scheduled_tasks.lock` 1 ファイルのみ（Claude Code ハーネスがセッション毎に sessionId/pid を書き込む
  ランタイムロック）。
- **原因**: 過去コミット 8569d3b9 で誤って git 追跡に入った。稼働セッションがあるだけで main が汚れる構造。
- **解決**: fix/untrack-scheduled-tasks-lock で `git rm --cached` + .gitignore 追加（working copy は温存）。
  merge-pr の clean 検査は ignored ファイルを見ないため以後は汚れない。
- **一時対処パターン**（同種の生成物が追跡されていた場合）: `git checkout -- <file>` で tracked 内容へ復元
  → 即 merge-pr。復元は稼働プロセスに実害なし（次回取得時に再書き込みされる）。
- 関連知見: gate 落ちの軽微 2 パターンも同日確認 — ①worklog テンプレの「Plan Delta: 」行末空白が
  `git diff --check` で fail ②md ファイル追加は `docs/research/registry.yaml` の
  `expected_managed_markdown_count` を同一 PR で +N する（[[project-desktop-design-reform-2026-07-19]] A0 で実証）。
