thread_id: 01a05013-2195-78c0-9690-743b25a1005d
updated_at: 2026-09-04T10:48:45+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\08\30\rollout-2026-08-30T09-30-26-01a05013-2195-78c0-9690-743b25a1005d.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# 文書管理標準の調査と再開用worklog作成

Rollout context: D:\Dev\Investmentで、UTF-8 Markdown、日本語本文、YAML front matter、正本・履歴分離、docs入口、生成物管理など14項目の文書標準について、実装前に現状・懸念・移行範囲を調査した。

## Task 1: 文書管理体制の現状調査と再開記録

Outcome: partial

Preference signals:
- ユーザーは「問題が発生するとか懸念点があるなどはユーザーと議論した上で実装」を求めた。文書標準のような広範な運用変更では、先に現行文書・正本・生成規則・移行コストを調べ、合意前に旧文書を一括変更しない。
- ユーザーは今回の実施内容と残課題を「次のセクションに移れるように」文書化することを求めた。新しい状態正本を増やさず、再開用worklogに確定事項・確認事実・未承認案・次回議題を分離する形式が適している。

Key steps:
- Matt Pocock Skillsの`writing-for-agents`を確認。常時ロード文書は短くし、context pointer、progressive disclosure、single source of truth、明確なcompletion criterionを重視する内容だった。
- 現行`AGENTS.md`、`CLAUDE.md`、`docs/OWNER_INTENT.md`、`docs/README.md`、ODR-0018、文書metadata checker、scope manifest、CI workflow、過去worklogをread-only調査した。
- 現行リポジトリはHEADとorigin/mainが一致し、mainはclean。`docs/README.md`が実質的な文書探索入口であり、`docs/INDEX.md`は存在しなかった。
- `scripts/check_docs_metadata.py --audit-all --similarity-min-score 0.85 --similarity-limit 30 --json`で、tracked文書2,501/2,501件を管理プロファイルへ分類。未分類0、scope gap 0、未登録authority候補0、完全一致・正規化一致0。高類似候補は月次/四半期run logの1組のみで、目的と周期が異なるため統合しない判断だった。
- worklog`docs/worklogs/20260904-documentation-cleanup-transition.md`を1件だけ作成し、2026年5月のアプリ改革12項目を現在の設計・実装・運用へ粗く対応付けた。旧文書・製品コード・API・DB・Desktop・Scheduler・Qwen進行中作業は変更していない。
- docs-onlyのReady gateは`harness-docs`と`git-diff-check`が成功し、overall statusはpassed。独立レビューはP0/P1なし、P2はmain統合未完了のみ。
- PR #366を公開したが、`finish-pr`は共有weekly audit stateの読取エラーでmerge未実施。診断では`read_aggregates=180`後に、削除済み監査詳細を参照する`weekly audit summary component is missing`が発生した。共有キューや他セッションは変更せず、PRと証拠を保持した。

Failures and how to do differently:
- 複雑なPowerShell/日本語引数はencoded-shell guardrailや文字化けで失敗した。Windows環境では短い直接コマンド、`cmd.exe`指定、英数字タイトルを使う。
- `check_md_links.py --scope docs/worklogs`は既存archive内の`<url>` placeholder 1件で失敗したが、新規worklog由来のbroken linkではなかった。既存問題と今回の変更起因を分離して報告する。
- `finish-pr`を対象worktree内から実行すると「run this command from outside the target worktree」となる。main checkoutから実行する。
- docs-only変更でも、共有weekly audit stateが壊れていると安全側にglobal stopされ、merge不能になる。共有状態を手動削除・修復・peer停止せず、読取専用で原因を特定し、修復PRの着地後にtested base/headを再確認して再実行する。

Reusable knowledge:
- 現行の文書metadata契約は`authority_key`、`ssot_role`、`status`、`implementation_status`、`owner`、`last_validated`、`supersedes`、`superseded_by`の8項目。scopeは`scripts/contract_scope.yaml`で明示管理される。
- `docs/README.md`はSSOT役割・現行読み順・Historical/Deprecated導線を持つ。現行状態はdocs/README、OWNER_INTENT、design/ODR、backlog、runbook/manifest、実行証拠へ分ける。worklogをcurrent authorityやtask状態の正本にしない。
- 機械検査はmetadata、分類、権威関係、リンク、重複候補の抽出までに留め、意味統合・改名・削除は自動化しない。類似度だけで文書を統合しない。
- 旧文書は内容を現在仕様へ一括書換せず、現在の正本への相対リンクと履歴位置付けを小さなwaveで追加する。意味が変わる編集・削除は項目別にユーザー承認を得る。
- 次回の最初の議題は、TDNET品質、決定論的KPI処理、Qwen分析、旧品質ゲートを別責務として扱う案の採否。これは未承認案であり、承認後に旧文書・design・backlogを同期する。

References:
- `D:\Dev\Investment-documentation-cleanup-transition\docs\worklogs\20260904-documentation-cleanup-transition.md`
- `docs/documentation-standard.md`
- `docs/decisions/20260830-documentation-authority-and-history-governance.md`
- `docs/README.md`
- `scripts/check_docs_metadata.py`
- `scripts/contract_scope.yaml`
- `uv run python scripts/check_docs_metadata.py --audit-all --similarity-min-score 0.85 --similarity-limit 30 --json`
- Ready evidence: `overall_status=passed`, `required_packs=["harness-docs"]`, head `4b17fc3e03f8c9be7522c24b9f78a20d4b794f83`
- PR #366: https://github.com/zmarl/Investment/pull/366
