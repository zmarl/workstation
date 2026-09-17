# 文書の置き場を docs/ へ集約し、現状レビューの家を作る

## Context

リポジトリの文書は、2026-02-08 に `docs/` へ種類別で集約されたのが出発点でした。しかしその後、種類別フォルダは文書設計の判断ではなく機能開発のコミットの中で 9 → 19 個へ増え、2026-08-30 に分類の軸を「フォルダ」から「役割（管理プロファイル）」へ移した際もフォルダの統廃合は行われませんでした。結果として、入口である `docs/README.md` から辿れないフォルダが 6 つ（audits / contracts / examples / handoff / operations / reference）残り、役割の重なったフォルダが並んでいます。

さらに重いのは、現状レビューがリポジトリの外へ出てしまったことです。`docs/audits/` という受け皿は存在し分類も付いているのに、README も命名規則も索引への導線もないため 2026-07-15 を最後に新規ゼロで、以降の現状調査・現状評価・総点検（2026-08-10 以降の 12 本以上）はすべて `D:\Dev\Investment_設計資料`（50 ファイル、バージョン管理なし）、`data/runtime/plans`、Claude の記憶、セッション作業フォルダにあります。**30 日凍結を決めた ODR-0038 は、根拠として版管理外の `Investment_設計資料/統合現状評価と改善計画_2026-09-07.md` を名指ししています。** 2026-08-28 の総点検は本文がどこにも残っておらず、過去に台帳へ登録した計画ファイル 13 件は現在 1 件も実在しません。

管理の仕組み自体も止まっています。監査は「未分類 0 件」と出ますが、これは置き場のパターンに当てはめただけで、現行か過去かを示す情報は主要 7 フォルダ 82 件中 27 件しかなく、登録漏れは 8 → 13 → 15 件と増加、週次監査は 3 回連続で失敗（原因は文書検査ではなく別の検査）、月次点検は仕組みごと存在せず、作業ログの履歴化は 8/30 で停止し期限超過 149 件です。

調査で判明した重要な前提: **「外部の調査本文はリポジトリに複製しない」は全体規則ではなく、2026-08-10 の取込 1 件に付いた条件でした。** したがって現状レビューを repo に入れるのに方針変更（ODR 起票）は不要で、決まりが無いところを埋めるだけで済みます。

## オーナー判断（2026-09-16）

1. **1 か所 = `docs/`**。入口は `docs/README.md` 1 枚のまま。投資フレームワークは投資方法論専用の別棚として残し、その中の開発・運用文書は docs へ寄せる。
2. **現状レビューの本文は `docs/audits/` に Markdown で置く**。
3. **読み物 HTML は正本にしない**。正本は Markdown 1 本、読むときは Desktop の Markdown 画面（`desktop/src/pages/markdown/`、ファイルツリー付き）で開く。維持する実体を 1 つに減らす。
4. **フォルダ統廃合まで実施**。ただし運用手順フォルダ（`docs/runbooks`）への吸収だけは凍結条項（ODR-0038 D1）に当たるため **2026-10-07 以降**へ分ける。

## 完了条件

- リポジトリ内の文書は `docs/` 配下か、その場に置くのが正当なもの（各 tool の README、AGENTS.md、skill、テスト fixture、投資フレームワーク）だけになる。
- `docs/README.md` から全フォルダへ辿れる。役割の重なるフォルダが解消されている（運用手順への吸収を除く）。
- `docs/audits/` が現状レビューの正式な家として成立し、既存の外部レビューが判定済み（取り込み／台帳登録／履歴凍結／重複）になっている。
- 文書関連の検査が緑（`docs_research_registry` は blocking、他は advisory だが手動で緑を確認）。
- 移動によって壊れた固定参照がゼロ。

## 作業単位

`pr-ready-gate` skill で外部 worktree を claim し、`worklog-starter` で worklog を起こす。DDL なし。main checkout は読み取り専用のまま。

---

## Wave 0 — 棚卸しと受け皿づくり（ファイル移動なし）

1. **登録漏れ 15 件を登録**: `scripts/contract_scope.yaml` の `documents:` に、ODR-0034〜0043 の 10 件（`docs/decisions/20260904-…` 〜 `20260914-earnings-label-lane-retirement.md`）、design 4 件（`loss-to-profit-valuation-design.md` / `qwen38-earnings-deep-analysis-owner-requirements.md` / `qwen38-initial-earnings-analysis-owner-decisions.md` / `statistics-data-acquisition-plan.md`）、runbook 1 件（`local-llm-rtx-pro-5000-operations.md`）を既存行と同じ `path / role / category` の 3 行形式で追加する。
2. **`docs/audits/README.md` を新設**（現状レビューの家）。既存 6 本が実際に使っている書式をそのまま規則にする: 冒頭に目的・調査方法・調査時点・注意、ファイル名は `YYYYMMDD-<slug>.md`。新しい metadata 項目は作らない（既存の `audit_record` プロファイルのまま。機械要求の追加は ODR-0018 決定 5 に当たるので行わない）。
3. **`docs/README.md` を改訂**: audits / contracts / examples / handoff / operations / reference の 6 フォルダと `known_issues.md` / `investment-knowledge-base.html` を役割表に追加。手書きの Design 17 件・Architecture 4 件の一覧（実体と不一致）は各フォルダへのリンクに縮約する。§7 のガバナンスサイクルに、実際には仕組みが存在しない月次項目の扱いを明記する。
4. **参照切れの修正**: `docs/known_issues.md:43`、`docs/guides/README.md:24`、`docs/roadmap/pro-discretionary-features.md` ほか、存在しないファイルを指す記述 10 件。
5. **`docs/OWNER_INTENT.md` §7** に ODR-0040・0041 の行を追加。

## Wave 1 — 外部レビューの回収

`D:\Dev\Investment_設計資料`（50 件）、`data/runtime/plans` 直下（7 件）、記憶にしか要約が残らない 3 本、scratchpad の技術的負債レポートと 9/15 HTML を、1 件ずつ次の 4 つに判定する。判定表は `docs/audits/20260916-external-review-recovery.md` に残す（本文欠落のものは「本文欠落」と明記する）。

- **取り込む**（自作の現状レビュー・評価・総点検、12 本前後）→ `docs/audits/YYYYMMDD-<slug>.md`。9/15 の総点検 HTML（442KB、今朝の第 2 版）は機械変換で Markdown 化し、図は表と Mermaid へ置き換える。元 HTML と初版は外部に残し台帳へ記録する。
- **台帳登録のみ**（ChatGPT 助言 9 本、2026-05 設計レビュー、取込パック 5 系統）→ `docs/research/registry.yaml` に `external://investment-design-docs/<相対パス>` 形式で登録。この台帳は blocking 検査に絶対パス禁止があるため、`D:\…` を書かない。
- **履歴として凍結**（採否が既に ODR へ反映済みのもの）。
- **重複**（`09_入力ツール全体像.md` など repo にコピーがあるもの）→ 削除候補として一覧化のみ。削除はオーナー承認（ODR-0026 D11）。

あわせて `RES-CLAUDE-PLAN-PRESENT`（現存 13 件と記載、実在 0 件）を訂正する。

## Wave 2 — docs 内の統廃合と履歴化

- `docs/contracts/`（2 件）→ `docs/design/`
- `docs/reference/`（2 件）+ `docs/examples/`（1 件）→ `docs/research/`（管理プロファイルは既に同一）
- `docs/architecture/` の Superseded（`evolution-roadmap.md` / `deployment-topology.md` ほか）と docs 直下の廃止 2 件（`MASTER_PLAN.md` / `データ基盤構築計画.md`）→ `docs/archive/` のミラー構造。旧パスには互換エイリアスを残す。
- `docs/archive/README.md` が説明する実在しない `legacy_root/` の記述を実体に合わせる。
- 作業ログの履歴化を再開: `uv run python scripts/archive_worklogs.py --execute` → `--rewrite-links --execute`（対象は `Status: Done` の 38 件のみ。`Verifying` 109 件は現行の PR フロー上そもそも履歴化されない構造的な問題なので、今回は触らず報告に残す）。

**移動のたびに毎回行う確認**（`--rewrite-links` は `.md` しか直さないため）:

1. `git -c core.quotepath=off grep -n "<旧パス>"` を **非 Markdown を含めて** 全件（`docs/<サブフォルダ>/` を参照する tracked 非 md は約 103 ファイル）
2. `desktop/src/lib/page-docs-registry.ts`（docs パス 68 件）の実在確認
3. `scripts/register_schedules.ps1` / `scripts/run_manifest.yaml` / `scripts/manifest/misc.yaml` / `tools/api/decision_api/`（`ops.py`・`report_sources.py`・`_markdown_repository.py`）の docs パス
4. `scripts/contract_scope.yaml` と `docs/research/registry.yaml` を**同時更新**（後者は blocking）

## Wave 3 — 投資フレームワーク内の開発・運用文書（最後・条件付き）

`投資フレームワーク/` 331 件のうち、投資方法論ではなく開発・運用の文書（`00_INDEX/Docs_*ハンドブック`、`運用Runbook.md`、`00_INDEX/監査ログ/`、`06_インプット設計/06_自動化設計/`、`06_インプット設計/05_ツール運用/`、`08_運用台帳/02〜05` など約 30 件）を個別判定し、docs 側へ寄せる。

- ODR-0040 は「既存 ID とフォルダの**一括**移動」を禁じているため、番号付き ID を持つ文書へ対象が及ぶ場合は**その時点で停止して報告**する。
- `06_インプット設計/06_自動化設計/README.md` の「S6_REVIEW_READY を含む最終判定まで機械実行」という記述は `docs/design/裁量投資判断OS_全体設計.md` の「最終判断はユーザー」と正面から矛盾する。移動の可否にかかわらず Historical 表示か導線外しを行う。
- 移動後に `check_framework_structure.py` の orphan 件数が悪化しないこと、`check_md_links.py --scope 投資フレームワーク` が緑であることを確認する。

---

## 2026-10-07 以降へ回すもの

- `docs/operations/`（2 件、実体は運用手順）→ `docs/runbooks/` への吸収。ODR-0038 D1 の凍結パスに `docs/runbooks` が含まれ、許可されるのは「赤→緑の 1 日修正」と「機構の削除・降格・通知化」だけのため。今回は `docs/README.md` への掲載と役割の明記だけ行う。
- 読み物 HTML の生成スクリプト（必要になった場合）。新しい仕組みの追加は凍結中は不可。
- 未分類の網の穴（テキスト形式など 60 件が `contract_scope.yaml` の `inventory.extensions` に入っておらず最初から数えられていない）。検査の対象範囲を広げる変更にあたるため、ODR-0018 決定 5 の承認台帳への追記が要る。

## 今回やらないこと / オーナー作業

- **未マージ作業の着地**（open PR 4 本: #438 / #411 / #410 / #230、未マージ 65 ブランチ、main に無い文書 163〜387 件）。今回は判定表を作るだけにし、取り込み・破棄は別途承認とする。`codex/earnings-documentation-integration` は PR が無いまま +69,324 行あり、単独で 1 セッション相当。
- **削除**（ODR-0026 D11 によりオーナー承認が要る）: `data/runtime/…/residual-20260830`（5.5GB・70,177 ファイル）、`D:\Dev\_to_delete_20260904`（437,641 ファイル）、空の `D:\Dev\ChatGPT` と `Cowork`、重複コピー。
- **`.tmp/env-backup-20260904/.env`（11,949B）が読める状態**である点の対処。秘密情報の deny は `./.env` と `secrets/**` しか塞いでおらず、このバックアップは対象外。削除はオーナー作業、deny パターンの追加は `.claude/` が凍結パスのため今回は行わず報告のみ。

## 検証

```bash
uv run python scripts/check_docs_research_registry.py --json
```

```bash
uv run python scripts/check_docs_metadata.py --audit-all --json
```

```bash
uv run python scripts/check_md_links.py --scope docs --json
```

- `check_docs_metadata.py` の `scope_gap_count` が **15 → 0**。
- `check_docs_research_registry.py` が緑（blocking。`expected_excluded_markdown_count` のドリフトが出ないこと）。
- `check_md_links.py --scope docs` / `--scope 投資フレームワーク` が緑（advisory なので自動では止まらない。手動で必ず実行する）。
- `check_docs_contract_keywords.py` / `check_backup_restore_readiness_contract.py`（blocking、固定 5 パス）/ `check_framework_structure.py` / `check_framework_html_drift.py` が緑。
- 旧パスの残存を `git -c core.quotepath=off grep` で非 Markdown 込みで確認しゼロ。
- Desktop で `docs/audits/` の新規レビューが Markdown 画面から開けることを実画面で確認する（読み物 HTML を置き換える判断の前提のため、ここは実際に開いて確かめる）。
- 最後に clean exact head で Ready gate を 1 回（docs 差分中心のため `--scope` は差分が要求する分だけ）。

## コストカード（ODR-0038 D9）

- 触るファイル数: Wave 0 で約 20、Wave 1 で約 15、Wave 2 で約 80〜120（大半は移動）、Wave 3 で約 30。
- 追加するテスト数: 0（既存の検査で検証する）。
- 新しい機構の有無: **なし**（既存の `contract_scope.yaml` / `registry.yaml` / 既存 checker / 既存 Desktop 画面だけを使う）。
- worklog 日数: 1 日（Wave 3 まで到達しない場合は途中状態として報告する）。
