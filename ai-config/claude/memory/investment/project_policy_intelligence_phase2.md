---
name: project-policy-intelligence-phase2
description: 政策インテリジェンス Phase 2 着地 (2026-05-18)。パブコメ/国会議案ツール + event sourcing + alias 連結 + Desktop TimelineMatrix 主軸化 + Drawer 撤去。9 ストリーム並列着地。
metadata: 
  node_type: memory
  type: project
  originSessionId: 6446fee9-225b-4b95-9892-e4790a137bbc
---

# 政策インテリジェンス Phase 2 着地 (2026-05-18)

[[project-policy-intelligence-phase1]] 続編。「規制」タブ運用不能問題の Phase 2 着地。プラン: `C:\Users\kazum\.claude\plans\sleepy-frolicking-deer.md` Phase 2、実装プラン: `C:\Users\kazum\.claude\plans\d-dev-investment-fancy-hoare.md`。

**Why:** Phase 1 で官報 / e-Gov 法令の取り込みは入ったが、(a) パブコメ・国会議案の実データ欠落、(b) Pipeline Kanban 主軸で施行残日数が見えない、(c) Drawer 480px + truncate で本文が読めない、の 3 つを同時に解消する必要があった。

**How to apply:** Phase 3 (LLM 業界タガー + 信頼度ドット配線) と Phase 4 (審議会クローラ + ingest 可視化バナー + mart view) はこの土台の上に積む。`regulation_alias` の `regulation_id NOT NULL` 制約のため、新規 scraper の `register_aliases` は当面 skip 経路。Phase 3 で alias の事前解決か NOT NULL 緩和が必要。

## Phase 2 着地物

- **DB**: alembic chain Phase 2 末端 head=`20260518_25_reg_events_alias`
  - 新規 `reg.pubcom_announcements` / `reg.diet_bills` / `reg.diet_bill_progress` (alembic 24)
  - 新規 `reg.regulation_events` (event sourcing, 14 event_type CHECK) / `reg.regulation_alias` (6 alias_kind CHECK, UNIQUE) (alembic 25)
  - `reg.regulatory_actions` に `source_tool` / `raw_blob_uri` / `dedupe_hash` 追加 + 部分 UNIQUE INDEX
  - `db/greenfield_postgres/39_reg_pubcom_diet.sql` 新設、`db/foundation_postgres/35_regulatory_intelligence.sql` 新設 (Phase 1 残宿題 #6)
  - `shared/db_contracts/regulatory_intelligence.py` を Phase 2 で新規作成 (Phase 1 では未実装と判明)、`ensure_pubcom_diet_tables` / `ensure_reg_event_tables` / `ensure_reg_alias_table` / `ensure_reg_action_extensions` / `ensure_reg_source_tables` を実装し `shared/db_contracts/__init__.py` で re-export

- **新規ツール 3 本**:
  - `tools/market_data/egov_pubcom_scraper/` (CliCommandSpec パターン、`source_name='egov_pubcom'`)、fixture 経路で完走、manifest `egov-pubcom-scraper-business-hours` (営業日 09:00-18:00 30分毎)
  - `tools/market_data/diet_bills_scraper/` (legacy argparse + `_DISPATCH` パターン、HTML パース主体、`source_name='diet_bills'`)、衆参 fixture HTML、manifest `diet-bills-scraper-daily-{morning,midday,evening}` (平日 09:30/13:30/17:30)
  - `tools/notifications/regulation_event_notifier/` (15分毎 polling、`reg.pubcom_announcements` deadline=7日 + `reg.diet_bill_progress` floor_passed/enacted を P2 通知)

- **既存ツール改修**:
  - `tools/notifications/law_tracker/grouper.py` に `resolve_or_create_alias(conn, grouping_key, regulation_id)` 追加、in-memory cache + DB 永続化
  - `tools/notifications/law_tracker/repository.py` の `save_actions` に `source_tool='law_tracker'` / `raw_blob_uri` / `dedupe_hash` (SHA256(title:date:agency)) を埋め、`ON CONFLICT (dedupe_hash) DO NOTHING` で二重書込防止
  - `tools/market_data/kanpo_crawler/main.py` の `--notify` を `shared.notifications.delivery.send_operational_alert` 経由 P2 配線 (Phase 1 残宿題 #5)

- **BFF**: `GET /api/v1/regulation/timeline` 新設 (7 フィルタ: sector_granularity / agency / direction / stage / enforcement_within_days / min_confidence / search)。8 バンド (today/within_7d/.../within_2y/undated) × 業界の matrix を返却、`partial_ministries` は `raw.ingest_runs` から best-effort 取得。`tools/api/decision_api/serving/_analytics.py` に `get_regulation_timeline()`、response_models に 6 モデル追加、`desktop/generated/decision-api.openapi.json` 再生成

- **Desktop**:
  - 撤去 (物理削除): `PipelineKanban.tsx` / `SectorImpactHeatmap.tsx` / `RegulationDetailDrawer.tsx` / `ActionsFeed.tsx` (トップ) + 各 `.test.tsx`
  - rename: `PipelineCard.tsx` → `TimelineCell.tsx`、`truncate` 撤廃 / `line-clamp-2 break-words` / `text-sm` 格上げ
  - 新規: `TimelineMatrix.tsx` (縦 8 時間バンド × 横 17 業界 grid、role="grid"/gridcell + aria-rowindex/colindex 完備、8 状態スナップショット緑) / `FilterSidebar.tsx` / `MatrixHeader.tsx` / `useRegulationTimeline.ts` / `__mocks__/timeline-fixture.ts`
  - `RegulationDetailPage.tsx` を `sections/` 配下 7 component (HeaderSection / LifecycleProgress / CountdownCard / BeforeAfterSection / IndustryImpactMatrix / CompanyExposureTable / ActionsTimelineSection) の組み立てに書き換え、Drawer 完全撤去
  - `useRegulationStore.ts` から drawer 系削除、`filters: { agency, stage, direction, sector_granularity, search, min_confidence }` + setter 追加 (URL state 同期は zustand までで Phase 3 持ち越し)
  - `api-client.ts` の `regulationTimeline` は BFF 未配線時に 404 → fixture フォールバック内蔵

- **shared/raw_ingest_tracking.py** `_STALE_RUNNING_HOURS_BY_SOURCE` に `egov_law` / `kanpo` / `egov_pubcom` / `diet_bills` / `regulation_event_notifier` を追加 (Phase 1 で追加宣言されていたが実体は Phase 2 で投入)

- **shared/source_freshness.py** `_PROBE_SPECS` に `egov_law` (06:00 JST ready, 全日) / `kanpo` (10:00 JST ready, 平日のみ) を追加 (Phase 1 残宿題 #3)

## 検証 (Phase 2 範囲)

- alembic Phase 2 chain head=`20260518_25_reg_events_alias` 単一 (リポジトリ全体は 20260514_18 / 20260514_22 / 20260518_25 の 3 head だが他 2 つは Phase 2 以前から存在する別ブランチ)
- ruff clean (Phase 2 全範囲: shared/db_contracts/ / shared/raw_ingest_tracking.py / shared/source_freshness.py / tools/market_data/egov_pubcom_scraper / diet_bills_scraper / kanpo_crawler / egov_law_sync / tools/notifications/regulation_event_notifier / law_tracker / tools/api/decision_api/)
- pytest: db_contracts 11 / source_freshness 5 / raw_ingest_tracking 26 / egov_pubcom 26 / diet_bills 33 / kanpo_crawler test_main 5 / regulation_event_notifier 19 / law_tracker 254 / decision_api 625 → **計 1,000+ 件 全 pass**
- Desktop regulation 範囲 vitest 53 / 13 file 全 pass、TimelineMatrix 8 状態 snapshot 緑、a11y `role="grid"` / `aria-rowindex` / `aria-colindex` 検証

## Phase 2 残宿題 (Phase 3 で消化予定)

1. **`reg.regulation_alias.regulation_id` NOT NULL 制約**: 新規 scraper (egov_pubcom / diet_bills) の `register_aliases` は当面 skip。Phase 3 で title/law_number/ministry_code から事前解決するか NOT NULL 緩和か方針決め
2. **`regulation_event_notifier` の永続 dedup**: 現状 in-memory `set` のみで 15 分毎の新プロセスでは状態がリセット。Phase 3 で `reg.regulation_events` に notified payload を永続化
3. **`scripts/register_schedules.ps1` に Phase 2 manifest entry 4 件未登録**: `EgovPubcomScraperBusinessHours` / `DietBillsScraperDaily*` / `RegulationEventNotifierQuarterHour` を Task Scheduler に登録する PS1 配線が別途必要
4. **URL state 同期 (`validateSearch` + `useSearch`)**: zustand までで Phase 3 持ち越し
5. **`regulationSectorImpact` API メソッドと query key**: `startup-preload.ts` から参照されているため後方互換のため残置、Phase 3 で preload 整理と一緒に撤去
6. **e-Gov パブコメ + 衆参議案 実 HTTP 接続**: client.py は `NotImplementedError`、fixture 経路のみ完走。Phase 3 で robots.txt 再確認 + 実 markup 照合
7. **e-Gov 法令 + 官報 実 API 仕様確定**: Phase 1 残宿題 #1/#2 のまま継続
8. **3 alembic heads 解消**: 20260514_18 / 20260514_22 は Phase 2 以前から存在する別ブランチ。merge or branch chain 整理が別途必要
9. **`shared/db_contracts/__init__.py` の re-export** は実装完了時に追加し忘れ、最終統合検証で発見・修復済 (本セッション内対応)

## Phase 3 以降の予定

- Phase 3: LLM 業界タガー (Qwen 3.5 + 辞書ハイブリッド)、信頼度ドット配線、URL state 同期、register_aliases 事前解決
- Phase 4: 審議会クローラ + ingest 可視化バナー + `mart.vw_reg_timeline` + RegulationCatalog dev page

関連: [[project-policy-intelligence-phase1]] / [[adr_changes_2026q2]]
