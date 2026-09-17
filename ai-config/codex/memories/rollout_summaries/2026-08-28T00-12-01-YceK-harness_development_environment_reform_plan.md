thread_id: 01a045b5-8db8-7001-9ae7-f977bf183762
updated_at: 2026-08-28T00:57:11+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\08\28\rollout-2026-08-28T09-12-01-01a045b5-8db8-7001-9ae7-f977bf183762.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# 開発環境・テストハーネス改革計画を再審査し、一時計画として保存した

Rollout context: `D:\Dev\Investment`。ユーザーは、テストが長すぎて開発が進まない現状について、局所的な高速化ではなく、テスト選択、Ready/T3、queue、ハーネス、計測、暫定文書の扱いを含む全体計画を再評価し、次セッションから実行できる計画文書にまとめるよう依頼した。

## Task 1: ハーネス改革計画の再審査と保存

Outcome: success

Preference signals:

- ユーザーは「大目標である現在の開発環境の改善」「テストが長すぎて開発が全然進まない」ことを重視し、前回案をそのまま実行せず妥当性を再確認するよう求めた。今後は、単なる非同期化ではなく、不要なテスト選択・待ち行列・再実行・文書増殖まで一体で評価する。
- ユーザーは「暫定的なものをそのまま残す設計にしない」ことを明示した。計画・調査メモは一時領域に置き、恒久的な判断と手順だけを既存の正本へ統合する方針が望ましい。
- ユーザーは非エンジニア向けに「実行したら最終こうなります」という結果イメージを求めた。計画には、現状と改善後の比較、品質基準・exact-head・週次監査を維持することを平易に含める。

Key steps:

- 最新 `origin/main` とローカル `main` を確認し、HEAD `4a5f81102e1f27086d3489516604601f576cfe39`、clean、origin一致を確認。
- 最新KPIを実測し、Ready中央値76秒だけではp95、queue待機、async完了まで、初回通過率が見えないことを確認。local-pr静的検査32本、`tests/scripts/**` 52,566行、shared変更時の広い`python-fast`、runner-coreの約2,600件固定選択などを問題として整理。
- ODR-0018（ハーネス縮減）とODR-0019（ゲートが完遂を妨げない）の緊張関係を確認し、検査項目の網ではなく「守るべき振る舞いの証明」を維持しつつ、重複・内部固定・低価値検査を置換または削除する計画に修正。
- Phase 0〜4を計画化。Phase 1を「選びすぎとqueue待ちを先に直す」、Phase 2をテスト負債削減、Phase 3を計測・正本整理、Phase 4をexact-head Readyからpublish/merge/main sync/cleanupまでの着地とした。
- 一時計画を `data/runtime/plans/20260828-harness-development-environment-reform.md` に作成。サイズ14,890 bytesで、`.gitignore:57` により無視されること、`git status --short --branch` がcleanであることを確認。

Failures and how to do differently:

- 複雑なPowerShellやJS wrapper経由のコマンドは、encoded-shell guardrailで拒否された。今後は直接PowerShell、`cmd.exe`、または単純なコマンドへ分割する。
- 最新KPIの`Ready中央値`だけを成功指標にしない。非同期完了、queue待機、p95、初回通過率を別に測り、pendingを成功扱いしない。
- `shared_core`やrunner変更を理由に固定の広いテスト集合を同期実行しない。まず変更されたmoduleのinterfaceを通るfocused testを選び、必要な広域検証だけをasyncへ回す。
- queueの単純な優先順位変更だけでは不十分。repair/Ready/full auditの優先順位、同種FIFO、non-preemption、full auditのagingまたは分割を実行で証明する。

Reusable knowledge:

- 通常ループの正本は、変更箇所のtest → 失敗時のみ`focus --lf` → 完成時にclean exact-head Readyを1回。全域監査は通常PRから分離する。
- 選択器の代表的な問題は、`shared/config.py` が`python-fast`を同期Python packへ入れること、`scripts/dev/proof_pack_queue_worker.py` がqueue interface以外を含む固定テスト群を選ぶこと。
- ODR-0018/0019により、品質基準、exact SHA証拠、週次全体監査、人手境界、worktree分離は維持し、無条件の検査追加・モデル推論強度の一律変更・Scheduler登録は対象外。
- 文書の正本は、判断理由=既存ODR、テスト作法=`docs/guides/testing.md`、操作手順=`docs/runbooks/local-pr-quality-gate.md`、常時規則=`AGENTS.md`、実装証拠=1タスク1worklogに分ける。

References:

- 一時計画: `D:\Dev\Investment\data\runtime\plans\20260828-harness-development-environment-reform.md`
- 実測コマンド: `uv run python scripts/dev/harness_kpi.py --since 2026-07-20`
- selector確認: `uv run python scripts/dev/run_changed_test_plan.py --changed-path scripts/dev/proof_pack_queue_worker.py`、`--changed-path shared/config.py`、`--changed-path AGENTS.md`
- 正本: `docs/decisions/20260823-harness-reduction-policy.md`（ODR-0018）、`docs/decisions/20260824-gate-must-not-block-completion.md`（ODR-0019）、`docs/guides/testing.md`、`docs/runbooks/local-pr-quality-gate.md`
- 保存検証: `git check-ignore -v data/runtime/plans/20260828-harness-development-environment-reform.md` → `.gitignore:57`、`git status --short --branch` → `## main...origin/main`
