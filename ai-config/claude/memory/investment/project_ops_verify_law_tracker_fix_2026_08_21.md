---
name: project-ops-verify-law-tracker-fix-2026-08-21
description: "台帳§0実機確認セッション (08-21夜)。law_tracker重複キー修理着地(PR #199)、J-Quants契約失効発見、scheduler再登録神話の解消"
metadata: 
  node_type: memory
  type: project
  originSessionId: 258dd0af-3360-42ba-bd65-b3d9dafefcec
  modified: 2026-08-21T13:42:38.138Z
---

台帳 [[project-worktree-landing-batch7-2026-08-21]] の §0 再開手順を 2026-08-21 夜に実機確認したセッション。

## 確定した事実

- **scheduler 再登録は引数修正には不要**: 登録済みタスクの action は `run_tool.ps1 -TaskId <id>` だけで、
  引数は実行時に `run_manifest.yaml` から解決される。PR #194 のマージだけで日次 4 タスクは success 復帰した。
  再登録が要るのはスケジュール時刻・タスク名・有効/無効の変更時のみ。
- **J-Quants 契約が失効中**（発見時点で未解決の人手境界）: API 全エンドポイントが
  403 `"No active subscription found"`。jquants-update-daily / topix-tracker-daily /
  jpx-tracker-check-daily が 2026-07-30/31 から毎日失敗し、株価・銘柄マスターが欠落し続けている。
  ユーザーの契約更新後に日次回復確認 + 欠落期間バックフィルが必要。
- **law_tracker 重複キークラッシュは修理済み** (PR #199, merge 87983df09): `save_actions` の
  `ON CONFLICT (dedupe_hash) WHERE ...` が `idx_reg_actions_title_url` UNIQUE (title,url) を
  カバーせず、同一 title+URL の別日付再掲載で毎日クラッシュ（データ最新 2026-05-17、96 日停止）。
  対象指定なし `ON CONFLICT DO NOTHING` へ変更。翌 07:30 の law-tracker-fetch-daily success を要確認。
- **審議会 crawler の errors=42 は全件外部要因**（METI の UA 遮断 403 + 省庁ページ移転 404。
  68 委員会中 26 は正常）。委員会 URL 台帳の保守が別タスクとして残っている。
- 未調査の stale/missing ソース: disclosure_issuer_facts (07-19〜) / financial_unifier /
  xbrl_dimension_builder / segment_timeseries_aggregator / edinet_partners_text /
  disclosure_supply_chain / jpx_participant_open_interest。

## 作業の罠（再発防止）

**Why:** 同種の着地作業で同じ足止めを繰り返さないため。
**How to apply:**

- **file_size_budget は凍結ファイルへの行追加を 1 行でも拒否する**（`scripts/file_size_budget_baseline.txt`、
  例: law_tracker/repository.py は 2130 行凍結）。大きい既存ファイルへ docstring を足すだけでも
  gate が落ちる。コミット前に `uv run python -I scripts/check_file_size_budget.py --json` で確認する。
- **requires_db テストの実測は `scripts/ci/run_local_pytest.py --profile db-focused --test-path <dir>`**
  （identity-bound 使い捨て PostgreSQL + フル baseline、1 回約 1 分）。素の pytest では設計どおり skip される。
  修正前コードへ一時復帰して同コマンドで fail を見る「逆検証」がバグ検出力の証明になる。
- requires_db マーカー + `pg_connection` fixture はフル baseline（index・sequence 込み）を適用するので、
  `tests/fixtures/ddl/` への index 追補は不要。
- **ready gate は全段階 pass でも `base_unchanged=false`（base race）で overall failed になる**。
  evidence の `budget.within_budget` だけでなく `base_unchanged` も見る。
- worklog を 1 件足すたび `docs/research/registry.yaml` の `expected_managed_markdown_count` +1
  （並行 PR と衝突したら実測 `scripts/check_docs_research_registry.py` で解決）。
- worktree-isolated セッションでも `finish-pr` は `cd D:\Dev\Investment && uv run python
  scripts/dev/sync_repo.py finish-pr ...` で実行できる（cd+生 git はガードされるが helper は通る）。
- claim ID は `git worktree list --porcelain` の lock reason
  （`agent-session-v2:claude:<task>:<claim_id>:{...}`）から取れる。
- law-tracker-fetch-daily の `--daily-pack` は実通知送信を含む → 手動再実行は人手境界に触れる。
  修理後の動作確認は翌日の定期実行で行う。
