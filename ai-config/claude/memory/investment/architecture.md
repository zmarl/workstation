---
name: アーキテクチャ詳細 (Desktop / BFF / DB / LLM の境界契約)
description: Desktop Control Tower の thin client 構成、5 層データ境界、LLM 経路統一、Phase A Ollama autostart の正本サマリ
type: project
originSessionId: 06a37e34-9804-430a-aa3a-f36ce72a0a61
---
正本: `docs/decisions/local-llm-desktop-control-plane.md` (Design-Locked) + `docs/decisions/postgres-sole-write-target.md`。

## 1. UI / API 境界

```
Desktop (Tauri 2 + React 18 + Vite 6, thin control plane)
  ↓ HTTP/SSE (api-client.ts のみ)
FastAPI BFF (tools/api/decision_api/, 127.0.0.1:8010)
  ↓ shared.database.get_connection()
PostgreSQL / Iceberg / ClickHouse / Filesystem
```

- **Desktop は FastAPI 以外へ直接アクセスしない** (`check_desktop_direct_access_prohibition.py` が `.tsx/.ts` をスキャン)
- **FastAPI が唯一の操作入口**。スクリプト直叩きや手動 SQL は禁止
- 認証: `X-Decision-Token` (read/run 分離)、Phase A は localhost-only、Phase B は Caddy reverse proxy + TLS

## 2. データ層 5 区分

| 層 | 役割 | 実体 | 書き込み |
|---|---|---|---|
| audit/journal/memory | 必須台帳 | PostgreSQL | **唯一の write target** |
| canonical (structured) | 主系正本 | Iceberg | 別経路で生成 |
| serving (read 主系) | 高速 read | ClickHouse | 派生のみ |
| durable object store | 大容量バイナリ | Filesystem | filesystem 固定 |
| research / analytical | 分析用 read | DuckDB (postgres_scanner) | **書き込み禁止** |

- `DB_ENGINE=postgres` 固定
- DuckDB はあくまで分析用 read。アプリから書かない
- S3 は 2026-04-17 廃止、durable は filesystem (`s3_deprecation.md`)

## 3. LLM 経路

```
Desktop -> FastAPI -> LLM Gateway -> vLLM/Ollama
```

- 外部 API 直接呼び出しは禁止 (Anthropic/OpenAI 等)
- Phase A: Ollama qwen3.5:9b (`LLM_PROVIDER=local_ollama`)
- 必要時の対話抽出は Claude Code / Codex CLI でローカル実行 → JSON import (`interactive_llm_pattern.md` 参照)

### Phase A Ollama autostart (Task Scheduler `\LocalLLM\`)

- `LocalLlmServeOnLogon`: ログオン時 `scripts/start_local_llm.ps1` (port 11434 既起動ならスキップ)
- `LocalLlmWarmupOnLogon`: ログオン 60秒後 `scripts/warmup_local_llm.ps1` (qwen3.5:9b を keep_alive=-1 で VRAM 常駐)
- 登録: `scripts/register_local_llm_autostart.ps1` (冪等)
- 確認: `Invoke-RestMethod http://127.0.0.1:11434/api/ps` で `size_vram > 0`

## 4. Desktop 技術スタック詳細

- React 18 + TanStack Router + TanStack Query
- 状態管理: Zustand (client) + TanStack Query (server)
- スタイル: Tailwind CSS 3 + `desktop/src/styles/tokens.ts` (design tokens)
- Layout primitive: `desktop/src/components/layout/primitives/{Metric,Panel,MetricStrip}`
- SSE: `useSSE.ts` で `/api/v1/stream` からリアルタイム更新
- Tauri ビルドには Rust ツールチェーン必要 (現行マシン未インストール)
- 既存トークン・primitive を必ず再利用 (新規 token / 新規 primitive 追加は最小限)

## 5. shared/ ライブラリ

- `shared.database.get_connection()` — 全 DB write はこれを通す。`?` プレースホルダーは psycopg `%s` に変換される
- `shared.config` — `.env` ロード、Settings class (ハードコード禁止)
- `shared.raw_ingest_tracking` — 全ツールの ingest run を `raw.ingest_runs` に統一記録
- `shared.tooling.repository.upsert` — 汎用 upsert (`upsert_rows`, `upsert_from_frame`)
- `shared.tooling.cli.output` — CLI 出力ヘルパー (旧 `shared/cli.py` は deprecated shim)
- `shared.ml_guardrails.engine` — ML 予測品質ゲート (drift / performance degradation 検知)
- `shared.notifications.orchestrator` — 通知 + alert 統合の orchestrator

## 利用シーン

- 新規エンドポイント追加・新規 panel 配線時に「正しい経路」を確認
- 新規ツールで write target / LLM 経路を選ぶ判断
- Phase B 準備時に Caddy / TLS / FQDN 設定を見直す際の前提
