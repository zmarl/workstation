---
name: project-policy-intelligence-phase4
description: 政策インテリジェンス Phase 4 着地 (2026-05-20)。審議会クローラ + Ingest 可視化 + mart.vw_reg_timeline + Phase 3 残宿題 7 件消化。4 波 21 ストリーム並列で着地。
metadata: 
  node_type: memory
  type: project
  originSessionId: ef6e7aed-5e53-4a33-9f39-62c511e371ba
---

# 政策インテリジェンス Phase 4 着地 (2026-05-20)

[[project-policy-intelligence-phase3]] 続編。プラン: `C:\Users\kazum\.claude\plans\d-dev-investment-phase-4-buzzing-octopus.md` (原プラン Phase 4 セクション正本: `C:\Users\kazum\.claude\plans\sleepy-frolicking-deer.md`)。

**Why:** Phase 3 で LLM 業界タガー + alias deferred 解決まで揃ったが、(1) 政策レーン上流の「審議会段階」を取り込む手段が無く、(2) ingest 7 source の live 状況が Desktop から見えず partial state が静的、(3) `/timeline` SQL の 7 JOIN 直書きが保守を圧迫していた。

**How to apply:** Phase 5 (e-Gov 法令 + 官報の実 API 仕様確定、規制詳細サイドパネルへの concordance 個別表示、shingikai PDF raw_blob 保存) はこの土台の上に積む。Phase 4 で 4 波 21 ストリームを並列着地した運用記録は Phase 5+ の規模見積もりに使える。

## Phase 4 着地物

### DB (alembic Phase 4 末端 head=`20260520_02_enable_pg_trgm`)

- alembic 20260520_01: `reg.shingikai_meetings` (UNIQUE `(ministry_code, committee_name, meeting_date)` が idempotency key、`idx_shingikai_meetings_ministry_date` 索引)、`reg.shingikai_documents` (`dedupe_hash` UNIQUE、`doc_type` CHECK 6 種 'agenda'/'minutes'/'reference'/'report'/'draft'/'other'、`meeting_id` FK CASCADE、`regulation_id` FK SET NULL + 部分 partial index)
- alembic 20260520_02: `CREATE EXTENSION IF NOT EXISTS pg_trgm` (本番 super user 権限が必要、downgrade no-op で他機能の GIN index 依存保護)
- greenfield 同期: `db/greenfield_postgres/40_reg_shingikai.sql` 新設 + `db/foundation_postgres/40_reg_shingikai.sql` 同期
- mart view: `db/greenfield_postgres/92_mart_regulatory.sql` 末尾に View 4 `mart.vw_reg_timeline` 追記。出力 18 列、`DISTINCT ON (rv.regulation_id) ORDER BY version_id DESC` で latest version、`WHERE r.is_active AND rv.lifecycle_stage != 'completed'` 内包。CURRENT_DATE 算出の `days_to_enforcement` / `days_to_pubcom`
- `shared/db_contracts/regulatory_intelligence.py` に `ensure_shingikai_tables(conn)` 追加 + `shared/db_contracts/__init__.py` re-export 同期 (Phase 2 で発覚した抜けの再発防止)

### 新規ツール 2 本

#### tools/market_data/shingikai_crawler/ (8 ファイル)
- `main.py`: CliCommandSpec で init-db / ingest / ingest-since、`--fixture <dir>` で HTTP bypass
- `client.py`: `RATE_LIMIT_SECONDS=2.0` (0.5 rps)、UA `Investment-Tools/1.0 (+shingikai_crawler)`、timeout 30 秒、HTTP error は raise せず None + logger.warning で degrade
- `parser.py`: `parse_index_html` / `parse_meeting_html` / law_number regex (`令和[一二三四五六七八九十]+年法律第\d+号|平成[一二三四五六七八九十]+年法律第\d+号|第[一二三四五六七八九十百千]+号`) / doc_type 分類 / 日本語日付 parser
- `ingest.py`: `execute_with_tracking(source_name='shingikai_crawler')` 経由、`shared.regulation_alias_resolver.attempt_resolution` で law_number → regulation_id 解決、`_insert_committee_referral_event` で `reg.regulation_events` に event_type='committee_referral' (既存 14 種に既出、CHECK 制約変更不要) を NOT EXISTS guard 付き INSERT
- `repository.py`: `upsert_meetings` (conflict_columns=(ministry_code, committee_name, meeting_date))、`upsert_documents` (conflict_columns=(dedupe_hash,))、`compute_document_dedupe_hash` (sha256(pdf_url || title || meeting_id))
- `models.py`: dataclass (`MeetingRecord` / `DocumentRecord` / `ShingikaiIngestSummary`)
- fixture: `tests/fixtures/shingikai_crawler/{meti_index.html,meti_meeting_001.html,test_index.yaml}` (令和六年法律第28号 埋め込み、議事次第/議事録/資料1/資料2/中間取りまとめ案/答申 6 doc_type)
- 29 unit tests PASS

#### tools/quality/reg_alias_resolution_audit/ (Phase 3 残 #7)
- `auditor.py`: `audit_alias_resolution(conn, apply=, attempt_threshold=5, limit=1000)` で `alias_resolution_status='pending' AND resolution_attempts >= 5` を SELECT、`--apply` 時 `unresolvable` + `last_resolution_at=NOW()` で UPDATE
- `main.py`: CliCommandSpec で check / apply subcommand、`--json` / `--run-id` / `--attempt-threshold` / `--limit` 対応。`shared.raw_ingest_tracking.start_raw_ingest_run` / `finish_raw_ingest_run` で source_name='reg_alias_resolution_audit' を raw.ingest_runs に記録
- Exit code: check で candidates>0 で 1 (CI 検知用)、apply 常に 0
- 9 unit tests PASS

### 既存ツール改修

- **egov_pubcom_scraper 実 HTTP 化 (Phase 3 残 #1)**: `client.py:78-96` の NotImplementedError 撤去、`_safe_get` ベースで `https://public-comment.e-gov.go.jp/servlet/Public?CLASSNAME=PCMMSTOLIST` から HTML 取得、エラーは logger.warning + 空リストで degrade。`parser.py` に `parse_announcements_html` 新設 (BeautifulSoup で table 行走査、列順非依存ヒューリスティック、PCMMSTDETAIL anchor から id 抽出)。fixture `live_sample_2026.html` (期間表記 `〜` / `~` / `-` の 3 種混在 + noise table)。CI は `--fixture` 経路維持。31 tests PASS (Phase 2 既存 23 + Phase 4 新規 8)
- **diet_bills_scraper 実 HTTP 化 (Phase 3 残 #1)**: `client.py` は Phase 2 時点で `_safe_get` 経由実装済 + 1.5s rate_limit、`parser.py` に 211 国会 markup 対応 (`_COLUMN_HEADER_HINTS` に `議案種類` / `審議結果` 追加で `bill_type` 専用スロット分離)、`normalise_bill_number()` に `bill_type=` 引数 (閣法/衆法/参法 検出時 `"211-閣-1"` 形式で per-type 番号衝突防止)、`_extract_progress_dates()` を segment 分割方式に書換 (`<br>` 区切りで `enacted` が `floor_passed` を奪う問題解決)、chamber 単位 bill_number dedup。fixture `shugiin_live_211.html` / `sangiin_live_211.html`。42 tests PASS
- **disclosure_scanner events 連動**: `tools/notifications/law_tracker/disclosure_scanner.py` に `_maybe_emit_regulation_event()` 新設、強シグナル mention (`mention_type IN ('earnings_impact', 'compliance_cost')`、disclosure_reg_mentions の実 CHECK 制約に合わせて修正) のみ `reg.regulation_events` に `event_type='amendment'` + `source_tool='disclosure_scanner'` で NOT EXISTS guard 付き INSERT、confidence = min(0.9, 0.5 + 0.05 * mention_count)。返却 dict に `events_emitted` 追加。29 tests PASS
- **reg_llm_tagger に tag-single subcommand (Phase 3 残 #4 準備)**: `--regulation-id` 必須 (≤ 0 で error / exit 1)、`--version-id` 省略時 MAX(version_id) 自動解決、`--fixture` 指定で Qwen 不要 (CI 安全)、出力 JSON に `dictionary_tags` / `llm_tags` / `concordance{both_match,dict_only,llm_only}` / `elapsed_ms`。**read-only、DB 書込なし** (probe 専用)。本番 1 銘柄 probe はユーザー手動 trigger 待ち、worklog 雛形 `docs/worklogs/20260520-policy-phase4-llm-probe.md` 作成済。29 tests PASS (既存 25 + 新規 4)
- **db_capacity_audit に pg_extension 監視追加 (Phase 3 残 #6)**: `tools/quality/db_capacity_audit/auditor.py` に `_REQUIRED_EXTENSIONS = ('pg_trgm',)` + `_audit_extensions()` 新設、欠落で `CapacityViolation(violation_type='missing_extension', severity='warn', relation='pg_extension')`。snapshot 側 (`_ops_catalog.py`) に extensions list + extension_count summary 追加。23 tests PASS

### BFF (Phase 4 BFF 拡張)

- **新規 GET /api/v1/regulation/ingest-status** (read token only): 7 source (kanpo_crawler / egov_law_sync / egov_pubcom_scraper / diet_bills_scraper / regulation_event_notifier / reg_llm_tagger / shingikai_crawler) + 12 省庁 (shingikai_crawler の MAX(fetched_at) GROUP BY ministry_code) を集約。status 分類: `unknown` (記録なし) / `failed` (7d 失敗 ≥3 or last_success が 72h 超) / `stale` (24h≤age<72h) / `fresh` (<24h)。overall: failed が半数以上で `failed` / 失敗あり→`degraded` / 全部 fresh→`fresh` / 残り `partial`。response_models に `RegulationIngestStatusItem` / `RegulationIngestStatusResponse` 追加、scope.txt + ratchet (399/475→401/477) 同期。6 tests PASS
- **既存 /api/v1/regulation/timeline を mart.vw_reg_timeline 経由に切替**: `serving/_analytics.py:493-580` の `get_regulation_timeline()` SQL を `FROM mart.vw_reg_timeline v` ベースに書換、7 JOIN → 1 view + filter。`_timeline_sector_column("sub")` を `subsector_code` → `sub_sector_code` に修正 (view カラム名と整合、旧名は view にも DDL にも実存せず、過去から実 DB では動作しない潜在バグだった)。filter / sector_granularity / 並び順 / 出力カラム名すべて維持、6 tests PASS
- **strict actor enforcement (Phase 3 残 #8)**: approve/reject 2 endpoint で `_normalize_actor(default='desktop-actor')` → `_require_actor(x_decision_actor)` 置換 (None/空文字/whitespace で HTTPException(400))。`_normalize_actor` は他 endpoint 互換のため `_auth.py` に残置。8 新規テスト + 既存 9 件 = 17 PASS
- **新規 GET /api/v1/analytics/regulation-tagging-concordance** (read token only): `analytics.regulation_tagging_concordance` 最新 50 run の run_id 別 concordance 指標を時系列降順で返却。response_models に `RegulationTaggingConcordanceItem` / `Response`、scope.txt 同期。3 tests PASS

### Desktop (Phase 4 Desktop 拡張)

- **types.ts 整合**: `RegulationIngestStatus` を W3-A BFF shape にミラー更新 (source_name / ministry_code / consecutive_failures / avg_elapsed_ms / age_hours / error_count_7d / overall_status / fresh_count / total_count / research_meta)、`RegulationIngestSourceStatus` / `RegulationIngestOverallStatus` Literal 型追加
- **api-client.ts**: `regulationIngestStatus` の 404 フォールバックを新 shape (空 sources/ministries + overall_status='fresh') に更新、新規 `regulationTaggingConcordance(limit=50)` method
- **useRegulationIngestStatus hook**: `refetchInterval: 60_000` 追加 (Phase 4 60 秒 live update)
- **IngestStatusChip 新設** (`desktop/src/pages/regulation/components/IngestStatusChip.tsx`): `取込: N/M 省庁 [OK/一部遅延/遅延/障害]` chip、4 状態 (fresh/partial/degraded/failed) + loading/error の tone 分岐、popover トグル、aria-label / aria-expanded / aria-haspopup 完備
- **IngestStatusPanel 新設**: role="dialog" の詳細パネル、sources (7 source: 状態/最終成功/経過/7日エラー/平均 elapsed) と ministries (12 省庁: コード/状態/最終成功/経過/連続失敗) の 2 表構成、status badge 色分け、閉じるボタン
- **RegulationPage.tsx ヘッダ slot**: 右寄せに IngestStatusChip 配置、`useRegulationIngestStatus` を Page 側で呼んで `status !== 'fresh'` 省庁コードを timeline 側 `data.partial_ministries` と union して `TimelineMatrix` の `partial` / `partialMinistries` props に渡す形に変更 (Matrix は pure props のまま、既存テスト破壊なし)
- **TaggingConcordanceTab 新設** (`desktop/src/pages/ops-hub/tabs/TaggingConcordanceTab.tsx`): 上段 concordance_rate 30 run sparkline (85% target ライン付)、中段 最新 run の 両一致/辞書のみ/LLMのみ/未タグ bar、下段 最大 50 run の履歴テーブル。loading/fresh/stale/partial/empty/error の 6 状態、36h 超で stale 表示・目標未達で partial 表示
- **OpsHubPage.tsx**: タブリストに「規制タグ整合性」追加 (concordance tab)
- **/_dev/RegulationCatalog 新設** (`desktop/src/pages/_dev/RegulationCatalog.tsx` + `regulation-mock.ts`): 22 component × 8 状態 = 176 cell、4 section (matrix 7 / queue 4 / detail 6 / ops 5)、`BusinessModelCatalog.tsx:206-353` の Cartesian render パターン完コピで内容入替、独立 QueryClient で `regulation-ingest-status` / `regulation-tagging-concordance` キーを seed → 実 HTTP 発火せずに描画、StartupOverlayBypass で BFF readiness gate 回避、`ResolutionAuditCard` / `NoticeToast` 未実装は skeleton placeholder で fallback。`app-router.tsx` に `/_dev/regulation-catalog` route 追加 (`import.meta.env.DEV` ガード)。25 tests PASS

### Scheduler (W4-C)

- `scripts/run_manifest.yaml` の `tasks:` に Phase 4 entry 2 本追加:
  - `shingikai-crawler-weekday-morning`: 平日 07:00 JST、scheduler_binding: required、timeout 30 min、recovery_policy: auto_retry / max_auto_retries 2 / retry_backoff_sec 180、source_type: `market_data`
  - `reg-alias-resolution-audit-weekly`: 土曜 03:00 JST、scheduler_binding: required、timeout 15 min、source_type: `quality_audit` (manifest meta.source_type_slas に既存)、`quality_layer: L2` 必須
- `meta.scheduler_audit.expected_task_ids` + `scripts/scheduler_expected_task_ids.txt` 同期 (101 → 103)
- `scripts/register_schedules.ps1`: RegLlmTaggerBackfillWeekly 直後に 2 つの `Update-InvestmentTask` 行追加
- `.bat` ラッパ 2 本新規: `run_shingikai_crawler_weekday_morning.bat` / `run_reg_alias_resolution_audit_weekly.bat` (BOM なし UTF-8、`run_tool.ps1 -TaskId` 経由)
- `tests/scripts/test_scheduler_integrity.py::test_policy_intelligence_manifest_and_scheduler_bindings` を 2 entry 追加で更新、37/37 PASS
- `weekdays` ではなく manifest 既存規約 `days_of_week` を採用 (Phase 3 reg_llm_tagger-backfill-weekly と同形)

### Seed 工程化 (Phase 3 残 #5)

- `Makefile` に Phase 4 命名規約 `regulation-seed-ministry-map[-check]` を追加 (Phase 3 の `seed-ministry-industry-map[-check]` は互換性維持で残置)
- `scripts/load_regulation_seeds.py` docstring に Makefile 経由運用手順 + worklog リンク追記
- `docs/worklogs/20260520-policy-phase4-seed-load.md` 新規 (Lite 形式、check → apply → COUNT → reg_llm_tagger probe の 4 段階)
- 本番 DB への `--apply` 実行はユーザー手動 1 回 (本タスクではコード追加のみ)

## 検証 (Phase 4 範囲)

- alembic head=`20260520_02_enable_pg_trgm` single head 確認
- ruff clean (Phase 4 全範囲、F401 4 件 auto-fix 経由で解消)
- pytest:
  - shingikai_crawler: 29
  - reg_alias_resolution_audit: 9
  - reg_llm_tagger (tag-single 追加): 29 (既存 25 + 新規 4)
  - egov_pubcom_scraper: 31
  - diet_bills_scraper: 42
  - disclosure_scanner: 29
  - decision_api (新 endpoint 含む): 411
  - scheduler_integrity: 37
  - db_capacity_audit: 23
  - 合計 **Phase 4 範囲 602 PASS / 6 skipped (環境依存)**
- Desktop:
  - typecheck エラー 0
  - lint Phase 4 新規/変更ファイルでエラー 0 (pre-existing 22 errors は本変更外)
  - vitest 23 files / 119 tests PASS (regulation 85 + RegulationCatalog 25 + OpsHub TaggingConcordance 4 + 他)
- 統合 smoke:
  - shingikai_crawler fixture: meetings=21 / documents=42 (dry_run、kantei/cao 系 fixture 未提供のため fetch_errors 61 は仕様内 degrade)
  - load_regulation_seeds --check: entries=65 / ministries=12 / sector17=17

## Phase 5 残宿題 (Phase 4 から繰越)

1. **e-Gov 法令 + 官報の実 API 仕様確定 (Phase 3 残 #2 継続)**: 外部仕様待ち。Phase 3/4 共に客先依存で動かせない
2. **本番 LLM 1 銘柄 probe 実行 (Phase 3 残 #4 残り)**: コード (tag-single) と worklog 雛形は揃った、実 GPU 起動 + 1 銘柄 probe + confidence ヒストグラム測定はユーザー手動 trigger 待ち
3. **ministry_industry_map 本番 DB apply (Phase 3 残 #5 残り)**: Makefile + worklog 整備済、`make regulation-seed-ministry-map` の本番実行はユーザー手動 1 回
4. **pg_trgm 本番 DB CREATE EXTENSION (Phase 3 残 #6 残り)**: alembic revision 20260520_02 で `CREATE EXTENSION IF NOT EXISTS pg_trgm` 配線済、本番 super user 権限での upgrade 実行はユーザー手動
5. **typed_response_scope 漏れ検出 audit (Phase 3 残 #9)**: Phase 4 では新規 2 endpoint の scope 追記のみ。漏れ検出 audit 本体は Phase 5 へ
6. **規制詳細サイドパネルへの concordance 個別表示**: Phase 4 では OpsHub サブタブで全体可視化、個別 regulation の both/dict_only/llm_only badge は Phase 5
7. **shingikai_crawler PDF 原本 raw blob 保存**: `raw_blob_uri` 列の活用、Phase 4 では HTML/text のみ抽出
8. **shingikai 一部省庁 fixture 整備**: kantei/cao 系の fixture 未提供で fetch_errors が degrade されている、Phase 5 で 12 省庁 fixture 完備

## 重要な設計判断 (Phase 4 で確定)

1. **shingikai event_type は既存 committee_referral 流用**: CHECK 制約 14 種に既出。新 event_type 追加で CHECK 変更を避ける
2. **mart.vw_reg_timeline は greenfield SQL 直書き**: alembic ではなく既存 3 view と同じ運用 (`CREATE OR REPLACE VIEW` で冪等)
3. **disclosure_scanner events 連動は強シグナル限定 (mention_type 実 CHECK 制約に合わせて修正)**: タスク仕様の `enforcement_response` は実 CHECK 制約に無く、disclosure_reg_mentions の実 5 種 (`risk_factor / earnings_impact / compliance_cost / opportunity / other`) のうち証拠強度が高い 2 種 (`earnings_impact` / `compliance_cost`) を採用
4. **Tagging concordance は OpsHub サブタブ**: run_id 別時系列集計に粒度が合う。規制詳細サイドパネルは Phase 5 へ
5. **W1-B view の 3 列は NULL プレースホルダ**: `reg.regulations` に `ministry_code` 列無し (`governing_agency` TEXT のみ)、`reg.industry_impacts` に `sector33_code` / `sub_sector_code` 列無し。Phase 1 プランでは追加予定だったが未実装。view は NULL で出力、BFF 側で必要なら逆引き JOIN (現状は不要)
6. **W3-B view 切替で潜在バグ解消**: `_timeline_sector_column("sub")` の戻り値 `subsector_code` は view にも DDL にも実存せず、過去から実 DB ではエラーになる潜在バグだった。view 切替で `sub_sector_code` (NULL) に修正、行儀が「実行時 SQL エラー → 明示的 NULL」に変わるだけで実害なし
7. **strict actor 400 化は approve/reject 2 endpoint のみ**: 他 endpoint で `_normalize_actor(default='desktop-actor')` を使う箇所は touch しない、Phase 4 では hypothesis-queue 系のみ厳格化
8. **shingikai_crawler の重複防止**: `reg.regulation_events` は UNIQUE 制約持たないため ingest 側で `(regulation_id, event_type, event_date, source_tool)` の NOT EXISTS 検査必須
9. **alembic 線形維持**: Phase 4 で 2 revision を 20260519_29 にぶら下げて線形連結、merge revision 不要 (現 single head=20260520_02)
10. **TimelineMatrix の ingest-status 連動は Page 層 lift**: Matrix component は pure props のまま、Page 側で `useRegulationIngestStatus` を呼んで partial_ministries と union → props 経由で渡す。既存 Matrix テスト破壊なし
11. **manifest source_type は実存値を使う**: タスク spec の `quality` は manifest meta.source_type_slas に存在せず、`quality_audit` を採用。`quality_layer: L2` も check_scheduler_integrity.py の必須タグ
12. **23 ストリームを 4 波並列で完走**: Wave 1 (5 並列) → Wave 2 (6 並列) → Wave 3 (W3-A/B/C/F の 4 並列 → W3-D → W3-E の 3 段階) → Wave 4 (3 並列)。Phase 3 の 13 ストリーム / 3 波より大規模化したが、依存マトリクスを事前設計したため completion 競合なし

## 関連

[[project-policy-intelligence-phase1]] / [[project-policy-intelligence-phase2]] / [[project-policy-intelligence-phase3]] / [[adr_changes_2026q2]]
