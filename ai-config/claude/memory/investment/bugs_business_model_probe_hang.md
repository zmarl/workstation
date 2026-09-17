---
name: business_model_probe_hang_root_cause
description: business-model probe が 5 分以上ハングする問題の真因は DB のスタック DDL トランザクションによるテーブルロック競合 (aggregator 設計ではない)
type: project
originSessionId: 64c71ccf-3446-4e14-9f5a-4f593f3f3c16
---
# Business Model Probe Hang — Root Cause

## 真因

`scripts/probe_business_model_frameworks.py` および `get_company_business_model_frameworks` が 5 分以上応答しない問題は、**aggregator の同期 I/O 積み重ね設計ではなく、DB に長時間スタックした DDL トランザクションによるテーブルロック競合**が原因。

事例 (2026-05-09):
- PID 409261 が `BEGIN; DROP MATERIALIZED VIEW IF EXISTS mart.vw_daily_valuation CASCADE; CREATE OR REPLACE VIEW ...` を **2 時間 15 分** 保持
- application_name=`investment-tools`, client=Docker bridge (172.18.0.1)
- state=active, wait_event=None (CPU 動作中だが進行極めて遅い)
- これが `mart.vw_daily_valuation` を読む全クエリ (probe / overview / Desktop UI) をブロック

**Why**: probe は `get_company_overview()` 内で `mart.vw_daily_valuation` の latest_valuation SELECT を発行する。DDL ロック保持中はこのクエリが応答せず、aggregator 全体が hang する。aggregator 自体は健全な DB 状態下で ~30s で完走する設計上問題のないコード。

**How to apply**: probe ハング報告を受けたとき:
1. 最初に `pg_stat_activity` で `wait_event_type='Lock'` の状況を確認
2. `pg_blocking_pids()` でブロッカー PID を特定
3. 保持クエリと age を確認、ユーザー承認を得て `pg_terminate_backend(<pid>)`
4. ロック解放後、コード変更なしで probe が動作するはず
5. aggregator 設計の "fast_mode skip option" 等の対症療法は **DB ロックが真因の場合は不要**。先に DB 側を疑うこと

## 診断クエリ

```sql
-- ロック競合の有無
SELECT pid, state, wait_event_type, wait_event,
       LEFT(query, 200), age(now(), xact_start)
FROM pg_stat_activity
WHERE state = 'active' AND wait_event_type = 'Lock';

-- ブロッカー特定
SELECT blocked.pid AS blocked_pid,
       blocking.pid AS blocking_pid,
       blocking.state, blocking.wait_event_type,
       LEFT(blocking.query, 300),
       age(now(), blocking.xact_start) AS xact_age
FROM pg_stat_activity blocked
JOIN pg_stat_activity blocking ON blocking.pid = ANY(pg_blocking_pids(blocked.pid))
WHERE blocked.state = 'active'
LIMIT 5;
```

## 9 銘柄実 framework available 検証結果 (2026-05-09)

| code | pack | status | metrics_count | notes |
|---|---|---|---|---|
| 4568 | pharma_rd | available 0.7 | 2 | OK |
| 8001 | trading_house | available 0.85 | 3 | OK |
| 6920 | semiconductor | partial 0.45 | 0 | bb_ratio/wafer_starts/utilization_rate 不在 |
| 4755 | ec_marketplace | partial 0.55 | 1 | metrics 部分不足 |
| 9501 | electric_unbundling | partial 0.45 | 0 | pack 固有 key 不在 |
| 9064 | logistics_hub | partial 0.45 | 0 | pack 固有 key 不在 |
| 9101 | shipping_fleet | partial 0.45 | 0 | pack 固有 key 不在 |
| 9432 | telecom | partial 0.45 | 0 | pack 固有 key 不在 |
| 8306 | bank | partial 0.45 | 0 | pack 固有 key 不在 |

実 available = **2/9**。prior worklog (`20260508-business-model-9of9-available.md`) の "9/9 available" は実は `has_segment_groups=True` の計測値で、framework status 自体は probe ハングのため未検証だった。

## 関連事実

- `business_model_segment_backfill` ツールは `core.segment_financial_facts` にのみ書込、`core.metric_observations` には書込しない
- framework available 化には `core.metric_observations` の pack 固有 metric_key (e.g. `bb_ratio`, `wafer_starts`, `utilization_rate`) が必要
- 6 銘柄 (6920/9501/9064/9101/9432/8306) の available 化は別経路 (Wave D Phase 3 IR 正規値化、各社 IR 資料を手動確認する必要)

## alembic 状態 (2026-05-09 時点)

- DB 適用済 head: `20260506_04_business_model_panel_health_satisfied`
- alembic heads (script tree): `20260506_04`, `20260508_08`, `20260508_10` の 3 つ
- 重複 revision ID: `20260508_08` が `exit_actions_thesis_violation_type.py` と `securities_insurance_metrics_catalog.py` で重複
- 必要な seed (`20260508_01`/`20260508_02`) は適用済 (chain は `20260507_01 → 20260508_01..04 → 20260506_01..04`)
- 未適用: `20260508_05〜10` (含む重複 08)。すべて untracked、未コミット
- probe 修復には影響しないが、次の DB schema 変更や CI run_manifest 更新の前に整理必須
