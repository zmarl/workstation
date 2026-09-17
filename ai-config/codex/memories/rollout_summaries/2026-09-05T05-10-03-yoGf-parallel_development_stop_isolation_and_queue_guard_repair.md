thread_id: 01a06ff9-4882-7512-8870-01d1300c6aeb
updated_at: 2026-09-08T07:31:57+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\09\05\rollout-2026-09-05T14-10-03-01a06ff9-4882-7512-8870-01d1300c6aeb.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# 並行開発を止める共有障害の調査・改善を実施したが、実運用での再発が残った

Rollout context: `D:\Dev\Investment`。ユーザーは、PR #388の共有監査停止、DB読み出し件数差異、PowerShell実行拒否などにより並行作業が止まる問題を改善するよう依頼した。

## Task 1: 共有停止条件と再開経路の改善

Outcome: partial

Preference signals:

- ユーザーは「影響範囲だけ停止」と「不足部分の改善」を選択した。無関係な作業を止めず、既存の修復担当と重複しない範囲を望んでいる。
- PowerShell共通設定について「限定修正を含める」を選択した。一括許可ではなく、危険操作の禁止を維持したまま通常コマンドだけ通す方針を採用した。
- 他セッションのプロセス、worktree、claim、queueを停止・手動解除しない方針を一貫して維持した。

Key steps:

- `C:/Users/kazum/.codex/rules/host-executables.rules` のPowerShell実行ファイル全体禁止を、EncodedCommand・Scheduler・Desktop配布・通知などの危険境界に限定する規則へ変更し、変更前ファイルを退避した。
- Windows共有キューのguard削除待ち競合に対し、ガード取得前と検証済みsnapshot読取りだけを有限回再試行し、claim・変更操作・検証実行・公開の重複再試行は避ける修正をPR #412へ反映した。
- ODR-0038に基づき、週次監査状態をmerge停止条件ではなくadvisoryへ変更した。監査状態は表示・記録するが、Ready成功と人手境界以外では無関係なmergeを止めない。
- 一時的に既存runbookの`disable-continuation`を使い、自身の未実行Ready待機だけを退役して手動経路でReady、publish、mergeを実行した。`enable-continuation`で復帰し、markerのhash/inode/mtimeを照合した。
- 新main `5bfe8087...` にrebase後、最終Readyは `ecb6ec03...` で全pack・全command成功、`688 passed, 13 skipped`。PR #412をmerge commit `e306a66d...` としてmainへ統合し、共有キュー370件・unknown 0・読取不足noneを確認した。
- その後、Desktop側の別候補でも同じ `WindowsCapabilityBusyError: queue guard deletion is pending` がpublish前読取りで再発。したがって、PR適用と一時的な読取り成功は達成したが、並行運用での根本解消は未達として訂正した。

Failures and how to do differently:

- PowerShellルール修正後も同一セッションは旧ルールを保持し、再起動・再読込みまで実動確認できなかった。設定保存済みと新セッションでの適用確認を分ける必要がある。
- Ready自体は成功してもmainが実行中に進んだ場合は `base_unchanged=false` で失敗扱いとなる。旧証拠を流用せず、新baseでrebaseとReadyをやり直す。
- 共有guard競合はPR #412適用後もDesktopのpublishで再発したため、単発のqueue read成功や一度の688件成功を並行運用解消の証拠とみなさない。
- 失敗したfinish intentや監査履歴を成功へ書き換えず、成功した新しいexact SHA・claim・evidenceだけで統合する。

Reusable knowledge:

- 現行の週次監査状態が `blocked: no matching repair_audit proof` でも、ODR-0038ではadvisory扱いであり、`merge-pr`は警告を出して進行できる。
- `harness_status --summary` は現在のjob記録だけを読む軽量確認で、`--job-id`を指定すると履歴・期間集計を走査しない。
- 通常復帰後の確認例: `uv run python -m scripts.dev.harness_status --summary`、および `_queue_snapshot_index` でsnapshot件数とunknown件数を確認する。
- DBの`earnings_asof_pack_cutoff_in_future`はseed時のDB時刻逆転までしか判明せず、比較値が記録されていないため原因未確定。製品の未来cutoff保護やDDLは緩和しない。
- PR #412はmainへ統合済みだが、Desktop側の公開経路では同じguard競合が再発したため、製品反映の完了とは区別する。

References:

- PR: `https://github.com/zmarl/Investment/pull/412`
- Merge commit: `e306a66d2fb61b7eb0528763361f107e64f754b9`
- Final Ready evidence: `data/runtime/evidence/local_pr_gate/v4/ecb6ec03c93ff2ec8229528838657b4f0ef6a510/1df61b6326759551106a31327595287f/result.json`
- Status/evidence: `data/runtime/evidence/queue-guard-resume-20260907/status.json`
- Temporary continuation receipt: `data/runtime/evidence/queue-guard-resume-20260907/continuation-fallback.json`
- Relevant error: `WindowsCapabilityBusyError: queue guard deletion is pending: '.proof-pack-capability-guard'`
- User-facing final correction: 「修正はmainへ反映済みですが、並行運用での問題解消は未達です。」
