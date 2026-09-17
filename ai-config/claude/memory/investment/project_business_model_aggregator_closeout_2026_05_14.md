---
name: business-model-aggregator-closeout-2026-05-14
description: "Phase 5/6/7 で aggregator catalog (_frameworks/__init__.py + business_model/__init__.py 5 箇所) に未登録だった 10 framework_key を本セッションで完全配線し、`framework_key_missing` ゼロを probe 実測で達成。catalog audit script を新設して再発防止"
metadata: 
  node_type: memory
  type: project
  originSessionId: 6eb00d19-3aa6-4f86-8944-883491395f36
---

# Business Model aggregator catalog 完全清算 (2026-05-14)

## 着地サマリ

[[project_business_model_aggregator_catalog_gap]] で記録した 10 framework の登録漏れを全て解消。

**配線対象 (10 件)** — いずれも `.py` ファイル + pack YAML は既存だが `_frameworks/__init__.py` 未 import 状態だった:

| Phase 由来 | framework_key | probe 実測 (代表 anchor) |
|---|---|---|
| Phase 5 | industrial_conglomerate | 6501 Hitachi → available 0.85 |
| Phase 5 | advertising_holding | 4324 Dentsu → available 0.85 |
| Phase 6 | textile_apparel | 8016 Onward → available 0.85 |
| Phase 6 | nonferrous_metals | 5714 DOWA → available 0.7 |
| Phase 6 | oil_gas_refining | 5019 / 5020 → available 0.7 |
| Phase 6 | glass_ceramics | 5201 AGC → available 0.7 |
| Phase 7 | rubber_tires | 5108 Bridgestone → available 0.85 |
| Phase 7 | temp_staffing_hr | 6089 / 2127 / 2181 / 6098 → available 0.7-0.85 |
| Phase 7 | drug_store_retail | 3088 / 3391 / 9989 / 7649 / 9627 → 全て available 0.85 |
| Phase 7 | construction_machinery | 6301 / 6305 → available 0.85, 6310 / 6326 → 0.7 |

## 変更ファイル (S1 配線)

1. `tools/api/decision_api/serving/company/business_model/_frameworks/_common.py` — `_BUSINESS_FRAMEWORK_LABELS` に 10 件追加
2. `tools/api/decision_api/serving/company/business_model/_frameworks/__init__.py` — 10 framework の `_build_*` / `_KEYWORDS` / `_METRIC_ALIASES` / `_find_*` を alphabetical 順で import
3. `tools/api/decision_api/serving/company/business_model/__init__.py` — 上位 aggregator dispatch の 5 箇所
   - imports (Top of-file import-from-local block)
   - `_excluded_business_model_frameworks_payload` の framework_id tuple
   - `get_company_business_model_frameworks` 内の `_build_*_framework(...)` 呼び出し 10 件
   - `availability = [...]` に `_framework_availability(...)` 10 件追加
   - return dict の `frameworks` 内に 10 key 追加

## 検証

- `uv run ruff check tools/api/decision_api/` → clean
- `uv run pytest tests/tools/api/test_business_model_*` → 167 passed
- probe 実測 (Phase 5-7 全 anchor) → `framework_key_missing` 完全ゼロ達成
- `tools/quality/business_model_catalog_audit/main.py` (S3 新設) を実行 → `orphan_samples = 0`

## audit script の継続出力 (参考)

新設した audit script は `empty_frameworks = 16` を報告するが、これは「SAMPLE_MAPPINGS に明示登録のない framework」を意味し、実態 (probe で available になっている Phase 6/7 framework) と乖離する false positive を含む。Phase 6/7 anchor は別経路 (`samples/official/` 直 load) で投入済みなので、SAMPLE_MAPPINGS の Phase 6/7 拡張は別 issue 推奨 (audit script の改善 issue としても扱える)。

`dispatcher_unused = 19` は `_frameworks/` 配下の他 framework (agribusiness / aquaculture / aviation_airport / building_materials / chemical_specialty / consumer_food / electronic_components / general_construction / home_appliances / insurance / media_broadcasting / medical_device / parcel_delivery / real_estate_developer / real_estate_securitization / securities_brokerage / semiconductor_equipment / specialty_retail / steel_materials) で、本セッションスコープ外。次の Phase で必要に応じて配線。

## A-2 KPI 補完 (skip 判断)

ad_supported pack (4751/2433/9449) の confidence 引き上げは A-1 配線だけで 4324 Dentsu (advertising_holding) が available 0.85 達成したため、本セッションでは「サービス側 3 銘柄の cpm/cpc/impressions/dau/mau 追加」は skip 判断。理由:
- CyberAgent / Hakuhodo / GMO の連結 IR では B2B プロダクト KPI (CPM/CPC/impressions) は通常非開示
- IR ページが動的 JS で WebFetch から PDF 取得できない (CyberAgent ライブラリページ確認済)
- 別 issue で pack 設計見直し (DAU/MAU 等の補助 KPI を主軸にするかどうか) と一緒に検討する方が ROI 高い

## 6920 Lasertec (skip 確定)

semiconductor pack partial 0.45 のまま据え置き。装置メーカー特性で IR が CPM/装置売上分解を非開示。別 issue でも pack 設計見直しが必要。

## How to apply

- 次回 framework 追加時は **「sample JSON 投入と aggregator catalog 登録の両方を同 PR で完結」** を厳守 (Phase 5/6/7 で 3 回連続で抜けたパターン)
- 週次 or PR ガードで `tools/quality/business_model_catalog_audit/main.py --strict` を走らせて orphan_sample を即時検出
- `_BUSINESS_FRAMEWORK_LABELS` への label 追加と `_excluded_business_model_frameworks_payload` の tuple 拡張は **5 箇所 + 1 箇所 = 6 箇所** が必要 (1 つでも抜けると runtime KeyError か silent skip)

## 関連

- [[project_business_model_aggregator_catalog_gap]] — 根本原因記録 (本セッションで解消)
- [[project_business_model_phase5_closeout_2026_05_10]] — Phase 5 (2 framework 漏れ)
- [[project_business_model_phase6_2026_05_10]] — Phase 6 (4 framework 漏れ)
- [[project_business_model_phase7_2026_05_10]] — Phase 7 (4 framework 漏れ)
- [[feedback_disclosure_kpi_loader_mapping]] — SAMPLE_MAPPINGS 追随 (関連)
- worklog: `docs/worklogs/20260514-business-model-aggregator-cleanup.md` (本セッション)
