---
name: project-pg-index-corruption-repair-2026-07-16
description: PGインデックス物理破損の修復完了 (07-16)。REINDEX全数再構築+重複75.9万行退避削除。再同期は並行セッション衝突で定時実行へ委任、翌日確認が必須
metadata: 
  node_type: memory
  type: project
  originSessionId: ac8f3da6-a3c3-46c8-9b23-d1fb116f740c
---

# PG インデックス物理破損の修復 (2026-07-16 実施)

監査 P0-1（[[project-functional-completeness-audit-2026-07-15]] 所見2-1）の止血。worklog 正本: `docs/worklogs/20260716-pg-index-corruption-repair.md`。

## 実施結果
- 破損2本を amcheck で特定: `raw.idx_edinet_xbrl_facts_raw_local_name`（mergejoin エラーの真因）と `raw.edinet_xbrl_contexts_raw_pkey`
- **壊れたユニーク pkey の隙間に重複 758,877組が実データ混入していた**（12.5M行中）。各組の古い方を `data/db_backups/edinet_xbrl_contexts_raw_dedup_removed_20260716.csv.gz` へ退避後、単一Tx+件数アサートで削除
- 1回目再同期が同一 posting list エラーで再失敗 → **bt_index_check デフォルト（並び順検査）は posting list 内部破損を検出できない** → `REINDEX TABLE raw.edinet_xbrl_facts_raw`（22GB, 613秒）で全数再構築して解決
- ディスク2本とも SMART/Health 正常。破損は 2026-03-28 DiskFull 事故の残痕とみられ進行性ではない

## 技術知見（再利用可）
- 破損調査の SELECT は必ず `SET enable_indexscan/indexonlyscan/bitmapscan = off`。**壊れたインデックスは GROUP BY で「重複0件」という嘘を返した**（読取汚染）
- amcheck は高速（22GBで約4分）だが完全ではない。疑いが残るなら個別特定を諦めテーブル単位 REINDEX（1GBあたり実測 約30秒〜2分、maintenance_work_mem=2GB）
- 削除を伴う修復は「COPY退避 → 単一Tx DELETE → 件数アサート → commit」で実質可逆化
- ハーネスのバックグラウンド Bash は10分上限 → 長時間 DDL は Start-Process 分離 + Monitor。クライアント kill 後のサーバ側残存クエリは pg_terminate_backend で掃除（[[bugs-hot-table-ddl-lock-pileup]] 同様）

## 並行セッション衝突（教訓）
- 再同期2回目が **別セッションの writer 静止化機構に強制終了**された（ingest_runs note=`terminated_by_earnings_shadow_recovery_writer_quiescence`）。worktree 分離でも**本番DBは共有**であり、書込系の復旧作業は衝突し得る
- 未コミット `tools/db_admin/edinet_recovery/`（フェイルクローズ型復旧ツール）が本ツリーに存在、別セッション作とみられる

## Handover（翌日確認必須）
- 7/16 20:10 の financial-unifier-daily 定時実行の成否 → success なら core.financial_facts_normalized/resolved に 7/11〜7/16 分が回復しているはず。terminated 再発なら並行作業完了後に `daily-sync --since 2026-07-11` を手動実行
- success 後: 下流 manual_only の xbrl-dimension-builder / segment-timeseries-aggregator を実行し 7/10 凍結解除
- バックアップ整備（監査 P0-2）はユーザー判断で見送り中
