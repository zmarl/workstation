---
name: reference-sector-market-cap-source
description: セクター/銘柄の時価総額の正本ソースは mart.vw_daily_valuation (百万円・materialized)。MAX(trade_date) 窓で高速化
metadata: 
  node_type: memory
  type: reference
  originSessionId: 60cac97c-1a3b-4147-902c-8c047702f4fb
  modified: 2026-07-19T10:55:47.393Z
---

Desktop の screening/valuation が読む per-code 時価総額の正本は **`mart.vw_daily_valuation.market_cap`**。
- 経路: `_screening.py` の market_cap → `mart.vw_screening_custom_base`（`SELECT DISTINCT ON(code) market_cap FROM mart.vw_daily_valuation ORDER BY code, trade_date DESC`）→ `mart.vw_daily_valuation`。
- **単位は百万円**（円ではない）。計算式 = `total_shares × close / 1e6`（18_views.sql の vw_daily_valuation 内）。×1e6 で円に戻る。
- `mart.vw_daily_valuation` は **MATERIALIZED VIEW**（履歴あり・code×trade_date 粒度）。`market_cap_quality_flag='market_cap_anomaly'`（>100兆円/単名）は集計から除外すべき。
- 別系統の `analytics.liquidity_profile_daily`（`mart.vw_liquidity_profile_latest`）も per-code market_cap を持つが**別パイプライン**。screening 表示値と一致させたいなら vw_daily_valuation を使う。

セクター合算のパターン（get_sector_performance に LEFT JOIN、DDL なし）:
```sql
LEFT JOIN (
  SELECT s.sector_name AS sector,
         SUM(lc.market_cap)::double precision AS total_market_cap,
         COUNT(lc.market_cap)::double precision / NULLIF(COUNT(*),0) AS market_cap_coverage
  FROM public.stocks s
  LEFT JOIN (
    SELECT DISTINCT ON (code) code, market_cap, market_cap_quality_flag
    FROM mart.vw_daily_valuation
    WHERE trade_date >= (SELECT MAX(trade_date) FROM mart.vw_daily_valuation) - INTERVAL '30 days'
    ORDER BY code, trade_date DESC
  ) lc ON (lc.code)::text=(s.code)::text
      AND (lc.market_cap_quality_flag IS DISTINCT FROM 'market_cap_anomaly')
  WHERE s.is_active=TRUE AND s.sector_name IS NOT NULL
  GROUP BY s.sector_name
) mc ON (mc.sector)::text=(p.sector)::text
```

**高速化の罠**: 全履歴に対する `DISTINCT ON(code) ... ORDER BY trade_date DESC` は materialized view でも遅い（実測 ~10秒）。
`WHERE trade_date >= (SELECT MAX(trade_date) FROM ...) - INTERVAL '30 days'` で窓を切ると ~1.8秒。**CURRENT_DATE ではなく MAX(trade_date) 基準**にすること
（dev DB スナップショットは valuation が30日以上 stale で、CURRENT_DATE 窓だと空になる）。実測: 34業種全てにcap・coverage平均0.93・電気機器≈215兆円。
2026-07-19 UX feedback で /sector ヒートマップの面積を stock_count→時価総額化した際の知見。関連: [[project-desktop-design-reform-2026-07-19]]
