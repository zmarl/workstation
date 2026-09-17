---
name: bugs-hot-table-ddl-lock-pileup
description: 稼働中テーブルへの DDL (DROP INDEX 等) が ACCESS EXCLUSIVE 待ちで全読者を堰き止める。孤児バックエンドの掃除手順と lock_timeout 必須の教訓 (2026-07-11 実事故)
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 2626d986-0a5c-46dc-a9b9-8e95f028586c
---

# 稼働中テーブルへの DDL はロック行列の「ダム」になる（2026-07-11 実事故）

**問題**: raw.financial_reports 上の検証用一時インデックスを `DROP INDEX` したところ、先行の長時間 SELECT（5h+ 走行中の vw_financials_unified 分析クエリ）の後ろで ACCESS EXCLUSIVE 待ちになり、**その後ろに全読者（pytest + 本番スケジュールジョブ 約60セッション）が数珠つなぎ**でブロックされ、フルテストが約3時間停止した。さらにクライアント側プロセスを kill しても **サーバ側バックエンドは生き残り**、待ち行列に居座り続けた（4本の孤児 DROP INDEX が滞留）。

**原因**: PostgreSQL のロック行列は FIFO — ACCESS EXCLUSIVE 待ちの DDL は、それより後に来た ACCESS SHARE（普通の SELECT）さえ全部せき止める。ホットテーブルでは「たかが DROP INDEX」でも実質的な全停止装置になる。

**解決**:
1. 孤児特定: `SELECT pid, state, wait_event_type, query FROM pg_stat_activity WHERE state<>'idle'` + `pg_blocking_pids(pid)`
2. 掃除: `SELECT pg_terminate_backend(pid)` で自分の DDL バックエンドを terminate → 行列が即時解消（blocked 60→0）
3. 以後の DDL は **必ず `SET lock_timeout = '3s'` を先行**させ、取れなければ自傷キャンセルで諦める（他者を堰き止めない）。リトライループで空きを待つ

**How to apply**:
- 検証用インデックスは本番 DB に作らない（EXPLAIN で判断するか、作るなら即 lock_timeout 付きで消す）
- alembic 適用も同様のリスク: ホットテーブルへの ALTER/DROP は稼働ジョブの少ない時間帯か lock_timeout 付きで
- クライアント kill ≠ サーバクエリ終了。kill したら pg_stat_activity を必ず確認
- 長時間クエリ（vw_financials_unified で 5h+）は VFU-PERF-01 の実体化で根治予定
