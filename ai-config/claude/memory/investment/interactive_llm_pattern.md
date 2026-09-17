---
name: 対話 LLM + JSON import パターン (Claude/Codex CLI)
description: 外部 LLM API を使わず、Claude Code / Codex CLI の対話セッションで構造抽出 → JSON ファイル化 → DB import するパターン。supply_chain_extractor / canvas 等で運用
type: feedback
originSessionId: 06a37e34-9804-430a-aa3a-f36ce72a0a61
---
## ルール

外部 LLM API (OpenAI / Anthropic API 直接呼び出し) は使わない。LLM 必要な抽出は次のいずれかに統一:

1. **ローカル Ollama** (`LLM_PROVIDER=local_ollama`) — `Desktop -> FastAPI -> LLM Gateway -> vLLM/Ollama` の 1 経路のみ。Phase A は qwen3.5:9b。
2. **対話セッション** (Claude Code / Codex CLI) — IR / 開示資料の構造抽出を対話的に行い、JSON で出力 → tools 側の `--from-json` import コマンドで DB に投入。

**Why:** 外部 API は (a) コスト管理しづらい、(b) ベンダーロックの再発リスク、(c) 監査ログの一貫性が崩れる、の 3 点で不採用。`supply-chain-llm-tier.md` ADR で Qwen 自動 classifier を一旦廃止した経緯と整合。

**How to apply:**
- 新規ツールで「LLM で何か分類/抽出したい」要望が出たら、まず Ollama で済むかを検討
- Ollama で精度が足りない領域 (R&D Pipeline / 業種特殊な構造) は対話パターンを採用
- 対話で得た JSON を読み込む import 経路 (`--from-json` 等) をツール側に必ず用意。手動 SQL は不可

## 実装例

| ツール | パターン | 出力先 |
|---|---|---|
| `tools/analytics/supply_chain_extractor/` | Claude Code 対話 → JSON → import | `analytics.supply_chain_edges` (tier_source='claude_inferred' or 'llm_inferred') |
| `tools/analytics/canvas_to_supply_chain/` | Canvas 9-block JSON → regex で 4桁コード抽出 | `analytics.supply_chain_edges` (tier_source='canvas_derived_v1') |
| `tools/analytics/canvas_summarizer/` | LLM 要約 → 9-block JSON | Canvas store |

## ファイル配置の慣行

- 入力 (Claude/Codex の対話結果): `data/llm_extracts/<source>/<date>.json`
- import コマンド: `uv run python -m tools.analytics.<tool>.main --from-json <path>`
- tier_source: 出所の表記を必ず付与 (`claude_inferred`, `codex_inferred`, `canvas_derived_v1` 等)。後段 BFF の tier_priority と整合させる

## 利用シーン

- LLM 必要な機能を新規追加するとき、まずこのパターンで設計可能か検討
- 対話セッションで何を抽出するかは「Hidden Edge / Red Flag / Business Model Graph」の運用化に直結
- 外部 API を呼びたくなったら、本メモリと `local-llm-desktop-control-plane.md` ADR を確認して却下
