---
name: project_business_model_wave_d_phase6_followups
description: Wave D Phase 6 残課題清算 (2026-05-10)。20→19 anchor 母集団に再定義し available 16/19 達成。5191/2412/6301 を構造的別 issue に分離
type: project
originSessionId: e7f8582c-9381-4c94-9b94-c625210573ed
---
# Wave D Phase 6 followups — 4 並列 Track 清算 (2026-05-10)

## 結果

母集団: 20 anchor → **19 anchor 再定義** (2412 ベネフィット・ワン上場廃止確定で除外)

available: Phase 6 の 15/20 → 本フェーズ完了時点 **16/19** (84%)

| Track | 寄与 | 確定事項 |
|-------|------|---------|
| A 5101+5105 metric 追加 | +1 (5101) | 5105 は IR 開示構造的制約で skip 維持 |
| B 5191 surface 除外 | +0 | core.instruments 市場再編 master 同期不全 (713 件影響) で別 issue 化 |
| C 2412 上場ステータス | +0 | TOB 完了で上場廃止確定、母集団 19 化 |
| D 6301 segment_extractor | +0 | コード bug ではなく Komatsu の EDINET XBRL 仕様 (workforce-only)。修正不要 |

## Track 別詳細

### Track A: +1 available (5101 横浜ゴム)

- 既存 5101 (`tire_production_units` 955千トン, 2023年度) を維持しつつ `tire_raw_material_cost_index` を追加
- value: ▲26 億円 (2024年通期事業利益への原材料コスト変動額。天然ゴム▲29 + 合成ゴム▲31 + 配合剤+8 + その他+26)
- ソース: 横浜ゴム 2024年度決算説明会資料 (`24_4Qmanagement.pdf`, 2025-02-19) p.6
- 5110 住友ゴム JSON と同一の運用パターン (前期比事業利益 delta) に揃え、confidence 0.85
- 5101 status: partial (1 metric) → **available (2 metric)**

5105 TOYO TIRE は短信のセグメント情報が「タイヤ事業 519,832百万円」「自動車部品事業 45,526百万円」のみで OE/REP 売上分解なし。統合報告書 p9 At a Glance も地域別構成比のみ (OE/REP 内訳混在)、サステナブル原材料比率 40% は metric_keys の `tire_raw_material_cost_index` (コスト delta) には充当不可。捏造禁止のため Phase 5 の skip 判断を維持。

### Track B: +0 (5191 別 issue 化)

`core.instruments` で 5191 は `market='東証一部'` (旧表記) かつ `is_active=False`。市場再編 (2022-04) の master 同期不全による構造的バグ。同根ケースが **713 件** (東証一部 362 / 東証二部 121 / マザーズ 49 / JASDAQ スタンダード 171 / JASDAQ グロース 10) 残存。1 行 UPDATE で副作用ゼロを確認できないため Plan 禁止事項に抵触。memory `bugs_core_instruments_market_reform_stale.md` に詳細記録。

### Track C: +0 / 母集団 19 化 (2412 上場廃止確定)

`core.instruments` で 2412 は `is_active=False`、`main.stocks` 行不在。2024 年第一生命 HD TOB 完了による上場廃止と整合。anchor 母集団から恒久除外し N=19 として可用率を再計算。probe スクリプト改修不要、集計説明変更のみ。

### Track D: +0 (6301 EDINET XBRL outlier、修正不要)

sec_code 形式 mismatch 仮説を read-only SQL で棄却 (raw/core 共に 4 桁固定)。真因は Komatsu の EDINET XBRL に segment 別 revenue/operating income が含まれないこと (`OperatingSegmentsAxis` ヒット 126 件はすべて NumberOfEmployees / CapitalExpenditures / R&D 系で `_SEGMENT_METRIC_MAP` 対象外、`NetSales`/`OperatingIncome` 16 件は全件 `NonConsolidatedMember` で `_parse_segment_from_dimension` が正しく除外)。USGAAP ベース開示の outlier。Phase 6 の official sample 経路が正解。memory `bugs_segment_extractor_6301_komatsu.md` 参照。

## 残 unavailable (本フェーズ完了時点)

- 5105 TOYO TIRE (rubber_tires): IR 開示の構造的制約 (skip 維持)
- 5191 住友理工 (rubber_tires): market 再編 master 同期不全 (別 issue)
- skip: 6473 ジェイテクト (建機 metric 不適合、Phase 5 から継続)

## 修正ファイル

- `tools/analytics/disclosure_kpi_extractor/samples/official/5101_yokohama_2025q3.json` (metric 1 件追加)
- `scripts/load_disclosure_kpi_samples.py` (Track A コメント追記のみ、SAMPLE_MAPPINGS 5101 既登録)
- `docs/worklogs/20260510-business-model-wave-d-phase6-followups.md` (新規)

## 別 issue 化した課題

1. **core.instruments 市場再編 master 同期** (Track B 起源、713 件影響): JPX 公式銘柄 list との突合パイプライン設計、master 更新の所在特定
2. **segment_extractor 本走化** (Track D 起源): run_manifest.yaml 登録 + source_priority_rules 整備で Phase 6 official sample (T1) と edinet_xbrl (T3〜) の優先度確定
3. **5105 TOYO TIRE の rubber_tires metric 充当**: 捏造禁止下では IR 開示の構造変化 (例: 短信での OE/REP 内訳開示) 待ち

## Phase 7 以降の優先度

- 別 issue 1 が解消すれば 5191 復活 + Track A pattern で metric 投入 → +1 available 余地
- 別 issue 2 は segment_extractor の cron 起動でデータ品質向上、ただし official sample との衝突回避が前提
