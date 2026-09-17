---
name: project_wave_g_followup_complete
description: Wave G follow-up 完了 (2026-05-06)。core.metric_catalog UNIQUE 修復 + 15 銘柄 sample DB ロード + 9 銘柄 probe で available 6/9。8951 J-REIT 全タスク除外、framework available 判定は metrics_count ≥ 2 AND has_segment_groups
type: project
originSessionId: 6562a378-9848-4ac7-85a5-928acc19c261
---
# Wave G follow-up 完了 (2026-05-06)

前セッション (Wave F Phase 3 / Wave G) の残務 3 タスクを 1 セッションで完遂。

## 達成

1. **`core.metric_catalog` UNIQUE INDEX 修復** — 23 重複 metric_key を整理。`scripts/repair_metric_catalog_duplicates.py` 新規作成 (--dry-run / --execute --backup-csv / --strategy refcount)。equality 検索が index 経由で正常動作。
2. **15 銘柄 sample DB ロード** — `scripts/load_disclosure_kpi_samples.py` 新規作成。SAMPLE_MAPPINGS から 8951 j_reit 除外 (15 件 / 計 52 metric_observations)。
3. **9 銘柄 probe** — `available 6/9, partial 3/9`。CSV: `artifacts/probe_20260506.csv`。

## available 6/9 詳細

| status | code:framework |
|---|---|
| available | 4755:ec_marketplace / 9501:electric_unbundling / 9064:logistics_hub / 9101:shipping_fleet / 9432:telecom / 8306:bank |
| partial (metrics 配線済、segment_groups 未整備) | 4568:pharma_rd / 8001:trading_house / 6920:semiconductor |

## 知見 (再発時に参照)

### `core.metric_catalog` UNIQUE INDEX 破壊メカニズム

**症状**: `WHERE metric_key = X` の equality 検索が index 経由で 0 件を返す一方、LIKE seqscan では正しく heap が読める。23 metric_key で metric_id が 2 行ずつ存在。
**Why**: alembic migration の upgrade/downgrade 反復で `_UPSERT_SQL` が新 UUID を生成し、古い UUID 参照行が orphan 化したのが推定原因。
**How to apply**: 同様の症状を見たら `scripts/repair_metric_catalog_duplicates.py --dry-run` で重複検出。`--execute --backup-csv <dir>` で修復。FK 自動探索 + 許可リスト (observations / series / profile / review_queue) 方式で予期せぬ参照を検知。

### Business-model framework の available 判定

`tools/api/decision_api/serving/company/business_model/_frameworks/<id>.py` の builder 共通仕様:
- `metrics_count >= 2 AND has_segment_groups` → available (0.85 if metrics ≥ 3, else 0.70)
- `metrics_count >= 1` (segment_groups なし) → partial (0.55, reason `metrics_partial_coverage`)
- candidate (keyword/sector ヒット、metrics 0) → partial (0.45)
- otherwise → unavailable

**Why**: J-REIT 以外は連結セグメント情報を構造化要素として要求する設計。
**How to apply**: 「metrics 配線済なのに available にならない」場合は `business_model.segment_groups` の DB 整備が未済か確認。J-REIT (`j_reit.py`) のみ専用ロジック (`metrics_count >= 3` で segment_groups 不要)。

### catalog 修復時の rebind 衝突

`core.metric_series` / `core.issuer_metric_profile` は metric_id を PK 構成要素に持つため、単純 UPDATE では PK 衝突。INSERT-ON-CONFLICT-DO-NOTHING + DELETE で keeper 側に統合 (victim 側は破棄)。Wave G follow-up では FX_BETA_USDJPY_60D / RELATIVE_STRENGTH_20D / TRACKING_ERROR_60D / REVIEW_AVG_RESOLUTION_HOURS / REVIEW_QUEUE_DEPTH / REVIEW_SLA_COMPLIANCE_RATE の 6 件で計 12,636 series 行が衝突破棄。

## 8951 J-REIT 除外方針 (2026-05-06 ユーザー判断)

- 8951 / J-REIT は投資対象外として全タスクから除外
- alembic `20260508_02_telecom_bank_jreit_metrics_catalog.py` の j_reit seed は触らず DB 上に存置
- 観測ロード / probe からは 8951 を除外
- J-REIT 関連コード (panel / framework / pack / sample) の整理は別 ADR で判断

## フォロー (次セッション候補)

1. `business_model.segment_groups` を 4568 / 8001 / 6920 に追加して再 probe → 9/9 available 達成可能
2. metric_catalog 重複の根本原因調査 (alembic upgrade/downgrade で UUID が再生成されるロジック) と再発防止策
3. 6 件の PK 衝突で破棄された victim 側 series 行が本当に不要だったか確認 — backup CSV (`artifacts/metric_catalog_backup_20260506/core_metric_series_affected.csv` 200MB) を保管

## 参照

- worklog: `docs/worklogs/20260506-wave-g-followup-catalog-repair-and-d-phase3-load.md`
- backup: `artifacts/metric_catalog_backup_20260506/` (5 CSV、計 ~206MB)
- probe CSV: `artifacts/probe_20260506.csv`
- 修復 script: `scripts/repair_metric_catalog_duplicates.py`
- loader script: `scripts/load_disclosure_kpi_samples.py`
