---
name: feedback-password-prompt-window
description: パスワード/UAC 入力が必要なコマンドは harness 内で実行せず、対話ウィンドウ（パスワード入力画面）を起動してユーザーに入力だけ委ねる — 専用 skill scheduler-registration を毎回使う
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f3815c9c-defa-449a-a7e4-7dea0708360a
---

ユーザー指示（2026-06-12）: パスワード入力をユーザーにさせる場合は「パスワード入力画面」を出すところまで自動で進めること。Codex 側と同様の skill を Claude でも毎回使うこと。

**Why:** `register_schedules.ps1` 等は BackgroundPassword モードで `Read-Host` のパスワード対話を要求する。harness のシェル/バックグラウンドで実行すると入力不能で無言ハングし、ユーザーにコマンドを手で打たせるのも手間。ウィンドウ起動までエージェントが進めれば、ユーザーはパスワードを打つだけで済む。

**How to apply:**
- scheduler 登録は repo skill `$scheduler-registration`（`.claude/skills/scheduler-registration/SKILL.md`）を必ず invoke し、`scripts/open_scheduler_registration_prompt.ps1` で管理者ウィンドウを起動する（UAC → 管理者 PowerShell → パスワード入力画面、の順で表示されると事前に一言伝える）
- scheduler 以外のパスワード/UAC/MFA 境界も同様: `Start-Process powershell -Verb RunAs -ArgumentList ...` で対話ウィンドウを起動して入力画面まで進め、入力だけユーザーに委ねる。パスワードをチャット・ログ・docs に書かせない
- CLAUDE.md の Rules にも MUST として明文化済み（2026-06-12）。[[project-docs-housekeeping-2026-06-12]]
