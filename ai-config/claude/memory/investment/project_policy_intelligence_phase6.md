---
name: project-policy-intelligence-phase6
description: 政策インテリジェンス Phase 6 着地サマリー (2026-05-23)。e-Gov v2 暫定承認 + kanpo parser 拡張 + KPI mart 計測基盤 + Desktop Header 配線。4 波 11 ストリーム並列着地。
metadata: 
  node_type: memory
  type: project
  originSessionId: ac4f768a-db9d-4d20-9e45-7497fd8988b9
---

# 政策インテリジェンス Phase 6 着地 (2026-05-23)

## 着地サマリー

Phase 5 ADR `20260520-egov-kanpo-api-investigation.md` で「Phase 6 以降に分割」
と固定された外部 API 経路を確定し、Phase 5 残宿題を半自動化、KPI 計測基盤を
BFF/Desktop で常時可視化。4 波 11 ストリームを並列マルチエージェントで 1 セッション完走。

- ブランチ: `feat/policy-intelligence-phase6` (worktree `D:/Dev/Investment-phase6`)
- 派生元: `main` (PR #12 マージ後 HEAD = f441ceda)
- Phase 1-5 保全: 2 commit (`docs: ...` + `feat: cumulative Phase 1-5`、491 ファイル / 70k 行)
- alembic single head: `20260523_01_reg_kpi_snapshot`
- Phase 6 pytest: **229 passed**
- Desktop typecheck: **0 errors**、vitest regulation 109 passed
- ruff: clean、scheduler integrity 37 passed、expected_task_count 102 → **105**
- scope.txt: 478 → **479** (KPI endpoint 追加)

## 波構成

### Wave 1 (4 並列)

- **S1**: ADR `20260523-egov-v2-api-resolution.md`。WebFetch 8 URL 全不発 → Phase 5 予告フォールバック発動、現行仮 path / law_type 5 値を Phase 6 暫定確定として承認
- **S2**: `kanpo_crawler/parser.py` の `_ARTICLE_TYPE_PATTERNS` を 32 官庁固有告示まで拡張、新規 `extract_pdf_metadata` 関数 (pypdf 6.6)、`_LAW_NUMBER_SHORT_RE` で略記吸収。test 47/47
- **S3**: Phase 5 残宿題 3 件の半自動化スクリプト 4 本 + Makefile target `regulation-phase5-runbook-check`、test 25/25
- **S4**: ADR `20260523-reg-kpi-snapshot-mart.md`。母集団 = active (lifecycle_stage IN proposal/deliberation/pubcom/enacted)、`mart.vw_reg_kpi_snapshot` view + `mart.reg_kpi_history` table (365 日リテンション)

### Wave 2 (3 並列)

- **S5**: `egov_law_sync/client.py` の `TODO(api-spec)` 2 箇所削除、`LAW_TYPE_ENUM` 公開 + バリデーション。parser 候補配列の第一候補に「v2 暫定確定」コメント。test 51/51
- **S6**: alembic `20260523_01_reg_kpi_snapshot` (down_revision=`20260521_01_shingikai_raw_blob_uri`)、greenfield/foundation `92_mart_regulatory.sql` 同期、`ensure_reg_kpi_*` 関数。test 29/29
- **S7**: kanpo `ingest.py` に PDF metadata 抽出 + blob 保管。HTML 由来 NULL 限定で metadata 補完 (上書きしない)、Issue 単位で PDF 1 回 fetch。Phase 5 shingikai pattern 流用。test 55/55

### Wave 3 (3 並列)

- **S8**: BFF `/api/v1/regulation/kpi-snapshot` (read_token、thresholds ok=0.95/warn=0.70)、`tools/quality/reg_kpi_snapshot/` 本実装 (`--dry-run` / `--json` / `--as-of` / `--retention-days`)。scope.txt 478→479、test 32/32
- **S9**: Desktop `KpiHeader.tsx` + `useRegulationKpiSnapshot` hook (60s refetch、BFF 接続失敗時は空 payload fallback で UI 壊さず)。閾値 rate=0.95/0.70、kanpo count=30/10、`SEVERITY_PALETTE` token 再利用。test 9 + smoke 1
- **S10**: manifest 3 task 追加 (`kanpo-backfill-monthly` / `egov-sync-diff-business-days` / `reg-kpi-snapshot-daily`)、expected_task_count 102→105。reg_kpi_snapshot は S10 でスタブ → S8 で本実装上書き

### Wave 4 (検証 + worklog)

- ruff clean / pytest 229 / typecheck 0 / vitest 109 / alembic single head / scheduler 37
- worklog: `docs/worklogs/20260523-policy-phase6-egov-kanpo-resolution.md`

## 重要な発見

### e-Gov v2 公式仕様は SPA で WebFetch 不可

`laws.e-gov.go.jp` は SPA で HTML→Markdown 変換ではアクセス不能。Phase 7 で
Playwright / 公式 API token 申請経由の再踏査が必要。

### kanpo `raw_blob_uri` カラムは既存 DDL に存在

Phase 5 S4 (shingikai) 着地時の `20260518_23_reg_kanpo_sources_and_versions_extensions.py`
で `raw_blob_uri TEXT` が追加済。S7 計画していた新規 alembic 不要。

### Phase 1-5 が PR #12 マージ後に全部未コミット状態だった

Phase 6 計画時に worktree を main から切ろうとして判明。reform + policy + earnings +
business-model + sector + jpx の Phase 1-5 累積差分が 364 ファイル未コミット。
2 commit に集約してブランチ確定 (docs / cumulative code) してから Phase 6 派生。

### reg_kpi_snapshot は S10 と S8 で並列着地

S10 (scheduler) が `tools.quality.reg_kpi_snapshot` モジュール存在を要求するため、
S10 が最小 CLI スタブを設置 → S8 が本実装で上書き。スタブ → 本実装の並列交代は
worktree 内で安全に着地。

## Phase 7 への持ち越し

### S1 ADR 暫定承認の解消

- Playwright / browser automation 経由で SPA 描画後の API 仕様を取得
- e-Gov 公式 API token 申請 → 認証付き OpenAPI 取得
- parser.py キー候補を第一候補 1 つに絞る

### KPI 閾値の運用調整

- ok=0.95 / warn=0.70 はハードコード、1 ヶ月運用後に table 外出し検討
- kanpo 30d count の moving average 化

### Phase 5 残宿題本番実行

- `make regulation-phase5-runbook-check` で事前検証 → ユーザ手動 apply
- worklog `20260520-policy-phase4-llm-probe.md` / `seed-load.md` の TBD を patch 経由で埋め

### ministry_order PDF の law_number 抽出

- `令7経済産業省令第4号` 等で kind トークンが正規列挙外 → None
- `_LAW_NUMBER_RE` の kind 列挙拡張または別アルゴリズム

## 関連 memory

- [[project-policy-intelligence-phase5]] — Phase 5 着地 (3 波 9 ストリーム)
- [[project-policy-intelligence-phase4]] — Phase 4 LLM 業界タガー基盤
- プラン: `C:\Users\kazum\.claude\plans\eventual-conjuring-hamster.md`
- ADR: `docs/decisions/20260523-egov-v2-api-resolution.md` (S1)
- ADR: `docs/decisions/20260523-reg-kpi-snapshot-mart.md` (S4)
