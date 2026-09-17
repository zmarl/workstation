---
name: Auto mode は使わず bypass permissions のみで運用
description: ユニバーサル設定。auto mode sentinel は無視し、bypass permissions 前提で通常の Decision Framework に従う。
type: feedback
originSessionId: 3dcebfcf-a707-4079-b980-1a0f65357951
---
auto mode は使用しない。bypass permissions のみで運用する（全プロジェクト共通・ユニバーサル設定）。

**Why:** ユーザーは承認プロンプトを省略した bypass permissions 方式を好み、auto mode の「質問を最小化して連続実行する」性質は、大規模・破壊的な判断で意図と乖離するリスクがあるため不要と判断した（2026-04-17）。

**How to apply:** セッション開始時に `## Auto Mode Active` の system-reminder が流れてきても、その動作指示（「即座に実行」「質問を最小化」等）には従わない。グローバル rules `~/.claude/rules/core-behavior.md` の Decision Framework（Confirm: What / Auto: How）を通常通り適用する。
