---
name: project-policy-intelligence-phase3
description: 政策インテリジェンス Phase 3 着地 (2026-05-19)。LLM 業界タガー + alias 事前/deferred 解決 + 通知永続 dedup + Desktop 仮説レビュー queue + URL state sync + sectorImpact 撤去。13 タスク並列着地。
metadata: 
  node_type: memory
  type: project
  originSessionId: d3021af6-df99-40b6-bbff-9ed7dc058ef7
---

# 政策インテリジェンス Phase 3 着地 (2026-05-19)

[[project-policy-intelligence-phase2]] 続編。Qwen 3.5 LLM 業界タガー導入で「dictionary だけでは捉えきれない同一省庁内の業界差」を補完し、信頼度 < 0.7 を hypothesis レビュー queue に流す。Phase 2 残宿題 4 件 (alias 制約 / 永続 dedup / PS1 登録 / sectorImpact 撤去) も同時消化。プラン: `C:\Users\kazum\.claude\plans\d-dev-investment-structured-squid.md` Phase 3。

**Why:** Phase 2 で TimelineMatrix と confidence ドット描画は完成したが、データを流す側 (業界タグ自動付与) が未実装で confidence ドット自体が無描画。同時に alias 制約による scraper の register_aliases skip と、in-memory dedup によるプロセスリセット問題が積み残されていた。

**How to apply:** Phase 4 (審議会クローラ + ingest 可視化バナー + `mart.vw_reg_timeline`) はこの土台の上に積む。tagger backfill の concordance 集計 (`analytics.regulation_tagging_concordance`) は Phase 4 で Desktop OpsHub に可視化候補。

## Phase 3 着地物

### DB (alembic chain Phase 3 末端 head=`20260519_28_reg_notification_dispatch_log`)

- alembic 26: `reg.regulation_alias.regulation_id` を NULLABLE 化、partial UNIQUE 2 本 (resolved 用 `WHERE regulation_id IS NOT NULL` / pending 用 `(alias_kind, alias_value, source_tool) WHERE regulation_id IS NULL`)、`alias_resolution_status` (CHECK 3 種 'resolved'/'pending'/'unresolvable') / `resolution_attempts` / `last_resolution_at` 列追加
- alembic 27: `reg.industry_impacts` に LLM タガー由来カラム 7 個追加 (llm_model / llm_prompt_hash / llm_reasoning / dictionary_match / human_verified / verified_at / verified_by)。新規 `reg.ministry_industry_map` (UNIQUE 3 列 `(ministry_code, sector17_code, sector33_code)`) / `reg.regulation_industry_tags` (source CHECK 'dictionary'/'llm'/'manual', partial UNIQUE `(regulation_id, version_id, sector_code, source) WHERE superseded_by IS NULL`) / `analytics.regulation_tagging_concordance` (PK=run_id、サマリ集計形式)
- alembic 28: `reg.notification_dispatch_log` (UNIQUE (source_tool, dedup_key))
- greenfield 新設 2: `db/greenfield_postgres/40_reg_notification_log.sql` / `93_reg_industry_dictionary.sql`、`35_regulatory_intelligence.sql` 拡張
- foundation 同期: `db/foundation_postgres/35_regulatory_intelligence.sql` 末尾追記
- `shared/db_contracts/regulatory_intelligence.py` に 6 ensure_* 追加 (regulation_alias_deferred_columns / industry_impacts_llm_columns / ministry_industry_map / regulation_industry_tags / regulation_tagging_concordance / notification_dispatch_log)、`__init__.py` re-export 漏れ防止確認

### 新規ツール: `tools/market_data/reg_llm_tagger/` (8 ファイル)

- `prompts.py`: PROMPT_VERSION="v1"、build_industry_tagger_prompt(title, body, ministry_code, granularity, candidate_sectors) で system/user prompt 構築 + SHA256 prompt_hash。Jinja2 でなく既存 LLM ツール (news_intelligence / tdnet) の Python 文字列構築パターン踏襲。system prompt に「ETF/J-REIT/投信は対象外」明示
- `tagger.py`: SharedOllamaClient.generate(prompt, system_prompt, schema=INDUSTRY_TAGGER_SCHEMA) で JSON schema enforce、post-validate (mart.sector17/33 突合で未知 sector は confidence×0.5 derate)、ETF/REIT 出力 sector フィルタ
- `dictionary.py`: reg.ministry_industry_map から ministry_code → 候補 sector 引き当て
- `repository.py`: upsert_rows で reg.regulation_industry_tags に dict + llm tag 別行投入、confidence ≥ 0.7 のみ reg.industry_impacts upsert (sector_granularity='s17' のみ、impact_type='other' 固定)、record_concordance_run
- `ingest.py`: execute_with_tracking(source_name='reg_llm_tagger') 経由
- `notifier.py`: confidence < 0.7 を send_operational_alert(priority='P2', channel='hypothesis_review') で配信
- `main.py`: CliCommandSpec で 4 subcommand (init-db / tag-backlog / backfill / refresh-dictionary)
- tests 24 件 (test_tagger 7 / test_dictionary 5 / test_repository 7 / test_main 5)

### alias 事前/deferred 解決 (Phase 2 残宿題 #1 解消)

- `shared/regulation_alias_resolver.py` 新設: resolve_by_law_number / resolve_by_egov_law_id / resolve_by_title_fuzzy (pg_trgm similarity 経路、未導入時は NFKC + containment fallback、score 固定 0.95)、attempt_resolution が統一エントリ、`upsert_alias_outcome` ヘルパで partial UNIQUE 経路を一元化
- `tools/market_data/egov_pubcom_scraper/repository.py`: Phase 2 で全件 skip だった register_aliases を有効化、戻り値 `(resolved, pending)` 2-tuple
- `tools/market_data/diet_bills_scraper/repository.py`: 旧 _resolve_regulation_ids を削除、attempt_resolution 経由に統合
- `tools/notifications/law_tracker/grouper.py`: resolve_or_create_alias の SELECT に `regulation_id IS NOT NULL` フィルタ追加 (NULL row 許容のため)、INSERT は upsert_alias_outcome 経由
- pg_trgm extension: 本番 host で `CREATE EXTENSION pg_trgm` 必要。未導入時は containment fallback で動作するが、本番監視推奨

### regulation_event_notifier 永続 dedup (Phase 2 残宿題 #2 解消)

- `tools/notifications/regulation_event_notifier/notifier.py`: NotificationDispatchLogReader 新設 (起動時に `reg.notification_dispatch_log` から source_tool 一致の dedup_key を一括 SELECT してメモリロード、record(key, ...) で DB INSERT + メモリ追加)
- `pipeline.py`: `_PROCESS_SEEN: set[str]` 削除、run_once の seen default を NotificationDispatchLogReader に
- `repository.py`: record_dispatch helper を `upsert_rows(conn, ..., update_columns=())` (= DO NOTHING) で実装
- `_SeenKeySet` Protocol は維持、既存 in-memory テスト (set 渡し) は後方互換動作

### BFF (W3-1)

- `GET /api/v1/regulation/hypothesis-queue` (read token、HypothesisQueueResponse): superseded_by IS NULL + human_verified=FALSE + confidence < max_confidence、limit/offset/source/sector_code/sector_granularity フィルタ、partial_freshness は raw.ingest_runs best-effort
- `POST .../hypothesis-queue/{tag_id}/approve` (run token + X-Decision-Actor): human_verified=TRUE / verified_by / confidence=1.0 更新、sector_granularity='s17' なら reg.industry_impacts upsert (impact_type='other')
- `POST .../hypothesis-queue/{tag_id}/reject` (run token + X-Decision-Actor、body HypothesisRejectRequest): 新規 manual reject tag を挿入し superseded_by 連鎖、industry_impacts は human_verified スタンプのみ (削除しない)
- response_models に HypothesisQueueItem / HypothesisQueueResponse / HypothesisActionResponse / HypothesisRejectRequest 追加
- LookupError → 404 'hypothesis_tag_not_found' / RepositoryUnavailableError → 503 'control_plane_backend_unavailable'
- endpoint_registry + typed_response_scope + ratchet (395→399 / 472→475) 更新
- sectorImpact 撤去 (W1-4): router + serving + endpoint_registry + scope.txt + ratchet 整合 + openapi 再生成

### Desktop (W3-2 / W3-3 / W3-4)

- URL state sync (W3-2): `desktop/src/pages/regulation/url-sync-schema.ts` (zod) + `hooks/useRegulationUrlSync.ts`、`app-router.tsx` newsRegulationRoute に `validateSearch` 追加、`useUrlBackedTab` と共存 (view 値は preserve)
- HypothesisQueuePage (W3-3): `desktop/src/pages/regulation/HypothesisQueuePage.tsx` + components (HypothesisQueueTable / HypothesisQueueRow / ReasoningExpander / hypothesis-queue-utils) + hooks (useHypothesisQueueQueries) + fixture (404 fallback)。8 状態管理、楽観更新で行即時非表示、Reject は reason prompt 必須、semantic `<table role="table">` + aria-label
- IndustryImpactMatrix tooltip (W3-3): mechanism 行を text-sm に格上げ、ReasoningExpander で LLM reasoning 表示 (共通 component)
- sectorImpact 撤去 (W3-4): api-client.ts L451 import + L2699-2700 method / startup-preload.ts L1195-1201 task / query-keys.ts L522 key / types.ts L310-328 型を削除、CompanyResearchWorkspace の sectorImpact (macro_industry_impact、別物) は温存
- NewsRegulation.tsx NEWS_REGULATION_VIEWS に `regulation-hypothesis` (label「仮説レビュー」) 追加
- ReasoningExpander: `<details>` + `<summary>` ベース、`.reg-reasoning-summary::-webkit-details-marker { display: none; list-style: none }` で a11y button role 検出対応
- Mutation 後 invalidate: hypothesisQueue + timeline + detail

### Scheduler (W1-5 + W3-1)

- `scripts/register_schedules.ps1`: RegLlmTaggerQuarterHour (平日 09:00-17:30 / 15 分毎) + RegLlmTaggerBackfillWeekly (土曜 02:00)
- `scripts/run_reg_llm_tagger_quarter_hour.bat` / `_backfill_weekly.bat` 新設 (run_tool.ps1 -TaskId 経由規約踏襲)
- `scripts/run_manifest.yaml`: reg-llm-tagger-quarter-hour / reg-llm-tagger-backfill-weekly (scheduler_binding: required)
- `scripts/scheduler_expected_task_ids.txt` + `tests/scripts/test_scheduler_integrity.py::test_policy_intelligence_manifest_and_scheduler_bindings` 更新
- `shared/raw_ingest_tracking.py` `_STALE_RUNNING_HOURS_BY_SOURCE` に `reg_llm_tagger={"incremental": 2.0, "backfill": 4.0, "reingest": 2.0}` 追加

### Seed (W1-3)

- `db/seeds/regulation/ministry_industry_map.yaml`: 12 省庁 × 65 entry (FSA / METI / MHLW / MAFF / MEXT / MOD / MLIT / MIC / MOE / MOFA / MOJ / MOF)。3 列 UNIQUE `(ministry_code, sector17_code, sector33_code)`
- `scripts/load_regulation_seeds.py`: --target=ministry_industry_map / --check モード、upsert_rows 経由
- Makefile: `seed-ministry-industry-map` / `seed-ministry-industry-map-check` target

## 検証 (Phase 3 範囲)

- alembic head=`20260519_28_reg_notification_dispatch_log` 単一 (リポジトリ全体は 20260514_18 / 20260514_22 / 20260519_28 の 3 head が pre-existing、Phase 3 では触らず)
- ruff clean (Phase 3 全範囲)
- pytest:
  - shared/db_contracts: 23 件 (W1-2 で 11 件 → W1-FIX で 23 件に拡張)
  - shared/regulation_alias_resolver: 16 件
  - reg_llm_tagger: 25 件
  - egov_pubcom_scraper / diet_bills_scraper / law_tracker (alias 改修側): 329 件
  - regulation_event_notifier: 33 件 (既存 19 + 新規 14)
  - decision_api: 2174 件 (W3-1 で +9)
  - scheduler_integrity: 37 件 + 49 件 (BFF endpoint contracts)
  - 合計 2000+ 件 全 PASS
- Desktop:
  - typecheck クリーン
  - lint: 新規/変更ファイルでエラー 0 (pre-existing 54 errors / 10 warnings は本変更外)
  - vitest: 465 files / 2214 tests PASS (W3-3 で +16 / W3-2 で +6)

## Phase 3 残宿題 (Phase 4 で消化予定)

1. **e-Gov パブコメ + 衆参議案 実 HTTP 接続**: client.py は `NotImplementedError`、fixture 経路のみ完走 (Phase 2 から継続)
2. **e-Gov 法令 + 官報 実 API 仕様確定**: Phase 1 残宿題のまま継続
3. **3 alembic heads 解消**: 20260514_18 / 20260514_22 / 20260519_28 の 3 head、merge or branch chain 整理が別途必要
4. **本番 LLM probe**: reg_llm_tagger の Qwen 呼出 (実機 GPU) は未実施、fixture テストのみ完走
5. **`scripts/load_regulation_seeds.py --target=ministry_industry_map` 本番投入**: Phase 3 で yaml + loader は整備したが本番 DB への投入は別工程
6. **pg_trgm extension 本番有効化**: alias resolver の title_fuzzy が pg_trgm 推奨。未導入時は containment fallback で動作するが本番監視推奨
7. **reg.regulation_alias.resolution_attempts 上限到達 → unresolvable 遷移 job**: `tools/quality/` 配下に新設候補 (Phase 4)
8. **strict actor enforcement**: BFF approve/reject の `X-Decision-Actor` header が未送信時に `verified_by='desktop-actor'` default。Desktop 側で session actor を送信する配線は Phase 4
9. **scripts/decision_api_typed_response_scope.txt** から `timeline` GET が漏れていたのを W3-1 で発見・追加 (typed_scope=True ratchet 整合の副産物)

## Phase 4 以降の予定

- 審議会クローラ (shingikai_crawler / 12 省庁 × 主要審議会 80 件)
- ingest 可視化バナー (Desktop ヘッダ右に `[取込: 7/8 省庁 OK]` チップ + 省庁別取込状況パネル)
- `mart.vw_reg_timeline` (施行日順 + 業界 cross 集約)
- `desktop/src/pages/_dev/RegulationCatalog.tsx` (22 component × 8 状態 dev catalog)
- 概算 Tagging concordance Desktop 可視化 (analytics.regulation_tagging_concordance)

## 重要な設計判断 (Phase 3 で確定)

1. **prompt は Python 文字列構築 (Jinja2 不採用)**: 既存 news_intelligence / tdnet 等のパターンに揃え、依存追加を回避
2. **`reg.notification_dispatch_log` は独立テーブル**: `reg.regulation_events` の event_type CHECK 14 種は法令ライフサイクル正規化のため、通知メタを混在させない
3. **`reg.industry_impacts` vs `reg.regulation_industry_tags` 役割分担**: 前者は version あたり最終確定 1 行 (BFF 正本)、後者は dictionary/llm/manual の生提案ログ (superseded_by 連鎖で履歴保持)。LLM tagger は confidence ≥ 0.7 で industry_impacts upsert、低信頼度は tags のみ書込 → hypothesis queue 経由人手昇格
4. **ministry_industry_map UNIQUE 3 列 `(ministry_code, sector17_code, sector33_code)`**: 同一省庁 × 同一 sector17 で複数 sector33 を別 row で持つ運用 (FSA × 11 で 7050 銀行 / 7100 証券 / 7150 保険 / 7200 その他金融 など)
5. **ETF/REIT 除外は出力 sector 側で**: 入力規制側 (例: 投信法) で除外すると正規制を取り逃がす。`shared/instrument_policy.py` の判定は LLM 出力 sector に適用
6. **HypothesisQueueView 配置**: 政策タブ内 `?view=regulation-hypothesis` (独立 route ではなく NewsRegulation.tsx 内分岐)。filter 共有 + URL 共有が自然
7. **楽観更新 + approve 即実行 / reject reason 必須**: 連続レビュー UX を優先、approve は誤操作 = confidence 低下で queue に戻る安全機構あり、reject は監査ログ性で reason 文字列を要求
8. **alias 解決ハイブリッド**: 規則ベース (law_number / egov_law_id / title_fuzzy threshold≥0.85) で解決できれば事前確定 `status='resolved'`、できなければ NULLABLE で deferred queue 化 `status='pending'`。`resolution_attempts` カウントで unresolvable 遷移条件を将来追加可
9. **W1-FIX schema 整合の教訓**: 5 並列で alembic / db_contracts / loader を別エージェントが書くと、UNIQUE 列構成 / カラム追加範囲が独自解釈で食い違う (peer_group_id / is_current / 5 タプル UNIQUE 等の YAGNI 拡張)。プラン正本に最も忠実な alembic を「正」とし、db_contracts / greenfield / foundation / tests を縮小修正する後追い W1-FIX タスクで吸収。次回からは alembic に schema を確定させてから他を派生する順序が安全

関連: [[project-policy-intelligence-phase1]] / [[project-policy-intelligence-phase2]] / [[adr_changes_2026q2]]
