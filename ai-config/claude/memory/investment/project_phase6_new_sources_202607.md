---
name: project-phase6-new-sources-202607
description: Phase 6 新規ソース接続完了 (2026-07-04) — IIP e-Stat 移行 / JSF逆日歩 / edinet text-blocks。非自明な知見多数
metadata: 
  node_type: memory
  type: project
  originSessionId: 8eca7815-00b8-4f60-b28f-29474a402de1
---

# 機能アップリフト Phase 6: 新規データソース接続 (2026-07-04, 未コミット)

alembic head: `20260704_03_phase6_new_sources`（down_revision=phase5）。新テーブル3本:
`raw.jsf_lending_daily` / `raw.edinetdb_text_blocks_raw` / `raw.edinetdb_company_profile_raw`。
greenfield `100_phase6_new_sources.sql` + foundation `82_*` + alembic の3点セット。

## 1. IIP を METI Excel → e-Stat API に移行（恒久退役）
- METI 2020基準 Excel はこの端末から取得不能（probe 実測: 0バイト/reset）。e-Stat が運用ソースに。
- **業種別 月次 原指数 statsDataId**: 生産=0004052181 / 出荷=0004052182 / 在庫=0004052183 / 在庫率=0004052184（2020=100.0、stat_name=鉱工業生産・出荷・在庫指数）。
- **この dataset は @time が代理コード（0500100等）で YYYYMM ではない**。getMetaInfo の time CLASS の @name に YYYYMM が入る。付加生産ウエイト行(0100100)は非月次でスキップ。
- **cat01(業種別_2020) の @name は「10桁METI業種コード + 日本語名」**（例 `1103000000 生産用機械工業`）。この安定 METI コードで意味キー5系列にマップ: manufacturing.general=1100000000 / production_machinery=1103000000 / transport_equipment=1107000000 / chemicals=1109000000 / iron_steel=1101100000。
- 実装: `tools/analytics/iip_sector_cycle/estat_adapter.py`（純粋パーサ）+ `repository.upsert_estat_core_values`（selected_source='estat', estat_value に格納, meti_value=NULL）+ main `ingest-estat` サブコマンド。core PK=(series,activity,month) なので原指数のみ採用（季調と併存不可）。
- **estat_tracker の 0003410734（不存在）→ 0004052181, filters cat01=0001000（鉱工業）に更新**。ただし代理 @time を日付化できないため `SeriesSpec.resolve_time_names` フラグ追加 → `_fetch_stats_data_once` で getMetaInfo の time 名で @time を YYYYMM に上書き（`_time_class_name_map` in ingest_helpers）。iip/activity バケットのみ True。
- **既存バグ修正**: 実データが初めて流れて `analytics.iip_screening_tailwind_daily` PK(as_of_date,code) 重複クラッシュ。コード6954 が manufacturing.general と production_machinery 両方の candidate_codes。calculator で screening を code 単位 max-exposure dedup。
- 検証: core 1980行/5系列/2018-01..2026-03、analytics 5セクター（Machinery strong_tailwind/recovery 等）。
- ADR: `docs/decisions/20260704-iip-estat-operational-source.md`。manifest: `iip-estat-ingest-monthly`(cron 30 6 5 * *) + `iip-estat-build-monthly`。旧 iip-meti 3本は disabled 維持。

## 2. JSF（日証金）逆日歩・貸株注意喚起 新ツール `tools/market_data/jsf_lending/`
- taisyaku.jp（robots.txt は実質404=制限なし）。CP932。**CSV直リンク**: `/data/shina.csv`(品貸料率=逆日歩, ヘッダ4行目) / `/data/seigenichiran.csv`(制限措置/注意喚起, ヘッダ5行目)。
- shina 列: 貸借申込日,決済日,コード,銘柄名,取引所区分,...,当日品貸料率(逆日歩),当日品貸日数,前日品貸料率,備考(満額),制限,応札倍率ランク。`*****`/満額=マスク値。
- **ETF/ETN/REIT 除外は core.instruments × instrument_policy.is_company_surface_eligible で**（プレフィックス単独NG: 1301極洋など13xx実企業を誤除外する。`is_fund_like_security` は name を渡すとprefix判定を回避するため、ETF略称(NF/iF/MXS/上場)がキーワード非一致で漏れる）。
- short_cost_collector(source_name=short_cost_proxy, 真の逆日歩なし)との分担: 実数ありは jsf_lending 優先。
- manifest: `jsf-lending-daily`(cron 15 16 * * 1-5)。検証: 937行(ETF除外後), 9983ファストリテ逆日歩4.05等。

## 3. edinet_db text-blocks/profile 配線
- `client.fetch_company_text_blocks`(有報定性17ブロック `{section,text}`)/`fetch_company_profile`(`{data,meta}`) を main `ingest-text-blocks` に配線。models `map_text_blocks`/`map_company_profile`、repository `upsert_text_blocks`(社単位 delete-then-insert)/`upsert_company_profiles`。
- **予算**: ops.edinetdb_call_budget_daily 共有カウンタ(try_consume_daily_budget)に相乗り。**edinet_db API はサーバ側1日100コール hard cap(429 "Daily rate limit (100)")が別途あり** — ops budget と二重。text-blocks は daily-budgeted-pack の残枠を opportunistic 利用(cron 0 7)。既定 max-companies=10, with-profile で2コール/社。
- 検証: text-blocks 34ブロック/2社を実書込み確認（profile は本日サーバ100枠消尽で429、マッパー自体は probe で検証済）。
- runtime_schema.py の RuntimeSchemaContract に edinet 2表+index、jsf_lending 新エントリ追加（require_runtime_schema_contract 検証型。closeout registry は runtime-CREATE 型のみ対象で新ツールは不要）。

## 登録・ゲート
- registry: `_ops_governance_defaults.py` に iip_estat(720h)/jsf_lending(24h) 追加 → ingest-governance-sync → freshness coverage ok。
- 全ゲート緑: cron_schema/mode_policy/scheduler_integrity/freshness/tool_count_drift。tool count 295→297・manifest active 317→332 等 doc 整合（先行フェーズ由来ドリフト含め実測に更新）。187 pytest 通過, ruff clean。
- **Windows スケジューラ登録（register_schedules.ps1 の5タスク: JsfLendingDaily/EdinetDbTextBlocksDaily/IipEstat×2 + bat）は人間境界で未実施**。要 `$scheduler-registration`。
- **既存の別失敗**: `tests/scripts/test_scheduler_integrity.py::test_ingest_freshness_check_reports_without_auto_recover` は Phase 3 が db-ingest-freshness-check-daily に --auto-recover を追加済み(HEADコミット)なのにテスト未更新で失敗。Phase 6 範囲外・私の変更と無関係。
