---
name: feedback-scheduler-bulk-registration
description: Windows タスク登録はユーザーが後日まとめて一括実行する方針 (2026-07-12)。セッション側は register_schedules.ps1 追記まで
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2626d986-0a5c-46dc-a9b9-8e95f028586c
---

# Windows タスク登録は「後日一括」方針（2026-07-12）

**Why:** 登録すべきスケジューラタスクは継続的に増えるため、バッチごとにパスワード境界を跨ぐより、ユーザーがタイミングを選んでまとめて登録する方が効率的（ユーザー明言）。

**How to apply:**
- 新タスク追加時は manifest（domain yaml → build_run_manifest → generate_task_wrappers）+ `scripts/register_schedules.ps1` へのエントリ追記**まで**をセッションの完了条件とする
- 登録実行の催促・個別 handover 起票・登録ウィンドウの起動提案はしない（ユーザーに言われたときだけ skill `$scheduler-registration` で起動）
- `register_schedules.ps1` を 1 回実行すれば未登録分が全部拾える状態を常に維持する（parity ゲートの task_without_register warning がその検知網）

関連: [[feedback-password-prompt-window]]
