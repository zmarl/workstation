thread_id: 01a04f31-a05a-7690-b370-890bc04bb478
updated_at: 2026-08-30T09:59:19+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\08\30\rollout-2026-08-30T05-24-07-01a04f31-a05a-7690-b370-890bc04bb478.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# テスト停止の主因を調査し、並列実行ハーネスを修正

Rollout context: `D:\Dev\Investment`。並列するCodex/Claude作業がテスト待ちで停止する原因を読み取り調査し、実装・検証・PR統合まで行った。

## Task 1: テスト待ち・全体停止の原因調査とハーネス改善

Outcome: success

Preference signals:
- ユーザーは「いろんな作業が止まっていた」状態について、原因調査と、目標が達成されたかの実測確認を求めた。今後も設計改善後は、コード上の説明だけでなく現在のqueue・作業状態・残存待機を再確認して説明する。
- 他セッションのprocess、worker、lock、queue jobを停止・削除・横取りしない運用を維持した。並列環境では所有境界を守ることが重要。

Key steps:
- 共有queue、worktree、監査証跡、実行中jobを調査し、旧設計ではhost-wide lockによりfull/repair audit、Ready asyncが全体として直列化されていたことを確認。
- resource class別admissionを実装し、DB/container/migrationなど実際に競合する資源のみ排他。Python/Desktop/Rustなど非競合jobは監査中でも実行可能にした。
- worker上限を3本に設定し、同一resource内の優先順位・FIFO・non-preemptionを維持。
- enqueue後のagent寿命依存を除き、detached drainer、自動wakeup、manual `--drain` fallbackを導入。
- 同一merged SHA・selection・packのfull auditを既存immutable jobへ束ね、post-merge時の重複監査登録を防止。
- wake起動失敗時はdurable jobのeventsを変更せず、次回wakeup/manual fallbackへ残すTOCTOU対策を追加。
- PR #282で並列queue本体、PR #283でpost-merge監査重複防止をmainへ統合。

Validation:
- focused suite: 本体224 passed/8 skipped、追加修正87 passed/1 skipped。
- rebase後のexact Ready: passed（head `9bc2fc099c1e6334a92ee9e0efc7363f1a206ea1`）。
- PR #283 merged、merge commit `b09e3819299a6e1de1e6b628381c3774cc1cd810`。
- mainとorigin/mainは同一commitでclean。専用worktree・branchはcleanup済み。
- 独立correctness/security reviewはいずれもP0/P1/P2なし。
- merge後の同一SHA full auditは重複せず1件だけqueue登録された。

Failures and how to do differently:
- 初回repairはforeground session終了により`incomplete_previous_attempt`でfailedとなり、merge証拠には使えなかった。その後、既存jobへ介入せずdetached workerとqueue recoveryで処理した。
- `finish-pr`をtarget worktree内から実行すると`run this command from outside the target worktree`で失敗する。lifecycle操作は必ず対象worktree外（通常main checkout）から実行する。
- PowerShellの複雑な引用やwildcard指定は環境guardrailで拒否されることがあった。必要に応じて`cmd.exe`、単純な個別コマンド、または直接指定のglobを使う。

Reusable knowledge:
- 修正後もDBを共有するfull auditとDB系Readyは意図的に直列化される。これは異常停止ではなく安全上の待機。
- 一方、DBを使わないPython/Desktop/Rust等の検証は、監査を理由に一律停止させない設計になった。
- queueの現状確認は`read_queue_snapshot(..., skip_invalid_non_audit_jobs=True)`で行える。terminal statusは`passed/failed/timed_out`で判定し、`cleanup_abandoned`やcleanup途中を単純な成功扱いにしない。
- 修正後も、すでに`idle`/`notLoaded`になった会話セッション自体は自動再開しない。必要ならユーザーが開き直す必要があるが、再開後に旧host-wide直列化へ巻き込まれる問題は解消済み。

References:
- [1] 設計: `docs/decisions/20260830-resource-class-parallel-proof-execution.md`
- [2] 運用手順: `docs/runbooks/local-pr-quality-gate.md`
- [3] Queue実装: `scripts/dev/proof_pack_queue.py`, `scripts/dev/proof_pack_queue_worker.py`
- [4] Ready入口: `scripts/ci/run_local_pr_gate.py`, `scripts/ci/local_pr_gate_queue.py`
- [5] 同一SHA監査重複防止: `scripts/dev/weekly_audit_enqueue.py`
- [6] 検証結果: `87 passed, 1 skipped`; exact Ready evidence run `4f2b0d4af32600e94ad7ca9161f138ee`
- [7] PR #283: `https://github.com/zmarl/Investment/pull/283`、merged commit `b09e3819299a6e1de1e6b628381c3774cc1cd810`
- [8] 最終観測時点では未完了queueは2件。main full auditはrunning、DB系Readyはqueued。これは意図されたresource排他であり、無関係な検証の全体停止ではない。
