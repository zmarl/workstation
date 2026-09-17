---
name: project-decision-journal-round2
description: 意思決定プロセス改革 Round 2 着地 (2026-06-19)。DQI 7項目本実装 + 改善採択ライフサイクル (decision.improvement_proposals) + タグ SSOT + 文書残課題。Round 3=死蔵分析接続が次
metadata: 
  node_type: memory
  type: project
  originSessionId: b891093e-c9e3-4ecd-a524-dbe653201a42
---

# 意思決定プロセス改革 Round 2 (2026-06-19 着地)

Round 1 (判断ジャーナル) の上に学習ループを実装。プラン: `C:\Users\kazum\.claude\plans\greedy-exploring-starfish.md`、worklog: `docs/worklogs/20260619-learning-loop-round2.md`。前段は [[project-decision-journal-round1]]。

## 着地内容
- **DQI 7項目化**: tools/quality/decision_quality_scorer/scorer.py を月次4→7項目。新3項目 (edge_accuracy 0.20 / resolution_calibration 0.15 / temperature_calibration 0.15) を decision.trade_decision_journals から計算。outcome_value: confirmed=1.0/partial=0.5/refuted=0.0/unobserved=分母除外。校正式 `_calibration_agreement` = 1−|expected−outcome|/max(expected,1−expected)。**_MIN_SAMPLE_N=3 未満は None** (journal 0件期間も安全、既存4項目で重み再正規化)
- **実バグ2件修正**: ① scorer repository が存在しない pl.thesis_tags を SELECT→例外→[] で prerecord_completeness 常時 None。② DqiTab が 0-1 スケールに 80/60 閾値→ほぼ常時「要確認」。0.70/0.50 + ×100 表示に統一
- **改善採択ライフサイクル**: decision.improvement_proposals (draft→trial→adopted/rejected) + measurements。R.9「1件だけ採択」を partial unique index で DB 強制、trial 3点必須 CHECK、adopted/rejected 不変化トリガー。feedback_loop/proposal_manager.py が postmortem→draft 自動起票 + 月次効果測定で adopt/reject/extend 推奨 (最終判定は Desktop の人間)
- **タグ SSOT**: 投資フレームワーク/02_用語定義/失敗分類タクソノミー.md (R.9 8カテゴリ正準コード: ev_design/quant_eval/qual_eval/market_read/flow_reaction/execution/rule_violation/opportunity_loss) + shared/taxonomy/failure_tags.py
- BFF: GET /api/v1/portfolio/dqi-monthly + improvement-proposals 7 endpoint。Desktop: DqiTab 月次パネル + ImprovementProposalsPanel (FeedbackCockpit 統合)
- 文書残課題: C-001/C-004 期限延長 (→2026-09-30、ログ蓄積待ち)、R.2 Step 4-0 で「PF モード最優先→レジーム配分で戦略群枠→枠内で期待値順位」明文化
- alembic head=20260613_03 (他バッチ revision が我々の _01/_02 後にチェーン)。スケジューラ3タスク (dqi-monthly-scoring 毎月2日 / sweep weekly / measure monthly)

## 重要な知見
- DQI scorer の calculate_overall_dqi は _WEIGHTS 総なめ + None 除外 + 再正規化の汎用実装 → 重み変更は _WEIGHTS 辞書だけ、コンポーネント追加も加算のみで壊れない
- /api/v1/portfolio/dqi 系は `_run_with_backend` で ClickHouse 優先 → ローカル (CH 不在) では日次・月次とも 503 control_plane_backend_unavailable。**これは環境要因で本番では動く**。ローカル smoke では postgres 直アクセスのロジックテストで代替
- [[bugs-time-bomb-tests]] スケール不整合 (0-1 vs 0-100) は表示層で常時誤判定を生む静かなバグ。SSOT (DQI.md=0-1) に表示層を合わせる
- 改善採択の状態遷移は Desktop mutation のみ (ユーザーは手動 CLI を嫌う、ops は scheduler 完全自動が前提)。measure_trials は推奨を書くだけで adopt/reject はしない
- worktree に複数バッチ未コミット並存が常態化 → ruff/pytest のフル実行は他バッチ由来の失敗が混ざる。自分のスコープ限定で緑を確認し、共有ファイル経由の失敗は git diff --stat で他バッチ由来を切り分けてから判断
- 関連: [[project-framework-docs-overhaul-2026-06]] (C-xxx 3点セット、HTML drift CI)、[[framework-ssot]]

## 残り (Round 3/4)
- Round 3: 死蔵分析の判断接続 (hidden_edge→sizing、historical_analog→期待修正、correlation→動的割引、theme_narrative 自動スコア)
- Round 4: 未実装戦略 (S.3 ショート/T.3 L/S/E.1・E.3 カタリスト/S.5・E.2・E.4 イベント検出)
- スケジューラ実登録は register_schedules.ps1 をユーザーが管理者実行 (パスワード境界)
