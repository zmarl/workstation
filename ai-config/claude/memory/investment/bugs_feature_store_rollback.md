---
name: bugs-feature-store-rollback
description: feature_store の regime 失敗が同一トランザクションの price upsert を巻き戻し、fs_price_features が4/23で2ヶ月凍結 (ログは毎日成功表示、2026-07-03 修正)
metadata: 
  node_type: memory
  type: project
  originSessionId: 9f7b3013-0350-4c83-96ab-dfd07bcd2c35
---

# feature_store サイレント凍結 — 後続グループの失敗が先行 upsert をロールバック

- **問題**: `analytics.fs_price_features` が 2026-04-23 で凍結していたのに、日次ログは毎日「Upserted 4,3xx price feature rows」成功表示。
- **原因**: 7 グループ (price→…→regime→portfolio→flow) を単一コネクション・単一トランザクションで処理し、regime グループが `mart.vw_macro_signal_daily` に存在しない `source_as_of_date` 列を SELECT → 例外 → except 節の `conn.rollback()` が**先にコミットされていない price/fundamental 等の upsert まで巻き戻し**。ビュー変更日 (4/23頃) から毎日再発。テストはフィクスチャが実ビューと乖離 (架空の source_as_of_date 列を持っていた) ため緑のまま。
- **解決** (2026-07-03): (a) SELECT を実ビュー列に整合、(b) `_build_single_group` 成功パスで**グループごとに conn.commit()**、(c) テストフィクスチャを実ビュー形に追随。修正後 build + 2024-07〜2026-07 の price バックフィルで復旧。
- **教訓**:
  - PostgreSQL は同一トランザクション内の1文でも失敗すると abort。マルチステージバッチは**ステージ成功ごとに commit** しないと「ログは成功・DBは空」のサイレント消失が起きる
  - 「upsert 成功ログ」と「テーブルの MAX(as_of_date)」の乖離が検知シグナル。freshness SLA はログでなくテーブル実測を見るべき
  - DDL/ビューを変えたら参照側 SELECT の grep 追随が必須。テストのスキーマフィクスチャは実 DDL から生成しないと乖離が事故を隠す
- 関連: [[bugs-manifest-argparse-order]] [[project-decision-round3-2026-07]]
