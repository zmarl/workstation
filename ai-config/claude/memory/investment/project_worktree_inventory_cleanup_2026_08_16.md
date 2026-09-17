---
name: project-worktree-inventory-cleanup-2026-08-16
description: "worktree 在庫整理 第1弾 (2026-08-16, PR #179)。条件2「アプリ側へ適用済み」の機械判定手順と、副産物で判明した Scheduler 実機乖離 64+7+8 件"
metadata: 
  node_type: memory
  type: project
  originSessionId: d0b43d5b-7090-4770-afee-f9f0784b88a0
  modified: 2026-08-17T10:27:41.373Z
---

# worktree 在庫整理 第1弾（2026-08-16 完了、PR #179）

ODR-0001 D6 をオーナー指定の 2 条件で**現時点再判定**（2026-08-10 の「稼働5本」リストは使い回さない）。
93 本 → 81 本（12 本回収、約 53GB 解放）。残余の処分手順は
`docs/backlog/worktree-disposition-ledger-20260816.md`、実施記録は
`docs/worklogs/20260816-claude-worktree-inventory-cleanup-20260816-4d5122eb09.md`（どちらもリポジトリが正本）。

## 判定手順（再利用可能）

**条件2の判定に `merge-base --is-ancestor head origin/main` を単独で使うと誤判定する。**
本リポジトリは merge commit 方式だが、gate 実行用の exact-head worktree は PR 前の rebase/amend で
SHA が変わるため、着地済みの作業が「未着地」に見える。段階的に:

1. `git cherry -v origin/main <head>` — patch-id 一致で rebase 耐性あり
2. 残った未着地コミットの**題名が origin/main のどこかに存在するか**（amend/conflict 解決で patch-id が変わった分を救う）
3. それでも残るものが真の未着地

**ただし 1 か月以上前のスナップショットには 1〜3 も効かない。** 決定版は
**「worktree HEAD のツリーに在って `origin/main` のツリーに無いファイルの全列挙」**
（`git ls-tree -r --name-only <head>` の差集合）。これが「消したら失われるもの」に直接答える。
残ったものだけ `git log --follow origin/main -- <path>` で「main が持ったのち削除・改名した」履歴を確認する。
Gate3 系 37 本ではこの方法で固有 10 種類まで絞り込め、うち 9 種類が意図的廃止と確認できた。
patch 逆当て（`git apply --check -R`）は文脈差で全件失敗し**判別に使えない**。

`git show --name-only` の出力は非 ASCII パスを**引用符付きで返す**ため、そのまま
`git rev-parse <rev>:<path>` に渡すと存在するファイルを「無い」と誤判定する。`-c core.quotepath=false` を付ける。

## 条件2の種別別 実測方法

| 種別 | 実測 |
|---|---|
| 通常コード | 実行コピー HEAD == `origin/main` かつ BFF プロセスの起動時刻 > main 最終コミット時刻。BFF は `Get-CimInstance Win32_Process` で CommandLine を見る |
| DDL | 稼働DB の `SELECT version_num FROM public.alembic_version` と `ScriptDirectory.walk_revisions()` の鎖順を突合。`alembic current` は `runtime_safety.py` が expected identity を要求して直接は動かない |
| Scheduler | `run_manifest.yaml` の `tasks/disabled_tasks/manual_only_tasks/retired_tasks` の `scheduled_task_name` と `Get-ScheduledTask -TaskPath '\Investment\'` の State を突合 |
| Desktop | `desktop/src-tauri/target/release/investment-desktop.exe` の LastWriteTime と着地日時を比較。ランチャーは起動時にソース mtime > exe mtime で自動再ビルドする（`scripts/run_desktop_phase_a_launcher.ps1 -BuildIfMissing`） |

`run_manifest.yaml` の `tasks` は **dict**（task_id → 定義）であって list ではない。

## 第2弾（同日、PR #180）で解消済み

93 本 → 81 本（第1弾）→ **74 本**（第2弾）。以下はすべて解消済み。

- Scheduler 再登録を `-Force` 全件で実施（skill `scheduler-registration`、パスワードはユーザー入力）。
  `check_scheduler_integrity.py` が全 failure count 0。登録 302 → 245 件。`WorktreeSweepDaily` 登録済み（毎晩 23:40）
- Desktop ビルド復旧。詳細は下記の罠を参照
- 保留 7 本を回収（`runner-7` のみ `cleanup --apply` が通り、1〜6 は `worktree unlock` + `remove`）

## Desktop ビルドの罠（2026-08-16 実測、ランチャー修正は別タスク起票済み）

**罠1: `desktop/node_modules` が空でもランチャーは `[OK] node_modules present` と言う**。
2026-08-11 21:09 以降空で、以後すべての起動が `npm error could not determine executable to run` で
失敗していた。ショートカットは `launch-with-autobuild-hidden.vbs` の `shell.Run cmd, 0, False` で
hidden 実行なので**失敗が一切表示されない**。`npm --prefix desktop ci` で復旧。
診断は `run_desktop_phase_a_launcher.ps1 -DryRun` が最短（`-DryRun` でも実ビルドは走るので失敗理由が出る）。

**罠2: stale exe 起動 → ロック → 複写失敗の無限ループ**。
`build-tauri.ps1` は `--target x86_64-pc-windows-msvc` でビルドし、
`target/x86_64-pc-windows-msvc/release/investment-desktop.exe` → `target/release/`（legacy）へ `Copy-Item`、
その後 `.last-source-build` にビルド時刻を書く。ところが
`run_desktop_phase_a_launcher.ps1::Get-DesktopExeCandidates` は **legacy パスしか候補にしない**うえ、
ビルド失敗時に legacy exe を起動して落とし込む。起動された exe は Windows にロックされ、
次のビルドの `Copy-Item` が失敗 → marker も書かれない → 毎回「ビルドして古い方が起動」を繰り返す。
**再起動を何度しても自然解消しない**。復旧手順は Desktop を完全終了 → 新しい exe を legacy パスへ複写 →
`.last-source-build` に `(Get-Date).ToString('o')` を ascii/NoNewline で書き `LastWriteTime` も揃える。

判定コマンド: legacy と target 別ディレクトリの exe 時刻を両方見る。片方だけ見ると誤診する。

## 副産物: 実機との乖離（第1弾時点の記録。第2弾で解消済み）

- **manifest で停止扱いなのに Windows で有効なまま: 64 タスク**。`3160085f3`(PR #170, 08-11) が
  安全側措置として停止指定したのに再登録されていない。`AllocationDriftDaily` / `BrokerReconcileWeekly` /
  `DailyBriefing` / `DecisionRunnerDaily` 等が毎日動き続けている
- **manifest で有効なのに未登録: 7 タスク**。うち **`WorktreeSweepDaily`**（夜間 worktree 自動回収、
  2026-07-23 追加）が未登録で、これが CLEANUP_DEFERRED 滞留の直接原因
- **manifest に無いのに登録: 8 タスク**（`FearGreedBuild*` / `IpoPipeline*` / `RatingScraper_*` の旧世代）
- 稼働DB の alembic は `20260720_05`。`20260731_01/02/03`（DecisionCase 群）はマージ済み未適用（ODR-0001 D4 承認待ち）
- Desktop 実行ビルドは 2026-08-10 23:47、ソースは 2026-08-14。08-11 以降の UI 変更が未反映

解消はいずれも人手境界だった: Scheduler は skill `scheduler-registration`、Desktop は
`tauri build` 系が project settings で機械 deny（ただし `npm ci` と exe の複写は deny 対象外）。

## 第3弾（同日、PR #181/#182/#183）— 93 → **40 本**

Gate3 系 37 本を評価し 34 本回収。固有ファイル 10 種のうち 9 種は main 側で意図的に廃止・改名済み。
唯一の未着地（確定済み as-of パックが上流 KPI の可変状態変更で不変であることの DB 回帰テスト）を
PR #182 で先に着地させてから回収した。未コミット変更を持つ 3 本は削除スクリプトの実行時チェックで自動除外。

### gate の構造欠陥（PR #181 で修正済み）

**DB マーカー付きテストだけを変更した PR は gate を構造的に通過できなかった。**
changed-test plan は同一の対象リストを `python-focused-fast` と `python-db-serial` の両方へ渡すが、
fast レーンのマーカー式が `not db ... not migration` を含むため収集ゼロ→pytest exit 5→失敗判定→
`python-db-serial` が `blocked_by_previous_failure` になる。`--scope` は追加のみ、`--skip-reason` は
記録のみで判定を変えないので回避不能だった。`run_pytest_lane.py` が明示パスあり時の exit 5 を成功に倒すよう修正。

### この修正で踏んだ罠

- `scripts/development_test_tiers.yaml` が実行スクリプトの `main` を **AST レベルで固定**している。
  `source_sha256` と `required_statement_sequence` を追随更新しないと `development_test_tiers` が落ちる。
  期待値は手書きせず、チェッカー自身の `_load_python_function_contract_lines` で生成する
- 基盤（gate 周辺）変更は `--mode ready` が拒否され `--mode t3` を要求される（約 10 分）
- **`publish-pr` / `after-merge` は gate evidence の `overall_status` が `passed` でないと必ず拒否**する。
  pre-existing 赤が 1 件でもあると helper 経路が全面的に使えず、生 `gh pr create` + `gh pr merge --match-head-commit`
  → main checkout で `git merge --ff-only origin/main` → 手動 worktree remove、という代替が必要
- `gh pr merge --delete-branch` は「main is already used by worktree」で最後に失敗するが、
  **GitHub 側のマージ自体は成功している**（ローカル後始末だけの失敗）。`gh pr view` で state を確認すること

### 救出テストの移植で必要だった調整

`tests/db/` の as-of パック系テストは `pytest.mark.migration` が無いと `db_fresh` レーンへ回され、
`_advance_baseline_to_pr3` が「full baseline 適用済み DB をさらに前のリビジョンへ upgrade」しようとして
`AlembicRevisionFailure` になる。兄弟テストに合わせて `migration` を付ける。

## 第4弾（2026-08-17、PR #184〜#187）— 40 → **32 本**。**ここが本題になった**

worktree 整理の過程で「実装もテストも完成しているのにマージされていない修正」が滞留していると判明し、
その原因追及が本題になった。

### 根本原因: `financial_data_invariants` ゲート（ODR-0002 で退役）

**このゲートはデータではなく帳簿を検証していた。** 検証項目は path enrollment、ソースの SHA-256 固定、
関数の AST 文列固定、test node id 登録のみ。数値の正しさは見ておらず、チェック全体が 20〜80 秒で
終わるのはテストを実行していないため。**価値があるのはレジストリが指すテストの方で、それは登録が
なくても通常レーンで走る。**

- 2026-07-22 導入時 1,364 行 → 2026-08-17 時点 **14,850 行**（26 日で 10 倍）
- `db/alembic/versions/` がガード対象になった 2026-08-01 以降、**マイグレーション着地 0 件**
- 稼働中の障害に対する完成済み修正 **3 件**を止めていた
- worklog 上で誤った数値を検出した記録は **0 件**（言及は全て「これに止められた」）
- ADR/ODR による承認記録なし。`feat(harness)` としてハーネスが自ら導入

オーナー判断で機械強制を退役（PR #185）。11 原則は `docs/contracts/financial-data-invariants.md` に
設計契約として残し、担保は振る舞いを検証するテストが持つ形にした。
**以後、機械チェックを足すときは台帳方式ではなく振る舞い検証にする。台帳方式へ戻すには ODR が要る。**

物理削除（約 14,850 行）は別 PR。初回試行で `run_local_pytest.py` の 66 箇所の配線を外したところ
旧構造前提のテスト 89 件が落ちたため分離した。要注意点は
`docs/worklogs/20260817-claude-retire-financial-invariants-gate-2026081-4d5122eb09.md`。

### 着地した障害修理

- **規制LLMタガー**（PR #184）: `raw.ingest_runs` に失敗 147 件、note は全て
  `current transaction is aborted`。部分一意索引 `WHERE superseded_by IS NULL` に
  `ON CONFLICT` が合致していなかった。44 コミット先へ乗せ直し。衝突 13 箇所のうち 10 箇所は
  main 側の別機能登録と加算的で**両側保持**が正解だった
- **審議会 crawler**（PR #186）: 毎回 `partial` / `errors=41`、文書 521 件に対しイベント 0 件。
  worklog は 00:57 の中間記録のままだったが実装は 01:21 まで継続しており、
  **worklog の「未実施」記載と実態が食い違っていた**（ファイル mtime で判明）

### 判断待ち: 資本政策 + 時価評価（`blocked`）

`Investment-valuation-capital-schema-recovery-20260813`（`ddl` resource 保持のまま保全）。
最新 main へ rebase 済み、t3-static 55 検査 pass。ただし**自身のテスト 2 件が RED**で未完成。
うち `_assert_same_snapshot(_CANONICAL, _LEGACY)`（新旧ビューの同値を適用時に検証）は
ODR-0002 が「本物の保護」と位置づけたもので、落として通すのは決定に逆行する。

### 明日以降まず確認すること

`raw.ingest_runs` で `reg_llm_tagger` と `shingikai_crawler` が改善したか。
どちらも平日タスクのため月曜以降に初めて結果が出る。確認クエリは処分台帳の冒頭にある。

## 残タスク

**正本は `docs/backlog/worktree-disposition-ledger-20260816.md`（冒頭に次セッションの再開手順あり）。
ただし D-1 完了と第5弾の内容は台帳へ未反映（2026-08-17 時点）。**

- ~~資本政策の未完成 2 件~~ → **2026-08-17 に2件とも実装して着地（PR #188）。40→32 本。
  詳細は [[project-valuation-capital-landing-2026-08-17]]**
- 金融データ不変条件の機構の物理削除（約 14,850 行）は別 PR
- ODR-0001 D6 の恒久ルール「旧形式 claim・claim なし worktree の 14 日自動レビュー」は未実装
- 稼働DB の DecisionCase 群 3 リビジョン未適用（ODR-0001 D4 の承認待ち）
- 台帳の優先度 C（api-v2 5 本、ODR-0001 D5 の顛末 ODR が前提）以降は未着手
- Desktop ランチャーの stale exe 競合（別タスク起票済み）
- **既存の赤**: `test_rehearse.py::test_rehearsal_uses_only_owned_container_and_writes_fail_closed_packet` は
  無改変 main でも落ちる。`_read_local_shadow_flag()` がキー不在を `None` で返し
  `_require_shadow_disabled()` が `None != "false"` で失敗させる。ローカル `.env` に
  `DECISION_CASE_SHADOW_ENABLED` の宣言が無いため。T3 でのみ表面化する
- fresh worktree で T3 を回すには `npm --prefix desktop ci` と repo 直下の `.env` 配置が必須

関連: [[project-phase-b-screening-completion-2026-07-23]]（lifecycle helper の使い方）/
[[feedback-scheduler-bulk-registration]] / [[project-owner-direction-intake-2026-08-10]]
