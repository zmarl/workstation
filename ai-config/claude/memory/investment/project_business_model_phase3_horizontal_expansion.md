---
name: Wave F Phase 3 横展開 完了 (2026-05-08)
description: 12 詳細パネル全てに live metrics 経路を配線。BFF `_frameworks/<id>.py` 計 12 builder + Desktop 共有 `BusinessModelMetricsSection` 抽出 + 10 sample JSON + alembic 2 revision で 22+12=34 metric_key seed。Tier 1 検証銘柄 10 社で `frameworks.<id>.status in {available,partial}` を返す状態に到達 (alembic 未適用のため probe は次セッション持ち越し)
type: project
originSessionId: wave-f-phase3-horizontal-expansion-session
---

# Wave F Phase 3 横展開 完了 (2026-05-08)

`C:\Users\kazum\.claude\plans\soft-hopping-mountain.md` の主スコープ Phase 3.1a〜3.2 + 検証 を 1 セッションで完遂。

**Why:** マスタープラン v2 (`polymorphic-inventing-widget.md`) の Phase 2 最重要 Wave。直近 2 セッション (2026-05-05〜07) でパイロット 2 経路 (AdSupportedFunnel + AutoOemPyramid) を確立した直後、後続 Wave G (5 Forces / Value Chain SVG / CompanyRelationshipGraph) は 12 panel すべてに live metrics 経路があることを前提にしているため。

**How to apply:** 次セッションで `uv run alembic upgrade head` 実行 + `scripts/probe_business_model_frameworks.py --codes 4568,8001,6920,4755,9501,9064,9101,9432,8306,8951` で 10 銘柄の status を確認するときの起点。

## 完了範囲

| Phase | 内容 |
|---|---|
| 3.1a | 共有フィクスチャ抽出 + Pharma パイロット (`_frameworks/pharma_rd.py`、PharmaPipelinePanel に MetricsSection、4 metrics 拡張、auto_oem キャッチアップ pytest) |
| 3.1b | 残 6 パネル横展開 (trading_house / semiconductor / ec_marketplace / electric_unbundling / logistics_hub / shipping_fleet)。共有 `BusinessModelMetricsSection` 抽出で重複圧縮 |
| 3.1c | alembic `20260508_01` で 7 pack 計 22 metric_key 一括 seed |
| 3.2 | 新規 3 pack (telecom / bank / j_reit) YAML + builder + sample + alembic `20260508_02` (12 metric_key)。J-REIT は segment_groups 不要の専用ロジック |

## 規範コード (横展開時の写経元)

| 種類 | パス |
|---|---|
| BFF builder 規範 | `tools/api/decision_api/serving/company/business_model/_frameworks/auto_oem.py` |
| BFF builder 規範 (J-REIT 専用ロジック) | `tools/api/decision_api/serving/company/business_model/_frameworks/j_reit.py` |
| Desktop 共有 metrics セクション | `desktop/src/components/company/templates/_business-model-metrics-section.tsx` |
| 共有テストフィクスチャ | `desktop/src/components/company/__tests__/business-model-fixtures.ts` (`createMinimalFrameworks()`) |
| alembic 規範 | `db/alembic/versions/20260508_01_business_model_packs_metrics_catalog.py` |
| sample JSON 規範 | `tools/analytics/disclosure_kpi_extractor/samples/4568_daiichisankyo_2025q3.json` |
| probe 補助 | `scripts/probe_business_model_frameworks.py` |

## 12 framework / pack / panel / Tier 1 銘柄 対応表

| framework_id | pack | Panel | Tier 1 銘柄 | 投入済 |
|---|---|---|---|---|
| ad_supported | ad_supported | AdSupportedFunnelPanel | 4751/4324/9449/2433 | ✓ (前セッション) |
| auto_oem | auto | AutoOemPyramidPanel | 7203/7267 | ✓ (前セッション) |
| pharma_rd | pharma | PharmaPipelinePanel | 4568 | ✓ (本セッション) |
| trading_house | trading_house | TradingHouseClusterPanel | 8001 | ✓ |
| semiconductor | semiconductor | SemiconductorSupplyPanel | 6920 | ✓ |
| ec_marketplace | ec | EcMarketplacePanel | 4755 | ✓ |
| electric_unbundling | electric_power | ElectricUnbundlingPanel | 9501 | ✓ |
| logistics_hub | logistics | LogisticsHubPanel | 9064 | ✓ |
| shipping_fleet | shipping | ShippingFleetPanel | 9101 | ✓ |
| telecom | telecom (新規) | TelecomLayerPanel | 9432 | ✓ |
| bank | bank (新規) | BankFundsFlowPanel | 8306 | ✓ |
| j_reit | j_reit (新規) | JReitSponsorshipPanel | 8951 | ✓ |

## 検証結果

- ruff: All checks passed
- pytest tests/tools/api/ + tests/tools/analytics/disclosure_kpi_extractor/: **1721 passed / 4 skipped** (regression 0)
- pytest test_company_business_model_frameworks.py: **43 passed** (16 既存 + 6 phase 3.1a + 18 phase 3.1b parametrize + 6 phase 3.2 parametrize + 3 j_reit 専用)
- desktop typecheck: 0 errors
- desktop vitest src/components/company/: **148 files / 643 tests PASS**
- probe スクリプト import OK / `--help` 動作確認済

## 設計判断

- **共有フィクスチャ抽出** (`createMinimalFrameworks()`) で 10 frameworks × 4 strict fixture = 40 箇所の追記コストを 13 行に圧縮。新 framework 追加は 1 関数追加 + 1 行で完結
- **共有 metrics セクション** (`BusinessModelMetricsSection`) で 6 パネル分の inline 重複 (~150 行 × 6 = 900 行) を回避。AutoOem / Pharma は inline のまま (パイロット規範を保存)
- **J-REIT 専用ロジック**: `metrics_count >= 3` で `has_segment_groups` 不要。REIT は連結 segment_groups を持たないため標準ロジックでは永久 partial 止まりだった
- **PharmaPipelinePanel の 2 つ目 useQuery**: 親 `BusinessModelCanvasView` と同じ query key (`["company-business-model-frameworks", code, { peers_limit: 0 }]`) で react-query キャッシュ共有、HTTP 重複なし
- **`as unknown as` キャスト派 panel test には共有フィクスチャ非適用**: 既存テストファイルは `as unknown as CompanyBusinessModelFrameworksResponse` で型を踏み倒しているため、`BusinessModelMetricsSection` 側で `framework: ... | undefined` を許容する安全弁を追加。新規追加した metrics section テストでは明示的に `frameworks.<id>` を埋める
- **metric_key 衝突 (churn_rate, ltv)**: saas pack と telecom/j_reit pack で意味が異なる。Phase 3.2 では telecom/j_reit の単位を catalog に seed (saas は未 seed なので衝突せず)。saas seed 時は別 metric_key (例: `saas_churn_rate`) への分離が必要

## 次セッション必須

1. `uv run alembic upgrade head` で 20260508_01 + 20260508_02 を本番 DB に適用
2. probe: `python scripts/probe_business_model_frameworks.py --codes 4568,8001,6920,4755,9501,9064,9101,9432,8306,8951` で 10 銘柄の status / metrics_count を確認
3. Tier 1 検証銘柄全てで `frameworks.<id>.status in {available, partial}` を確認 (sample JSON が seed されていれば available になる想定)

## 次セッション候補 (Wave F 完了後)

1. **Wave D Phase 3 IR 数値再投入**: 10 銘柄の概略値を IR 資料から正規値に上書き、confidence ≥ 0.85 化
2. **Wave G**: 5 Forces レーダー / Value Chain SVG / SaaS Dashboard / CompanyRelationshipGraph 4 tier 統合 (12 panel 完成を前提)
3. **Wave L**: pixelmatch ベースのビジュアル回帰 (40 テンプレ × 3 銘柄 = 120 ケース)
4. **Wave M**: Playwright + qwen3.5:9b narrative endpoint
5. **Desktop 実機検証**: 全 12 panel で metrics セクションが live 表示することを目視確認

## 関連ファイル数

- BFF `_frameworks/<id>.py` 新設: **10** ファイル
- Desktop パネル修正: **10** ファイル
- Desktop パネルテスト修正: **10** ファイル
- 新規 sample JSON: **10** ファイル
- 新規 pack YAML: **3** ファイル
- 新規 alembic revision: **2** ファイル
- 新規 Desktop 共有モジュール: **2** ファイル (fixtures + metrics section)
- 新規 probe スクリプト: **1** ファイル

合計: 約 **48 新規ファイル**、加えて types.ts / `_common.py` / `_frameworks/__init__.py` / `business_model/__init__.py` / 4 strict fixture / pytest test 等の既存ファイルへの修正
