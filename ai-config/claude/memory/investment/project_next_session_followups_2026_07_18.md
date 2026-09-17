---
name: project-next-session-followups-2026-07-18
description: 財務変化追跡ロードマップ完了後の次セッション用バックログ(main ゲート負債一掃・派生指標の画面接続・EPS偽中立停止ほか、優先順位と着手点付き)
metadata: 
  node_type: memory
  type: project
  originSessionId: 02350eec-274a-44f9-8f49-edef7245291e
---

# 次セッション着手バックログ (2026-07-18 セッション終了時点)

前提: [[project-financial-change-tracking-2026-07-18]] のロードマップ8本+chore2本+ラチェット修正1本(PR #61-#63, #65-#71)は全てマージ済み。本番 alembic head=20260718_03。ユーザー承認済みの優先順: **1 → 2 の順で先行、3-4 はその後**。

## 優先1: main ゲート負債の一掃バッチ → **完了 (07-18 夜, PR #75 + #77)**
[[project-repo-state-repair-backlog-2026-07-18]] セッションの PR #75(app refresh)と財務バックログセッションの PR #77(残差分: sector_macro_impact の boundary 公開層復元+allowlist 負債2エントリ撤去・8569d3b9 で脱落した workflow marker/phase-b llm-gateway 3 gate 復元・tool_count_drift checker の README 単独参照化・registry count 追随)で完全解消。**main = check_suite 51/51 pass + pytest pr 0 fail**(PR #77 gate evidence)。
- **残: db レーン 69 fail**(`run_local_pytest --profile db`): tdnet backfill 等。07-13 green 化(PR #51)後の腐り→大統合起因の疑い。#75 の gate は run_local_db_gate(pass)までで db profile 全体は未検証。失敗リスト採取済みの手法: grep '^FAILED' で main と突合
- 教訓は継続: ゲート赤の判断は「main ベースラインと失敗リスト diff」で(件数比較では不足)

## 優先2: 派生指標ビューの画面接続 → **完了 (07-19 未明, PR #83)**
新エンドポイント `GET /company/{code}/financial-derived-metrics`(新 serving/router モジュール、wave10 typed)+ 変化タブ新パネル「営業利益の増減分解(円/pt)」(OperatingIncomeBridgePanel、直近期カード+期別テーブル、単Qは YoY/QoQ トグル)。BFF 再起動済みで実 200 確認。恒等式実測済(7203)。残: 実画面 QA(既存バックログと合流)・cold クエリ5秒(全銘柄用途が出たら materialized 化)・annual 層の粗利部分欠損期は GM<OPM の見かけ逆転あり(mixed_source で判別)。
- **db レーンも完了 (PR #82)**: 64 fail→0(370 passed/3 xfailed)。production 実欠陥2件同梱修正(pool の dollar-quote 破壊・20260711_10 downgrade の view 列削除不能)。xfail 3件は要リライト/read-path 設計判断としてバックログ化(20260718-db-lane-repair worklog 参照)

## 優先3: コンセンサスEPS偽中立の縮退停止(小粒先行)
consensus_eps 史上0件 → 改定モメンタム 69,309行が全件 direction='flat'/momentum=0 の偽中立を毎日量産(判断系への実害継続中)。
- 先行縮退: EPS 欠損時は direction='unknown' へ(小修正)。監査指摘: `revision_quality_score/scorer.py:113-114` の `/100` 撤去も同時に
- 本修復(別途): IFIS に EPS 行が存在しない→別ソース選定が必要な取得系トラック

## 優先4: 正規化層再開ほか(修復系)
- **core.edinet_facts_normalized 5ヶ月凍結**: 根因ほぼ特定済 — `edinet-facts-refresh`(tools/market_data/disclosure/repository_core_edinet.py:611 refresh_edinet_facts_normalized_impl)が run_manifest 未配線。manifest 配線(scripts/manifest/*.yaml→build_run_manifest.py --write)+2026-02-20〜backfill(月次チャンク)。下流: 大量保有・取引先・供給網が復旧
- earnings_quality_labeler 2ヶ月沈黙 / feature store numeric overflow(NUMERIC(18,6) 拡張)83日 stale
- 単位契約明文化(backlog #36)/ 訂正報告書 E2E 検証 / 連結単体区分カラム / cross-audit warning 253 トリアージ

## その他の控え(小粒・機会あれば)
- **実画面 QA 未実施**: 画面5本(チャート長期化・受注チャート・変化タブ・セグメント利益率・タブ再編)はコンポーネントテストのみ。$webapp-testing 等で実画面確認+IRバンク突合の銘柄拡充
- **BFF 再起動**: 常駐 BFF(port 8010)はメインツリーの旧コードで稼働中。メインツリーが最新 main 追随後に再起動→standalone_basis=sql_view を実測確認(それまで Python フォールバックで無害)
- **単Qビューの性能**: 全件走査 COUNT 7.1s。1社アクセスは問題ないが、スクリーナー等の全銘柄用途が出たら materialized view 化を検討
- セグメント別受注: /segments serving のメトリクス集合外(データは会社レベルのみ)。serving 拡張+セグメント受注ファクト投入が前提
- ~~2026-07-18 夜 19:50/20:10/20:29 定刻実行(EDINET 復旧後初回)の成否確認~~ → **確認済み (07-18 21時)**: raw.ingest_runs で edinet_db バルク群 20:07(success 2+partial 2、partial は予算系)・edinet incremental 20:30/20:33 success(150/373件)。健全
- D:\Dev\Investment-wt-maincheck 残骸ディレクトリのユーザー手動削除待ち

## 教訓(新セッションが引き継ぐべき運用知見)
- ゲート赤の判断は「main ベースラインと失敗リストを diff」で行う(件数比較では不足 — 件数一致でも中身が入れ替わる)
- DDL PR の CI 連鎖: revision + generate-fingerprints(LOCAL_COMPOSE_BOOTSTRAP_FINGERPRINTS.json)同一PR + 本番適用後 baseline 再生成 + 指紋再々生成。baseline 直後は compose e2e の managed シナリオが縮退窓(#70 で明示スキップ化済)
- desktop の decision-surface 候補コンポーネント追加時は shared/catalogs/decision_surface_candidate_classifications.yaml + テスト定数の同時更新
- shrink-only 行数ラチェットは full レーンのみ(pr-profile ゲートに出ない)— 大きめ Python 追加をしたら scripts/check_file_size_budget.py を手動確認
