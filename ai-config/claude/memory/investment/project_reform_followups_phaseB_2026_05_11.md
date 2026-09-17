---
name: 改革ロードマップ Desktop統合 3提案 Follow-ups Phase B 着地 (2026-05-11)
description: 提案#4/#5/#6 の Follow-ups 4 件 (FU-1 deeplink test / FU-2 event-taxonomy / FU-3 Decision 連携 / FU-5 RiskTab 整理) を着地。司令塔 critical/today を決定導線3箇所に浮上。
type: project
originSessionId: ed221d80-9624-4c77-96aa-8a8d8ecc8177
---
# Reform Phase B 完了 (2026-05-11)

前回 (2026-05-10) で Phase 1〜3 着地済の Desktop 統合 3 提案について、Follow-ups 7 項目のうち 4 件を着地。司令塔タブを開かないと critical/today が見えない問題と RiskTab 内の二重実装問題を解消。

**Why:** 司令塔タブだけに critical を閉じ込めると、Portfolio ActionQueueTab / TodayDecisionQueue / DecisionSpine の決定導線では緊急対応が抜け落ちる。BFF 側 `_risk_command.py` と Desktop 側 `buildRiskCommandChecks` の二重 threshold 計算も解消対象。

**How to apply:**
- 新司令塔の triage critical/today/watch を `desktop/src/lib/risk-command-decision-mapper.ts` で `DecisionSpineItem` に変換し、Portfolio.tsx の `portfolioDecisionItems` useMemo の **先頭** に挿入する設計。ActionQueueTab は無変更で props 経由で自動取得
- TodayDecisionQueue は `RiskCommandTopStrip` を feedback 直下に挿入。empty 時 `return null`、最大 3 件で警告過多回避
- `queryKeys.riskCommand.summary()` を 3 surface (RiskCommandPage / Portfolio / TodayDecisionQueue) で共有 → TanStack Query cache が 1 リクエストで足りる
- RiskTab は `RiskCommandRedirectNotice` (data-testid="risk-command-redirect-notice") で「司令塔タブへ」誘導のみ、`buildRiskCommandChecks` などの threshold ロジック完全削除
- EventStudyPanel は `desktop/src/lib/event-taxonomy.ts:eventTypeLabel()` 関数を呼ぶ。`EVENT_TYPE_META` が canonical 定義 (EventImpactTimeline 等で既使用)

## 既存ファイル変更
- 修正: `tools/api/decision_api/serving/_decision.py:5611-5612` (前回着地済の capital_policy_watch 配線)
- 修正: `tests/tools/api/test_decision_api.py` (FU-1 テスト追加)
- 修正: `desktop/src/components/decision/decision-spine-builders.test.ts` (FU-1 検証は priorityQueueHref が module-private のため `buildDashboardDecisionItems` 経由)
- 修正: `desktop/src/components/company/EventStudyPanel.tsx` + test (FU-2)
- 修正: `desktop/src/components/portfolio/RiskTab.tsx` + test (FU-5、約 150 行削減 + RiskCommandRedirectNotice inline 追加)
- 修正: `desktop/src/pages/Portfolio.tsx` + test (FU-3)
- 修正: `desktop/src/pages/TodayDecisionQueue.tsx` + test (FU-3)

## 新規ファイル
- `desktop/src/lib/risk-command-decision-mapper.ts` + test
- `desktop/src/components/today/RiskCommandTopStrip.tsx` + test

## Verification
- `uv run ruff check .` clean
- `uv run pytest` 全 11456 passed (regression 0)
- `cd desktop && npm run test` 1754 passed (前回 1742 + 新規 12)
- `cd desktop && npm run build` exit 0

## 残 Follow-ups
- FU-4 (single route 化): 既に解決済 (Portfolio.tsx に risk-command タブ実装済)
- FU-6 (PBR 履歴計算): 中〜大スコープ、Phase C で対応 (BPS×daily_quotes、period alignment 設計済)
- FU-7 (per-event AR ストア): 大スコープ、別タスク化 (`analytics.event_study_results` PK 拡張必要)

## Tip / 落とし穴
- `priority_bucket` は `WatchlistMonitorPriorityItem` の field であり、`PriorityQueueItem` (decision priority queue) には**ない**。BFF も queue dict には含めず target_path/severity 計算にのみ使う。テストで `as PriorityQueueItem` キャスト時に priority_bucket を入れると TS2352 エラー。`satisfies PriorityQueueItem` + `priority_score` 必須付与で対応
- worklog: `docs/worklogs/20260511-reform-3proposals-followups-phaseB.md`
- プラン: `~/.claude/plans/12-docs-roadmap-investment-app-reform-p-zany-leaf.md`
