---
name: project-edinet-extraction-corruption-fix-2026-06
description: EDINET→raw.financial_reports 抽出の3系統バグ修正と全データ再構築 (2026-06-19)。決算評価の数値正確性の根幹
metadata: 
  node_type: memory
  type: project
  originSessionId: 633a62b8-04f2-4ae6-84f4-5b287c7cc11b
---

# EDINET 抽出データ破損の根本修正 (2026-06-12〜19)

決算評価バッチで発見した 7203 不正行を精査 → `tools/market_data/financial_unifier/` の **3 つの系統的バグ**と判明。raw.financial_reports は raw.edinet_xbrl_facts_raw/contexts/documents から再構築可能な派生テーブルなので全削除+再抽出で修正。worklog: `docs/worklogs/20260612-edinet-extraction-corruption-fix.md`

## 3 系統バグ

1. **concept 誤マッピング (最重大)**: `concept_map.py` `resolve_concept` の **startswith マッチ**で `ProfitLoss` alias が 90+ の "ProfitLoss*" concept (非支配持分/税引前/非継続事業/セグメント/評価・売却損益) を net_income に誤マッチ。first-wins で 7203 純利益が非支配持分 246億 (正: 親会社株主帰属 4.77兆) に。全 metric で誤マッチ 3,047 件。**修正**: startswith 撤廃 (endswith のみ) + 除外ブロックリスト + `CONCEPT_PRIORITY` (親会社株主帰属 > 連結合計 > その他) を `edinet_extractor.py` 集約に導入
2. **期間/年度破損**: `_fiscal_period_from_context` が `fiscal_year=期間終端の暦年` (規約は FY=決算期末の年)。instant fact の提出日 fallback + Q4 仮定で bogus Q4 1,777 件。集約キーに doc_id 無く複数文書/コンテキスト混合 (フランケン)。**修正**: doc_type {120/140/160} 限定 + context_id 完全一致ホワイトリスト (CurrentYearDuration/CurrentYTDDuration/CurrentYearInstant/CurrentQuarterInstant) + doc 単位集約 (代表 120>160>140) + `_load_fiscal_year_end_months` (J-Quants Q4 行から決算期末月導出、4,555銘柄) + sanity ガード 11 種
3. **予想値の実績混入**: monex_writer が bogus FY アンカーで進行中年度の年次予想を実績分類。**修正**: アンカー参照を健全化、再同期で actual/forecast 正しく分離

## サービング層防御 (恒久)
`vw_financials_unified` (db/greenfield_postgres/90_marts.sql edinet_rows CTE) に汚染除外 WHERE 3 条件 (period_end=announcement_date / period_start>period_end / 主要メトリクス全NULL)。alembic 20260613_03。旧コード再実行事故への最後の砦として恒久保持

## raw.financial_reports 再構築手順 (再利用可)
1. バックアップ: `CREATE TABLE raw.financial_reports_<src>_bak_<date> AS SELECT * WHERE source_id=N` + 件数一致確認
2. `DELETE FROM raw.financial_reports WHERE source_id=N`
3. `extract-edinet --since 2000-01-01` (★ --since 必須: 無いと ingest watermark で facts 全 skip)
4. `sync-jquants` (FY アンカー鮮度) → monex 削除 → `sync-monex` (アンカー健全後)
5. `normalize-facts --truncate` → `resolve-facts --truncate` (fiscal_period 全面変更時)
6. 検証: check-conflicts --summary / financial_facts_outlier_audit / golden check / consensus compare

## 成果 (Before→After)
conflict total 73,754→27,212。gt_10pct: 売上 18,804→364 / 営業利益 31,267→387 / 純利益 35,344→548 / EPS 36,092→222 (98-99%減)。outlier critical 3,697→23、balance_identity_violation 3,633→0、unit_magnitude 2,478→17。fy/q 不一致 33,118→276。7203 偽サプライズ -51.5% 解消

## 回帰事例 (2026-07-04 修正済)
startswith 撤廃の副作用で **BS 系 IFRS variant が解決不能に**: `CashAndCashEquivalentsIFRS` / `ShortTermBorrowingsIFRS` が明示列挙に無く resolve_concept が None → BFF の貸借対照表ラベル/metric 分類が退化 (test_serving_repository の BS detail テストで検出)。IFRS suffix は endswith マッチ不能なので**新 concept 追加時は IFRS variant (+IFRSSummaryOfBusinessResults) を必ず明示列挙**すること。_EQUITY_CONCEPTS が手本 (EquityIFRS 列挙済みだった)。

## 残課題
- source_id: jquants=1 / edinet_xbrl=2 / monex_scouter=623 (core.source_catalog)
- 巨大売上×極小純利益 63 件は大半が薄利小売 (8267 イオン 0.3%) の正常値。6800 FY2019 売上54兆等の個別外れ値は outlier audit 継続監視
- fy_end_month_conflict 13,068 件 = 決算期変更銘柄の安全 skip (カバレッジ軽微欠損)
- バックアップ raw.financial_reports_{edinet,monex}_bak_20260612 は当面保持、不要確認後 drop
- git commit 未実施 (worktree に並行セッション変更混在)
- 関連: [[project-earnings-evaluation-batch-2026-06]] の「7203 不正行」がこの調査の起点
