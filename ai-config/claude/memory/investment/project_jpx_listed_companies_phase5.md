---
name: jpx-listed-companies-phase5
description: JPX 銘柄マスター同期 Phase 5 follow-up クロージング。Track A (新 InstrumentMasterTab を OpsHub に有効化、旧 JpxDriftTab/Panel を削除) + Track B (JpxProtectedCodesPanel.test.tsx 新規 4 ケース) + Track D (jpx_protected_codes_review_reminder weekly notification + manifest 配線) を 3 並列マルチエージェントで一括着地 (2026-05-14)
metadata:
  node_type: memory
  type: project
  originSessionId: 9c7d6788-2cc7-4292-8d2b-af15aa354759
---

JPX 銘柄マスター同期 Phase 5 完了 (2026-05-14)。Phase 4 で 6 件繰越していた follow-up のうち、実装価値のある 3 件 (Track A/B/D) を 3 並列マルチエージェントで一括クロージング。残 3 件は調査の結果でスキップ確定 (F1 admin 手動 / F4 ラッパー 1 行委譲で価値ゼロ / F6 衝突マーカー不在で Phase 4 メモリ誤認)。pytest 45/45 / vitest 22/22 / ruff clean / manifest_safe_semantics PASS (checked=302, violating=0)。

**Why:** Phase 4 メモリ末尾の follow-up 6 件のうち F2 が最も影響大 — 新 `InstrumentMasterTab` (Phase 4 で実装した 3 サブタブ: ドリフト / 実行履歴 / 保護コード) が OpsHubPage.tsx の TABS array にも TAB_COMPONENTS map にも未配線で完全死蔵。ユーザーには旧 `JpxDriftTab` (summary のみ) しか見えず、Phase 4 の sync 履歴 / 保護コード UI が実用に出ていなかった。F3 (保護コードテスト穴) と F5 (2026-06-15 再評価リマインダ) も併せて閉じる Phase 5 として一括着地。

**How to apply:**
- OpsHub の "銘柄マスター" タブ (num=5) は `InstrumentMasterTab` (`desktop/src/pages/ops-hub/tabs/InstrumentMasterTab.tsx`) が正本。旧 `JpxDriftTab` / `JpxDriftPanel` は完全削除済みで参照禁止。`JpxDriftReportPanel` は新タブの「ドリフト」サブタブで再利用されているので維持
- OpsHubTabId union (`desktop/src/pages/ops-hub/data/types.ts`) は `"jpx-drift"` → `"instrument-master"` に変更済み。`useOpsHubStore.activeTab` は persist 永続化なし + 初期値 "overview" なので既存ユーザー影響なし
- `JpxProtectedCodesPanel` テストは「動的日付 helper `isoDaysFromNow(days)`」パターンで時間非依存に。`isWithinReviewWindow()` ±30 日判定が `Date.now()` ベースなので、ハードコード日付では時間経過でテストが崩れる
- 警告スタイルは role/icon ではなく Tailwind utility (`bg-yellow-400/20` + `⚠` glyph)。className 文字列マッチ + span 数で「正しく 1 件だけ警告」を確認
- `jpx-protected-codes-review-reminder-weekly` は毎週月曜 08:00 起動 (source_type=notification / weekly / auto_retry=1)。`config/jpx_protected_codes.yaml` の next_review_at が `today + 7days` 以内 or 過期で Discord ops チャネル配信。該当なしなら `status=success` で no-op、yaml 不在なら `status=partial` (failed ではない、shared.raw_ingest_tracking.record_raw_ingest_error パターン)
- 2026-05-14 時点で 10 件全て `next_review_at: 2026-06-15` (32 日先) なので、初回該当は 2026-06-08 月曜の weekly fire (7 日前 due_soon マーキング)

**Files of record:**
- Track A 編集: `desktop/src/pages/ops-hub/OpsHubPage.tsx` (TABS / TAB_COMPONENTS / TAB_CATEGORY map + import 差し替え)、`desktop/src/pages/ops-hub/data/types.ts` (OpsHubTabId union)
- Track A 削除: `desktop/src/pages/ops-hub/tabs/JpxDriftTab.tsx` / `desktop/src/components/ops/JpxDriftPanel.tsx` / `JpxDriftPanel.test.tsx`
- Track B 新規: `desktop/src/components/panels/JpxProtectedCodesPanel.test.tsx` (4 ケース: 正常 / 警告 / 空 / API エラー)
- Track D 新規: `tools/notifications/jpx_protected_codes_review_reminder/{__init__.py, main.py, README.md}` + `tests/tools/notifications/jpx_protected_codes_review_reminder/{__init__.py, test_main.py}` (6 ケース) + `scripts/run_jpx_protected_codes_review_reminder_weekly.bat`
- Track D 編集: `scripts/run_manifest.yaml` (jpx-protected-codes-review-reminder-weekly エントリ追加)、`scripts/register_schedules.ps1` (Update-InvestmentTask 1 行追加、Monday 08:00)
- Plan: `C:/Users/kazum/.claude/plans/cryptic-floating-pike.md`

**Smoke verification (2026-05-14):**
- `uv run ruff check tools/notifications/jpx_protected_codes_review_reminder/ tests/tools/notifications/jpx_protected_codes_review_reminder/` → All checks passed
- `uv run pytest tests/tools/notifications/jpx_protected_codes_review_reminder/ tests/tools/market_data/jpx_listed_companies/` → 45 passed (Track D 6 + JPX 既存 39)
- `uv run python scripts/check_manifest_safe_semantics.py` → PASS (checked=302, violating=0)
- `cd desktop && pnpm vitest run src/pages/ops-hub/ src/components/panels/Jpx*` → 22 tests / 7 files all pass
- `uv run python -m tools.notifications.jpx_protected_codes_review_reminder.main --dry-run` → 10 entries loaded; overdue=0 due_soon=0 (window=7d) で想定通り no-op skip

**Multi-agent execution:**
- 3 並列実装エージェント着地: Track A (`a89510caa8fe8a4c6`, 24 tools, 143s) / Track B (`a7041dd7d7636f1a0`, 11 tools, 132s) / Track D (`ab0fd164590482bb3`, 58 tools, 312s)
- 事前 Phase 1 で 3 Explore agent 並列 (重複整理状況 / drift_check + tool_tiers / scheduler + 保護コード現状) で F4/F6 スキップを根拠ベースで確定
- Orchestrator は最終検証 (ruff/pytest/manifest_safe_semantics/vitest) + MEMORY 更新

**Out of scope (明示的スキップ):**
- F1 admin Task Scheduler 実登録: ユーザー手動領域 (runbook §4 `register_schedules.ps1` 1 コマンド)
- F4 `jpx_listed_companies_drift_check` pytest: ラッパーは 1 行委譲、実体は `tests/scripts/test_check_jpx_listed_companies_drift.py` でカバー済み、テスト価値ゼロ
- F6 `tool_tiers.yaml` line 272 衝突: 探索で衝突マーカー不在、Phase 4 メモリ記述が誤認

**Follow-ups (繰越):**
1. F1 admin PowerShell 実登録 (引き続きユーザー手動領域、Phase 4 worklog runbook 既存)
2. 2026-06-08 月曜の weekly fire で `due_soon=10` Discord 配信を観測 → 運用上問題ないかチェック (初回稼働確認)
3. 2026-06-15 保護コード 10 銘柄再評価: weekly リマインダが起爆 → 運用者が `scripts/investigate_jpx_missing_codes.py` 再走 → yaml 更新

**関連:**
- @./project_jpx_listed_companies_phase4.md
- @./project_jpx_listed_companies_phase3_followup.md
- @./project_jpx_listed_companies_phase3.md
- @./project_jpx_listed_companies_phase2.md
- @./bugs_core_instruments_market_reform_stale.md
- @./desktop_test_patterns.md
