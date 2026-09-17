---
name: project-docs-consolidation-2026-09-16
description: 2026-09-16 の文書集約（docs/ 一本化・docs/audits 新設・外部レビュー16本回収）の結果と、残した宿題
metadata: 
  node_type: memory
  type: project
  originSessionId: fe6b2ba9-42cd-4471-968a-5bedb3e50d16
  modified: 2026-09-16T01:48:17.357Z
---

2026-09-16、散在した文書を `docs/` へ集約し、現状レビューの置き場を成立させた（**PR #453 マージ済み、merge commit `41aa2ae52`**、worklog `docs/worklogs/20260916-claude-docs-consolidation-508fb6c48d.md`）。

**着手前の状態（調査で判明）**

- 現状レビューは 2026-07-15 を最後に repo から消え、`D:\Dev\Investment_設計資料`（git 管理外・50 ファイル）、`data/runtime/plans`、セッション作業フォルダ、エージェントの記憶へ分散。ODR-0038 は版管理外のファイルを根拠として名指ししていた。2026-08-28 の総点検など 3 本は本文がどこにも残っていない。
- 「未分類 0 件」は見かけ。`contract_scope.yaml` の `inventory.extensions` は `.md/.html/.pdf/.docx` だけで、`.txt` など 60 件は最初から数えられていない。
- **「外部調査の本文はリポジトリに複製しない」は全体規則ではない。** `registry.yaml` の 1 エントリの `scope` 行と ODR-0006（外部の機能目的台帳 1 件限定）だけ。回収に ODR は不要だった。
- 週次監査は 3 回連続失敗しているが、原因は `framework_structure` / `task_status_parity` 等で `docs_metadata` ではない。scope_gap は何件あっても exit 0 で、失敗としてすら表に出ない。

**やったこと**: 登録漏れ 15 件登録（scope_gap 15→0）／`docs/audits/README.md` 新設／索引へ 6 フォルダ・2 ファイル追加／外部レビュー 16 本回収（回収メモに原本パスと sha256）／2026-09-15 総点検 HTML 442KB を Markdown 化（見出し 168/168・数値 422/422・図 16 を mermaid 11 + 表 5 へ）／`docs/contracts`→`docs/design`、`docs/examples`→ツール配下／worklog 履歴化 38 件を再開／BFF に `audits` カテゴリ追加。

**残した宿題**

- `docs/operations/` → `docs/runbooks/` の吸収は ODR-0038 D1 の凍結パスのため 2026-10-07 以降。
- `.txt` 等 60 件の分類漏れは `inventory.extensions` の拡張＝検査範囲の変更で、ODR-0018 決定 5 の承認台帳が要る。
- `docs/reference/` は移動しない判断。BFF `report_sources.py`・`tests/docs/test_sector_kpi_reference.py`・`shared/catalogs/sector_kpi_requirements.yaml`・`backlog_scanner` が本文/パスを読むうえ、`contract_scope` 上は既に `docs/research` と同じ profile なので移動しても分類上の利得がゼロ。
- 投資フレームワークの開発・運用文書 約40件は ODR-0040（既存 ID・フォルダの一括移動禁止）に当たるため移動せず、索引に理由を明記。
- 削除候補（`data/runtime/…/residual-20260830` 5.5GB、`D:\Dev\_to_delete_20260904`、外部の重複 `09_入力ツール全体像.md`）と `.tmp/env-backup-20260904/.env`（deny 対象外で読める）はオーナー作業。

**罠**

- `archive_worklogs.py --rewrite-links` は `.md` しか直さず、dirty なファイルは SKIP する。実行後に必ずリンク検査をやり直す。worklog を履歴化すると `RES-WORKLOG-ARCHIVE.content_hash` がずれて blocking 検査が落ちるので、`check_docs_research_registry.py --json` の `computed_content_hashes` から新値を取って更新する。
- 参照切れの機械検出は、凍結記録（worklog/archive/handoff/status）と単なるファイル名を除外しないと 645 件の偽陽性になる。現行正本かつ `/` を含むパスに絞ると 171 件、移動先が一意に定まるのは 42 件。
- `check_docs_metadata.py` の `ROLE_STATUS_VOCAB` に Audit role は無い。audits に front matter を付けるとかえって現在性を主張してしまう。
- `docs/research/registry.yaml` は **Windows 絶対パス禁止**（blocking）。外部資料は `external://investment-design-docs/<相対パス>` 形式で書く。
- Ready gate の `git-diff-check` は **EOF の余分な空行 1 行でも exit 2** になる。YAML へ追記するときは `printf '\n' >>` で末尾を足さない。publish 前に `git diff --check origin/main..HEAD` を自分で回すと 1 往復減る。
- 新しい path（例: `scripts/*_baseline.txt`）を足すと Ready gate が `classification_required` で止まる。分類先は `scripts/development_test_selection.yaml`（top-level `scripts/` なので凍結対象外）。同種の対（checker + baseline）が既にある group に並べる。
- docs 中心の PR でも required packs は `harness-docs / runner-core / python / db-fresh / bff-contract` になり、`db-fresh` は非同期キュー行き。
- **`pending_async` のあと gate を再実行しても合格にならず、毎回新しい job を積むだけ**。合格証拠は**ワーカー自身が別 run として書く**（`queue_attestation` 付き、`overall_status=passed`）。`harness_status.py --job-id` も待機せず現在値を返すだけなので、`data/runtime/evidence/local_pr_gate/v4/<head>/*/result.json` を全部見て `queue_attestation` が非 null かつ `passed` の run を探すのが正しい。それを `publish-pr --evidence-path` に渡す。
- `finish-pr` の worktree 削除は uv の `.venv` ハードリンクで `proof runner tree contains a hardlinked entry` になる。マージと main 同期は完了しており `CLEANUP_DEFERRED` として残る。`rm -rf` は機械 deny なので迂回せず、夜間の `worktree-sweep-daily`(23:40) に任せる。

関連: [[feedback-review-placement-markdown-canonical]]
