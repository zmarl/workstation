---
name: Business Model Phase 5 業種カバー拡張 (2026-05-10 BFF 配線まで完了)
description: 17 → 21 業種拡張。Phase 5 開発(2026-05-09)で 4 builder + alembic + 12 sample 完了、2026-05-10 で BFF dispatch 配線 + label 登録まで着地。alembic 適用と 12 銘柄 probe は ops.screening_alert_rules 未作成の別 issue で繰り越し
type: project
originSessionId: 33a16884-5095-4efc-8160-8e7c161b53a7
---
# Business Model Phase 5 業種カバー拡張 完了 (2026-05-09)

Phase 4 末の 17 業種カバー基盤に対し、Phase 5 で 4 業種を追加して **21 業種カバー** に到達。Phase 4 と同じ pack YAML / framework builder / alembic / sample の一気通貫パターンを 4 トラック並列で実行。

**Why:** マルチエージェントによる横展開の効率検証 + Wave G/L/M（visual / narrative）の前提となる業種網羅性の前進。

**How to apply:** Phase 6 でさらに業種を追加する際は、本 worklog の `Out of Scope` 節と `Coordination 補正事項` 節を必ず先に読む。並列前に rd_to_revenue_ratio のような共通 metric の seed 担当を 1 トラックに固定する SendMessage 調停が必須。

## 追加された 4 業種

| pack | Tier 1 銘柄 | TSE 33-sector | 差別化観点 |
|---|---|---|---|
| automotive_parts | 5108 Bridgestone / 6902 Denso / 7259 Aisin | 3700 + 3500 | OEM 集中度 / EV 売上比率 / Capex 強度 (auto_oem との差別化) |
| gaming_entertainment | 7974 Nintendo / 9697 Capcom / 9684 Square Enix | 4150 + 5250 | IP-driven / hit-driven / console+mobile gacha 構成 |
| precision_optics | 7751 Canon / 7733 Olympus / 7731 Nikon | 3650 | imaging tech / segment portfolio / patent moat |
| leasing_consumer_finance | 8591 Orix / 8593 MUFG Lease / 8572 Acom | 7100 | リースポートフォリオ / asset-yield-driven (bank との差別化) |

## 新規 metric_key (14)

- automotive_parts (4): `oem_concentration_top3`, `ev_revenue_share`, `supplier_capex_intensity`, `rd_to_revenue_ratio` (Phase 5 共通指標、Track A 単独 seed)
- gaming_entertainment (3): `hit_title_revenue_concentration`, `recurring_user_share`, `ip_franchise_count`
- precision_optics (3): `medical_segment_share`, `patent_count_growth`, `imaging_segment_revenue`
- leasing_consumer_finance (4): `lease_portfolio_balance`, `asset_yield_ratio`, `lease_segment_revenue`, `consumer_finance_loan_balance`

## alembic chain

`20260509_99 → 20260510_01..._10 → 20260509_03 → 20260509_05..._08`（単線、head=20260509_08）。Track A の chain anchor 補正で並走 worktree (20260510_*) の Phase 5 後段への chain 合流を発見、precedent 通りに `revises=20260509_03` を採用して DAG fork 回避。

## j_reit-style fallback (Track D)

`leasing_consumer_finance.py` builder で採用: `metrics_count >= 3 AND is_candidate (sector 7100 OR keyword) → available` を `has_segment_groups=False` でも許容。pure-play 消費者金融 (8572 Acom 等) は単一事業のため segment_groups を持たないため、j_reit pack と同じ救済ロジック。

## Coordination で得た知見

1. **共通 metric 二重 seed のリスク**: Phase 4 の idempotency 強制 (no metric_key seeded by more than one revision) のため、複数 Track が同じ NEW metric を seed すると失敗。並列前に「共通 metric は最初の Track が seed、他は reused 扱い」を SendMessage で固定する必要あり
2. **alembic anchor の自動補正**: 並走 worktree が予期せず chain head を進める可能性があるため、エージェントは grep で実機 head を確認し precedent に従って anchor を選ぶ自律性が必要
3. **Olympus disambiguation**: 7733 Olympus は medical_device pack の sample が既存。precision_optics 用 sample は `7733_olympus_precision_optics_2025q3.json` で suffix 付与（既存パターン `6502_toshiba_home_appliances_2025q3.json` に倣う）

## 触らなかった (並走中)

- `_frameworks/__init__.py`（wiring は merge 後）
- `scripts/run_manifest.yaml`
- Desktop 配下すべて
- official tier sample（confidence ≥ 0.85 化は Phase 6+）

## クロージング状況 (2026-05-10)

| 項目 | 状態 |
|---|---|
| BFF 配線（_frameworks/__init__.py + business_model/__init__.py + _common.py LABEL 登録）| ✅ 完了 (commit ed75ebcf) |
| 検証 (ruff + pytest 3362 passed / 33 skipped) | ✅ 完了 |
| alembic upgrade head | ⏸ 繰り越し（`20260509_02` で `ops.screening_alert_rules` 未作成エラー、Phase 5 スコープ外）|
| 12 銘柄 probe | ⏸ 繰り越し（alembic 適用待ち）|

DB head は `20260506_04_business_model_panel_health_satisfied` のままで安全。Phase 5 配線コードは worktree に merge 済。

**配線時に追加で必要だった編集**: dispatch site (`business_model/__init__.py`) は import + excluded payload availability + excluded payload frameworks dict + active call block + active availability list + active return frameworks dict の 6 箇所、加えて `_BUSINESS_FRAMEWORK_LABELS` (`_common.py`) も。Plan 上の「`_frameworks/__init__.py` だけ wire」は不足で、4 ファイル合計 88 行の挿入が必要だった。

## 次セッション必須 (alembic 修復後)

1. `ops.screening_alert_rules` の正規スキーマを確定 → CREATE TABLE alembic revision を新設
2. `uv run alembic -c db/alembic/alembic.ini upgrade head` で Phase 5 4 業種の `metric_keys` seed まで適用
3. probe で 12 銘柄の status / metrics_count を確認

## 次セッション候補 (Phase 6)

候補業種: textile_apparel / rubber_tires (5108 Bridgestone は automotive_parts に既配置のため除外) / glass_ceramics / nonferrous_metals / oil_gas_refining / temp_staffing_hr / drug_store_retail / construction_machinery

## 関連ファイル

- worklog: `docs/worklogs/20260509-business-model-phase5-industry-expansion.md`
- predecessor: `docs/worklogs/20260509-business-model-multi-track-expansion-phase4.md`
- contract test: `tests/tools/api/test_business_model_framework_builders_contract.py` (COVERED_BUILDERS Phase 5 4 entry 追加で 110 pass)
- 検証コマンド: `uv run ruff check tools/ tests/ db/ scripts/` + `uv run pytest tests/db/ tests/tools/quality/ tests/tools/analytics/ tests/tools/api/test_business_model_framework_builders_contract.py tests/tools/api/test_business_model_panel_health.py tests/tools/api/test_company_business_model_frameworks.py tests/tools/api/test_company_business_model_template.py` → 3362 passed, 33 skipped, 0 failed
