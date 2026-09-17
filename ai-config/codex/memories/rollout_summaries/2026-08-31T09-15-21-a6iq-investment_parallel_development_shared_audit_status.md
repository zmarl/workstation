thread_id: 01a0571a-11a9-7412-9247-2a9e1a90ce1e
updated_at: 2026-09-09T23:32:09+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\08\31\rollout-2026-08-31T18-15-21-01a0571a-11a9-7412-9247-2a9e1a90ce1e.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# 並行開発を妨げる共有障害の調査と現状確認

Rollout context: `D:\Dev\Investment`。ユーザーは、並行開発中にマージ不能・全体監査停止・別作業による中断が起きる原因、改善状況、残課題、今後の進め方を確認した。調査は主に読み取りで行われ、他セッションの停止・削除・横取りや重複監査は行われていない。

## Task 1: 並行開発環境と共有監査停止の診断

Outcome: success

Preference signals:

- ユーザーは「今どういう状況？」「これから何すべき？」「どういう問題が起こっていて、何が課題となっている？」と、実装説明だけでなく現時点の状態・原因・次の順序をまとめて求める。今後は結論、確認済み事実、未確認事項、次の行動を分けて報告する。
- 「適用した？」と繰り返し確認しており、検証済み候補・PRマージ・main同期・実運用成功を別物として扱うことを重視している。異なるSHAの証拠を流用せず、main反映と運用確認を別々に明示する。
- 他作業を止めず、重複実行や無断cleanupを避ける運用を期待している。peerのprocess、worktree、lock、queue jobは所有が証明できない限り触らない。
- 監査や待機が長い場合も、単に待ち続けるのではなく、実際に必要な資源待ちか、古いcleanup失敗・状態不整合かを切り分けることを求めている。

Key steps:

- 旧来のhost-wide heavy queueがfull/repair auditやReady asyncを一律直列化し、head-of-line blockingを起こしていたことを確認。
- ODR-0025に基づき、DB/container/migrationだけを排他し、Python/Desktop/Rust等は並行可能とするresource-class admission、worker上限、detached drainer、自動wakeup、immutable job再利用を確認。PR #282/#283で実装されmainへ統合済み。
- Windows capability guardの2reader close race（errno 5）を実worker診断と短い再現で特定。受付前の一時的なguard競合だけを再試行扱いにし、受付後の実エラーは隠さないようcatch境界を補正した。
- PR #394をmergeし、main/origin/mainが `7e635479de492be17c9c9abf062831d46a024023` で一致・cleanとなったことを確認。正式repair `3660325eb88cdb9856004cf2a4048226` はpassed/cleanup cleaned。
- その後の分類・DB fallback・foreign venv依存の後続修正PR #396もmergeされ、main/origin/mainは `ec2c5808e8ef1f098c0a684a3f03c806a150b118` で一致・clean。無関係な作業はclear、migration対象だけblockedという停止範囲を実読取りで確認。
- 2026-09-07のODR-0038で、9/8〜10/7はハーネス新機構を凍結し、マージ停止をReady gateの赤と人手境界に限定、週次監査を夜間pytest＋通知へ降格し、製品作業（HOLD 80タスク解除）へ戻す方針を確認。
- 2026-09-10時点ではPR #412「Windowsキュー読み取り競合とReady入力の誤停止を修復」はmerge済み。mainは `289ddaabf8a7ebaddea4b177cca177b0679024df`。`harness_status.py --summary`では古いv2 jobが6件残り、4件は `cleanup_abandoned`、2件はDB工程の受付待ち表示。ただし記録の古さから、現在資源を占有しているとは断定不可。
- Schedulerの `NightlyRegressionPytest` は登録済みで、9/10 02:30に起動したが、`LastTaskResult=267014`で成功確認できず、正常終了ログも確認できなかった。夜間監査の「登録済み」と「初回成功・運用確認済み」は未分離のまま残課題。

Failures and how to do differently:

- 初期のforeground repairはセッション終了で `incomplete_previous_attempt` になった。既存jobを奪わず、detached worker/queue recoveryで扱う。
- PowerShellの複雑な引用、wildcard、外部PowerShell実行は環境guardrailで失敗した。Windowsでは単純な個別コマンド、`cmd.exe`、直接パス指定へ分割する。
- 後続修正のcatch範囲が広すぎると、実行後のエラーまで一時的な順番待ちに見せる危険がある。受付前のresource-busyと、claim後・実行中の失敗を別経路で扱う。
- `pending_async`、`cleanup_abandoned`、Scheduler登録、コード修正済みを成功扱いしない。terminal証拠、cleanup、実運用初回成功を個別に確認する。
- 週次監査の失敗で無関係な変更を止める設計は廃止方向だが、古い待機記録やDB/migration固有の停止は残り得る。全体再監査やworker増枠を先に行わず、対象jobと資源占有を読み取りで確認する。

Reusable knowledge:

- 正本の入口は `AGENTS.md`、`docs/OWNER_INTENT.md`、`docs/README.md`、`.agents/skills/pr-ready-gate/`、`docs/runbooks/local-pr-quality-gate.md`。
- 状態確認は `uv run python scripts/dev/harness_status.py --summary`。期間集計を混ぜず、必要なら `--job-id <ID>`で個別jobを確認する。
- merge条件は同一exact base/head、schema v4 Ready passed、required pack、claim、evidence hash、独立review、main同期を別々に確認する。古いheadの証拠は再利用しない。
- ODR-0038凍結中は新しいqueue、hook、台帳、契約テスト、常設ゲートを追加しない。赤→緑の1日以内修正、削除・降格・通知化のみ許可し、新機構案は既存駐車場へ1行記録して止める。
- 製品作業のDoneは、main mergeだけでなく、このPCへのアプリ/BFF/worker反映、必要なScheduler登録、初回成功まで含む。不要な場合はPR本文に明記する。

References:

- `scripts/dev/proof_pack_queue.py`, `scripts/dev/proof_pack_queue_worker.py`, `scripts/dev/proof_pack_queue_fs.py`
- `scripts/dev/weekly_audit_guard.py`, `scripts/dev/harness_status.py`
- `tools/quality/nightly_regression/main.py`
- `docs/decisions/20260830-resource-class-parallel-proof-execution.md`
- `docs/decisions/20260907-harness-freeze-and-product-return.md`
- `docs/decisions/20260906-parallel-development-efficiency.md`
- `uv run python scripts/dev/harness_status.py --summary`
- `PR #412` merged 2026-09-08、main `289ddaabf8a7ebaddea4b177cca177b0679024df`
- 2026-09-10観測: `NightlyRegressionPytest` state `Ready`、`LastTaskResult=267014`、成功ログ未確認
- 2026-09-10時点の残存job: `2d4842e0291d7ff7d7559b59adfb286e`、`3f011ea57fdc5cb818a8af2e924d9a43`、`9ecc1d7f2568725a5f22dcf0c4a14eb9`、`b3f4425cfbfe64c955d92d6bd373b78c`、`bd6984e71b0e63435dee16b410ede5ef`、`c72fe6ece27306e74cd412f697c4f638`
