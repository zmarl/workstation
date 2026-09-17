---
name: ADR 変更ログ 2026 Q2
description: 2026-03〜04 に確定した重要な方針転換と恒久廃止リスト。Notion 廃止 / ETF 除外 / Qwen→Claude / Control Tower 単一 UI / postgres-sole-write 更新を時系列でカバー
type: project
originSessionId: 06a37e34-9804-430a-aa3a-f36ce72a0a61
---
正本は `docs/decisions/`。本メモリは時系列+影響範囲のクイック参照。

## 時系列サマリ (2026-03〜04)

| 日付 | ADR | 決定 | 影響 |
|---|---|---|---|
| 2026-03-25 | `notion-deprecation.md` | Notion を Delivery Target から **完全廃止**。Desktop Control Tower を唯一の UI レイヤーとする | UI / Task管理 / 全 Notion 同期コード削除 |
| 2026-04-15 | `notion-role-delivery-target.md` (Superseded) | Notion 廃止実装完了。`mart.vw_notion_*` ビューは FastAPI BFF 経由で Desktop に配信 | Desktop / API / Scheduler |
| 2026-04-18 | `local-llm-desktop-control-plane.md` | Desktop = thin control plane。FastAPI が唯一の操作入口。LLM は `Desktop -> FastAPI -> LLM Gateway -> vLLM` のみ。Phase A は Ollama autostart スタック | Desktop / BFF / LLM 全体 |
| 2026-04-18 | `postgres-sole-write-target.md` (更新) | PostgreSQL = audit/journal 単一 write。DuckDB = read-only。Iceberg canonical / ClickHouse serving は独立 | Database / Schema |
| 2026-04-18 | `product-policy-etf-exclusion.md` | ETF/ETN を投資対象から **恒久除外**。us-market-pulse-daily / benchmark-proxy-collector-daily / Opportunity Cost / Safe Haven を恒久停止 | Market Data / Decision Support |
| 2026-04-18 | `kpi-extraction-decisions.md` | 入力優先順位を HTML > XBRL > PDF > OCR に固定。LLM はローカル Ollama。KPI 再開条件を OPS-12 完了に固定 | KPI / LLM / Scheduler |
| 2026-04-20 | `alt-data-external-scope.md` | 外部代替データは external tier。freshness SLA / contract audit に含めない | Data Platform |
| 2026-04-20 | `options-individual-scope.md` | オプションは個別銘柄スコープに限定 | Screener / Decision Support |
| 2026-04-21 | `supply-chain-llm-tier.md` | ローカル Qwen3.5:9b classifier を **廃止**。`tier_source='llm_inferred'` スキーマは Claude/Codex 書き込み先として保持 | Supply Chain / Analytics |
| 2026-04-21 | `supply-chain-classifier-claude.md` | 外部 API 不使用、Claude Code / Codex CLI 対話セッション + JSON import に変更。`tools/analytics/supply_chain_extractor/` 新設 | Supply Chain / Interactive |
| 2026-04-21 | `sub-sector-classification-layer.md` | 33業種 → 17業種 → サブセクター(1:N) → ピアグループ(1:1) の 4階層採用。週次再計算 | Classification / API / Desktop |
| 2026-04-21 | `20260421-operations-cleanup.md` | manifest を 4区分構造化: `tasks` / `disabled_tasks`(3件) / `retired_tasks`(3件) / `manual_only_tasks`(6件) | Scheduler / Manifest |

## 恒久廃止リスト (新規実装 / 復活提案禁止)

| 機能 | 廃止 ADR |
|---|---|
| Notion sync (双方向) | `notion-deprecation.md` |
| US Market Pulse / Benchmark Proxy / Opportunity Cost / Safe Haven | `product-policy-etf-exclusion.md` |
| Qwen 版 supply_chain_llm_classifier | `supply-chain-llm-tier.md` |
| TDnet KPI Gate / KPI Dashboard / backlog-sync-audit-daily | `20260421-operations-cleanup.md` |

## 横断的な意味

- **正本契約**: PostgreSQL (audit/journal) / Filesystem durable / Iceberg canonical / ClickHouse serving / DuckDB analytical の 5 層境界が固定
- **UI 単一性**: Desktop Control Tower 以外の表示先 (Notion / メール本文 等) は配信ターゲット非対応
- **LLM 経路統一**: 外部 API は使わず、Ollama or 対話 (Claude Code / Codex CLI) に統一。直接呼び出し禁止
- **ETF 恒久除外**: 商品ポリシーで ETF/ETN を扱わない。新規経路は instrument_policy filter を必ず通す
- **manifest 4 区分**: disabled は復活想定の standby のみ。恒久廃止は retired、手動運用は manual_only

## 利用シーン

- 「これ復活させてもいい？」が出たら本メモリで該当 ADR を確認
- アーキテクチャ判断で Iceberg / ClickHouse / DuckDB の役割を切り間違えないようにする
- スクリーニング / API / Desktop で ETF が混入していないか機能設計時に確認
