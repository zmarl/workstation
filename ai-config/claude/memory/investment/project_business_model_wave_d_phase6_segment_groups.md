---
name: project_business_model_wave_d_phase6_segment_groups
description: Wave D Phase 6 着地 (2026-05-10)。partial 5 銘柄に segment_financial_facts 投入で available 15/20 達成。新規 loader scripts/load_segment_facts_samples.py 作成
type: project
originSessionId: 931f2be9-f5be-4f1a-81ce-0e4df9e57462
---
# Wave D Phase 6 — segment_groups 拡張で partial → available (2026-05-10)

## 結果

20 anchor probe (matching framework 集計): **available 15/20 達成** (Wave D Phase 5 の 10/20 から +5)

### available 15/20 (Phase 5 から +5、★ が新規)
- 5108 ブリヂストン / 5110 住友ゴム (rubber_tires)
- 6098 リクルート HD / 2181 パーソル HD / 6089 ウィルグループ / **★ 2127 日本M&Aセンター** (temp_staffing_hr)
- 3088 マツキヨココカラ / 9989 サンドラッグ / 9627 アイン HD / **★ 3391 ツルハ HD** / **★ 7649 スギ HD** (drug_store_retail)
- 6305 日立建機 / 6326 クボタ / **★ 6301 コマツ** / **★ 6310 井関農機** (construction_machinery)

### partial 1/20
- 5101 横浜ゴム (Phase 5 残、1 metric のみ)

### unavailable 3/20
- 5191 住友理工 / 2412 ベネフィット・ワン (surface 除外、別 issue)
- 5105 TOYO TIRE (IR 該当数値なし、Phase 5 skip)

### skip 1/20
- 6473 ジェイテクト (建機 metric 不適合、Phase 5 skip)

## 実装サマリー

### 新規 loader (`scripts/load_segment_facts_samples.py`、~340 LOC)

Wave D Phase 5 の `load_disclosure_kpi_samples.py` と同 pattern。
- `core.segment_catalog` upsert (SELECT-then-INSERT、historical duplicates 対応)
- `core.segment_financial_facts` ON CONFLICT DO UPDATE on (instrument_id, segment_id, fiscal_period, metric_name)
- `selected_source_id` は既存 `business_model_segment_backfill_official` (source_id=650, T1) を再利用 → 新規 source 追加不要
- dry-run 時 rollback、本 load 時 commit
- JSON schema 簡易 validation (code/segments/facts 必須、metric_name enum、confidence >= 0.85)

### 4 並列 Stream (3 IR + 1 loader)

各 IR Stream が IR 公開資料 (有報セグメント情報 / 決算短信 / 決算説明資料) から segment_name + revenue (+ operating_income) を抽出。loader と並列で進行し、orchestrator が dry-run + 本 load + probe で merge。

### 5 銘柄の IR 開示の特徴

- **2127 日本M&Aセンター**: IFRS 単一報告セグメント (M&A コンサルティング事業) のため、決算短信 p.14「収益認識関係 顧客との契約から生じる収益を分解した情報」の **5 区分** を segment 化。サービス区分別 operating_income は非開示
- **3391 ツルハ HD**: 単一報告セグメントのため、商品グループ別販売実績 6 区分を採用。子会社別 (くすりの福太郎 / レデイ薬局 等) は IR 非開示で取得不可
- **7649 スギ HD**: ドラッグストア・調剤事業の単一報告セグメント。決算説明資料の商品セグメント別実績 6 区分を採用。物販 4 カテゴリは構成比 × 通期売上で按分 (confidence 0.85)
- **6301 コマツ**: 報告セグメント 3 種 (建設機械・車両 / リテールファイナンス / 産業機械他) を decimal 短信から取得。3 segment × 3 metric = 9 facts (revenue / external_customer_revenue / operating_income)。confidence 0.97
- **6310 井関農機**: 単一報告セグメント (農業関連事業) のため、決算短信「品目別の販売状況」5 区分を採用。**国内/海外を合算**して品目軸で BFF kind 分類の geographic 誤判定を回避

## 重要な学び (memory 用)

- segment_groups は metric_observations と完全独立な build path。metric 投入だけでは available 化しない。`core.segment_catalog` + `core.segment_financial_facts` への populate が必須
- BFF の `_get_company_overview_segments()` (overview.py L1085-1209) は `core.segment_financial_facts` から最新 fiscal_period の segment 行を集計し、`_classify_company_overview_segment_group_kind` で business / geographic kind 判定
- segment_name の主部に「国内」「海外」「Domestic」 等 geographic token を多用すると BFF で geographic 寄りに分類され business kind が立たないリスク → 機能名 (商品 / 事業 / サービス) を主部に
- 単一セグメント企業 (IFRS 単一報告セグメント) の対処パターン:
  - **収益分解情報** (IFRS 15 顧客との契約から生じる収益、有報注記)
  - **商品グループ別販売実績** (決算短信、決算説明資料)
  - **品目別販売状況** (短信注記)
  - これらは正式な「報告セグメント」ではないが、ビジネスモデル理解に有用な business kind segment として投入可能
- segment_extractor (`tools/market_data/financial_unifier/segment_extractor.py`) は EDINET XBRL `_SEGMENT_AXIS_KEYS` (4 種) で抽出。canonical axis を持たない銘柄は処理されないため、IR 手動投入が必要
- source `business_model_segment_backfill_official` (source_id=650, T1) は予め greenfield seed に登録済み。新規 INSERT 不要

## ファイル

### 新規作成
- `scripts/load_segment_facts_samples.py` (loader CLI)
- `tools/analytics/business_model_segments/__init__.py`
- `tools/analytics/business_model_segments/samples/official/README.md`
- `tools/analytics/business_model_segments/samples/official/2127_nihon_ma_segments_2025q3.json`
- `tools/analytics/business_model_segments/samples/official/3391_tsuruha_segments_2025q3.json`
- `tools/analytics/business_model_segments/samples/official/7649_sugi_segments_2025q3.json`
- `tools/analytics/business_model_segments/samples/official/6301_komatsu_segments_2025q3.json`
- `tools/analytics/business_model_segments/samples/official/6310_iseki_segments_2025q3.json`
- `docs/worklogs/20260510-business-model-wave-d-phase6-segment-groups.md`

## 別 issue 化 (本フェーズ範囲外)

- **6301 コマツの segment_extractor 不具合**: EDINET XBRL に Segment dimension (canonical `jpcrp_cor:OperatingSegmentsAxis`) 126 facts あるが、segment_extractor が 0 件しか processing していない。原因: extractor が XBRL の dimension qname を正しく拾うものの、別 ETL job (segment_extractor の実行 trigger) が動いていない or filter 条件で除外されている可能性。本フェーズは sample 投入で着地し、原因調査は別 issue
- 5191 / 2412 surface 除外 (Phase 5 から繰越)
- 5101 横浜ゴム / 5105 TOYO TIRE の追加 metric 取得 (Phase 5 から繰越)
