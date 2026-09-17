---
name: 改革ロードマップ A+B+D 各 S 粒度 並列着地 (2026-05-10)
description: #11 Phase 2-A scheduler 登録 + Wave E edge confidence (案 A: tier-fixed band) + 改革 #7 認知バイアス UI バナーを 3 並列で着地。ファイル衝突ゼロ
type: project
originSessionId: fd002f51-3dd4-4c42-8c0c-c9e24b23d7b2
---
# 改革ロードマップ A+B+D 並列着地 (2026-05-10)

直前 3 セッションの自然な続き 2 系統 (#11 Phase 2-A、Wave E confidence) + 新領域開拓 1 系統 (改革 #7 認知バイアス) を 3 並列で着地。

**Why:** Phase 1 で完成した auditor を運用ループに乗せる (A)、Wave E inferer の reference_candidate 確度を edge band として可視化する (B)、既存稼働中の `behavioral_alerts` を投資判断 surface に出す (C)。各 S 粒度で完結することで destructive 変更ゼロ。

**How to apply:**
- Stream A: `db_capacity_audit` を scheduler 登録するときは manifest + register_schedules.ps1 + .bat の三点セット必須。`tests/scripts/test_scheduler_integrity.py` が静的検査するため、3 点が揃わないと pytest が落ちる
- Stream B: Wave E inferer の confidence 反映は **案 A (tier-fixed: 1=0.85 / 2=0.70 / 3=0.55 / 4=0.40)**。BFF primary 由来 confidence は `edge.confidence == null` のときだけ tier band で補完 (不変性保証)
- Stream C: behavioral 関連の UI 統合は **既存 `/api/v1/portfolio/behavioral` を最小拡張**。新規 endpoint は overhead 大 (READ_TOKEN_PROTECTED_ROUTES + RESIDUAL_READ_ROUTE_CONTRACT_SCHEMAS + openapi 再生成等)
- DB スキーマ実態尊重: `analytics.behavioral_alerts.severity` は `info/warning/critical` (`low/medium/high` ではない)。`recommended_actions` カラムなし → クライアント側で `pattern_type` から派生

## 既存ファイル変更

### Stream A (4 件、+20 行)
- 修正: `scripts/run_manifest.yaml` (`db-capacity-audit-daily` task 追加)
- 修正: `scripts/register_schedules.ps1` (`DbCapacityAuditDaily` 登録、TriggerTime 01:45)
- 新規: `scripts/run_db_capacity_audit_daily.bat` (6 行シム)
- 修正: `tools/quality/db_capacity_audit/README.md` (Phase 2-A 登録の旨を 1 行追記)

### Stream B (8 件、+130 行)
- 修正: `tools/analytics/business_model_frameworks/tier_inferer.py` (`_TIER_CONFIDENCE` 定数 + `infer_tier_chain` 戻り値拡張)
- 修正: `tools/api/decision_api/response_models.py` (`SupplyChainTiersResponse.confidence_by_tier` optional 追加)
- 修正: `tools/api/decision_api/routers/company.py` (return dict +1 行)
- 修正: `desktop/src/lib/types/company.ts` (interface optional 追加)
- 修正: `desktop/src/components/company/PureSupplyChainDiagram.tsx` (`buildTierLookup` 拡張、`applyTierAnnotations` で不変性保証、TierLegend で推定確度表示)
- 修正: `tests/analytics/business_model_frameworks/test_tier_inferer.py` (新規 `TestTierConfidence` 4 ケース + 既存 1 件 assert 更新)
- 修正: `tests/tools/api/test_decision_api.py` (既存 3 ケースに confidence assert 追加)
- 修正: `desktop/src/components/company/PureSupplyChainDiagram.test.tsx` (既存 mock 拡張 + 新規 2 ケース)

### Stream C (8 件、+250 行)
- 修正: `tools/api/decision_api/serving/_portfolio.py` (`get_portfolio_behavioral` SQL 拡張: alert_id 追加 + acknowledged=FALSE フィルタ)
- 新規: `desktop/src/components/shared/BehavioralAlertBanner.tsx` (約 110 行)
- 新規: `desktop/src/components/shared/BehavioralAlertBanner.test.tsx` (4 ケース)
- 修正: `desktop/src/pages/Dashboard.tsx` (import + AggregatePartialNotice 直後に `<BehavioralAlertBanner />` 1 行)
- 修正: `desktop/src/i18n/ja.ts` (`behavioralAlert` namespace 追加)
- 修正: `desktop/src/lib/types/portfolio.ts` (`alert_id?` / `acknowledged?` optional 追加)
- 修正: `tests/tools/api/test_serving_repository.py` (新規 3 ケース)
- (Dashboard.test.tsx は既存 mock そのまま流用、変更なし)

## Verification

統合検証 (main agent):
- `uv run ruff check .` clean
- `uv run pytest` 全体 11566 passed, 333 skipped (前回 11530 + 新規 36)
- `cd desktop && npx tsc --noEmit` clean
- `cd desktop && npm run test` 全体 1793/1793 passed (前回 1768 + 新規 25)
- `cd desktop && npm run build` exit 0 (8.96s)

## 落とし穴・Tip

- **Stream A**: Plan agent 当初想定の「uv runner 直叩き」は誤り。`.bat` ラッパーは既存 quality lane (`run_tdnet_quality_check.bat` 等) と同形式の 6 行シムで `run_tool.ps1 -TaskId <id>` に委譲する形が必須。`tests/scripts/test_scheduler_integrity.py` が三点整合 (manifest + ps1 + .bat) を強制検査
- **Stream A check_scheduler_integrity の runtime drift**: `static_integrity ok=true` だが `missing_in_scheduler_count=1` の warning は Windows 側で `register_schedules.ps1` を実行するまで残る (期待動作)
- **Stream B 不変性保証**: edge.confidence == null チェックを必ずガードに入れる。BFF primary 由来 confidence (例 0.92) を Wave E tier band (例 0.70) で上書きしないことを専用テストでカバー
- **Stream C severity 値**: DB は `info/warning/critical`。`low/medium/high` を使うと SQL 一致せず空応答になる
- **Stream C 配置先選定**: Dashboard.tsx の `AggregatePartialNotice` 直後が既存 banner 群と並列共存しやすい。`StrategyConflictsBanner` / `DecisionReadinessBanner` も同レベル
- **Stream C i18n namespace**: `behavioralAlert` は新規 namespace、既存 namespace と衝突しないことを確認
- **3 並列の効果**: ファイル分離が完全だったため衝突ゼロで wall clock 大幅短縮。各 stream の duration_ms = A: 108k / B: 424k / C: 456k (合計 ~990 秒、並列実行で実質的に最遅 stream の時間で完走)

## Plan agent 出力の検証 (継続学習)
- Stream A の Plan agent #1 が「`.bat` wrapper 不要」と当初想定 → 実装中に誤りと判明、修正
- Stream C の Plan agent #3 が新規 endpoint `/api/v1/behavioral/alerts/active` 案を提示 → 実態調査で既存 `/api/v1/portfolio/behavioral` 流用がベターと判明
- → **Plan agent 出力は方向性として参照、修正前にファイル単位で実態確認を徹底**する方針を再度確認

## 残 Follow-ups

- Stream A: `--persist` 実装は Phase 2-B (`ops.db_capacity_snapshots` 新設 + alembic + governance YAML 連動)
- Stream A: `register_schedules.ps1` を Windows 側で実行して `DbCapacityAuditDaily` を Task Scheduler に登録 (runtime drift 解消)
- Stream B: 業界別 tier layout template (pyramid/layered/hub 切替) は Wave E Phase 2 別 task
- Stream C: ActionQueueTab への BehavioralAlertBanner 配置は次回、daily reset 機構も将来課題
- 改革 #11/#12 Phase 2-B (retention 承認 UI / log scrubber 拡張) → 次セッション
- 改革 #8/#9/#10 + FU-6/FU-7 → 別セッション
- worklog: `docs/worklogs/20260510-reform-a-b-d-parallel.md`
- プラン: `~/.claude/plans/12-docs-roadmap-investment-app-reform-p-parallel-teacup.md`
