---
name: project-analytics-accuracy-202607
description: "分析正確性向上プログラム完了 (2026-07-04, feat/analytics-accuracy worktree)。17件修正+共通品質基盤。マージ方針と再計算 handover、価格/単位/財務ビューの重要データ事実"
metadata: 
  node_type: memory
  type: project
  originSessionId: a89ee46f-c16c-4af8-bf52-772b55e76059
---

# 分析正確性向上プログラム (2026-07-04)

branch `feat/analytics-accuracy`（worktree `D:\Dev\Investment-accuracy`、HEAD 205c281d から分岐、コミット済み）。worklog: `docs/worklogs/20260704-analytics-accuracy.md`。プラン: `C:\Users\kazum\.claude\plans\luminous-tinkering-storm.md`。Explore×3 + Plan×2 + 実装agent×5 + reviewer で実施。

## 成果
- **共通基盤**: `shared/financial_units.py`（百万円→円は契約ベース無条件換算、桁推測禁止）+ `shared/data_quality.py`（営業日鮮度 assess_freshness / guard_min_samples / build_data_quality / DataSourceUnavailableError / alert_if_stale）+ `shared.source_freshness.expected_latest_jp_trading_day` 公開化
- **17件修正**: 単位ヒューリスティック(59行未換算) / 未調整株価 / RRG構成バイアス / fail-loud / momentum捏造 / 可変窓 / 鮮度5ツール / 最小サンプル / EPS最近傍 / 陳腐化ゲート / MWU / 分散 / 定数化 / min_periods / breadth日付窓 / broad except / **#17: surprise期間不一致**（下記）
- 市場系5ツール payload に追加キー `data_quality`（既存キー不変で後方互換）

## 重要データ事実（他作業でも参照価値大）
- **調整済み株価の正本 = `mart.vw_price_daily_corporate_action_adjusted`**（996万行、2016-03〜、close は調整済み、code で join）。`raw.prices_daily` は **0行**、`main.daily_prices` は **直近42営業日のみ**（長窓計算に使用禁止）
- `analytics.consensus_preferred_snapshots` 金額列は**全行百万円**（円建て0行、2026-07-04 実測）
- **`mart.vw_financials_unified.operating_income` は四半期累計**、guidance_operating_income は通期予想で **Q4行では実績と同値**（同一行 guidance 使用は look-ahead）。→ 通期比較は fq=4 行のみ+先行行 guidance の carry-forward が正しい
- `core.instruments` の33業種列は `sector_code`/`sector_name`（industry_code_33 は存在しない）

## 2026-07-05 進捗: マージ・配線・再計算 実施済み
- マージ完了（f937380a、競合2ファイルは mart ビュー版で解消）。persist 5本への alert_if_stale_payload 配線もコミット済み（8d7b0712）
- **新発見（改革プログラムへの申し送り）**: reform の baseline 生成物 `db/baseline/postgres/*.sql` に **CREATE INDEX が1本も無い**（pg_dump ベース生成の欠落）。さらに実DBから `idx_eg_code`/`idx_eg_quadrant` が消失していた（7/4 まではスケジュール実行成功=存在。relation_cleanup か baseline 系操作で drop された疑い）。ガード `require_indexes` により expectation_gap 全銘柄が即死→ 旧 DDL（74_expectation_gap.sql の定義）どおり CREATE INDEX IF NOT EXISTS で実DBに復元済み。**他テーブルでも同型のインデックス消失が起きていないか、baseline 生成器のインデックス出力対応が必要**
- 全体テスト: 旧持ち越し31件は解消済み、現存の失敗は runtime_schema_governance 1件のみ（origin/main 由来の generate_db_baseline.py 許可リスト未登録、改革セッション領域）

## マージ時の注意（handover）
1. **競合予定**: market_breadth / sector_rotation_rrg の calculator は並行セッション（functional-uplift-p1 側）が `main.daily_prices`（42日分）へ暫定切替済み。**本ブランチの mart ビュー版（10年・調整済み）を正とする**
2. マージ後の**保存値再計算**: expectation_gap_analyzer → market_expectation_surface → consensus_revision を再実行（過去の surprise/edge_score は単位バグ+期間不一致で汚染されている）
3. **persist.py（Phase 5 の5本）に alert_if_stale 配線**（worktree 分岐時点に未存在のため未実施。BFF on-demand はフラグのみ、発報は scheduled 経路のみの原則）
4. 全体 pytest の失敗31件は HEAD 時点から同一の持ち越し（検証用 worktree で突き合わせ済み、当バッチの退行ゼロ）

## 教訓
- **「単位バグが別の構造欠陥を隠す」**: 単位修正後のスモークで surprise が Q1≈-75%/Q2≈-45% の規則パターン → 累計vs通期の期間不一致（#17）を発見。修正後は必ず実データスモークで分布を見る
- 同居テスト（tools/ 配下の test_*.py）は pytest testpaths 外で全体実行に含まれない → import 互換を壊すと気づけない（reviewer が検出）
- fail-loud は「フィルタ後0件」と「基盤テーブル空」を probe で区別しないと正当な空が503化する

**Why:** マージ・再計算・persist 配線の3つの handover が残っており、次セッションが正確に引き継ぐ必要がある。
**How to apply:** マージ着手時は本ファイルの「マージ時の注意」を正本に。関連: [[project-phase5-history-edinet-structuring-202607]] [[feedback-parallel-session-worktree]]
