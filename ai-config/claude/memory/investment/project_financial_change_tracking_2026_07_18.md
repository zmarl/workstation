---
name: project-financial-change-tracking-2026-07-18
description: 財務「変化を追う」ロードマップ (2026-07-18 承認、PR 8本) の進捗と、今回スコープ外に控えた修復バックログ
metadata: 
  node_type: memory
  type: project
  originSessionId: 02350eec-274a-44f9-8f49-edef7245291e
---

# 財務変化追跡ロードマップ (2026-07-18 承認)

計画正本: `C:\Users\kazum\.claude\plans\edinet-db-ir-xbrl-splendid-duckling.md`

目的: IRバンク/EDINET DB 的な「1社1画面で財務推移を追える」化。核心は派生指標(粗利率・営業利益率等)の**変化を追い原因分解**できること。粒度=通期長期+四半期+単四半期換算の3層。受注・セグメント重視。

## PR 構成と進捗
- [x] PR-1 **マージ済 (#61, 07-18)**。共有ヘルパー fiscal_period_utils.py 新設、edinet_extractor は純委譲(挙動不変)。**旧セグメント実装は start年基準だったため、3月決算銘柄含め core.segment_financial_facts 全面が再抽出対象**。残 ops: 07-18 夜定刻実行(19:50/20:10/20:29)後の抽出前進確認 + 全面再抽出(DB書込、未実施)
- **PRゲート既知失敗 (main 75eb4b89 で実証済みの既存負債7件)**: screening serving 5件(HVセッション申し送り済)+ ops_hub TestGetCompanyDataCoverage(時刻依存 stale assertion)+ decision test_signed_identity_context(単体でも error)。ゲート red はこの7件と突合して判断。証跡: PR #61 コメント
- [x] PR-2 **マージ済 (#62, 07-18)**。レンジトグル(5/10/全期間・8/20/40Q)、limit=200 は専用3要素クエリキー(snapshot-core の50行シードにシャドウされる罠を回避)、thinLabels 間引き
- [x] PR-3 **マージ済 (#63)**。OrdersTrendChart(受注高バー+売上/受注残線+Book-to-Bill 右スケール、追加フェッチなし、受注銘柄のみ4枚目カード)
- [x] PR-7 **マージ済 (#65)**。「変化」タブ新設(利益率長期チャート+MarginBridge 40Q連動+WhatChanged/RedFlags+MetricHistory プリセット15年)。?tab=margin-bridge→changes リライト。**BFF の standalone_* ヒント列は生成元なし=常に None(PR-4 で判明)**
- [x] PR-4 **マージ済 (#67)**。alembic 20260718_01(catalog.aggregation_type)+_02(mart.vw_financial_metrics_single_quarter)。ゴールデンテストで BFF 減算プリミティブと数値一致証明。**DDL PR は generate-fingerprints(使い捨てコンテナ)で db/baseline/LOCAL_COMPOSE_BOOTSTRAP_FINGERPRINTS.json を同一 PR 更新必須**(db gate の FingerprintContractError の正体)。旧 head 指紋は main 時点で既に stale だった(修正済)
- [x] PR-5 **マージ済 (#68)**。alembic 20260718_03(mart.vw_financial_derived_metrics)。3層×4利益率+YoY/QoQ pt+**増減分解(OP変化=粗利変化−販管費変化+残差、円/pt)**。セグメント利益率は再抽出後の別ビューへ先送り
- [x] PR-6 実装済 (#69、ゲート実行中)。ビュー優先+指標単位 Python フォールバック+standalone_basis 可視化。フロント無変更
- [x] PR-7 **マージ済 (#65)**(前掲)
- [x] PR-8 **マージ済 (#66)**。セグメント利益率推移+タブ再編。**セグメント別受注は /segments serving のメトリクス集合外→serving 拡張が前提(フォローアップ)**
- [x] PR-6 **マージ済 (#69)**。#70 chore も**マージ済**: 本番 alembic 適用完了(head=20260718_03)・baseline 再生成(乖離なし3ファイルのみ)・指紋契約再生成・CompanyChangeDashboard を decision surface カタログ208件目に登録・**compose e2e の縮退窓(baseline 直後は manifest head=chain head で managed シナリオ構造的 fail)を明示スキップに修正**
- 実データ検証済: 単Qビュー251万行、7203 の単Q売上4Q合計=通期累計(恒等式成立)
- [x] 行数ラチェット復元 **マージ済 (#71)**。_single_quarter_source.py/_panel_math.py/metric_catalog_sync.py へ純移動+re-export で patch 先維持。**shrink-only ラチェットは full レーンのみで pr-profile ゲートには出ない**(すり抜けに注意)
- セッション作成の worktree 6つは削除済(D:\Dev\Investment-wt-maincheck の残骸ディレクトリのみ権限で削除不可→ユーザー手動削除待ち)
- [x] セグメント全面再抽出**完了** (07-18 16:54)。バックアップ=scratch.segment_financial_facts_pre_fy_fix_20260718(183万行、確認後 DROP 可)。再抽出 331万 upsert→dedupe 後 182.8万行、幻の FY2027Q1 消滅、FY2026 四半期 35,180行。**JT(2914, 12月決算)の FY2025Q4 セグメント売上が実決算と一致(旧ロジックでは Q3 誤配置)**。segment_timeseries_aggregator 再集計済(43,168行)
- 残 ops: ①今夜19:50/20:10/20:29 定刻実行の確認 ②**BFF 再起動は保留** — BFF(PID 1604)はメインツリー(別セッションが旧ブランチで使用中)のコードで常駐しており、再起動しても PR-6 は載らない。メインツリーが最新 main に追随後に再起動+standalone_basis=sql_view 実測。PR-6 はフォールバック設計のため実害なし ③ラチェット修正 PR のゲート+マージ
- 並行セッション観測 (07-18 17時): D:\Dev\Investment-api-v2-20260718 / D:\Dev\Investment-earnings-reference-dashboard-20260718 が pytest 実行中(触らないこと)
- **教訓: DDL PR の CI 連鎖** = alembic revision + LOCAL_COMPOSE_BOOTSTRAP_FINGERPRINTS.json(generate-fingerprints)+ 本番適用後に baseline 再生成 + 指紋再々生成。desktop の decision-surface 候補コンポーネント追加は shared/catalogs/decision_surface_candidate_classifications.yaml + テスト定数の同時更新必須

## 重要な調査確定事項
- 単四半期換算は BFF Python に完全実装済(SQL 正本がないだけ)。新規 BFF エンドポイント 0 本で全画面構成可能
- /margin-bridge quarters<=40、/financial-history years<=15、/segments include_quarterly 対応済
- 表は既に全期間(limit=200)。制約はフロント定数のみ
- cross-audit は 07-17 に稼働再開済み(監査文書 7/15 の「一度も稼働せず」は古い)
- 訂正報告書 130/150/170 は抽出層実装済(edinet_extractor_corrections.py)

## 今後の課題バックログ(ユーザー「すべてやりたい」明言、今回スコープ外)
1. **正規化層再開**: core.edinet_facts_normalized 5ヶ月凍結。根因ほぼ特定 — `edinet-facts-refresh`(disclosure/repository_core_edinet.py:611)が run_manifest 未配線。配線+2026-02-20〜backfill で大量保有・取引先・供給網が復旧
2. コンセンサスEPS修復(史上0件→偽中立量産。IFIS に EPS 行なし、別ソース選定必要)
3. cross-audit warning 253 / value_mismatch 443 のトリアージ
4. 訂正報告書 E2E 検証(raw 取込側の 130/150/170 保存確認+訂正勝ちテスト)
5. 連結/単体区分カラム(raw.financial_reports.consolidation_basis nullable)
6. 単位契約明文化(backlog #36、COMMENT ON+共有定数)
7. earnings_quality_labeler 2ヶ月沈黙 / feature store numeric overflow 83日 stale
8. 原本ビューア(短信PDF/有報)+ 決算説明資料 KPI 抽出(非定型データ蓄積)

関連: [[project-repo-consolidation-2026-07-16]] [[project-pg-index-corruption-repair-2026-07-16]]
