---
name: project-error-sweep-2026-07-09
description: 定常エラー一掃バッチ (2026-07-09) — 毎日failed 8系統+degraded 4系統の修理記録と再発防止知見
metadata: 
  node_type: memory
  type: project
  originSessionId: 0ed8cc77-f1b5-4122-b540-6d78510d83a7
---

# 定常エラー一掃バッチ (2026-07-09 完了)

夜間スケジューラで毎日 failed になっていた 8 系統 + 品質 degraded 4 系統を一括修理。
alembic 3 revisions (`20260709_01/02/03`) + DB baseline 再生成 + file size budget baseline 更新込み。

## 修理内容 (要点)

| 系統 | 真因 → 修理 |
|------|------------|
| tdnet_delist_monitor | `20260517_02` が CREATE TABLE IF NOT EXISTS 方式で既存テーブルに event_key 列が追加されず「適用済みだが列なし」乖離 → `20260709_01` で ALTER+sha256バックフィル+unique index |
| estat_tracker | Stage2 closeout で無効 index 3本を DROP 後、再作成 migration が無かった → `20260709_02` |
| raw-contract-audit 17件 | `shared/db_contracts/_ops_governance_defaults.py` の契約9件が metric_key (実列は series_key)、estat_daily/financial_reports も実列と乖離 → 修正+governance sync。**契約は DB でなくこのファイルが正** (sync が毎日上書き) |
| egov_law | v2 API 暫定パス law_lists/law_updates が 404。実仕様は `/laws` + ネスト構造 + `order=-revision_info.updated`。さらに reg.regulations.egov_law_id の unique index 欠如で upsert 不可 → `20260709_03`。ADR `docs/decisions/20260523-egov-v2-api-resolution.md` に Phase 7 確定表を追記済み |
| shingikai_crawler | --since なし ingest が毎回フルクロール (2秒RPS×全会議×全PDF) で 30分 wrapper 超過 → incremental モードは既定 30 日 rolling window (`DEFAULT_INCREMENTAL_LOOKBACK_DAYS`)。fixture 経路は適用外 |
| news_detector serve | stuck_task_detector が timeout_minutes:0 (無制限) タスクをマップせず 120 分デフォルトで健全 serve を force-fail → timeout 0 は 1440 分天井にマップ + manifest に `source_names: [news_detector]` |
| disclosure reingest worker | --source both が全ソースの queue を claim → dispatch 非対応で毎回 failed → claim/list を edinet/tdnet に限定 |
| embedding indexer | ollama `nomic-embed-text` 未導入 → pull 済み・実行成功 |
| fx degraded | BIS EER 月次に staleness 7日 → 45日 |
| macro degraded | FRED の JP CPI/PMI 系は月次+数週ラグで revision 35/45日が構造的偽陽性 → 75日。**jp.cpi (JPNCPIALLMINMEI) は実データも 2026-03 止まりの上流ラグ — e-Stat (main.estat_daily.cpi_headline) への乗り換えが残課題** |
| sector_indicators jama | lookback 60日 < 公表ラグで YoY 正規化 0 件 + persist フィルタでも最新公表月が落ちる → `normalization_window_start` に 3ヶ月バッファ + persist 側も同バッファ |
| sector_public_kpis | agri_price: maff /nouka/ 廃止(403)→ /noubukka/ + e-Stat 直リンク workbook パーサ新設。power_demand: enecho 3-1 xlsx パーサ未実装だった → 月別シート「合計」行パーサ新設。`workbook_parsers.py` に分離 (file size budget対応) |

## 再発防止の知見

- **IF NOT EXISTS 方式 migration の罠**: 既存テーブルがあると列定義差分が永遠に塞がれない。修理は「headの後ろに ALTER の新 revision」一択 (詳細 [[bugs]])
- **METI系ドメイン (meti.go.jp / enecho.meti.go.jp) は bot 対策**: カスタム UA→403、ブラウザ UA でも連続アクセスで 202 チャレンジ。日次 1 回なら通る。maff.go.jp はページ単位で 403 (廃止ページ)
- **月次官公庁統計の公表ラグ**: lookback < ラグだと (1) YoY 正規化基準月がウィンドウ外 (2) persist の from_date フィルタで最新公表月が落ちる、の二段構えで空になる
- **file size budget**: 凍結超過ファイルへの追加は新モジュール分離が正道。どうしても残る分は `--write-baseline` 再生成を同一コミットに含める
- shingikai の mlit 系 3 委員会 index と e-Stat 系 manual_follow 3 ソース + warehouse/wholesale link_drift は既知の warning 枠 (blocking ではない)

## Handover / 残課題

- 翌日 (2026-07-10) のスケジューラ実行で全系統 success/partial 化を確認する
- macro.jp.cpi.yoy の e-Stat ソース接続 (SeriesSpec fallback 機構利用)
- estat_tracker は failed→partial 化。残る degraded は e-Stat メタデータ鮮度 (metadata_refresh) で reingest ops が自動追跡中
- shingikai の mlit 3 委員会は index URL 変更の可能性 (fetch_failed) — 別途追随
- 電力需要の旧 DB 値 (2025-10〜12, 171M MWh) は新パーサ値 (42-50M) と定義が異なる。新値は需要実績合計で一貫
