# 6301 コマツ segment_extractor 0 件 processing — not a bug

調査日: 2026-05-10 (Wave D Phase 6 followups Track D)

## 仮説 A (sec_code 形式 mismatch) は **棄却**

read-only SQL で確認:

- `raw.edinet_xbrl_facts_raw.sec_code` は 4 桁固定 (`6301`)。`length(sec_code), count(*)` 集計で **(4, 4435)** のみ
- `core.instruments.code` も 4 桁 (`6301`)
- `_preload_instrument_cache` lookup は MISS していない

つまり segment_extractor.py の `_preload_instrument_cache` 改修は不要。

## 真因: Komatsu の EDINET XBRL に segment 別 revenue/operating income が無い

`f.sec_code='6301' AND ctx.dimension_json LIKE '%OperatingSegmentsAxis%'` は **126 件**ヒットするが、内訳は:

| local_name | 件数 |
|------------|------|
| AverageNumberOfTemporaryWorkers | 48 |
| NumberOfEmployees | 48 |
| CapitalExpendituresOverviewOfCapitalExpendituresEtc | 18 |
| ResearchAndDevelopmentExpensesResearchAndDevelopmentActivities | 12 |

**いずれも `_SEGMENT_METRIC_MAP` に含まれない** (mapは revenue / orders / operating income 系のみ)。

一方 6301 の `NetSales` / `OperatingIncome` は 16 件存在するが、`dimension_json` は全件 `{"jppfs_cor:ConsolidatedOrNonConsolidatedAxis": "jppfs_cor:NonConsolidatedMember"}` で、`_parse_segment_from_dimension` が `NonConsolidatedMember` 検出時に None を返すロジック (L69) で正しく除外されている。

参考: 9446 / 2743 / 7518 等は `OperatingSegmentsAxis` で `NetSales`/`OperatingIncome` を持つ (1000 件規模) ので、コマツが outlier。Komatsu は USGAAP ベースで開示し segment 別 revenue は EDINET XBRL に **無い**。決算短信 (TDnet) または official sample 経由の取り込みが必要。

## 結論

- segment_extractor.py に **コード修正は不要**。126 → 0 は仕様通りの挙動
- Phase 6 の official sample (`selected_source_id=650 business_model_segment_backfill_official`) で 6301 を可視化する従来路線が正しい
- 横展開で他 anchor が segment_extractor で復活する可能性はあるが、Komatsu と同じ workforce-only 開示パターンの企業は手動 sample 経路が必須

## 残課題

- Phase 7 以降で segment_extractor を本走させる場合は source_priority_rules で official sample (T1) と `edinet_xbrl` (T3〜) の優先度を整備
- run_manifest.yaml への登録は本フェーズ対象外
