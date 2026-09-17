---
name: project-db-ops-optimization-2026-07-11
description: DB運用最適化バッチ完了 (2026-07-11)。ClickHouse退役・VACUUM 186GB回収・品質ゲート3種・Desktopティア再分類。DDL凍結ウィンドウ課題が handover
metadata: 
  node_type: memory
  type: project
  originSessionId: ae24642f-3458-49e6-bcbf-c3d78398485f
---

# DB運用最適化バッチ (2026-07-11, feat/db-ops-optimization, worktree D:\Dev\Investment-dbopt)

11コミット。詳細: docs/worklogs/20260711-db-ops-optimization.md

## 何をしたか
- **A 基盤**: ClickHouse serving 退役（serving_read_mode 分岐230箇所→postgres一本、config/契約スクリプト/CI追随）+ DBレイヤー契約.md を実稼働3層へ全面改訂 + docs キーワード契約を「PostgreSQL canonical/serving」必須へ変更。physical_audit 週次ツール新設
- **VACUUM FULL で DB 954GB→768GB（-186GB）**: boj_metrics 188GB→9.1GB。真因=upsert 変更検知 WHERE に run_id/raw_ref（毎run変化）が入り全18.3M行が毎日死行化 → 両列を検知から除外して修正済み
- **B 品質**: (1) volume異常検知（28日中央値×0.3 / nonzero-gap p95×1.5、warn-only）を governance-audit へ (2) カナリアゲート（EDINET DB 由来20社×3年 fixture、full-sync昇格を>1%乖離でブロック）(3) financial_facts_cross_audit 新ツール（EDINET DB×core 12指標突合、日次 manifest 登録済み）(4) 上場廃止797社の manual-only 取込
- **C 表示**: STALE_TIME.daily(30m) 新設+fastMoving 267→約40箇所へ削減+gcTime 60m / BFF @read_cache 15関数（deepcopy+ingest_runs世代プローブ+pytest自動無効）/ FreshnessTag 15枚 / 利益形状ラベル+進捗3系列

## 実検知した故障（ツールが初回実行で発見）
- estat_bridge/incremental 沈黙故障（当日0 vs 中央値46）
- **6619 fy2021 年度オフバイワン破損5指標 + 7202 fy2024 equity 異常**（cross-audit、要修理）

## Handover 消化（同日 2026-07-11 に完遂、計15コミット・PR #45）
- **6619/7202 は両方誤検知と裁定**（6619=EDINET DB の年度採番+1〈変則1月決算〉、7202=JGAAP純資産 vs IFRS親会社持分）。降格ルール2種を実装し critical 6→0。修理不要が正解だった
- EDINET DB 実 API に **is_delisted** フィールド実在 → delisted 判定校正済み。--cross-audit-reserve-calls 15 実装・manifest 配線済み
- pg_stat_statements 導入済み（ALTER SYSTEM + compose + 安全窓再起動。統計蓄積は 2026-07-11 起点）
- 時限性残件はバックログ登録済み: warn→fail 昇格 due 07-18 / index drop due 08-10 / DDL 3本 / IFRS equity 概念ポリシー

## main 統合完了（2026-07-12、直 push・PR #45 は自動 MERGED）
main 側の並行前進（PR #38-46: xdist/happy-dom・AsyncPanel統一・FreshnessBadge・**main も独自に ClickHouse 退役済み（インライン化でより徹底、当方はシム残除去を上乗せ）**・manifest ソース生成化・CI quota diet）と統合。競合50件解決の知見:
- **manifest は scripts/manifest/*.yaml ソース → build_run_manifest.py 生成に変わった**（run_manifest.yaml 直編集はドリフトゲートで落ちる）
- routers/company.py は routers/company/ パッケージへ分割、LatestEarnings は pages/earnings/ へ移動
- マージ検証: pytest 7,020 + desktop 2,439 全緑・全契約ゲート PASS・519 routes

## 全残件完遂（2026-07-12）
- **孤児化していた適用済み revision 20260711_03〜11 を main へ着地**（本番は _09 停止だった→_10/_11 も適用し head 化。main の _02 変種を採用して dangling だった _01_precommit_thesis_tags をグラフに接続、列の本番実在を確認済み。_03 mergepoint は既存 ADR + ラチェット台帳へ登録）
- **20260712_01 で DDL 4点完了**: registry volume列（検知コード配線・分析系5ソース off シードで警告18→11）/ cross_audit 永続テーブル（初回25,883行、誤検知6行を false_positive 裁定記録）/ boj autovacuum 0.02 / pg_stat_statements 拡張。baseline 再生成（head 記録一致）
- **Windows 登録2本完了**（DbPhysicalAuditWeekly / FinancialFactsCrossAuditDaily、Ready 確認・integrity 検証済み。missing 1件は他セッション由来の既存ドリフト）
- **重要インシデント修理: DB 再起動後に docker の ::1:5432 バインドが消失**し、DSN の `localhost` が IPv6 先行で全接続30秒ハング（pool 1秒 timeout で全滅リスク）→ 両 .env の DSN を 127.0.0.1 へ明示して 0.07秒 に回復。**教訓: docker restart 後は netstat で v4/v6 リスナー確認 + DSN は 127.0.0.1 明示が安全**

## 時限のみ残り（バックログ管理）
- warn→fail 昇格 due 2026-07-18（fail 機構は配線済み、registry で mode 指定するだけ）
- 未使用インデックス drop + マテビュー化 due 2026-08-10（pg_stat_statements 統計蓄積中）
- IFRS equity 概念ポリシー統一（起票済み）

## 重要知見
- pg_stat リセット済みクラスタでは n_live_tup 不能 → reltuples+pg_stats 列幅でブロート推定（physical_audit 実装済み）
- **upsert 変更検知に run 毎変化列を入れると全行毎日死行化**（boj の教訓、他ツールも要警戒）
- 並行エージェントが git rm したステージ済み削除は自分の `git commit` に混入する → コミット後 diff-tree 確認必須
- serving 関数へのデコレータは def 時適用なので monkeypatch プロキシ（_install_proxy）と両立する
- docs 契約 REQUIRED_TERMS 変更時は check_docs_contract_keywords.py + test の _base_doc + 対象 docs を同時更新
- EDINET DB raw: キー=EDINETコード（E01015）・単位=円・501社。証券コード解決は public.company_master.canonical_code（core.instruments に edinet_code 無し、core.issuers.edinet_code 全NULL）

関連: [[project-structural-cleanup-202607]] [[project-reform-program-202607]] [[ci-new-manifest-task-contracts]] [[feedback-parallel-session-worktree]]
