---
name: project-functional-uplift-202607
description: 既存機能 実用化アップデートプログラム（2026-07-04 完了）。6フェーズ23バッチで配線断絶・偽数値・誇大命名・形骸化ゲートを一掃。残タスクと教訓
metadata: 
  node_type: memory
  type: project
  originSessionId: b291d279-8fab-47c4-88ee-1f1c9886c5b3
---

# 既存機能 実用化アップデート（2026-07-04、branch: feat/functional-uplift-p1）

プラン正本: `C:\Users\kazum\.claude\plans\opus-functional-wall.md`。worklog: `docs/worklogs/20260704-functional-uplift-phase1.md`。全23バッチ完了（約20コミット、Explore×3 + Plan×2 + 実装agent×10）。

## 発見した「動いているつもりで死んでいた」重大故障（全て修理済み）
1. screening_alert_dispatcher — 存在しない orchestrator.notify import を except で握りつぶし**一度も配信されたことがなかった**（＋ルール自体0件）
2. guardrail_gate_evaluator — strategy_id 列不存在（正: strategy_code）で毎日「戦略0件」成功終了＋snapshot 不在で GO 空押印 → fail-closed 化、22戦略 hold/no_data
3. consensus_revision — placeholder 31 vs params 32 で **2026-04-14 から全実行例外死**＋生産側 manifest 未登録。復旧後 3,194銘柄/日
4. pf_risk_monitor — 実在しない thesis_tags 列参照で run が毎回途中死
5. oos_rule_review — 実在しない列4つ参照で半年レビュー毎回即死＋PF=∞→green の偽判定
6. expectation_calculator — consensus_target=current_price 代入で upside≈0 の偽 p*。正しい導出関数は実装済みなのに未配線だった

## 教訓（同型バグ4パターン、再発防止ゲート済み）
- **「存在しないシンボル/列/テーブル参照 + except 握りつぶし」が最頻出**。握りつぶしは fail-loud に倒す
- **「正しい実装が存在するのに配線されていない」**が2件（expectation target 導出、consensus_revision 生産側）
- manifest args ↔ argparse 整合は `manifest_sla_audit` の `cli_flag_not_defined` 検査（block）で機械化済み
- 調査結果は実装前に必ず実データ・実コードで再検証: U8（Flow拡充）は実装段階で「中止が正解」と判明（US-pulse は410恒久停止、Flow統合は既決定）。U5 も8本中6本が空/重複で接続見送り

## 残タスク
1. **Windows タスク登録4本**（$scheduler-registration）: ConsensusRevisionDaily / StrategyConflictResolverDaily / SegmentValueAnomalyQuarantineWeekly / CanslimScreenWeekly
2. 1週間後: strategy-conflict-resolver の --dry-run 除去（live 昇格）。未処理conflict 79件
3. qwen3.5:9b 常駐化 → asset_acquisition manual_only 解除 + tdnet-ops12-gate strict 化
4. 持ち越し退役: industry_kpi_collector（依存鎖）/ execution_quality_collector（鮮度SLA絡み）。詳細 `docs/backlog/20260704-retired-collector-stubs.md`
5. 死蔵API第2弾候補: `docs/audits/20260704-unused-bff-routes-triage.md`（Ops Hub 5本、Regulation 2本等）
6. R11 で同日別セッションの「market indicator 5本 precompute 登録」を disable で上書き（永続化なしで precompute 不成立のため）— ユーザー再裁定の余地あり

**Why:** 大規模プログラムの完了状態・残タスク・再発防止知見を次セッションに引き継ぐ。
**How to apply:** 残タスク着手時はこのファイルと worklog を正本に。関連: [[project-reform-program-202607]]
