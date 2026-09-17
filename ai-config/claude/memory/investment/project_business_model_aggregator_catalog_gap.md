---
name: business-model-aggregator-catalog-gap
description: Business Model 図解で「sample 投入」と「aggregator framework_key 登録」の 2 ステップが分離しており、後者が Phase 5/6/7 で繰り返し抜けている根本問題。probe 結果を memory に書く前に framework_key 登録状況を確認する手順を確立する必要あり
metadata: 
  node_type: memory
  type: project
  originSessionId: f14e4017-4392-4665-a7d8-7d59acf18864
---

# Business Model aggregator catalog gap (2026-05-14 発見)

## 何が起きているか

Business Model 図解の業種拡張は、以下の 2 ステップを必要とする:

1. **Sample 投入**: `tools/analytics/<extractor>/samples/official/<code>_<issuer>_<period>.json` を作成し、`scripts/load_disclosure_kpi_samples.py` の SAMPLE_MAPPINGS に追加して loader 実行 → DB に metric_observations を投入
2. **Aggregator framework 登録**: `tools/analytics/business_model_frameworks/` 配下の catalog/dispatcher に framework_key を登録 + 必須 metric_keys セットを定義

**問題**: Phase 5 / Phase 6 / Phase 7 で「(1) Sample 投入は完了したが (2) framework 登録は未着手」のまま完了宣言 + memory 記録されているケースが複数ある。

## 確認された未登録 framework (2026-05-14 probe 時点)

| Phase | framework_key | 状況 |
|---|---|---|
| Phase 5 | industrial_conglomerate | 未登録 (6501 Hitachi sample 投入済み、framework 未) |
| Phase 5 | advertising_holding | 未確認 (4324 Dentsu sample 投入済み) |
| Phase 7 | rubber_tires | 未登録 (5108/5101/5110/5105 sample 投入済み) |
| Phase 7 | temp_staffing_hr | 未登録 (6098/2181/2127/6089 sample 投入済み) |
| Phase 7 | drug_store_retail | 未登録 (3088/3391/7649/9989/9627 sample 投入済み) |
| Phase 7 | construction_machinery | 未登録 (6301/6305/6326/6310/6473 sample 投入済み) |

aggregator 登録済み 20 framework_key: ad_supported / auto_oem / automotive_parts / bank / ec_marketplace / electric_unbundling / five_forces / gaming_entertainment / j_reit / leasing_consumer_finance / logistics_hub / pharma_rd / platform_marketplace / precision_optics / saas_metrics / semiconductor / shipping_fleet / telecom / trading_house / value_chain

## Why (なぜ繰り返されるか)

- 各 Phase で複数並列 agent を起動して分担した結果、「sample loader を担当した agent」と「aggregator catalog を担当した agent」が別で、後者が落ちることがあった可能性
- probe 結果で `framework_key_missing` が出ていても、過去の memory には partial / available として書かれているケースが見られる (実測ログとの突合がされていなかった)

## How to apply (今後の運用)

1. **業種追加 PR では必ず「probe で当該 framework_key が出ること」を merge 条件にする**
2. memory に「N/M available」と書く前に **必ず probe を実走**して結果を含める
3. `framework_key_missing` の reason は「sample 不足」ではなく **「aggregator catalog 未登録」を意味する**ので、この理由が出たら sample loader を弄る前に aggregator 側を確認する
4. 関連: [[project_business_model_phase5_closeout_2026_05_10]] [[project_business_model_phase7_2026_05_10]]

## 残タスク (新規 issue 候補)

- [Phase 5+] industrial_conglomerate / advertising_holding framework 登録 + 必須 metric セット定義
- [Phase 8] rubber_tires / temp_staffing_hr / drug_store_retail / construction_machinery framework 登録 + 必須 metric セット定義
- [全体] memory `project_business_model_*` 系の他ファイルでも同様の事実誤認がないか棚卸し (Phase 6 / Wave D Phase 6 segment_groups なども再 probe で確認)
- [監査] aggregator catalog と sample 投入状況を突合する audit script を作成 (今回のような乖離を防止)

## 詳細実測ログ

`docs/worklogs/20260514-business-model-residuals-completion.md`

---

## 2026-05-14 解消

本ファイルに記録した 10 framework_key 登録漏れ (industrial_conglomerate / advertising_holding / rubber_tires / temp_staffing_hr / drug_store_retail / construction_machinery + Phase 6 由来 textile_apparel / nonferrous_metals / oil_gas_refining / glass_ceramics) を本セッションで完全清算。probe 実測で `framework_key_missing` ゼロ、新設 audit script で `orphan_samples = 0` を確認。

詳細: [[project_business_model_aggregator_closeout_2026_05_14]]
worklog: `docs/worklogs/20260514-business-model-aggregator-cleanup.md`
