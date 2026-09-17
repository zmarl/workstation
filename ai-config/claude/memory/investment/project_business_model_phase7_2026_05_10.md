---
name: Business Model Phase 7 着地 (2026-05-10)
description: Phase 7 業種拡張 (rubber_tires / temp_staffing_hr / drug_store_retail / construction_machinery) を framework dispatch + alembic seed + 20 anchor probe まで着地。25→29 業種、industrial_machinery 補充含む。Wave D Phase 5 で available 化待ち。
type: project
originSessionId: 794e0b04-9368-4e5a-b20e-e077a90359ed
---
# Business Model Frameworks Phase 7 (2026-05-10 着地)

## 着地サマリー

- framework dispatch: 25 → 29 framework_id
- tier_inferer catalog: 7 → 11 industries
- alembic head: 20260510_21 → 20260511_04 (linear chain で 4 revision 着地、本セッション後に既存 20260510_22 が後続として残っているのは無関係)
- 20 anchor probe: **partial 16/20 + unavailable 4/20** (1 surface 除外 / 1 keyword 不一致 / 2 surface 除外)

## industrial_machinery 補充 (重要)

- tier1 削除: 6301 コマツ / 6326 クボタ → construction_machinery へ移籍
- tier1 昇格: 6954 ファナック / 6506 安川電機 (Phase 7 で新規 tier1)
- 修正後 tier1 (7 件): 6273 / 6367 / 6361 / 7011 / 7012 / 6954 / 6506
- test_industrial_machinery_anchor_detected も 6301 → 6273 SMC に差替

## 新規 metric_keys (16 件、衝突なし)

- rubber_tires: tire_production_units / oem_tire_revenue_share / replacement_tire_revenue_share / tire_raw_material_cost_index
- temp_staffing_hr: registered_staff_count / staff_utilization_rate / active_job_orders / staffing_take_rate
- drug_store_retail: drugstore_count / revenue_per_drugstore / dispensing_revenue_share / private_brand_revenue_share
- construction_machinery: construction_machinery_overseas_share / parts_service_revenue_share / construction_machinery_order_backlog / construction_machinery_utilization

共通 metric (`overseas_revenue_ratio` / `segment_op_margin`) は再宣言禁止、framework metric_aliases で reuse のみ。

## anchor (5 件 × 4 業種)

- rubber_tires: 5108 / 5101 / 5110 / 5105 / 5191
- temp_staffing_hr: 6098 / 2181 / 2127 / 2412 / 6089
- drug_store_retail: 3088 / 3391 / 9989 / 7649 / 9627
- construction_machinery: 6301 / 6305 / 6326 / 6310 / 6473

## 20 anchor probe 結果 (要詳細)

**完全 partial (期待通り)**:
- drug_store_retail: 全 5 件 partial 0.45
- construction_machinery: 全 5 件 partial 0.45

**Mixed (要 follow-up)**:
- rubber_tires: 4 件 partial / 5191 住友理工 outside_current_listed_company_surface (surface 設定要確認)
- temp_staffing_hr: 3 件 partial / 2127 日本M&Aセンター keywords_not_detected (M&A 仲介は HR 業種境界例) / 2412 ベネフィット・ワン outside_current_listed_company_surface (TOB で非上場化済み可能性)

**Wave D Phase 5 への持ち越し**:
- 5191 / 2412 の surface 除外問題は別レイヤー (listed company surface)
- 2127 を temp_staffing_hr に含めるなら keyword 拡張 (M&A仲介 / 事業承継 等)、含めないなら anchor 差替を検討
- partial 16 件は Wave D Phase 5 で official sample (confidence ≥ 0.85) 投入で available 化候補

## **Why**

ビジネスモデル図解の業種カバー率を 25 → 29 へ。Phase 6 と同パターンで 4 並列実装し、framework dispatch までを 1 セッション完結させた。available 化 (sample 投入) は次セッション以降に切り出し、Phase 7 では配線完成と回帰確認を最優先した。

## **How to apply**

- Phase 8 以降の業種拡張も同パターン: alembic seed + framework <id>.py + pack YAML + tier_chains entry + dispatch 5 箇所 + _common.py LABELS + test_tier_inferer 拡張
- ruff の import order は `_frameworks/__init__.py` ではアルファベット順厳守 (`uv run ruff check --fix` で自動整列)
- probe で `outside_current_listed_company_surface` が出る場合は surface レイヤー側の問題、framework 設計の問題ではない
- probe で `keywords_not_detected` が出る場合は keyword 拡張または anchor 差替
- alembic 実行は `uv run alembic -c db/alembic/alembic.ini upgrade head` (alembic.ini が `db/alembic/` 配下にあるため `-c` 必須)

---

## 2026-05-14 訂正 (実測 probe 再走による)

「20 anchor probe: partial 16/20 + unavailable 4/20」「partial 16 件は Wave D Phase 5 で available 化候補」の記述は、本セッションの 2026-05-14 再 probe で **事実と乖離していることが判明**:

- 18 anchor (2412 除外) × 4 framework (rubber_tires / temp_staffing_hr / drug_store_retail / construction_machinery) で probe を再実行 → **全 72 行が status=missing, reason=framework_key_missing**
- aggregator 登録済み framework_key 20 種を確認 → Phase 7 で追加したはずの 4 業種は **すべて未登録**
- official sample JSON (`samples/official/5108_bridgestone_2025q3.json` 等) は確かに投入されているが、aggregator catalog 側の framework_key 登録が抜けている
- これは Phase 5 の 6501 industrial_conglomerate と同根: 「sample 投入と framework 登録の 2 ステップが分離しており、後者が未着手」

[[project_business_model_aggregator_catalog_gap]] に Phase 5/7 共通の根本原因を別途記録。
詳細実測ログ: `docs/worklogs/20260514-business-model-residuals-completion.md`

**Phase 8 で必要な作業**: 4 業種 framework_key を aggregator catalog に登録 (場所: `tools/analytics/business_model_frameworks/` 配下) + 必須 metric_key セット定義 + probe 再実行で available 化検証。
