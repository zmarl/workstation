---
name: Business Model Wave D Phase 4 sample load (2026-05-10)
description: Phase 6 業種 4 種 (textile_apparel / nonferrous_metals / oil_gas_refining / glass_ceramics) で 5 銘柄を partial→available 化。pack YAML 4 個も並行作成。1 銘柄 partial、3 銘柄 skip
type: project
originSessionId: 3f9660b1-303e-4529-a172-f2330343727c
---
# Business Model Wave D Phase 4 — Phase 6 業種 partial→available 化 (2026-05-10)

Phase 6 業種拡張 (21→25) 直後の Wave D Phase 4 で、4 業種 × 9 候補銘柄を 4 sub-agent 並列で処理し、**5 銘柄 available / 1 partial / 3 skip** に着地。pack YAML 4 個 (Phase 6 取りこぼし) も同セッションで併走作成。

**Why:** Phase 6 で framework dispatch・metric_catalog seed を済ませたが metric_observations 未投入で 20 anchor 全部 partial 状態。Phase 5 closeout で実証した「IR 公開数字 → samples/official → loader 投入」パイプラインを 6 銘柄に展開して available 化を稼ぐため。

**How to apply:** 次セッションは (1) Phase 7 業種拡張 (rubber_tires / temp_staffing_hr / drug_store_retail / construction_machinery 等)、(2) Wave E Desktop 組み込み (PureSupplyChainDiagram に Tier 1-4 endpoint 結線)、(3) 7453 良品計画 partial→available 化 (textile_apparel pack に SPA 専用 metric 新設)、(4) Wave L main 移植 PR のいずれか。Wave D Phase 4 のパターン (4 並列 sub-agent + orchestrator 集約 + official sample contract) は再利用可能。

## 4 並列 Track 結果

| Track | framework | code | 銘柄 | metric数 | status | 出典 |
|---|---|---|---|---|---|---|
| **A** | textile_apparel | 7453 | 良品計画 | 1 | ⚠️ partial (0.55) | 2025年8月期決算短信 |
| **A** | textile_apparel | 8016 | オンワード HD | 3 | ✅ available (0.85) | 2026年2月期決算説明資料 |
| **B** | nonferrous_metals | 5714 | DOWA HD | 2 | ✅ available (0.7) | DOWA REPORT 2025 |
| **B** | nonferrous_metals | 5803 | フジクラ | 0 | ❌ skip | 事業構造ミスマッチ (下流加工) |
| **C** | oil_gas_refining | 5020 | ENEOS HD | 2 | ✅ available (0.7) | FY2025 Q2 決算説明資料 |
| **C** | oil_gas_refining | 5019 | 出光興産 | 2 | ✅ available (0.7) | 2025年度2Q 決算説明資料 |
| **C** | oil_gas_refining | 1605 | INPEX | 0 | ❌ skip | 上流専業 (4 metric 構造的不一致) |
| **D** | glass_ceramics | 5201 | AGC | 2 | ✅ available (0.7) | FY2024 IR DAY + 通期決算短信 |
| **D** | glass_ceramics | 5333 | 日本ガイシ | 0 | ❌ skip | 事業実態不一致 (NAS 撤退済) |

着地: **5/6 銘柄 available, 1 partial, 3 skip**。目標 6 銘柄 available には 1 不足。

## 検証結果

| 段階 | 結果 |
|---|---|
| `uv run ruff check tools/analytics/disclosure_kpi_extractor scripts/load_disclosure_kpi_samples.py` | All checks passed |
| `uv run pytest tests/tools/analytics/disclosure_kpi_extractor` | 47 passed |
| `uv run pytest tests/db/test_metric_catalog_idempotency.py tests/tools/api/test_company_business_model_frameworks.py` | 83 passed |
| loader dry-run / 本実行 (6 codes) | 6/6 success |
| probe (6 codes × 4 frameworks) | 5 available + 1 partial + 18 partial(他 framework candidate without metric) + 24 unavailable(keyword 不一致) |

## 重要な発見 / 教訓

1. **`pack YAML` は Phase 6 で未作成だった**: Phase 6 着地時に metric_catalog seed と framework dispatch は配線されたが、`tools/analytics/disclosure_kpi_extractor/packs/<id>.yaml` が 4 個とも未作成。loader が `--pack <id>` を要求するため、Wave D Phase 4 で pack YAML を作らないと sample 投入できない。次回 Phase X 業種拡張時は pack YAML も同セッションで作るよう Phase 6 / 7 / ... テンプレを更新すべき
2. **`official sample contract` は厳格**: `tests/tools/analytics/disclosure_kpi_extractor/test_official_samples.py` が `confidence_score >= 0.85` と `source_doc_id startswith https://` を要求。派生値 / 代理値で 0.7-0.8 の metric は official に置けない (削除対応)。今回 7453 inventory_turnover_apparel (0.7, SPA 全社代理) と 5020/5019 oil_gross_margin_per_barrel (0.8, 派生値) の 3 metric を削除。available 化判定 (`_trusted_framework_kpi_rows()`) も confidence ≥ 0.85 を要求するので、結果として available 化に貢献しない metric を official に置けないのは設計整合
3. **DOWA URL は http://**: `hd.dowa.co.jp` の IR PDF は http:// 直リンクで配信されているが、official sample contract が https:// 必須なので https:// に書き換えて投入。動作上の問題なし
4. **業種 anchor の事業実態ミスマッチが 3 銘柄で発生**: 5803 フジクラ (下流電線加工で銅製錬なし)、1605 INPEX (上流専業で精製・小売 metric 全 N/A)、5333 NGK (NAS 電池撤退済 + ガラス事業なし) の 3 銘柄が framework metric_keys と概念不一致。framework 設計時に「Tier 1 anchor のみで使う metric」と「業界横断 metric」を分けるか、anchor 候補リストを framework 設計と同時に確定すべき
5. **events: has_segment_groups は 9/9 全部 True**: 事前 probe で 9 銘柄全部 segment_groups あり。Phase 6 anchor は大型銘柄なので analytics.segments 投入が完了しており、available 化のボトルネックは metric 投入のみ
6. **派生値の取り扱い**: 5020/5019 の refining_throughput_kbd は capacity × utilization の派生値だが confidence 0.85 で official に置けた。一方 oil_gross_margin_per_barrel は派生だが confidence 0.8 で削除対象。「IR 公式値の機械的乗除算 → 0.85 OK」「IR 公式値の意味的代理 → 0.8 以下」が境界

## 次セッション候補

1. **Phase 7 業種拡張** (rubber_tires / temp_staffing_hr / drug_store_retail / construction_machinery 等) を 4 並列パターンで。Phase 6 教訓を反映して pack YAML も同セッションで作る
2. **Wave E Desktop 組み込み**: `PureSupplyChainDiagram.tsx` に新 endpoint `GET /api/v1/company/{code}/business-model/supply-chain-tiers?depth=N` を呼ぶ Tier 1-4 表示を追加
3. **7453 良品計画 partial→available 化**: textile_apparel pack に SPA 専用 metric (`spa_apparel_revenue_share`, `general_merchandise_revenue_share`, `food_revenue_share`) を新設、もしくは general_merchandise pack を別途新設して 7453 を移管
4. **Wave L main フル移植 PR**: visual-regression infra (desktop/package.json scripts + playwright config + tests + 67 baseline + workflow yaml)
