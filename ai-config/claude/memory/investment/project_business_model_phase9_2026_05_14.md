---
name: project-business-model-phase9-2026-05-14
description: Business Model 図解 Phase 9 (2026-05-14) で 34 industry framework に anchor sample 投入、audit `empty_frameworks=37→3`、anchor probe `available 13/partial 20`。8 cluster general-purpose agent 並列で 1 セッション完走
metadata:
  type: project
  originSessionId: phase9
---

# Business Model 図解 Phase 9 (2026-05-14)

Phase 8 ([[project-business-model-phase8]]) で 58 framework に倍増させた業種カバレッジを「**フル稼働化**」する Stream A 着地。

## 着地サマリ

| 指標 | Phase 9 開始 | Phase 9 完了 |
|---|---|---|
| audit `empty_frameworks` | 37 | **3** (j_reit + value_chain + five_forces のみ) |
| audit `wired_and_seeded` | 22 | **56** (+34) |
| audit `framework_key_missing` | 0 | **0** (維持) |
| anchor probe `available` (新規 34 ペア) | 0 | **13** |
| anchor probe `partial` (新規 34 ペア) | 0 | **20** |

新規 available 化 13 銘柄: 2871 ニチレイ (agribusiness), 4452 花王 (cosmetics_toiletries), 5938 LIXIL (building_materials), 1801 大成建設 (general_construction), 5401 日本製鉄 (steel_materials), 4063 信越化学 (chemical_specialty conf=0.85), 7741 HOYA (precision_optics), 9143 SG ホールディングス (parcel_delivery), 9020 JR 東日本 (railway_passenger conf=0.85), 9531 東京ガス (gas_utility), 9843 ニトリ (specialty_retail conf=0.85), 4661 オリエンタルランド (entertainment_facilities), 9708 帝国ホテル (hospitality_lodging)

## マルチエージェント運用

8 cluster general-purpose agent を並列起動 (Phase 8 の 11 並列パターンを踏襲):
- C1 食品/農水 (4 framework) → 4 sample
- C2 建設/素材 (4 framework) → 4 sample
- C3 エレクトロ/精密 (5 framework) → 5 sample
- C4 医療/教育/SaaS/プラットフォーム/ゲーム (5 framework) → 5 sample
- C5 不動産/金融 (6 framework) → 6 sample
- C6 運輸/インフラ (4 framework) → 4 sample
- C7 メディア/サービス (4 framework) → 4 sample
- C8 外食/小売 (2 framework) → 2 sample

各 agent: anchor 銘柄選定 (TOPIX Core30/Large70/Mid400) + IR 取得 + sample JSON 作成 + diff snippet 返却。Coordinator が `SAMPLE_MAPPINGS` / `PACK_TO_FRAMEWORK_KEYS` を sequential merge。

## 変更ファイル

- `scripts/load_disclosure_kpi_samples.py` `SAMPLE_MAPPINGS` に 34 entry 追加
- `tools/quality/business_model_catalog_audit/auditor.py` `PACK_TO_FRAMEWORK_KEYS` に 28 entry 追加
- `tools/analytics/disclosure_kpi_extractor/packs/` に 12 新規 pack YAML
- `tools/analytics/disclosure_kpi_extractor/samples/official/` に 34 新規 sample JSON
- `db/alembic/versions/20260514_15_phase9_business_model_packs_metrics_catalog.py` 新規 (29 metric_key)
- `db/alembic/versions/20260514_16_phase9_supplementary_metrics_catalog.py` 新規 (12 metric_key)
- `tools/api/decision_api/serving/_utilities.py` `_COMPANY_DESCRIPTION_NOTE_RE` / `_COMPANY_DESCRIPTION_OTHER_COMPANIES_RE` 定数追加 (Phase 8 残課題解消、aggregator 経由 E2E probe 復旧)

## 重要な気づき

1. **Phase 8 残課題: 定数欠落** — `_COMPANY_DESCRIPTION_NOTE_RE` / `_COMPANY_DESCRIPTION_OTHER_COMPANIES_RE` が定義されていなかったため、aggregator 経由 probe 全体が失敗していた。Phase 9 Step 0 で発見・修正
2. **Pack YAML enum 制約** — disclosure_kpi_extractor の `--pack` 引数は `packs/` 配下の YAML から enum 構築。新 pack 投入には YAML 作成が必須
3. **metric_catalog 二重宣言禁止** — `tests/db/test_metric_catalog_idempotency.py::test_no_metric_key_seeded_by_multiple_revisions` で metric_key の 2 migration 重複は禁止 (digital_revenue_share / npl_ratio / store_count_total を Phase 9 migration から削除)
4. **partial 20 framework の真因** — metric_key が framework `_<KEY>_METRIC_ALIASES` の alias と完全一致していない。loader は受け入れるが aggregator の `_find_<KEY>_metrics()` でマッチせず metrics_count=0 → partial。Phase 9.5 で alignment 補正必要

## Phase 10 Stream B 着地 (2026-05-14 同セッション内)

5 群 general-purpose agent 並列で 37 industry panel 新規作成・dispatch 統合・TS 型エラーゼロ達成。

| 群 | panel 数 | 流用 template |
|---|---|---|
| G1 LayeredFlow | 8 | FoodValueChain / ChemicalMaterials / Construction / Steel / ElectricEquipment 等 |
| G2 HubSpoke | 8 | InsuranceThreeMargin / Securities / OtherFinancial / BankFundsFlow / GameF2PFlow / PetroleumEnergy / JReitSpecialized |
| G3 RadialCluster | 7 | Machinery / ElectricEquipment / RetailFranchise |
| G4 VerticalPyramid | 6 | PharmaRdStructure / FoodValueChain / HotelLeisure / ItServicesSaas / Airline |
| G5 Custom SVG | 8 | RealEstateDeveloper / LogisticsHub / RailwayNetwork / AutoOemPyramid / TextileFiber / TireRubber / OtherManufacturing / GameF2PFlow |

Coordinator が `BusinessModelCanvasView.tsx` の 3 site (imports / `BusinessModelTabId` 型 / `FrameworkBody` dispatch) に 37 entry を bulk merge。`npx tsc --noEmit` で Phase 10 関連エラー 0。

## 残課題 (繰越)

1. **Phase 9.5 metric_key alignment** — 20 partial framework の `_<KEY>_METRIC_ALIASES` と sample JSON の metric_key を厳密一致化
2. **Phase 11 Stream C visual baseline** — `business-model-catalog-mock.ts` `CATALOG_ENTRIES` 拡張 + Playwright pixelmatch baseline 生成 (37 panel × 3 状態 × 2 platform = 222 PNG)
3. **types/company.ts 型拡張** — `CompanyBusinessModelFrameworksResponse.frameworks` interface に 37 新 framework_key を追加 (現状 `as Record<string, unknown>` cast で迂回)
4. **9783 ベネッセ framework_key_missing** — aggregator が education_services を返さず。銘柄側メタデータ問題 (instrument scope?)、別 issue

## 検証

- `uv run ruff check` clean (新規 4 ファイル)
- `uv run pytest tests/db/test_metric_catalog_idempotency.py` 38 passed
- audit `--strict --json` empty_frameworks=3
- probe (34 anchor × intended framework): available 13 / partial 20 / missing 1

詳細: `docs/worklogs/20260514-business-model-phase9.md`

## 関連
- [[project-business-model-phase8]] — 58 framework 配線完了、本 Phase の前提
- [[project-business-model-aggregator-closeout-2026-05-14]] — framework_key_missing ゼロ達成 (Phase 9 で維持)
- [[feedback-disclosure-kpi-loader-mapping]] — SAMPLE_MAPPINGS と pack YAML 同期の運用ルール
