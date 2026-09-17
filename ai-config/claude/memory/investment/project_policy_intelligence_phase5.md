---
name: project-policy-intelligence-phase5
description: 政策インテリジェンス Phase 5 着地サマリー (2026-05-20)。Phase 4 残宿題 8 件 + 隣接拡張 2 件を 3 波 9 ストリームで並列着地。手動実行 3 件は runbook 化。
metadata: 
  node_type: memory
  type: project
  originSessionId: dd155cbf-8ecb-460e-ae5b-0ba57e8daedd
---

# 政策インテリジェンス Phase 5 着地 (2026-05-20)

## 着地サマリー

Phase 4 から繰越された 8 件の残宿題 + Phase 5 隣接拡張 2 件 = 計 10 ID。
3 波並列マルチエージェントで 9 ストリーム (S1〜S9) を 1 セッション完走、
手動実行 3 件 (S10〜S12) は runbook 化、最終検証 (S13) で全緑確認。

- alembic single head: `20260521_01_shingikai_raw_blob_uri`
- 全体 pytest (Phase 5 関連 + regression): **739 passed**
- Desktop typecheck: **0 errors**
- Desktop vitest (新規範囲): **117 passed** (regulation 99 + filter sidebar 18)
- ruff check: clean
- scheduler integrity: **37/37 passed**、expected_task_count 101 → **102**

## 波構成

### Wave 1 (3 並列 / 独立 docs / scope audit / fixture)

- **S1**: `docs/decisions/20260520-egov-kanpo-api-investigation.md` 新設 (~80 行)。e-Gov v2 / 官報 API 仕様調査 ADR、解消順序を「kanpo_crawler → egov_law_sync」と確定
- **S2**: `tests/scripts/test_decision_api_endpoint_contracts.py` に 2 test 追加 (`test_decision_api_typed_response_scope_completeness` + 回帰)。`scripts/decision_api_typed_response_scope.txt` に 76 行追記 (401 → **477 entries**)、ratchet 同期
- **S3**: `tests/fixtures/shingikai_crawler/` に 11 省庁分 fixture 追加 (22 ファイル)。`fetch_errors=61 → 0`、documents=347、smoke test に 12 省庁 errors=0 + fixture 存在チェック 2 assert 追加

### Wave 2 (4 並列 / バックエンド)

- **S4**: alembic `20260521_01_shingikai_raw_blob_uri` 新設、`reg.shingikai_documents.raw_blob_uri TEXT` 追加 + foundation/greenfield SQL 同期。ingest.py で `client.fetch_pdf()` → `FilesystemObjectStore.put_bytes()` → URI 保管、失敗時は logger.warning + NULL で続行 (graceful degradation)。test +4 (合計 35)
- **S5**: BFF `/api/v1/regulation/{regulation_id}/tagging-concordance` 新規 (read_token)。**`reg.llm_tagging_runs` / `reg.regulation_llm_tags` テーブルは存在せず、`reg.regulation_industry_tags` に `source` 列 ('dictionary'/'llm') で統合されている**。`sector_granularity:sector_code` キーで set 差分計算 → badge 4 種 (both/dict_only/llm_only/untagged)。scope.txt 477 → **478 entries**、ratchet 同期、openapi typegen 再生成
- **S6**: `tools/quality/shingikai_resolver_retry/` 新設 (8 ファイル) + `shared/regulation_alias_resolver.py` に `force_reattempt: bool = False` 引数追加 (既存 caller 挙動維持)。週次 cron `shingikai-resolver-retry-weekly` (土曜 04:00、source_type=quality_audit、quality_layer=L2) 登録、manifest expected_task_count 101 → 102。test 69 pass
- **S7** (S5 後): `/timeline` に `has_shingikai_referral: bool = False` query param 追加、True で `EXISTS (reg.regulation_events WHERE event_type='committee_referral')` を WHERE に注入。**`get_regulation_timeline()` は async/conn ではなく sync** だったため既存 pattern に合わせて実装。mart.vw_reg_timeline DDL 変更不要。test +2、419 passed (timeline 8/8)

### Wave 3 (2 並列 / Desktop)

- **S8** (S5 後): `desktop/src/pages/regulation/components/sections/TaggingConcordanceCard.tsx` 新設、6 状態対応 (loading/fresh/stale 24h+/untagged/empty/error)、badge 4 色 (ok/info/warn/muted tokens)、60s polling。RegulationDetailPage の sidepanel に CountdownCard と MetadataPanel の間に配置。React Fast Refresh 配慮で `*-utils.ts` 分離。test 8/8 + 既存 91 = 99 passed
- **S9** (S7 後): FilterSidebar に「審議会段階」(2 Chip toggle: 全表示/審議会段階のみ) 追加、`RegulationTimelineFilters.has_shingikai_referral` 配線。URL state sync (`&has_shingikai_referral=1`、default 値は省略)、`useRegulationUrlSync` の filtersKey 拡張で同期ループ防止。test 18/18 pass

### Wave 4 (手動 + 検証)

- **S10-12 runbook**: `docs/worklogs/20260520-policy-phase5-manual-runbook.md` 新設。3 件の手順 (順序: #2 ministry_industry_map → #3 pg_trgm CREATE EXTENSION → #1 LLM probe) + worklog 埋め方を集約
- **S13**: 全体検証完走、ruff clean / pytest 739 pass / typecheck 0 / alembic single head / scheduler 102 整合

## 重要な発見 (Phase 5 で確定)

### `reg.llm_tagging_runs` / `reg.regulation_llm_tags` は存在しない

Phase 5 S5 で当初プラン想定 (run 単位の 1:N) と異なり、実 schema は `reg.regulation_industry_tags` 1 テーブルに `source` 列 (`'dictionary'` / `'llm'`) + `llm_prompt_hash` + `created_at` で統合されていることが判明。

- 「最新 run」は `source='llm'` 行の `MAX(created_at)` と `llm_prompt_hash` で代用
- concordance キーは `sector_granularity:sector_code` を tag_key として使用
- badge 4 種判定は `source` 別に group して set 差分

Phase 6 以降で `reg.llm_tagging_runs` テーブルを切り出す場合はマイグレーション + Phase 5 endpoint の書き換えが必要。

### `get_regulation_timeline()` は sync 関数

プラン想定では `async + conn` 引数前提だったが、実コードは sync で `_query_optional_relation_rows` を内部使用。S7 は既存 pattern に合わせて sync 実装。

### `force_reattempt` 引数の効果

`shared/regulation_alias_resolver.attempt_resolution(force_reattempt=True)`:
- True: `resolution_attempts >= unresolvable_threshold` の row も skip せず再評価
- True: `upsert_alias_outcome()` で `resolution_attempts` increment しない
- 既存 caller (shingikai_crawler 等) は引数省略で従来挙動維持

### shingikai PDF raw blob の bucket

`Settings.object_store_bucket_raw` を再利用 (新規 env 追加なし)。backend が filesystem 以外なら `object_store=None` で raw blob 経路をスキップ。

## Phase 6 への持ち越し

### 手動実行 3 件 (runbook 化済)

`docs/worklogs/20260520-policy-phase5-manual-runbook.md` に手順集約。実施後に以下 worklog の TBD 埋め:
- `docs/worklogs/20260520-policy-phase4-llm-probe.md`
- `docs/worklogs/20260520-policy-phase4-seed-load.md`

### 外部 API 仕様確定 (Phase 6 以降)

- `tools/market_data/egov_law_sync/client.py:91-109` (TODO(api-spec))
- `tools/market_data/kanpo_crawler/client.py:83-107` (rate_limit, fetch_pdf 実装済)
- ADR: [[egov-kanpo-api-investigation]] (Phase 5 で新設)
- 解消順序: kanpo_crawler (parser 強化) → egov_law_sync (v2 仕様確定 → client 実装)

### 未消化の Acceptance criteria

- egov_law_id 埋まり率 >= 95%、days_to_enforcement >= 95% (実 API 後)
- LLM tagged 95% × active regulation、整合率 >= 0.80 (手動 probe + 本番 backfill 後)
- 12 省庁議事録 48h 内取込 (本番 scheduler 稼働後の継続監視)

## 関連 memory

- [[project-policy-intelligence-phase4]] — Phase 4 着地 (4 波 21 ストリーム)
- [[project-policy-intelligence-phase3]] — Phase 3 LLM 業界タガー基盤
- [[project-policy-intelligence-phase2]] — Phase 2 pubcom/diet/timeline matrix
- [[project-policy-intelligence-phase1]] — Phase 1 DB 拡張 + BFF
- プラン: `C:\Users\kazum\.claude\plans\sleepy-frolicking-deer.md` (Phase 1-4) + `C:\Users\kazum\.claude\plans\d-dev-investment-zany-peach.md` (Phase 5)
