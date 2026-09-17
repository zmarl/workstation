---
name: project-scheduler-manual-only-drift-2026-08-17
description: 規制LLMタガーが15分おきに失敗し続けていた件 (2026-08-17 解消)。manual_only化した直後はWindows登録が残るので再登録が要る
metadata: 
  node_type: memory
  type: project
  originSessionId: c288e354-4d4e-4325-9c0d-4bba4c1055cb
  modified: 2026-08-17T10:27:19.600Z
---

# manual_only 化した直後は Windows 登録が残る（2026-08-17 解消）

PR #184 が `reg-llm-tagger-quarter-hour` / `reg-llm-tagger-backfill-weekly` を
`manual_only_tasks` へ移し、`register_schedules.ps1` の `DisabledTaskPolicies` にも追加した。
しかし Windows 側の登録は **2026-08-16 の再登録時点のまま**で（policy 追加はその後の
`9545ce715`）、`RegLlmTaggerQuarterHour` が平日 09:00〜17:30 に15分おきに起動しては
exit 2 で失敗し続けていた。

**シグネチャ**: `check_scheduler_integrity.py --json` の
`runtime_inventory_summary.disabled_present_in_scheduler_count` が非0、
`runtime_strict_failure: true`。ただし `errors` には
`Runtime scheduler drift detected: strict_failure_count=N` としか出ず**タスク名は出ない**。
特定するには manifest の `disabled_tasks` / `manual_only_tasks` / `retired_tasks` の
`scheduled_task_name` と `Get-ScheduledTask -TaskPath '\Investment\'` を突合する。

**解消**: skill `scheduler-registration` で
`open_scheduler_registration_prompt.ps1 -OnlyTaskNames <name1>,<name2>` を実行。
`-OnlyTaskNames` で絞ると `Remove-DisabledInvestmentTasks` もその2件だけを対象にするので影響が最小。
リポジトリ側の修正は不要だった（policy は既に正しかった）。結果 245 → 243 件、
`disabled_present_in_scheduler_count` が 0、`ok: true`。

**教訓**: manifest でタスクを停止・manual_only へ移す PR は、着地後に Scheduler 再登録まで
やらないと実機に反映されない。`register_schedules.ps1` は `Remove-DisabledInvestmentTasks` を
先に呼び、その後 `Update-Investment*Task` が `Get-DisabledTaskReason` で skip する二段構えなので、
policy さえ入っていれば再登録1回で消える。

## reg_llm_tagger は今も機能停止中

停止したのは**無駄な失敗**であって、ツールは動いていない。
`automation_policy.require_attempt_ledger_for_mutation()` が**常に例外を投げる**設計で、
永続的な attempt ledger が実装されるまで書き込みを fail-closed している
（`REG_LLM_APPROVED_MANUAL_RUNTIME_HOLDS` に2タスクが「承認済みの手動 hold」として登録済み）。
規制文書への業種タグ付けは現在ゼロ。実装は次アクション台帳の `REG-LLM-INT-01`（`todo`）。

**`REG-LLM-INT-01` と `JPX-OI-INT-01` の `dod_check_cmd` は
`scripts/check_financial_data_invariants.py` を指したままで、ODR-0002 で退役済み。**
台帳内に同スクリプト参照が計4箇所。完了条件の書き換えが必要。

関連: [[project-valuation-capital-landing-2026-08-17]] /
[[project-worktree-inventory-cleanup-2026-08-16]] / [[feedback-scheduler-bulk-registration]]
