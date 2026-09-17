---
name: Freshness SLA coverage gate
description: check_freshness_sla_coverage.py が ops.ingest_source_registry / ops.data_freshness_sla / raw.ingest_runs の三角整合を検証する。新 ingestion ツール追加時に必ず通す
type: reference
originSessionId: f0d390ab-33f3-43b0-96c2-7588ecf74db1
---
## 概要
- 2026-04-17 新設: `scripts/check_freshness_sla_coverage.py` + `tests/scripts/test_freshness_sla_coverage.py`
- 3 ルールを検証:
  1. active な `ops.ingest_source_registry` 行は `ops.data_freshness_sla` に対応行必須
  2. 直近 N 日で `raw.ingest_runs` に観測された source は registry に登録必須
  3. SLA の `max_lag_hours > 0` かつ `warn_lag_hours <= max_lag_hours`

## 使い方
- `uv run python scripts/check_freshness_sla_coverage.py --json`
- CI に組み込む場合は exit code で判定（0=pass, 1=fail）
- デフォルトの観測窓は 14 日。`--observed-days` で変更可能

## 関連テーブル
- `ops.ingest_source_registry` — source 登録の正本
- `ops.data_freshness_sla` — tier 別の warn/max lag 時間
- `raw.ingest_runs` — 実際に実行された run 履歴

## 新規 ingestion ツールを追加するとき
1. `shared/db_contracts/ops.py` の `_DEFAULT_INGEST_SOURCE_REGISTRY_ROWS` に source を追加
2. `_default_data_freshness_sla_for_tier` で tier ベースの SLA が自動設定される
3. `uv run python scripts/check_freshness_sla_coverage.py` で違反ゼロを確認
