---
name: project-session-resume-2026-08-24
description: 2026-08-24〜25 セッションの再開手順。未マージ PR 5 本・保全 branch 1 本・週次監査の全体停止と解除手順
metadata:
  type: project
---

# 再開手順（2026-08-25 更新。コンテキスト消去後はここから読む）

## 最新（2026-08-26 夜）— **自分の PR は全部着地。停止も解除済み**

origin/main は `269bbd936`。自分の未マージ PR はゼロ。

### 今日直した「反映を妨げていたもの」3 件

1. **時間切れで壊れたテスト 9 件**（`capital_cost_tracker`、PR #223）
2. **共有 queue に残った死んだジョブ** — Codex 側の gate 実行が未承認 pack `python-broad` を参照する
   `ready_async` ジョブを残し、`merge_attested_aggregates` が `QueueContractError` で例外 →
   **全セッションの merge 判定が読めなくなっていた**（13 時間・263 回失敗）。
   オーナー承認を得て退避のうえ削除。`.git/investment/proof_pack_queue/v1/jobs/<id>` を消すだけ
3. **PR #227 の追随漏れ**（PR #234） — `64bbaef58` で GC の proof 方式が `ready_terminal_proof.publish` に
   変わり rename が 1→3 回に増えたのに `assert observed == [145]` が残り、週次監査が global stop。
   3 回とも 145（拒否）＝保護は効いていたので、回数の固定をやめ性質の固定へ

### Codex と重複していた件（重要）

- Codex の `codex/selector-config-python-broad-20260826` が**同名 `python-broad` で同じ G-2 修理**を
  より広く（selector / queue / evidence の pack ID 契約 3 箇所）進めていた。私の PR #232 は取り下げ
- **ただしあちらのやり方だけでは merge 段階を必ず失敗する**: merge 時の再構成は main checkout 側の
  旧コードで行われるため、pack 識別子が厳密一致だと一覧を変更する PR は永久に通らない
  （実測 `schema-v4 selector could not be reconstructed`）。**PR #233 でその厳密一致を
  「既知 pack をすべて含むこと」に緩めて着地済み**。あちらはこれで通るはず

### 毎回効く手順の罠

- **force push 禁止**。main の取り込みは `git merge --no-ff origin/main`
- **スナップショット再生成は他の変更を commit した後**（途中だと `worktree_dirty: true` が焼き込まれる）
- 衝突はほぼ `docs/research/registry.yaml` の件数と `generated-repository-snapshot.json` だけ。
  件数は**算術で埋めず `check_docs_research_registry.py` の実測値**を使う
- **1 本 merge するたび main が動く**ので残りは毎回やり直し
- 監査は 1 回 70 分・host 全体で 1 本。`--run-one` の `PermissionError` は peer 実行中の意味
- **fresh worktree では `tests/scripts/` が 105 件落ちる**（`.env` / `node_modules` 不在）。main checkout では通る

### 残っている自分の作業

- branch `claude/book-knowledge-principles-ftd-20260824-263b499247`（head `484c98792`、origin へ push 済み）。
  投資原則 30 件 + 朝会/Knowledge Base 配線 + O'Neil FTD 検出。
  **Codex の `python-broad` が着地すれば publish できるようになる**
- worktree `Investment-claude-broad-lane-async-20260826-263b499247` は取り下げ済み PR #232 の残骸。片付けてよい
- 次の作業: 審議会クローラーの委員会 URL 台帳（68 中 42 失敗）

---

## 旧（2026-08-26 昼）— **未マージ PR は全部片付いた**

origin/main は `c7de1ad73`。自分の PR は **#223 → #220 → #219 → #218 → #216 の順で全件着地済み**。
残る自分の作業は投資原則 branch 1 本だけ（下記）。

### 週次監査の全体停止は解除された

- **実質原因は harness ではなくテスト**: `tests/tools/market_data/capital_cost_tracker/` の 9 件が
  fixture `2026-06-30` 固定で鮮度窓 55 日を超え、必ず失敗していた。PR #223 で修理して着地
- 解除の実手順（**機械作業。実行してよい**）:
  `uv run python -m scripts.dev.weekly_test_audit --enqueue-repair --expected-head <40桁> --source-claim-id <32桁>`
  →`uv run python -m scripts.dev.proof_pack_queue --run-one` → passed → finish-pr。
  merge 後は `--enqueue-current-main` の full_audit を通すと global stop が完全に消える
- **1 回およそ 70 分・host 全体で 1 本だけ**。`--run-one` が `PermissionError` を返すのは peer が実行中の意味なので待つ
- **混雑時は harness が落ちる**: 別セッションの監査や自分の gate と重なった回は、監査本体ではなく結果書き出しの
  `git rev-parse --git-common-dir` が失敗して `evidence:EvidenceContractError`。69 分ぶんが無駄になる。空いてから 1 本

### 毎回効く手順の罠

- **force push は禁止設定**。main の取り込みは rebase ではなく `git merge --no-ff`
- **スナップショット再生成は他の変更を commit してから**。途中で生成すると `worktree_dirty: true` が焼き込まれて
  `current_docs_snapshot` 検査が落ちる
- 衝突はほぼ毎回 `docs/research/registry.yaml` の件数だけ。**算術で埋めず `check_docs_research_registry.py` の実測値を使う**
  （branch 値と main 値が偶然一致すると git は衝突を出さないまま間違った値を残す）
- **1 本 merge するたび main が動く**ので、残りは毎回 merge 取り込み → gate → push → publish-pr → finish-pr をやり直す

### 残っている自分の作業

- branch `claude/book-knowledge-principles-ftd-20260824-263b499247`（head `484c98792`、origin へ push 済み、
  worktree `D:\Dev\Investment-claude-book-knowledge-principles-ftd-20260824-263b499247`、
  claim `a541147179e199a33394f1ab92dd9007`）。投資原則 30 件 + 朝会/Knowledge Base 配線 + O'Neil FTD 検出
- **2026-08-26 の最新 main でも publish 不能**。`shared/principles.py` を含むため selector が `broad_fast` を選び、
  `python-fast`（実測 11 分）が同期 300 秒予算で timeout する = G-2。`--scope` は追加しか許さず回避路なし
- G-2 の正本記録は `docs/backlog/20260824-harness-gate-gaps.md`（main に着地済み）。
  harness 側の直しは peer セッションが同領域で作業中（PR #227 / #228）なので単独で触らない

---

## 旧（2026-08-25 時点の記録）

## 最新（2026-08-25）

- origin/main は `6d382817e`（08-24 の緑の隙間に Codex の PR #215 が入った）。**自分の PR 4 本は全部これに載せ替え済みで gate 緑**
- **force push は禁止設定**。rebase して push し直すことはできない。origin/main を branch へ **merge** して取り込む
- **スナップショット再生成は作業確定後にやる**。途中で生成すると `worktree_dirty: true` が焼き込まれて `current_docs_snapshot` 検査が落ちる
- **週次監査が通らない実質原因を特定した**: `tests/tools/market_data/capital_cost_tracker/` の 9 件が
  fixture の日付固定（`2026-06-30`）で鮮度窓 55 日を超え、必ず失敗していた。修理は **PR #223**
- **停止解除の正規手順（機械作業。実行してよい）**:
  `uv run python -m scripts.dev.weekly_test_audit --enqueue-repair --expected-head <40桁> --source-claim-id <32桁>`
  → `uv run python -m scripts.dev.proof_pack_queue --run-one`。1 回およそ 70 分。
  **passed になって初めて停止が解ける**（failed を積んでも解けない）。集約は git common dir 配下

## 0. まず確認する 2 つ

### (1) 週次監査の全体停止が解けたか

```
uv run python -c "from pathlib import Path; from scripts.dev import weekly_audit_guard as g; a=sorted(g.read_aggregates(Path('.')), key=lambda x: str(x.get('created_at'))); print(a[-1])"
```

- `job_kind=full_audit` かつ `status=passed` の集約が最新なら**解除済み**。以下の PR を `finish-pr` でマージできる
- まだ failed が続いていれば**マージ不可**（2026-08-23 16:18 の full_audit 失敗に由来。08-24 11:18 時点で
  repair_audit は通算 8 回以上失敗。所有は別セッションの進行中タスク `20260823-test-gate-weekly-audit`）
- **自動では解けない**。`ProofPackFullAuditWeekly` 等は `manual_only` で Scheduler 未登録

### (2) `shared/**` を触る変更が publish できるようになったか（G-2）

`docs/backlog/20260824-harness-gate-gaps.md` の G-2 が未解消なら、`shared/` を含む PR は作れない
（Ready で 11 分の lane が同期 300 秒予算で timeout。audit 証跡は仕様上 publish 不可）。

## 1. 未マージ PR（自分のもの 4 本。すべて gate green・review 済み）

| PR | 内容 | 状態 |
|---|---|---|
| #216 | worktree 整理の最終記録（登録外 0 件） | merge 待ち |
| #218 | ゲート不具合 3 件 + 定期タスク修理計画の記録 | merge 待ち |
| #219 | **ODR-0019**（ゲートは完遂を妨げない。オーナー指示の記録・Codex 共有） | merge 待ち |
| #220 | 定期タスク 3 件の修理（+ 同種バグ 3 箇所） | merge 待ち |
| #223 | capital_cost_tracker のテスト日付固定を修理（**監査が通らない実質原因**） | merge 待ち・最優先 |

他セッションの #215（週次監査の修復）/ #217 も同じ停止で待機中。

### マージ再開コマンド（停止解除後、worktree の**外**から）

```
uv run python scripts/dev/sync_repo.py finish-pr --pr <番号> --worktree <path> --claim-id <id> --tested-base <base> --tested-head <head> --evidence-path <evidence>
```

**PR #205 以降 `--evidence-path` が必須**。evidence は
`data/runtime/evidence/local_pr_gate/v4/<head>/<run-id>/result.json`。

| PR | worktree（`D:\Dev\Investment-` 配下） | claim ID | tested-head |
|---|---|---|---|
| #216 | `claude-ledger-artifacts-final-20260824-263b499247` | `dca0545e962f0e94f2dd95ae2bdefb55` | `81e61552c0ce7e6b47decc1c16c00211c4cad16c` |
| #218 | `claude-harness-gaps-and-repair-plan-20260824-263b499247` | `93924a6332ced50b14baaef92b78f433` | `91670df4f62f30fc198c37e144f6dc9cdcffd174` |
| #219 | `claude-owner-intent-gate-completion-20260824-263b499247` | `f59c6ef23b1060655819f7c6bbb21040` | `b3d5792bc64fc94c339a615d5d48548fbfc915c3` |
| #223 | `claude-capital-cost-tracker-date-rot-20260825-263b499247` | `8bd9c9be06824b4054fb19656175f4ea` | `064b0215385f87b4c427f5538eb681b3ca977bc4` |
| #220 | `claude-scheduled-task-repairs-batch1-20260824-263b499247` | `3a30cfba99e495f9dd372c8c3bbb6bf1` | `5b830747ca9f404a2466e9ba032edf32ddb15c14` |

tested-base はいずれも `6d382817e5fb206aa5a8b02372f3b9bcf631dd80`。**1 本マージするたび main が動くので、残りは毎回 merge 取り込み → gate 再実行 → push → publish-pr をやり直す**（衝突は毎回 `docs/research/registry.yaml` の件数だけ）。
**base が進んでいたら rebase して gate をやり直す**（旧 evidence は流用しない）。全 worktree は clean・claim 保持。

**リポジトリ側の正本**: `docs/backlog/worktree-disposition-ledger-20260816.md` §0 に同じ再開情報を記載済み
（PR #216 = head `4ddd00f40`。ここが merge されれば main から読める）。

## 2. 実装完了だが PR にできていないもの

- branch `claude/book-knowledge-principles-ftd-20260824-263b499247`（head `d9e2f9dd0`、origin へ push 済み、
  worktree `D:\Dev\Investment-claude-book-knowledge-principles-ftd-20260824-263b499247`、claim `a541147179e199a33394f1ab92dd9007`）
- 内容: 投資原則集（30 原則・決定的日替わり・朝会ブロック・Knowledge Base セクション）+ O'Neil FTD 検出 +
  `config/**` の selector 分類追加（G-1 の修理）
- 検証済み: audit モードで 17 コマンド全 pass、広域 23,130 passed、実 DB で FTD 検出（日経225 / 2026-08-05）
- **G-2 解消後に ready gate → publish-pr**（`shared/principles.py` を含むため現状は publish 不能）

## 3. 次の作業候補

1. **定期タスク修理 第 2 便**: 審議会 crawler の委員会 URL 台帳（68 中 42 が省庁側 403/404）。
   全部追うか投資判断に効くものだけかは要オーナー確認
2. **第 3 便**: 精査待ち 5 件（`edinet-db-bulk` の partial 内訳 / `ingest-recover-flow` / `jpx-participant-open-interest` /
   `instrument-master-scheduler-sla` / `market-maintenance-score` の重複）。
   および #220 で残った「announcements 7 日 / financial_reports 39 日」の degraded 判定
3. **book-knowledge 残り**: book-search 系 + Alembic `20260711_04`、`economic_moat` + `_05`、Desktop、
   `market_regime` への FTD 配線。**PR-2 の shin_netnet はカタリスト例外のオーナー確認待ち**
4. **timeout ガードレールの有効化**（PR #200 で既定 0 出荷。棚卸し → override 付与 → .env 段階有効化）
5. ir-quant（6 PR 計画）/ integrated-residual（分割着地、意味変更 2 点はオーナー承認）

## 4. オーナー判断待ち

- `shin_netnet` の「6/6 通過でカタリスト不要」F.3 契約例外
- integrated-residual の F1 ランキング意味変更 / CAPEX watch-only 固定
- ir-quant の policy 自動承認 ADR
- Gate 3 完全版 / 縮小版（ODR-0001 D4）
- 審議会 URL 台帳の対象範囲

## 5. 保留（オーナー指示）

- `earnings-tdnet-intraday-refresh`（8/21 09:56 以降 70 回超連続失敗）はローカル LLM 再設計待ちで**着手しない**

## 6. 着地後に確認すること

- #220 マージ後、JPX400 初回成功時に **ADD 47 / REMOVE 42**（8 月年次入替）が通知される。想定どおりで異常ではない
- 翌日の `revision-predictor-health-daily` / `business-model-probe-weekly` / `jpx-tracker-check-daily` の runlog
- Scheduler 再登録は不要（action は `run_tool.ps1 -TaskId` 固定で引数は manifest 解決）

関連: [[project-worktree-disposition-completion-2026-08-22]]（今日の作業詳細と罠）、
[[project-ops-verify-law-tracker-fix-2026-08-21]]、[[jquants-standard-plan]]
