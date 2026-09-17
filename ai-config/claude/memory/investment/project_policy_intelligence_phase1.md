---
name: project-policy-intelligence-phase1
description: 政策インテリジェンス (旧「規制」タブ) 再設計 Phase 1 着地 (2026-05-18)。DB/BFF/Desktop/2新ツール並列着地。
metadata: 
  node_type: memory
  type: project
  originSessionId: fa5bf6f7-14f3-4b78-87b5-50a3d100d5e7
---

# 政策インテリジェンス Phase 1 着地 (2026-05-18)

「規制」タブ運用不能問題への抜本再設計の第1段。プラン: `C:\Users\kazum\.claude\plans\sleepy-frolicking-deer.md`。

**Why:** 既存 `reg.*` 9テーブル + BFF 7 endpoint は精緻だが、官報・e-Gov・パブコメ・国会議案・審議会の取り込みツールが1本も実装されておらず実データほぼ空。さらに UI が Pipeline Kanban (5 ステージ) 主軸で「どの業界に何日後に何の影響が来るか」が一目で分からない。

**How to apply:** Phase 2 以降の作業 (timeline UI 骨格、パブコメ・国会議案ツール、LLM 業界タガー) はこの土台の上に積む。`law_tracker` (17省庁プレス RSS 既稼働) との重複は `regulation_alias` で連結する設計 (Phase 2 で実装)。

## Phase 1 着地物

- **DB**: alembic head=`20260518_23_reg_kanpo_sources`
  - 新規 `reg.kanpo_issues` / `reg.kanpo_articles` (`db/greenfield_postgres/38_regulatory_sources.sql`)
  - `reg.regulations` に `ministry_code` / `egov_law_revision_id` / `watch_priority` 追加
  - `reg.regulation_versions` に `enforcement_status` / `promulgation_date` / `partial_enforcement_dates` / `source_kanpo_article_id` 追加
  - `days_to_enforcement` は STORED 生成列にできない (`CURRENT_DATE` 非 IMMUTABLE) → BFF クエリで `(enforcement_date - CURRENT_DATE)::int` として算出
- **BFF**: `tools/api/decision_api/serving/_analytics.py` の `get_regulation_overview` を施行残日数昇順ソートに変更、`days_to_enforcement` / `days_to_pubcom` / `enforcement_status` / `promulgation_date` / `ministry_code` / `watch_priority` をレスポンスに追加。`get_regulation_detail_base` / `_version` も同様
- **新規ツール** `tools/market_data/egov_law_sync/` (8 ファイル + 5 テスト)、source_name=`egov_law`、manifest 2 ジョブ (daily 05:00 / weekly 月曜 04:00)。実 API パス未確定のため `--fixture` で fixture JSON テスト経路あり
- **新規ツール** `tools/market_data/kanpo_crawler/` (8 ファイル + 3 テスト)、source_name=`kanpo`、manifest 2 ジョブ (daily 平日 09:30 + reingest worker)。2025-04 完全電子化後の公式 JSON API 仕様は未確認、現状 HTML スクレイピング前提
- **Desktop**: タブ「規制」→「政策」、`/policy/regulations/:id` 全画面 route 新設 (RegulationDetailPage)、Drawer は内部委譲で並存、PipelineCard に施行残日数バッジ (≤7日=赤 / ≤30日=琥珀)、`truncate` 撤廃で `line-clamp-2 break-words`
- **shared/raw_ingest_tracking.py**: `_STALE_RUNNING_HOURS_BY_SOURCE` に `egov_law` / `kanpo` 追加

## 検証

- alembic single head `20260518_23_reg_kanpo_sources`
- ruff clean (新規バックエンド + BFF + shared)
- pytest 68 件 (regulation BFF 2 + egov_law_sync 33 + kanpo_crawler 33) 全 pass
- Desktop: lint / typecheck / vitest 全緑

## Phase 1 残宿題 (Phase 2 で消化予定)

1. e-Gov API v2 実エンドポイント仕様確定 (`egov_law_sync/client.py`)
2. 官報 2025-04 電子化後の公式 API 確認 + HTML/PDF パーサ実 markup 対応 (`kanpo_crawler/parser.py`)
3. `shared/source_freshness.py` DbRegistry SLA に `kanpo` / `egov_law` 登録
4. `law_tracker` との dedup → `reg.regulation_alias` テーブル新設 (Phase 2)
5. `kanpo_crawler --notify` の orchestrator 配線
6. `db/foundation_postgres/` への reg.* 同期 (現状 foundation 側に reg ファイルなし、Phase 2 で要評価)

## Phase 2 以降の予定 (プラン参照)

- Phase 2: タイムライン UI 骨格 + パブコメ・国会議案ツール + `reg.regulation_events` (event sourcing) + `reg.regulation_alias`
- Phase 3: LLM 業界タガー (Qwen 3.5 + 辞書ハイブリッド)
- Phase 4: 審議会クローラ + ingest 可視化バナー + `mart.vw_reg_timeline`

関連: [[adr_changes_2026q2]] (Notion 廃止 ADR、`/regulation` ページが唯一の UI)
