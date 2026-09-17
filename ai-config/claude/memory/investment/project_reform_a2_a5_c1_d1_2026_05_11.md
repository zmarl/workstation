---
name: 改革ロードマップ続編 4 並列着地 (#11 Phase 2-B' / foundation sync / #7 ActionQueueTab / FU-6 range)
description: 2026-05-11 着地。Stream A2 (DbRegistry violation 可視化補強) + A5 (foundation_postgres sync) + C1 (#7 ActionQueueTab に BehavioralAlertBanner) + D1 (FU-6 PbrHistoryChart range セレクタ) を 4 並列で着地
type: project
originSessionId: 427e9f2c-7d96-43c1-ad81-0449da993398
---
# 改革ロードマップ続編 4 並列着地 (2026-05-11)

直前セッション (改革 A+B+C 並列着地) の自然な続きとして、4 stream を S 粒度で並列着地。

## 着地内容

### Stream A2: DbRegistry violation 可視化補強
- `desktop/src/pages/ops-hub/tabs/DbRegistryTab.tsx` (+22 行) — critical 件数 summary chip を filter count 行隣に追加 (`text-rose-400`)、critical 行限定で 2 行 title + 強化 aria-label
- `desktop/src/pages/ops-hub/tabs/CatalogTabs.test.tsx` (+78 行) — `vi.hoisted()` で fixture state 切り出し、新 it block で critical シナリオ assertion
- BFF 変更ゼロ。critical_count=0 のとき chip 非表示で警告過多回避

### Stream A5: foundation_postgres sync
- `db/foundation_postgres/40_ops_tables.sql` (+88 行) — `security_audit_events` (12 col / 4 CHECK / 1 UNIQUE / INDEX 2) + `db_capacity_snapshots` (14 col / 1 UNIQUE / INDEX 2) を `command_runs` 直後に追記
- alembic 不要 (foundation_postgres は lexical order 実行、`README.md:24-26` 明記)
- greenfield 側 (`60_ops_quality.sql:927-1012`) からの 1:1 コピー、`IF NOT EXISTS` で IDEMPOTENT 維持
- psql 環境なしで構文検証 skip、次回 DB 接続環境で `psql --set ON_ERROR_STOP=1` 推奨

### Stream C1: ActionQueueTab に BehavioralAlertBanner 配置
- `desktop/src/components/portfolio/ActionQueueTab.tsx` (+3 行) — import + JSX 1 行
- `desktop/src/components/portfolio/ActionQueueTab.test.tsx` 新規 (102 行) — 5 メソッド mock + 3 it (集計表示 / critical alert / blockers 描画)
- 配置位置: 集計ヘッダ box `</div>` 直後、grid container 直前 (Dashboard.tsx:2614 と同等)
- BehavioralAlertBanner は内部で `useQuery(api.portfolioBehavioral)` 完結、props 不要

### Stream D1: PbrHistoryChart range セレクタ UI
- `desktop/src/components/company/charts/PbrHistoryChart.tsx` (+24 行) — RangeKey type + RANGES 定数 + useState + レジェンド行右に inline 4 ボタン (aria-pressed / aria-label)
- `desktop/src/components/company/charts/PbrHistoryChart.test.tsx` (+45 行、5→7 件) — range="1y" click 検証 + aria-pressed 単一 active 検証
- `Props.range` を `defaultRange` に rename (signature 後方互換)
- TimeRangeSelector token (`1D/1W/1M/...`) と PBR API 想定 (`1y/3y/5y/max`) が非互換のため専用 inline button group を新設

## Plan agent 出力で判明した重要な前提修正

| 項目 | 当初想定 | 実態 |
|---|---|---|
| Stream A2 | violation badge 未実装 | 既に実装済 (`DbRegistryTab.tsx:206-223` で severity badge + `+N日`)。残務は summary chip + tooltip 強化のみ |
| Stream A5 alembic | 必要 | 不要 (foundation_postgres は alembic 管理外、SQL ファイル lexical 実行) |
| Stream D1 既存 range UI | TimeRangeSelector 流用 | 流用不可 (token 非互換)。専用 inline button group を新設 |
| Stream C1 props | 親から props 経由 | `BehavioralAlertBanner` は内部で hook 完結、props 不要 |

## 検証結果

- `uv run ruff check .`: All checks passed!
- `uv run pytest tests/tools/api/ tests/tools/quality/db_capacity_audit/`: 2062 passed / 7 skipped
- `cd desktop && npx tsc --noEmit`: clean
- `cd desktop && npm run test`: 14 / 14 pass (CatalogTabs 5 + ActionQueueTab 3 + PbrHistoryChart 6)
- `cd desktop && npm run build`: success (vite + tsc -b、dist 全生成)

## 規模感

合計 ~393 行 (foundation +88, A2 +131, C1 +105, D1 +69)。S 粒度想定 (~229 行) に対し test 拡充で +160 行、本 phase 内では許容範囲。

## 残作業

- A2: retention summary header per-policy 集計 / trend chart は Phase 2-C 以降
- A5: greenfield ↔ foundation drift 検証 CI ゲート (Phase 3 候補)
- C1: ActionQueueTab 内で behavioral alert を decision item と統合する深い UX (Phase 2)
- D1: BPS 真 forward fill (`core.financial_facts_resolved_v2` LATERAL JOIN)、5y percentile バッジ、ROE 履歴の同経路展開 (FU-6 Phase 2)
- 改革 #11 Phase 2-C / Phase 3、#12 Phase 2、#8/#10、FU-7 → 別セッション

## 引継ぎ事項

1. PbrHistoryChart の loading/error/empty 状態では range セレクタが非表示 (chart container 内に配置のため)。必要なら上位レイアウトに移動 (Phase 2)
2. foundation_postgres SQL は psql 不在環境で構造検証のみ。実 DB 構文検証は次回必須
3. commit 単位は 4 stream 完全分離のため stream ごと別 commit が望ましい
