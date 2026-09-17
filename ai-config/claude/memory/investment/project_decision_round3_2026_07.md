---
name: project-decision-round3-2026-07
description: 意思決定改革 Round 3 着地 (2026-07-03)。3分析を journal prefill + wizard に接続、真因の生産側系統故障 (37タスク引数バグ / feature_store 凍結) も修理
metadata: 
  node_type: memory
  type: project
  originSessionId: 9f7b3013-0350-4c83-96ab-dfd07bcd2c35
---

# 意思決定プロセス改革 Round 3 着地 (2026-07-03)

**DECIDE-R3 done**: hidden_edge→sizing / analog→期待修正 / correlation→動的割引 を判断導線に接続。

- **BFF**: `journal_repository._collect_prefill` に `hidden_edge` / `historical_analog` / `correlation` の3セクション追加 (best-effort null degrade)。`analytics.correlation_sizing_adjustments` / `group_correlation_summary` に初の読取経路。`search_analogs(conn=...)` 対応 (prefill は同一接続共有、universe_limit=20000/top_k=5)。prefill contract + openapi + d.ts 同期済み
- **Desktop**: `JournalAnalysisPanels.tsx` (AnalogContextPanel=Step1 / SizingContextPanel=Step2)。推奨サイズは「反映」ボタンのみ (人が最終決定)、根拠は size_rationale 追記 + create `prefill: true` で draft_payload に分析スナップショット永続化。未蓄積時は正直表示
- **生産側修理が本丸だった**: 3分析テーブルは全部空。真因は [[bugs-manifest-argparse-order]] (37タスク全滅) と [[bugs-feature-store-rollback]] (fs_price_features 凍結)。修理+position_recorder 実走で core.positions 4/19→当日化、correlation チェーン復旧 (保有1銘柄のため pairs=0 は正当)。price 特徴量は 2024-07〜 バックフィル済みで analog が実用化
- **残課題**: hidden_edge ツールは schema drift で腐敗 (core.tranches に無い ticker_code/total_return_pct 等を参照)。クローズ済み取引のアウトカム正本 (postmortem 等) への再マッピング設計が必要 → 別チケット。BT-LINK-01 (journal⇔backtest 突合 view) 未着手。DECIDE-R4 は R3 done で着手可能
- worklog: `docs/worklogs/20260703-decision-round3-analysis-injection.md`
