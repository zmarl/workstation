---
name: jpx-listed-companies-phase4
description: JPX 銘柄マスター同期 Phase 4 着地。scheduler 月次配線 + 10 銘柄真因 P1 確定 (JPX 配信側欠落) + 保護コード機構の本実装 + BFF sync 履歴 endpoint + Desktop OpsHub 3 サブタブ化 (2026-05-14、3 並列マルチエージェント着地)
metadata: 
  node_type: memory
  type: project
  originSessionId: 8522062d-000e-46dc-9c51-6cc03bbe2e82
---

JPX 銘柄マスター同期 Phase 4 完了 (2026-05-14)。Phase 3 follow-up で残った 3 領域 (scheduler 未配線・10 銘柄真因未確定・Desktop sync 履歴観測なし) を Track A/B/C の 3 並列マルチエージェントで閉ループ化。pytest 39/39 / vitest 7/7 / ruff clean / manifest_safe_semantics PASS (301 checked, 0 violating)。

**Why:** Phase 3 follow-up (`project_jpx_listed_companies_phase3_followup`) で観測ライン + 自動修復ライン + 可視化レーンは揃ったが、月次自走には scheduler 配線が必要、10 銘柄取り込み漏れは真因未確定で保護コード回避にとどまり、sync 実行履歴は Desktop から見えないままだった。Phase 4 はこの 3 ギャップを並列で閉じて運用可能状態に仕上げるフェーズ。

**How to apply:**
- 月次 scheduler は `jpx-listed-companies-sync-monthly` (07:50) + `jpx-listed-companies-drift-check-monthly` (09:45) の 2 タスク構成。BFF 側の `JPX_SYNC_SOURCE_IDS` で旧 ID (`jpx-true-monthly` / `jpx-listed-companies-monthly`) も互換対象なので raw.ingest_runs の過去履歴も読める
- 10 銘柄 (202A, 3541, 3902, 4690, 5259, 7092, 7105, 7250, 7739, 8209) は JPX 配信側 data_j.xls 段階で欠落 (parser drops=0、xls rows=4449)。downloader/parser は健全。隣接 code は xls に存在する isolated gap。保護コード機構が恒久対策として確定
- 2026-06-15 再評価は `scripts/investigate_jpx_missing_codes.py` 再走 → `in_raw_xls=true` になっていれば yaml から削除、引き続き false なら next_review_at 延長、3 ヶ月継続なら JPX へ直接ステータス照会 (監理銘柄等)
- Phase 3 follow-up worklog では「保護コード機構を sync.py に永続実装」と記述されていたが**実コードは sentinel と path 定数のみで未着地**。Phase 4 Track B でまとめて本実装 (yaml ロード / `_build_plan` 配線 / SyncSummary 拡張 / regression test 3 件)
- Desktop OpsHub の `InstrumentMasterTab` は 3 サブタブ化 (drift / 実行履歴 / 保護コード)。旧 `JpxDriftTab` (`components/ops/JpxDriftPanel`) は別ルートで残存しており、OpsHub ナビゲーション統合は別 PR で実施予定
- `register_schedules.ps1` のマージ衝突 13 箇所は auto-resolution によって incoming (reform PR `f441cedad6`) 側が既に採用済みだった。HEAD 側で個別保持したかったタスク (`EarningsAnalyzer` / `RegimeScorecardDaily` / `NewsDigest*` / `DecisionReadinessMonitor` 等) は incoming で pack 集約されている。pack 集約と意味的に整合するため auto-resolution を尊重

**Files of record:**
- 真因調査: `scripts/investigate_jpx_missing_codes.py` (新規)、`tmp/jpx_data_j_<YYYYMMDD>.xls` (gitignore)、`tmp/jpx_missing_codes_investigation_<YYYYMMDD>.json`
- 保護コード本実装: `tools/market_data/jpx_listed_companies/sync.py` (yaml ロード + `_build_plan` 配線 + SyncSummary 拡張)、`tests/tools/market_data/jpx_listed_companies/test_sync.py` (保護 3 件追加)
- parser regression: `tests/tools/market_data/jpx_listed_companies/test_parser.py` (10 銘柄 parametrize + `_zero_pad_code` alphanumeric 保持)
- Manifest: `scripts/run_manifest.yaml` (`jpx-listed-companies-sync-monthly` リネーム + `jpx-listed-companies-drift-check-monthly` 新規)、`scripts/tool_tiers.yaml` 同期
- Scheduler: `scripts/register_schedules.ps1` (Update-InvestmentTask 2 行 + `-DaysOfMonth` パラメータ拡張 + `Remove-DeprecatedTaskIfSelected JpxTrueMonthly`)
- BFF: `tools/api/decision_api/ops_hub_repository.py` (`get_jpx_sync_history` + `get_jpx_protected_codes`)、`routers/ops.py` (`/api/v1/ops/jpx/sync-history` + `/api/v1/ops/jpx/protected-codes` + inline Pydantic schemas)
- Desktop: `desktop/src/components/panels/JpxSyncHistoryPanel.tsx` + `JpxProtectedCodesPanel.tsx` (新規)、`InstrumentMasterTab.tsx` (3 サブタブ化)、`misc.ts` + `api-client.ts` 拡張
- Tests: `tests/tools/api/decision_api/test_jpx_sync_history.py` (新規 9 ケース)、`desktop/src/components/panels/JpxSyncHistoryPanel.test.tsx` (新規 3 ケース)
- Runbook: `docs/runbooks/jpx-listed-companies-scheduler-registration.md` (Phase 4 完了 + 2026-06-15 再評価ガイド追記)
- Worklog: `docs/worklogs/20260514-jpx-listed-companies-phase4-missing-codes-rootcause.md` (Lite)

**Smoke verification (2026-05-14):**
- `uv run python scripts/check_manifest_safe_semantics.py` → PASS (checked=301, violating=0)
- `uv run pytest tests/tools/market_data/jpx_listed_companies/` → 39/39 pass (元 30 + parser regression 2 + sync 保護 3 + その他 4)
- `uv run ruff check tools/market_data/jpx_listed_companies/ tools/api/decision_api/{ops_hub_repository,routers/ops}.py scripts/investigate_jpx_missing_codes.py` → All checks passed
- `pnpm vitest run JpxSyncHistoryPanel.test.tsx JpxDriftReportPanel.test.tsx` → 7/7 pass
- 調査スクリプト実走 verdict = `P1_jpx_delivery_missing`

**Multi-agent execution:**
- 3 並列マルチエージェント着地: Track A (`a45ec3cc9c69c608c`, 105 tools, 723s) / Track B (`a46a758522a06ca10`, 50 tools, 385s) / Track C (`aa86337918d071638`, 85 tools, 546s)
- Plan agent 1 本 + Explore agent 3 本で事前調査、ユーザー 2 問質問でスコープ確定 (sync 履歴 UI を含む最大スコープ + 真因確定 + 修正まで)
- Orchestrator は調整・最終検証・MEMORY 更新を担当

**Follow-ups (繰越):**
1. F1 admin PowerShell 実登録 (ユーザー手動領域、runbook §4 に手順記載済)
2. `JpxDriftTab` (旧 `components/ops/JpxDriftPanel`) と `InstrumentMasterTab` (新 3 サブタブ) の OpsHub 重複整理 (別 PR)
3. `JpxProtectedCodesPanel.test.tsx` (低優先、機能影響なし)
4. `tools/quality/jpx_listed_companies_drift_check/` の pytest ディレクトリ未作成 (薄い委譲ラッパーのため低優先)
5. 2026-06-15 保護コード 10 銘柄再評価 (next_review_at トリガー、`investigate_jpx_missing_codes.py` 再走で in_raw_xls 判定)
6. tool_tiers.yaml の別箇所衝突 (line 272 付近、Phase 4 スコープ外)

**関連:**
- @./project_jpx_listed_companies_phase2.md
- @./project_jpx_listed_companies_phase3.md
- @./project_jpx_listed_companies_phase3_followup.md
- @./bugs_core_instruments_market_reform_stale.md
