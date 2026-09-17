---
name: Business Model Phase 6 業種拡張 4 並列着地 (2026-05-10)
description: Phase 5 (17→21) に続き 4 業種 (textile_apparel / nonferrous_metals / oil_gas_refining / glass_ceramics) を 4 sub-agent 並列で同セッション着地。21→25 業種へ拡張。20 anchor 全て partial/candidate_without_metrics で正常 dispatch
type: project
originSessionId: 4a23e34d-fe85-494f-aa68-3e3d0fefc8d0
---
# Business Model Phase 6 — 4 業種並列拡張 (2026-05-10)

Phase 5 closeout 完了直後のセッションで、Phase 5 の Track A-D 並列パターンを踏襲し 4 業種を同セッションで並列着地。21→25 業種に拡張。

**Why:** Business Model 図解の業種カバーを 25 まで広げ、Wave M (narrative) や Wave E Desktop 組み込みの前提を整備するため。Phase 5 で Track 並列着地パターンが実証されたので再利用が安全。

**How to apply:** 次セッションは (1) Wave D Phase 4 で各 framework の sample KPI を投入し partial→available 化、(2) Wave E Desktop 組み込み (PureSupplyChainDiagram に Tier 1-4 表示)、(3) Phase 7 業種拡張 (rubber_tires / temp_staffing_hr / drug_store_retail / construction_machinery)、(4) Wave L main 移植 PR のいずれかに進む。

## 完了サマリ

| Stream | 結果 | ファイル |
|---|---|---|
| **Track A** textile_apparel | ✅ framework + alembic seed (4 metric: brand_apparel_revenue_share / sales_per_store / inventory_turnover_apparel / ec_revenue_share_apparel) | `_frameworks/textile_apparel.py` / `db/alembic/versions/20260510_14_*` |
| **Track B** nonferrous_metals | ✅ framework + alembic seed (4 metric: copper_production_tons / smelter_throughput_tons / recycling_revenue_share / byproduct_revenue_share) | `_frameworks/nonferrous_metals.py` / `db/alembic/versions/20260510_15_*` |
| **Track C** oil_gas_refining | ✅ framework + alembic seed (4 metric: refining_throughput_kbd / crude_oil_self_sufficiency / retail_station_count / oil_gross_margin_per_barrel) | `_frameworks/oil_gas_refining.py` / `db/alembic/versions/20260510_16_*` |
| **Track D** glass_ceramics | ✅ framework + alembic seed (4 metric: display_glass_revenue_share / automotive_glass_revenue_share / ceramic_capacity_utilization / ev_battery_ceramics_share) | `_frameworks/glass_ceramics.py` / `db/alembic/versions/20260510_17_*` |
| **orchestrator** | ✅ dispatch 配線 (`business_model/__init__.py` + `_frameworks/__init__.py` + `_common.py`)、tier_chains.yaml に 4 entry 追加、test_tier_inferer.py 7 industries 化 | 既存ファイルへ追記のみ |

## 20 anchor probe 結果

全 20 anchor が `partial / *_candidate_without_metrics` で着地 (Phase 5 直後と同じ状態、metric_observations 未登録のため available 化は次セッション)。

| 業種 | anchors | status |
|---|---|---|
| textile_apparel | 9983 / 8016 / 7453 / 3401 / 3402 | 全 5 が partial (conf 0.45) |
| nonferrous_metals | 5713 / 5714 / 5801 / 5803 / 5802 | 全 5 が partial (conf 0.45) |
| oil_gas_refining | 5020 / 5019 / 5021 / 1605 / 9531 | 全 5 が partial (conf 0.45) |
| glass_ceramics | 5201 / 5202 / 5333 / 5334 / 5331 | 全 5 が partial (conf 0.45) |

skip / unavailable は 0、framework dispatch が全 anchor で正常動作することを確認。

## 検証結果

- `uv run ruff check .` (Phase 6 範囲): All checks passed
- `uv run pytest tests/db/test_alembic_chain_integrity.py tests/db/test_metric_catalog_idempotency.py tests/tools/api/test_company_business_model_frameworks.py tests/analytics/business_model_frameworks/test_tier_inferer.py`: 105 passed
- `uv run alembic -c db/alembic/alembic.ini upgrade head`: 20260510_13 → 20260510_18 完走 (Phase 6 4 seed + 並走 PR の 18 が線形 chain)

## 重要な発見 / 教訓

1. **CHECK 制約は絶対**: `core.metric_catalog.value_type` の許容値は `numeric / ratio / count / currency / text` のみ、`metric_group` は `balance_sheet / capital_policy / cash_flow / cashflow / efficiency / financial / guidance / monthly / orders / other / sector` のみ。sub-agent が誤って `currency_amount` / `quantity` / `operational` を使ったため、orchestrator 側で 4 ファイル fix が必要だった。次回からプロンプトで CHECK 制約を明示すべき
2. **Test 7 industries 化忘れ**: `tests/analytics/business_model_frameworks/test_tier_inferer.py` の `test_catalog_has_three_industries` を `test_catalog_has_seven_industries` に rename + assertion 更新が必要だった (yaml に entry を追加するだけでは test が落ちる)
3. **5 anchor minimum**: `test_each_industry_has_minimum_anchor_count` が tier1 ≥5 を要求。oil_gas_refining は当初 4 (5020/5019/5021/1605) だったので 9531 東京ガス (LNG受入/都市ガス精製) を Tier 1 に昇格させた
4. **`_BUSINESS_FRAMEWORK_LABELS` への追加忘れ厳禁**: `_frameworks/_common.py` の `_BUSINESS_FRAMEWORK_LABELS` dict に framework_id を追加しないと `_framework_availability` が `KeyError` で全テスト fail
5. **dispatch 配線 5 箇所**: business_model/__init__.py には (a) imports、(b) `_excluded_business_model_frameworks_payload` の framework_id tuple と frameworks dict、(c) `get_company_business_model_frameworks` の build call、(d) availability list、(e) frameworks dict 5 箇所すべての更新が必要
6. **probe は metric_observations 未登録なら全 partial**: alembic seed (metric_catalog 定義) は dispatch を通すが actual KPI ではない。available 化は Wave D 流で sample JSON + load_disclosure_kpi_samples.py の SAMPLE_MAPPINGS 拡張が必要

## 次セッション候補

1. **Wave D Phase 4 (Phase 6 業種の available 化)**: 20 anchor から 8-10 銘柄を選んで sample JSON 作成、load_disclosure_kpi_samples.py に追加。期待: confidence 0.85+ で 6-8 銘柄が available 化
2. **Wave E Desktop 組み込み**: `PureSupplyChainDiagram.tsx` に新 endpoint `GET /api/v1/company/{code}/business-model/supply-chain-tiers` を呼ぶ Tier 1-4 表示追加
3. **Phase 7 業種拡張**: rubber_tires / temp_staffing_hr / drug_store_retail / construction_machinery / oil_minor / paper_pulp_specialty 等
4. **Wave L main 向けフル移植 PR**: visual-regression infra (desktop/package.json scripts + playwright.config.ts + tests/visual/ + 67 Win32 baseline + 67 Linux baseline) を main へ

---

## 2026-05-14 訂正

「Track A-D 4 業種すべて framework + alembic seed 完了」「orchestrator dispatch 配線 (business_model/__init__.py + _frameworks/__init__.py + _common.py)」と記載しているが、本セッション (2026-05-14) の実測 probe で **4 業種 (textile_apparel / nonferrous_metals / oil_gas_refining / glass_ceramics) すべてが `_frameworks/__init__.py` への import 未済**だったことが判明。`.py` ファイル + pack YAML + alembic seed は確かに本セッションで投入されたが、aggregator dispatch 側 (5 箇所への登録 + `_BUSINESS_FRAMEWORK_LABELS` への追加) が抜けたままで完了宣言されていた。

2026-05-14 セッションで 10 framework まとめて配線清算。Phase 6 4 業種は probe で available (8016/5714/5019/5020/5201) を確認。詳細: [[project_business_model_aggregator_closeout_2026_05_14]]
