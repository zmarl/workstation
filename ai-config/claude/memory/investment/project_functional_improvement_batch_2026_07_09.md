---
name: project-functional-improvement-batch-2026-07-09
description: 機能完全改善バッチ (2026-07-09)。評価ロジック13+表示5+品質可視化5の一掃。worktree=Investment-funcfix、マージは本体静止待ち
metadata: 
  node_type: memory
  type: project
  originSessionId: 52564e5c-a636-473e-89e2-1a46f6025635
---

# 機能完全改善バッチ (2026-07-09, feat/functional-improvement-batch @ D:\Dev\Investment-funcfix)

3方向調査（評価ロジック/表示/データ品質）→ 4エージェント並列実装。コミット 13275ad2（61ファイル）。全検証 green（pytest 13,713 / desktop 2,416 / ruff / tsc / eslint / 予算ゲート）。

## 直した重大バグ（再発時の参照用）
- **CANSLIM が main.daily_prices(42営業日cache)で52週高値/200日MA/RS/breadth を計算**。実測乖離: トヨタ+17.2%・ソニー+28.3%（真の52週高値との差）。価格の長期計算は必ず mart.vw_price_daily_corporate_action_adjusted。
- **guidance_credibility 着地精度**: 通期予想 vs 四半期累計実績を fq 一致 JOIN → Q1-Q3 が常に「下振れD」。actuals fq=4 限定 + initial_guidance は FY 内最初の通期予想で解消。
- **capital_policy ROE−WACC**: ROE 分数格納(中央値0.076) vs WACC %単位 → spread 常時 -6pt≒全銘柄D。shared/units.py の ratio_to_percent で正規化。再計算後は median +2.5pt / 65%正。
- **earnings_event_evaluator**: 改定4指標全None → ("title_inference",0.0) で FINAL/ELIGIBLE/0.95 に化けていた。DB 上の該当60行（final/eligible×magnitudes無し×revision）は38件再評価+22件（候補喪失の過去イベント）直接SQL降格。
- **SectorDecisionMatrix**: desktop 型が industry_code、BFF 実体は sector_code → 右半分の列が全滅。BFF契約変更時は desktop/src/lib/types の突き合わせ必須。
- **mart.vw_reg_timeline は DB に存在しなかった**（serving は _query_optional_relation_rows が warning+[] に吸収）→ 規制タイムライン全粒度空。alembic 20260709_04 で新設（17業種91行、33/subは reg.regulation_industry_tags 0行のためNULL契約）。
- **execution_planner の注文照会3関数**が実在しない列（i.ticker/i.company_name/dp.close_price/instrument_id）参照で実行時 UndefinedColumn。core.instruments は code/name。

## 運用知見
- **凍結ファイルサイズ予算**: 凍結ファイルに加筆すると check_file_size_budget が fail。新ロジックは同パッケージの新モジュールへ（_loaders.py/_bdi.py/_acceptance.py 方式）。800行未満に縮んだ frozen エントリは baseline から行削除（--write-baseline 全体実行は並行変更を巻き込むので不可）。
- **earnings_quality_scorer は retired legacy**（CLI 廃止・本番の読み書き経路なし）。canonical は earnings_event_evaluator。decision.earnings_quality_scores(379行) のバックフィルは不要と判断。
- evaluate-event は `--scope-key` フラグ必須。過去イベントは候補喪失で再評価不能 → 安全側 SQL 降格 + quality_flags 追記（backfill_downgrade_20260709）。
- 並行セッション（同日 desktop 大改修中）と同一ブランチ共存: error-sweep 分だけパス指定 commit → worktree 分離。マージは本体コミット静止（>15分）を watcher で待つ。マージのテキスト衝突0でも、相手が SectorDecisionMatrixSection を新設しているため **semantic conflict（型名変更）検証に post-merge typecheck 必須**。

## handover（2026-07-09 深夜に消化済み）
- ~~本体静止後 merge~~ → **完了**: 本体コミット静止（>15分）を watcher で確認後 feat/hidden-asset-screener へ merge（16ce1193、衝突0）。post-merge の desktop typecheck / vitest 290件 / pytest 3,388件 全 green（相手側 SectorDecisionMatrixSection との semantic conflict なし）。worktree Investment-funcfix とブランチは削除済み。
- daily_screener の turnover 2箇所は SSOT exception のまま（view に turnover 列なし、フォローアップ課題）。
- earnings_quality の進捗率線形固定は TODO 残し（業種別データ駆動化は未実施）。
- VaR は union+ffill 化で翌営業日から系列拡大 → PF モード判定が変わり得る。

関連: [[project-error-sweep-2026-07-09]] [[feedback-parallel-session-worktree]] [[bugs-module-split-monkeypatch-binding]]
