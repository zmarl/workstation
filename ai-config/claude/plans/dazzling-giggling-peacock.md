# ハーネス再設計 — Phase 0（取込・計測・割れ窓）実行計画

## Context

オーナーが Cowork セッションで作成した 2 文書（`Investment_設計資料/取込パック_20260823_ハーネス再設計/` の調査レポート + 実装指示書）を取り込み、ハーネス（ゲート・台帳・契約テスト・指示ファイル・役割）を「足す」から「引く + 検証の向きを変える」方向へ向け直す。本計画は指示書 §0「取込手順」と §3「Phase 0 — 凍結と計測」を対象とする。**Phase 1 以降はハーネス縮減 ODR にオーナーが「はい」と答えてから**着手する（指示書 §0-3）。

### 指示書どおりに進められない点と、その扱い

| # | 事実（本セッションで実測） | 扱い |
|---|---|---|
| 1 | **ODR-0015 は並行セッションが既に使用**（PR #204 で main にマージ済み = `11fcaeff1`。「投資判断OS Phase 0A worktree の処分顛末」。OWNER_INTENT §7 / README §3 / registry.yaml（2300）も更新済み） | ハーネス縮減方針は **ODR-0017**、ODR-0002 衝突の振り直し先は **ODR-0016**（指示書「0015 の前番」案を番号だけずらす）。origin/main は同期済みで衝突なし |
| 2 | `scripts/dev/*.py` の新規追加と `scripts/contract_scope.yaml` の編集は、どちらも selection registry 上 **unknown → T3 強制**（約 55〜67 分） | **H0a と H0b を 1 PR に統合**し T3 を 1 回にする（指示書は別 PR だが「別の形で」） |
| 3 | `docs/status/harness-kpi-<日付>.md` を週次で足すと毎回 `expected_managed_markdown_count` の更新が要る（台帳追随の典型） | **固定ファイル名 `docs/status/harness-kpi.md`**（日付は本文冒頭に刻印、履歴は git）。`--out` で日付付き出力も可 |
| 4 | gate 証跡は head SHA ごとに通過記録しか持たない（104/104 passed） | 初回通過率は「未計測」と記す。所要中央値は算出可能（ready 93 秒 n=11、t3 67 分 n=25） |
| 5 | メタ件名比率は指示書定義の正規表現で **202/557 = 36%**（レポートの 46% は `close gaps` / `reject|enforce|bind` を含む広義） | KPI 文書に両定義の値を併記 |
| 6 | `tests/scripts` の赤は記録の 135 件ではなく **実測 19 件**（2,256 件中、12 分） | 削除 17 / 修正 1 / 隔離 0。隔離ディレクトリは作らない（作ると pyproject 変更で T3 化） |

### 承認後の追記（PR #205 マージによる差分、2026-08-23）

- PR #205（Codex、「変更別証明パック型テストゲート中核切替」）が main に着地。**ODR-0002 衝突は同 PR が ODR-0016 へ振り直し済み**（索引・contract_scope も更新済み）→ 計画 §3 は不要。残る stray 参照 2 箇所（ODR-0014:42 / ODR-0015:37 の「ODR-0002 の機構削除」）だけ ODR-0016 に直す。
- **ODR-0017 = 変更別証明パック（Accepted, 08-21）** → ハーネス縮減方針は **ODR-0018**。`amends` に ODR-0001 と ODR-0017 を併記し、背景に「ODR-0017 と重なる点（週次監査・ready/audit 分離）と逆向きの点（queue/attestation/mutation test/未知 path 停止の追加）」を書く。
- gate は `ready` / `audit`（t3 は deprecated alias）。`scripts/contract_scope.yaml` は `harness_docs` クラスに分類済み（unknown ではない）。**未分類 path は `classification_required` で停止**するため、`scripts/dev/harness_kpi.py` を `development_test_selection.yaml` の `harness_docs.patterns` に 1 行追加する → 必要 pack は `harness-docs`（sync 120s）+ `runner-core`（sync 180s）。PR-1 は **Ready で完結**（T3 不要）。
- registry count は 2302 → **2305**。README §3 は 21 項目 → ODR-0018 を 18 番に挿入し 19〜22 へ振り直し。
- `publish-pr` / `finish-pr` は `--evidence-path <schema v4 result.json>` が必須（既定 `data/runtime/evidence/local_pr_gate/v4/<head>/<run-id>/result.json`）。

## 全 PR 共通の作法

- `1 PR = 1 claimed 外部 worktree = 1 worklog`。main checkout では編集しない。`EnterWorktree`（WorktreeCreate hook が claim を作る）→ 実装 → focused 検証 → worklog commit → exact-head gate → `publish-pr` → `finish-pr`（skill `pr-ready-gate`）。
- 指示書にない検査・台帳・契約テスト・役割・hook は追加しない。削除で済むものは書き換えない。
- 検証は実行で。受入コマンドの出力を worklog に貼る。
- 生成 md/py は `write_text(encoding="utf-8", newline="\n")`（LF）。PowerShell `Set-Content` は使わない。

---

## PR-1（H0a + H0b）: 取込 worklog・ODR-0017 起票・ODR-0002 衝突修正・KPI 計測

worktree 名: `harness-intake`。worklog: Full。gate: `--mode t3`（fresh worktree では `npm ci` と `.env` を先に整える）。

### 1. 取込 worklog `docs/worklogs/20260823-claude-harness-intake-<hash>.md`（Full）

- 雛形: `.agents/skills/worklog-starter/references/worklog-full-template.md`（ExecPlan 5 小節の見出しは逐語）。Harness: claude、Status: Draft から。
- §4 適合表: 既存例 `docs/worklogs/20260810-claude-owner-direction-intake-68c2f7d8fd.md` の形式 `| # | 外部資料 | 判定 | 取込先 / 理由 |`。指示書 §0〜§8・付録 B/C/D の全項目を 1 行 1 項目で判定（Phase 0 = 取り込む、Phase 1〜4 = 取り込む(ODR 承認後)、上表 #1〜#6 = 別の形で、ODR-0015 番号前提の記述 = やらない）。
- §5 H0d（global 設定の棚卸し）の結果: 矛盾 4 件（後述）。
- 一次資料 3 ファイルの SHA-256 と `source summary, not original-session verbatim` の明示（OWNER_INTENT §5-1）。

### 2. ODR-0017 `docs/decisions/20260823-harness-reduction-policy.md`

- 指示書 §2 ドラフトを全文採用し、番号を 0017 に、「背景」をレポート §5 の数値（feat 7% / メタ 36〜46% / 検査 56〜61 / 赤 19（記録 135）/ 不変条件ゲート 1,364→14,850 行・真陽性 0）+ H0d の矛盾 4 件で 10 行以内に。
- frontmatter: `authority_key: decisions.harness_reduction_policy` / `ssot_role: ADR` / `status: Proposed` / `implementation_status: Planned` / `owner: Project owner` / `last_validated: 2026-08-23` / `supersedes: []` / `amends: [docs/decisions/20260810-owner-direction-2026q3.md]` / `superseded_by: []`（ODR-0013/0014 と同形）。
- 「一次記録」は空欄（オーナーの「はい」を逐語で追記してから Accepted へ）。`docs_contract_keywords` の禁止語 10 語を含めない。`TODO/課題/今後` 等の語があれば `backlog_scanner scan --write` で Layer-B を追随。

### 3. ODR-0002 衝突の修正（見出し振り直し、ファイル名不変 = README §7 の規則）

- `docs/decisions/20260817-financial-data-invariants-gate-retirement.md:12` → `# ODR-0016: …`。同 17 行目の worklog パス誤記（`…-gate-20260817-…` → 実在する `…-gate-2026081-…`）も修正。
- 退役 ODR を指す `ODR-0002` を `ODR-0016` へ: `docs/contracts/financial-data-invariants.md`、`docs/backlog/worktree-disposition-ledger-20260816.md`、`docs/backlog/次アクション管理台帳.md`、`docs/decisions/20260822-api-v2-worktree-disposition.md:42`、worklog 11 本（20260817/0820/0821 の retire・handoff 系、20260812 の 5 本、20260813-valuation）、テスト内コメント 3 件（`tests/scripts/ci/test_run_local_pytest.py:188`、`tests/scripts/ci/test_local_pytest_process_isolation.py:89`、`tests/tools/decision_support/disclosure_event_desk/test_cli.py:316`）。
- 不変: IIP の ODR-0002 参照（`20260813-macro-statistics-continuity.md`、`20260812-external-report-intake-owner-odrs.md` の `ODR-0002〜`）。
- 確認: `git grep -n "ODR-0002"` の残りがすべて IIP 参照であること。

### 4. 索引・登録（既存 ODR 14 本の慣行）

- `docs/OWNER_INTENT.md`: §7 に ODR-0016（2026-08-17）/ ODR-0017（2026-08-23、Proposed）の 2 行、§3-3「保守面積の削減」に ODR-0017 の 8 週間目標を 1 行、冒頭「最終更新」。§5 は変更しない（H1c の範囲）。150 行以内（現 89 行）。
- `docs/README.md` §3 に 2 項目追加し番号振り直し。
- `scripts/contract_scope.yaml` `docs_metadata.documents` に ODR-0017 を `role: ADR, category: canonical_ssot` で登録（退役 ODR は従来どおり未登録）。
- `docs/research/registry.yaml` `expected_managed_markdown_count` を **2300 → 2303**（worklog・ODR・KPI md の 3 件）。

### 5. KPI 計測 `scripts/dev/harness_kpi.py`（≤150 行、テストなし、ゲート非対象）

- 標準ライブラリのみ（`subprocess` で git、`json`、`statistics`、`re`、`pathlib`）。出力は `# ruff: noqa: T201` の既存慣行で `print`。引数 `--since`（既定 8 週前）/ `--write` / `--out`（既定 `docs/status/harness-kpi.md`）。
- 出力項目（指示書 H0b）: ① 件名 prefix 集計と feat 比率 ② メタ件名比率（指示書定義 + 広義の 2 値）③ `run_check_suite.py --profile local-pr --list` の検査本数（`--list` は実在、現在 56） ④ gate 証跡直近 20 件の mode 別所要中央値（`budget.elapsed_seconds`）と「初回通過率: 未計測（証跡は通過記録のみ）」 ⑤ `tests/` ファイル数・`def test_` 数・行数、`tests/scripts` 行数（直下 / ci+dev 込み）、`scripts/check_*.py` 本数 ⑥ `git worktree list` 本数 ⑦ `revert` 件名数。
- md 冒頭に生成元コマンド・計測時点・各定義（`docs/status/README.md` の「生成元明記」規約）。`21戦略` 等の旧用語は書かない（`strategy_contract_sync` が docs/status を走査）。
- 受入: `uv run python scripts/dev/harness_kpi.py --write` で生成され、レポート付録 A と ±10%（事前実測: 557 件 / fix 229 / docs 158 / feat 37 / tests/scripts 直下 ≈35.7k 行）。

### 検証（worklog に出力を貼る）

```
uv run python scripts/check_docs_metadata.py --json
uv run python scripts/check_docs_research_registry.py --json
uv run python scripts/check_docs_contract_keywords.py --json
uv run python scripts/check_strategy_contract_sync.py --json
uv run python scripts/check_md_links.py --scope docs/decisions
uv run python -m tools.quality.backlog_scanner.main check
uv run python scripts/dev/harness_kpi.py --write && git diff --stat docs/status/harness-kpi.md
uv run ruff check scripts/dev/harness_kpi.py
```
その後 exact-head gate `--mode t3` → `publish-pr` → `finish-pr`。

---

## PR-2（H0c）: `tests/scripts` の赤 19 件の解消

worktree 名: `harness-red-tests`。worklog: Full。gate: Ready（`tests/**` = focused_python、`db/*.yml` は db scope）。

### 実測した赤と三分（実装時に worktree で再実行して確定）

| 区分 | 対象 | 根拠 |
|---|---|---|
| **削除 14** | `test_earnings_carry_manifest.py` 10 件 / `test_earnings_intraday_fresh_success_wait.py` 2 件（ファイルごと）/ `test_daily_briefing_manifest_contract.py` 1 件 / `test_earnings_reference_scheduler_registration.py` 1 件 / `test_earnings_scheduler_chain.py` 1 件 / `test_listing_lifecycle_manifest_cli_args.py` 1 件 | 参照する task（`daily-briefing`、`earnings-carry-*`、`earnings-post-action-short-cycle`、`daily-screener-run`、`candidate-universe-refresh-daily` 等）は `run_manifest.yaml` の **`disabled_tasks:` 配下**で、現在動かない task の scheduler 契約を固定している台帳テスト。EARN-CARRY 系は OWNER_INTENT §4 の hold 解除時に commit `8fe2dd03f` から復元可と worklog に記す |
| **削除 1** | `test_disabled_task_readiness.py::test_real_manifest_has_complete_47_task_triage` | 「47 task」の件数固定。現在 disabled 96 件・triage 未登録 18 件以上（2026-07-20 以降の triage 台帳不追随）。単体テスト 7 件は残す |
| **削除 1** | `test_check_desktop_api_client_inventory.py::test_write_baseline_then_validate_clean` | 2026-08-02 の checker 変更（baseline は diagnostic → reviewed ratchet）に未追随。同趣旨の現行テストは `test_check_desktop_api_client_usage.py::test_reviewed_baseline_allows_known_unused_method` に存在（重複） |
| **修正 1（2 行）** | `db/runtime_schema_governance_allowlist.yml`: `tools/market_data/estat_tracker/response_spool.py` を追加、stale の `shared/db_contracts/ops.py` を削除 | `test_db_runtime_schema_governance_check_passes` は実 checker を呼ぶ。estat の spool は一時 **sqlite3** ファイル（PostgreSQL ではない）で、checker の文字列検出の偽陽性。allowlist が本来の用途 |
| **隔離 0** | — | 設計判断を要する振る舞いテストは無かった |

- 関数削除後は未使用 import を `ruff check --fix` で掃除。ファイル内のテストが 0 になれば ファイルごと削除。
- 削除対象ファイルは gate 契約（`REQUIRED_LOCAL_PYTEST_FILES` / `_RUNNER_CONTRACT_TEST_NODES` / `RUNNER_SAFETY_TEST_PATHS` / file_size_budget baseline）に **含まれていない**ことを確認済み（`test_check_desktop_api_client_inventory.py` は selection.yaml の pattern にあるが関数削除のみで存続）。
- 受入: `uv run pytest tests/scripts -q -p no:cacheprovider` が失敗 0（実行 12 分）。削除・修正・隔離の件数を KPI 文書に反映（`harness_kpi.py --write` を再実行し差分を commit）。

---

## H0d: global 設定の棚卸し（調査済み、PR-1 の worklog §5 と ODR-0017 背景に記録）

1. `scripts/check_claude_agent_roles.py` が `run_check_suite` / selection に未登録（Codex 側 `codex_agent_roles` だけ gate 化。`docs/guides/development-harness.md:21` は両方を契約正本と記述）
2. `~/.codex/rules/host-executables.rules`（13 rule）は global 専用でミラー検査対象外（`default.rules` は repo と byte 一致）
3. `~/.claude/rules/` に `.bak` 残骸 2 件。`~/.claude/CLAUDE.md` は不存在（repo CLAUDE.md は `~/.claude/rules/multi-agent.md` を参照）
4. `.claude/worktrees/book-knowledge` が claim 外の内部 worktree（PreToolUse 未配線のため機械的に防げない）
補足: `~/.codex/config.toml` は `goals = true`・親 `xhigh`・`max_threads = 6`（repo は 4）。`~/.claude/settings.json` は deny 80・hooks なし・`effortLevel: xhigh`・`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`。秘密情報は値を書かない。

---

## 解釈エコー（指示書 §1 の形式。本計画の承認 = Phase 0 の「1. はい」）

```
【確認】次の理解で進めます。
- 変更前: ODR-0002 が 2 本ある／ハーネス縮減方針の ODR が無い／KPI の基準値が無い／tests/scripts に赤 19 件
- 変更後: 退役 ODR を 0016 に振り直し、縮減方針を ODR-0017（Proposed）として起票。KPI を docs/status/harness-kpi.md に生成。tests/scripts は赤 0
- 触るもの: docs（worklog・ODR・OWNER_INTENT §3/§7・README §3・ODR-0002 参照 ≈25 箇所）、scripts/contract_scope.yaml、docs/research/registry.yaml、scripts/dev/harness_kpi.py（新規）、tests/scripts の赤 18 関数/2 ファイル、db/runtime_schema_governance_allowlist.yml（2 行）
- 触らないもの: AGENTS.md / CLAUDE.md / 役割ファイル / hook / run_check_suite / selection.yaml / 検査スクリプト本体（Phase 1〜2 の範囲）。OWNER_INTENT §5。投資ロジック
- 完了条件: (a) docs 検査 5 本 + ruff が pass し T3 gate green で PR-1 マージ (b) harness_kpi.py --write の数値がレポート付録 A と ±10% (c) uv run pytest tests/scripts -q が失敗 0 で PR-2 マージ
選択肢: 1. はい  2. ここが違う  3. もっと小さく
```

## 着手順

1. PR-1（T3）→ 2. PR-2（Ready）。PR-2 は PR-1 と独立なので、PR-1 の T3 待ち時間に並行して進めてよい（同時書き込み 2 本以内）。
3. Phase 0 完了後、ODR-0017 の解釈エコー（Phase 1〜4 の内容）をオーナーへ提示し「はい」を得てから Phase 1（H1a〜H1e）へ。

## 参照

- 指示書: `D:\Dev\Investment_設計資料\取込パック_20260823_ハーネス再設計\実装指示書_ハーネス再設計_2026-08-23.md`
- worklog 例: `docs/worklogs/20260810-claude-owner-direction-intake-68c2f7d8fd.md` / ODR 例: `docs/decisions/20260822-api-v2-worktree-disposition.md`
- lifecycle: `.agents/skills/pr-ready-gate/SKILL.md`、`scripts/dev/sync_repo.py`（`repo_lifecycle_cli.py`）
- 実測ログ: `D:\DevTemp\kazum\claude\D--Dev-Investment\3f6c93bb-2607-440c-9e37-cb6a33159fc7\scratchpad\tests_scripts_run.txt`
