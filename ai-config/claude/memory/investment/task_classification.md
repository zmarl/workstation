---
name: scheduler タスク 4 区分運用
description: scripts/run_manifest.yaml の tasks / disabled_tasks / retired_tasks / manual_only_tasks の区別。2026-04-21 cleanup ADR で確定した運用ルール
type: project
originSessionId: 06a37e34-9804-430a-aa3a-f36ce72a0a61
---
正本: `docs/decisions/20260421-operations-cleanup.md` (Accepted)、実装: `scripts/run_manifest.yaml` + `scripts/register_schedules.ps1`。

## 4 区分の意味

| セクション | 意味 | スケジューラ登録 | `.bat` ファイル | 件数 (2026-04-21) |
|---|---|---|---|---|
| `tasks:` | Active (定期実行) | あり | あり | 既存 + 4 復活 |
| `disabled_tasks:` | 商品ポリシー停止 / standby のみ | なし (将来復活想定) | あり (停止中) | **3** |
| `retired_tasks:` | 恒久廃止 (コード削除済み) | unregister 対象 | なし | **3** |
| `manual_only_tasks:` | 意図的に手動運用 | なし | あり | **6** |

## disabled_tasks (3 件)

商品ポリシー変更まで継続停止:

| タスク | 理由 |
|---|---|
| `us-market-pulse-daily` | ETF 政策 ADR `product-policy-etf-exclusion.md` |
| `benchmark-proxy-collector-daily` | 同上 |
| `securities-report-qualitative-batch-daily` | Monex Scouter 優先で standby |

## retired_tasks (3 件)

恒久廃止、コード削除済み:

| タスク | 廃止理由 |
|---|---|
| `tdnet-kpi01-gate-daily` | TDnet 固有 SLA で運用困難。OPS-12 Gate がカバー |
| `tdnet-kpi-dashboard-daily` | 独立 KPI 計測廃止。決算評価ツールへ統合予定 (別セッション) |
| `backlog-sync-audit-daily` | primary-only backlog cutover で需要消失。CLI として残置 |

## manual_only_tasks (6 件)

スケジューラ登録対象外、必要時のみ手動実行:

| タスク | 手動実行が必要な理由 |
|---|---|
| `tradingview-server` / `tradingview-watchdog` / `tradingview-daily-scan` | webhook 受信 + scan-daily を必要時のみ |
| `twitcasting-bridge` / `twitcasting-monitor` | Chrome 拡張連携時のみ |
| `monex-scouter-scrape-weekly` | MFA 手動突破必須 |

運用手順は `docs/operations/manual-only-tools.md`。

## 復帰した 4 件 (2026-04-21 active へ移動)

| タスク | 復帰理由 |
|---|---|
| `scheduler-bindings-external` | 10 営業日安定の restore_condition 満了 |
| `tdnet-resolve-pending-assets-daily` | asset registry 修復連動で日次化 |
| `cycle-analyzer-ingest` / `cycle-analyzer-compute` | input contract `docs/contracts/cycle_analyzer_input.md` 確定 |

## 数値の現状 (実態 2026-04-28)

CLAUDE.md 記載 `active 267 / disabled 3 / manual-only 20` は古い。実態は active 308。本メモリと CLAUDE.md は同期済み (Phase 1 で更新)。

## 利用シーン

- タスクを停止するとき、どの区分に置くか判断 (恒久廃止 vs standby vs 手動のみ)
- 「このタスク以前あったよね？」と聞かれたとき、retired か manual_only かを確認
- `register_schedules.ps1` の動作 (登録 / 解除 / スキップ) を区分から逆引き
