---
name: project-repo-audit-2026-07-12
description: リポジトリ全域監査2弾完了 (2026-07-12)。docs/audits/ に2本のレポート。確証済み計算バグ3件・バックアップ実装ゼロ・EDINET凍結等の重大発見
metadata: 
  node_type: memory
  type: project
  originSessionId: a7d33272-ba93-47c8-a19b-3f8424753ce9
---

# リポジトリ全域監査（2026-07-12、調査のみ・未修正）

24体の調査エージェントで3弾実施。正本レポート:
- 第1弾（構造・仕組み）: `docs/audits/20260712-repo-wide-improvement-audit.md`
- 第2弾（中身の正しさ・未踏領域）: `docs/audits/20260712-repo-wide-improvement-audit-round2.md`
- 第3弾（目的別・動的検証）: `docs/audits/20260712-repo-wide-improvement-audit-round3.md`
- **統合バックログ（着手はここから）**: `docs/audits/20260712-unified-improvement-backlog.md`（Tier 0〜4、50項目）

## 第3弾の重大発見と訂正（2026-07-12 追記）

- **第1弾 P0 の3件（tdnet-notifierゾンビ/cancel-in-progress/baseline FAIL）は stale worktree による誤判定**。origin/main では解決済み。本 worktree は main から98コミット遅れ・34先行の diverged。正アクションは「マージ前に origin/main 取り込み」（取り込まないと本流の改善を退行させる）。origin/main は manifest を scripts/manifest/*.yaml + generator 方式へ移行済みで衝突注意。**監査・突合の baseline は必ず origin/main に固定すること**。
- **daily_screener が 7/5 から7営業日連続失敗**（main.py:1212 のログ行 KeyError 1行バグ）+ 候補ユニバースが `gate0_evaluations.edge_conviction_score` 欠落で停止。空の候補の上で sizing が「成功」し続けている。
- **意思決定ループの中間5段（判断/サイジング/執行/記録/振り返り/学習）は実データ史上ゼロ件**。ジャーナル・orders・trade_track_records すべて0行。校正ビューは 2026-02-10 のシード値で凍結。成果計測（mm_signal_reviews 2,382件）は全件 open でリターン充填0。
- 通知の一元ログは3経路とも機能不全（reg.notification_dispatch_log は0行、alert_events は列不一致で毎回 legacy フォールバック）。actionable 通知は実質0本。
- 到達率は健全（真の死蔵タスク約2%）だが capital-cost-tracker は書込先テーブルがDBに存在しない完全断裂。correlation_pairs 930万行が未読。
- 維持コストは「発散関数を成長停止で凍結中」（追加:修理比 5月78:1→7月0.16）。ゼロ件成功ソース 23→35→40 増加中。
- serving 握りつぶし層は git 上 fix=0（失敗が観測不能な Pattern B）。hotspot No.1 はスケジューラ3ファイル。

## 未修正の重大発見（着手時はレポートの P0/P1 表から）

- **確証済み計算バグ3件**: ①HV二重年率換算（volatility_regime がレジーム恒常バイアス）②コンセンサス改定率の fraction/percent 不一致（改定スコア50%死亡+大幅改定アラート発火不能）③ショート損切り符号逆転（exit_monitor/sizing_engine）
- **バックアップ実装ゼロ**: pg_dump を取るコードが1本もない（契約・チェッカだけ存在する「バックアップ演劇」）。判断ジャーナル・トレード記録が PC 全損で永久消失。作業ブランチ34コミットも未 push
- **EDINET 正規化が2026-02-20で凍結**（実測）: 下流の大量保有・取引先・供給網・発行体ファクトが4月中旬から連鎖停止。reg_llm_tagger も30日で525失敗+偽成功
- **ML/guardrail の空回り**: 特徴量4本NULL・PIT検査no-op・guardrail_gate_evaluator の供給テーブル不在で毎日P2誤報・学習未スケジュール
- **現ブランチの bat 破損**: `scripts/run_book_knowledge_load_weekly.bat:6` が `.\scriptsun_tool.ps1`（現物確認済み、1行修正）
- **baseline parity ゲートが現在FAIL**（head 20260709_04 vs 20260711_05）— マージ前に再生成必須
- スケジューラ WakeToRun ゼロ（スリープでタスクが飛ぶ）/ `set_rust_rollout_profile.ps1:215` が .env を BOM 付きで書き戻す地雷 / pytest-xdist 導入済み未配線（-n auto で半減）

## 監査手法の知見

- records_out=0 は upsert 再計算ツールでは正常。故障判定は「ingest ゼロ + 実テーブル鮮度」の突合必須
- 0行の表面テーブル（raw.prices_daily、public.consensus_estimates）は実体が別テーブル。鮮度SLA対象にすると誤検知
- pg_stat の live/dead は autovacuum 未実行の巨大テーブルで信用不可（実COUNT必須）。estat/EDINET系 100GB超×4本が autovacuum 一度も未実行
- 戦略文書⇔コードの数値突合は CI 保証なし（契約syncは構造のみ）。書籍原典照合台帳の追跡対象は約95%+一致で良質

関連: [[project-book-knowledge-integration-2026-07-11]] [[bugs-hot-table-ddl-lock-pileup]]
