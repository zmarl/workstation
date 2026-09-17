---
name: project-decision-journal-round1
description: 意思決定プロセス改革 Round 1 着地 (2026-06-12)。判断ジャーナル (DB+BFF+UI) + PriorityQueue/Ideas/ExitSignal アクション配線 + サイドバー意思決定プロセス順再編。Round 2-4 ロードマップあり
metadata: 
  node_type: memory
  type: project
  originSessionId: b891093e-c9e3-4ecd-a524-dbe653201a42
---

# 意思決定プロセス改革 Round 1 (2026-06-12 着地)

「投資フレームワーク文書とアプリの断絶」解消の第1弾。プラン: `C:\Users\kazum\.claude\plans\greedy-exploring-starfish.md`、worklog: `docs/worklogs/20260612-decision-journal-round1.md`

## 着地内容
- **判断ジャーナル**: `decision.trade_decision_journals`(draft→committed→closed/voided、PASS見送りも記録) + `decision.journal_entries`(追記専用)。既存 `core.tranche_precommit_logs` を不変スナップショットとして再利用し commit 時に `create_thesis_precommit()` でリンク（複製テーブルなし）。immutability は DB トリガー2本 (`journal_committed_immutable` / `journal_entry_append_only`)。alembic head=20260611_01
- **BFF**: `routers/journal.py` 10 endpoint。commit 検証 = Hard Gate 7項目 + p*=D/(U+D) 乖離0.05 + pf_mode risk_off/freeze で NO_NEW。prefill は gate0/screening/expectation/allocation/scorecard 集約。ideas status POST 新設
- **Desktop**: /journal 3ルート（一覧/3ステップウィザード R.1→R.2→R.3/詳細）、PriorityQueuePanel（Dashboard+ActionQueueTab、handled/hold/snooze/dismiss）、Ideas 承認/却下、ExitFlowStepper（respond→promote→approve→submit、respond 実契約は approved/executed/rejected の3値のみ）、サイドバー6グループ再編（DECIDE/COMMIT・REVIEW/LEARN 新設、Review/RiskCommand オーファン解消）
- 検証: ruff/pytest/tsc/vitest 全緑 + 実機 smoke 12/12（TestClient+実DB）

## ロードマップ（残り）
- Round 2: DQI 計算式実装（journal の edge_outcome/info_resolution_score/temperature/t_stop_date/PASS 記録が起点）+ postmortem→改善採択半自動化 + 文書矛盾解消（21/22戦略表記・R.2 provisional 係数・タグ体系）
- Round 3: 死蔵分析の判断接続（hidden_edge→sizing、historical_analog→期待修正、correlation→動的割引、theme_narrative 自動スコア）
- Round 4: 未実装戦略（S.3 ショート / T.3 L/S / E.1・E.3 カタリスト / S.5・E.2・E.4 イベント検出）

## 重要な知見
- PriorityQueue の BFF 受理契約は handled/hold/snooze/dismiss（desktop 旧型の mark_done/escalate は幻だった）。契約確認は response_models.py の Field(pattern=...) が早い
- [[bugs-time-bomb-tests]] 固定日付フィクスチャ + 実時刻比較のテストは時限爆弾。scorer 系は `as_of_date` 引数を必ず固定で渡す
- worktree に未コミットバッチが複数並存する状態では、共有ファイル（api-client.ts 等）が絡んで切り出しコミット不可になる。Round 1 はコミット見送り（ユーザーのバッチコミット待ち）
- 関連: [[framework-ssot]]
