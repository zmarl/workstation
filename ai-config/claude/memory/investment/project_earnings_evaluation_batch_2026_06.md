---
name: project-earnings-evaluation-batch-2026-06
description: 決算評価改善バッチ全量一括着地 (2026-06-11/12)。look-ahead修正・デッドパス4種解消・答え合わせ基盤・業種別閾値・レビュー効率化
metadata: 
  node_type: memory
  type: project
  originSessionId: 633a62b8-04f2-4ae6-84f4-5b287c7cc11b
---

# 決算評価改善バッチ (2026-06-11〜12 着地、9ストリーム+Wave4)

プラン: `C:\Users\kazum\.claude\plans\cheerful-zooming-puddle.md` / worklog: `docs/worklogs/20260611-earnings-evaluation-improvement-batch.md`

## 着地内容
- **S1**: consensus_earnings_comparison の look-ahead 修正（`as_of_date <= announcement_date` フィルタ + STALE_CONSENSUS_DAYS=45 降格 + post_announcement 降格）。pack に age_days/staleness
- **S2/S3/S6**: labeler デッドパス4種解消 — repository に供給ヘルパー4本（guidance_revision / consensus_surprise[Q4のみ] / progress_baseline / peer_relative、全て PIT フィルタ付き）。進捗率は過去年同四半期平均優先 + fiscal_quarter/4 フォールバック
- **S4**: detect_unit_magnitude_mismatch（log10 [5.5,6.5]/[2.5,3.5]、warning 固定）→ 実走で 2,478 件検出。financial_unifier conflict gate（--strict-conflicts）。order_narrative 億円/千円対応
- **S5**: `analytics.earnings_event_outcomes`（alembic 20260611_02 適用済み）+ `tools/decision_support/earnings_outcome_tracker`（fill / label-accuracy / calibrate-thresholds）+ labeler `revaluate-reaction`。STOCK_REACTION_* を実適用 200 件（肯定25/無反応117/否定58）
- **S7+W4**: rules v3 — `resolve(sector33, sub_sector, fiscal_quarter)`、sector_overrides 初期3件、quarter_overrides は progress_band_pp のみ（Q別 progress_above は二重補正になるため不採用）。新ラベル: GUIDANCE_REPEAT_REVISER / ORDER_BACKLOG_COVERAGE_* / GOODWILL_TO_EQUITY_WARNING
- **S8**: review-stats CLI + `GET /api/v1/earnings/review-stats`。priority に outcome 乖離 urgent（±3pp）+ 保有/監視昇格。Desktop 一括承認（high×positive×pending のみ、alertdialog）
- **S9**: `GET /api/v1/scoring/earnings-eval/{code}/prefill` — 6軸スコアUIに自動ラベルからの提案値プリフィル（手動上書き優先、保存経路無変更）

## 重要知見
- **register_schedules.ps1 は自動実行不可**: BackgroundPassword モードで Read-Host のパスワード対話あり → 必ずユーザー実行。`-OnlyTaskNames A,B` で部分登録可
- **consensus surprise は Q4（通期実績）のみ供給**: consensus_snapshots は通期予想のみで Q1-Q3 比較は偽 MISS になる
- **既存 `earnings_post_return_5d` ツールは ML 予測パイプライン**（ops.ml_*、mart.vw_ml_earnings_*）で、outcome_tracker（実測の答え合わせ）とは役割が別。リターン計算の共通化は将来課題
- **labeler の供給パターン**: `repository._load_*_metrics`（_relation_exists ガード + PIT フィルタ）→ `_fill_missing_metrics` チェーン接続で labeler.py 本体無改修でラベル発火
- 初回 label-accuracy 実測（2026-05-15〜20 の 285 件、改善前ラベル）: ACCELERATION_QUALITY (positive, n=145) の符号一致率 45.5%、平均超過 -0.78pp → 閾値改善ループの起点

## 未了・繰越
- [ ] Windows タスク登録2件（人間ステップ、worklog に手順）: EarningsOutcomeFillDaily / EarningsReactionRevaluateDaily
- [ ] **mart.vw_financials_unified の 7203 FY2026Q4 不正行**（Q2 数値の使い回し + NI 桁違い）→ consensus 比較が -51% 偽サプライズ。上流 financial_unifier の行ラベル/dedup 問題、高優先
- [ ] unit_magnitude_mismatch 2,478 件 / net_income_eps_mismatch 472 件の triage、detector critical 昇格
- [ ] git commit 未実施: worktree に並行セッション（journals/ideas/theme）の変更が混在 + `tools/market_data/jpx_listed_companies/sync.py` に**競合マーカー残留**（別ストリーム起因）
- [ ] outcome fill の per-event eps クエリが slow (6s) → vw_financials_unified の索引/実体化検討
- [ ] sector_overrides 本格拡充（calibrate-thresholds → 人間レビュー → YAML の運用）
- [ ] expectation_calculator の get_latest_consensus_by_ticker に PIT フィルタ未展開
