thread_id: 01a045e1-19b0-7090-9a89-69ca61d5ba44
updated_at: 2026-08-30T09:48:36+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\08\28\rollout-2026-08-28T15-45-17-01a045e1-19b0-7090-9a89-69ca61d5ba44_01a0471d-9930-7a51-b0f6-f2f76f083f2a.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# ハーネス改革を最新mainへ統合し、PR #265をmergeした rollout

Rollout context: D:\Dev\Investment。ユーザーは競合解消後の継続作業を依頼。対象は投資アプリ本体ではなく、テストハーネス・queue・KPI・運用文書。

## Task 1: Phase 1〜3のハーネス改革と統合

Outcome: success

Preference signals:
- ユーザーは「続き」「今どういう状況？」と進捗確認を行い、最終的に「ある程度改善されたという状況かな」と確認した。今後も、実装完了・統合完了・継続計測・文書整理を分けて、過大評価せず説明するのが望ましい。
- 実装では他セッションのprocess、worktree、lock、queue jobを停止しない方針が一貫して守られた。並行作業の所有境界を尊重することが重要。

Key steps:
- 最新mainとのrebaseで`proof_pack_queue_worker.py`に競合が発生。main側とqueue優先順位変更の意図を確認し、rebase abortせず解消。
- queueを`repair > aged full (>=24h) > ready > recent full`へ変更。同種FIFO、non-preemption、host-wide lockを維持。
- shared-coreの広いPython検証を`python-broad` async packへ分離し、runner/selector/container変更をinterface別の既存テストへmapping。未知sourceは安全側fallback。
- Phase 2は、current-mainのduration・所有状況を確認し、追加削減候補が安全に確定できない領域は保留。履歴30commit固定テストをinterface proofへ置換し、テスト行数は純減。
- `harness_kpi.py`をstdout専用の約311行へ縮小。schema v4のpayload時刻で集計し、sync p50/p95、async queue wait/worker/E2E、first-pass、pending、結合不能件数、`tests/scripts/**`規模を表示。証拠不足を0秒や成功に補完しない。
- staleな`docs/status/harness-kpi.md`を削除し、ODR、testing guide、gate runbook、AGENTSへ役割別に内容を統合。
- 初回publishはmain checkoutから実行して`pull request head does not match tested head`で事前停止。所有worktreeの新helperを使い、既存PRのremote headをexact leaseで安全に更新した。
- repair enqueueは監査停止解除後のため契約どおり拒否。repairはactive audit stop専用の復旧手段であり、通常merge前に強制作成しないと確認。
- `finish-pr`でPR #265をmergeし、main同期、evidence archive、remote/local branch削除、専用worktree削除まで完了。post-merge full auditも自動enqueueされ、最終的に複数jobがpassed・cleanup済み。

Failures and how to do differently:
- Windowsでは空白を含むタイトルを直接コマンドに渡すと引数が分割された。専用scriptまたは配列引数で実行する。
- main側の古いhelperでは、既存PRの旧headから新tested headへのexact-lease更新契約を使えず停止した。PR側の最新helperを所有worktreeから実行する。
- 複合コマンドはWindows harness guardで拒否されることがある。小さい直接コマンドへ分割し、shell指定を環境に合わせる。
- Phase 3のKPI初稿は約500行増となり過大だったため採用せず、必要な集計と既存契約の再利用に縮小した。
- 最初のrebase後focused検証では3件失敗したが、aging境界・明示runner mappingに追随して既存テストを修正し、最終的に315 passed/6 skippedへ回復。

Reusable knowledge:
- PR #265 `Harness Ready queue and focused proof reform`は、tested head `194910d0cf4f7428b39e92217040786f8da55606`、Ready gate `passed`（119.614秒）、merge commit `c99e490b9598b186b710d40cbf2b9c13e730df3d`。
- PR #265の統合後、mainとorigin/mainはcleanかつ同一。後続PR #282ではworker最大3本、DB resource直列化、非DB検証の並行実行、自動wakeupを導入し、長時間auditによるhead-of-line blockingも改善。
- PR #265後のfull audit job（例: `f04363fb8cd20aa0108af406cd50fb10`）は約62分実行後passed、runner cleanupもcleaned。後続auditもpassed実績あり。
- 実測KPIではsync Ready p50 55.5秒、p95 500.7秒、first-pass 39/40。ただしasync実測は`n=0`で、`invalid_evidence`や`job_missing`を明示。p95改善を恒常的成果として断定するには継続母数が必要。
- 一時計画`data/runtime/plans/20260828-harness-development-environment-reform.md`とworklogの表示整理は、実装統合後も残課題として確認された。機能統合と文書cleanupを別タスクとして扱う。

References:
- `D:\Dev\Investment\scripts\dev\proof_pack_queue_worker.py`
- `D:\Dev\Investment\scripts\dev\harness_kpi.py`
- `D:\Dev\Investment\docs\worklogs\20260828-harness-development-environment-reform.md`
- `D:\Dev\Investment\data\runtime\evidence\local_pr_gate\v4\194910d0cf4f7428b39e92217040786f8da55606\d2e2c9bcf2e4cf8cf9843e8a27f64bad\result.json`
- `uv run python scripts/dev/sync_repo.py publish-pr ...`
- `uv run python scripts/dev/sync_repo.py finish-pr --pr 265 ...`

## Task 2: 統合後の現在状況確認

Outcome: success

Key steps:
- `git fetch origin main`、`git rev-parse HEAD/origin/main`、`git status`でmainの同期・clean状態を再確認。
- `gh pr view 265`でMERGED状態、merge commit、旧PR headを確認。
- post-merge full auditのqueue request/eventsを確認し、passedとcleanup済みを確認。
- PR #282もMERGEDで、長時間監査中の並行実行改善がmainに入っていることを確認。

Reusable knowledge:
- 2026-08-30確認時点のmain/origin/mainは`290a245a9fff32ede05474cae9a3e6ff9bcbb1fb`でclean。
- ユーザーへの説明は「テスト全体が劇的に短縮」ではなく、「focused Ready化、重い検証のasync分離、queue競合緩和、DBだけ直列化により、無関係な開発作業の巻き添え停止を改善」と表現するのが正確。
