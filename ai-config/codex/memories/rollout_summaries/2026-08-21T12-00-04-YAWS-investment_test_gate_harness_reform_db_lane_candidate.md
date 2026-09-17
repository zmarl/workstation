thread_id: 01a02431-4601-72a0-9129-8fa0e87eb562
updated_at: 2026-08-26T00:48:08+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\08\21\rollout-2026-08-21T21-00-04-01a02431-4601-72a0-9129-8fa0e87eb562.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# テストゲート／ハーネス改革の現状調査とDBレーン並行化候補の作成

Rollout context: `D:\Dev\Investment`。ユーザーは、テストが1セクション数時間〜数日かかる問題について、既存ハーネス・開発環境・T3運用を含めてリポジトリ設定を見直し、確認しながら進めるよう依頼した。途中でユーザーは「全体を一括設計」を選び、T3の基本方針自体が時間・トークン消費の原因ではないかも含めた再検討を求めた。

## Task 1: 現行ゲート／ハーネスと改革資料の照合

Outcome: partial

Preference signals:
- ユーザーは単なる部分的な高速化ではなく、テスト方式・T3の役割・ハーネス・PC設定を含めて「全体を一括設計」することを選択した。今後は局所修正だけでなく、運用方針そのものを評価対象にする。
- 変更前に現行環境を確認し、ユーザー確認を取りながら進めることを求めた。外部資料の数値や提案は現行HEAD・実測・正本文書と照合してから採用する。
- 報告は結論先出し、平易な日本語、根拠と時点を明示する形式が望ましい。

Key steps:
- `D:\Dev\Investment_設計資料\着手パック_テストゲート改革_2026-08-13.md` は指定パスではなく sibling の `D:\Dev\Investment_設計資料\着手パック_テストゲート改革_2026-08-13.md` に存在することを確認。
- main checkout は調査開始時点で clean、HEAD `51f857bf3a22b750ca8eb5be22264982727fb686`。複数の外部worktreeとlockが存在するため、変更は専用worktreeで分離する方針を確認。
- 過去資料のT3 88〜95分に対し、2026-08-20〜21のevidenceではT3約51〜74分。ただし主因は依然 `t3-python` 約45〜69分で、Ready（通常数分）とは別問題。
- 現行の `scripts/development_test_selection.yaml` は `runner_gate` にAGENTS/CLAUDE/.agents/.claude/.codex、runner、conftest、fixture等を広く含み、文書変更でもT3へ昇格し得る。`harness_docs` 分離やlane並走は未実装。
- 2026-08-17のODRで金融データ不変条件の帳簿型機械強制は退役済み。従来資料の589本hardeningを前提にPR-βをそのまま実施するのは不適切。
- repo内のCodex/Claude役割検査は合格。一方、ユーザー側Codex設定検査は `global config model_reasoning_effort must be 'xhigh'` で失敗し、実値は `ultra`。モデル既定値変更はODR対象。

Failures and how to do differently:
- 複雑なPowerShellをJS exec wrapper経由で実行すると `Use the harness PowerShell directly` で拒否された。今後は単純な直接PowerShellコマンドに分割する。
- 指定された資料パスが存在せず、siblingフォルダを探索して実体を特定した。外部設計資料はパスを鵜呑みにせず、実在確認とregistry・hash確認を行う。
- 過去の資料・worklogの「完了」やT3数値を現行事実として扱わない。現在HEADのevidenceと再実測を優先する。

Reusable knowledge:
- 正本確認の入口は `docs/OWNER_INTENT.md`、`docs/README.md`、`docs/decisions/`、`docs/backlog/次アクション管理台帳.md`、`docs/research/registry.yaml`。
- 永続境界は、発注・資格情報・外向き発注通信なし、DesktopはBFF `127.0.0.1:8010`のみ、DB変更はAlembicのみ、LLMは補助限定、旧経路はshadow/rollback/restore証拠まで削除しない、ETF/ETN/REIT/投信除外。
- `docs/OWNER_INTENT.md` の現行方針では、PR品質判定は全域回帰の毎回実行ではなく変更別証明パックを正本とし、長時間検証・全域監査を非同期へ分離する方向がODR-0017で採択済み。ハーネス縮減と実行による証明重視はODR-0018、ゲートがアプリ完遂を妨げてはならない方針はODR-0019。

References:
- `docs/guides/testing.md`: 通常ループは変更箇所test → 失敗時`focus --lf` → clean exact-head Ready。T3は通常開発に入れず専用回帰に限定。
- `docs/guides/development-harness.md`: explorer/reviewer/security reviewerはread-only、implementerは1 task/1 worktreeで1名、同一SHAを独立review。
- `docs/decisions/20260712-local-pr-quality-gate.md`: GitHub Actionsを品質正本にせず、local exact-head gateと独立reviewを正本とする。
- Evidence例: `97046fae...json` は2026-08-21 T3 passed、total `3082.524s`（約51.4分）、`t3-python` `2679.031s`。

## Task 2: DBレーン並行化候補の実装

Outcome: partial

Preference signals:
- ユーザーの「T3方針自体を含めて見直す」という指示を受け、通常Ready・個別proof pack・週次全体監査を分離し、DB並行化は独立実験として扱った。変更を混ぜず、効果を測ってから採否を決める進め方が適切。
- 20%以上の短縮と検査内容完全一致を満たさない限り採用しない条件をworklogに固定した。

Key steps:
- 専用worktree `D:\Dev\Investment-db-lane-parallel-experiment-20260826` を作成。claim ID `14d3fd71fe3c03532072ecc365c8af08`。
- `scripts/ci/run_local_pytest.py` に、週次DB確認向けの固定enum `db-txn` / `db-fresh` / `migration` と内部lane指定を追加。通常の直列方式と個別proof pack経路は維持。
- `scripts/dev/weekly_audit_execution.py` に、3レーンを別process・別ローカルPostgreSQLコンテナで並行実行する候補を追加。任意command/path/pytest引数は受け付けない。
- 0件扱いを従来契約へ合わせ、一部laneがexit 5でも他laneにテストがあれば成功、3lane全て0件なら失敗とした。コンテナ起動失敗のみ固定3laneを1回再試行し、テスト失敗・不正結果・timeout・runner異常は再試行しない。
- focused pytestは最終的に `92 passed, 1 skipped`、Ruffと`git diff --check`は成功。commit `441139345f9aac5b6a60417e47518a35252ba800` を作成。

Failures and how to do differently:
- 最初にexclusive resourceへファイルパスを渡して `unsupported exclusive resource` となった。現在のclaim resourceは`ddl`のみ（`scripts/dev/repo_lifecycle_claims.py`）で、通常のrunnerファイルはresource指定せずworktree単位で分離する。
- 実DB/Docker実行、旧方式3回＋候補方式3回の性能測定、node digest・件数・DB identity・cleanupの完全一致確認は未実施。候補は未採用であり、速度改善を主張してはいけない。
- 候補実装をcommitしただけで、rebase、独立review、Ready、PR、mergeは未完了。commit済み＝採用済みと扱わない。

Reusable knowledge:
- 実験worklog `docs/worklogs/20260826-db-lane-parallel-experiment.md` に、旧方式/候補方式を同一SHAで各3回、20%以上短縮時だけ採用する受入条件を記録。
- 週次監査のDB入口は `scripts/dev/weekly_audit_execution.py` の `safe-db` / `safe-audit-db`、実行器は `scripts/ci/run_local_pytest.py` の `weekly-db` / `weekly-audit-db`。通常のデフォルト動作は直列のまま。
- 各候補laneはloopback、ランダムDB名、identity-bound scratch PostgreSQL、owned process、終了後cleanupを維持する必要がある。

References:
- Commit: `441139345f9aac5b6a60417e47518a35252ba800` (`feat: add measured DB lane parallel candidate`)
- Changed files: `scripts/ci/run_local_pytest.py`, `scripts/dev/weekly_audit_execution.py`, `tests/scripts/ci/test_run_local_pytest_weekly.py`, `tests/scripts/dev/test_weekly_test_audit.py`, `docs/worklogs/20260826-db-lane-parallel-experiment.md`
- Validation: `92 passed, 1 skipped`; DB/Docker/性能測定は未実行。

## Task 3: 長時間検証の証拠判定共通化

Outcome: partial

Key steps:
- `schema v4`のReady成功条件をqueue event共通validatorへ集約し、API表示・証拠保存・統合判定の重複検査を削減。
- weekly audit repair判定でもsnapshot経路とファイル読取経路を共通化。
- `40 passed in 3.89s`、`56 passed in 7.47s`、Ruff・diff check green。commit `2261780a9e63583ab0f55d35b84374a392434937`。

Failures and how to do differently:
- branchは正式schema v4 request契約より古く、最新mainへのrebase後に正規request生成との結合確認が必要。最終Ready・独立review・merge未実施。

References:
- Commit: `2261780a9e63583ab0f55d35b84374a392434937` (`refactor: share verification success contracts`)
- Modified files: `scripts/dev/proof_pack_queue_events.py`, `scripts/dev/weekly_audit_guard.py`, `tools/api/decision_api/verification_status_repository.py` と対応テスト・worklog。
