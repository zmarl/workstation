---
name: ローカルLLM専用方針
description: 全LLM推論はローカルOllama専用。Claude API等の外部APIは使用しない（コスト方針）。Qwen3.5:9bが主力、VLMモデルは廃止済み。
type: project
originSessionId: f70f43d3-6919-4ad4-821d-66042e588aa4
---
## 方針

全LLM推論はローカルOllamaのみで運用する。Claude APIを含む外部LLM APIは使用しない。

**Why:** コスト面の理由。新しいモデルや新しいPCを導入した際にローカルモデルを更新・変更する方針。

**How to apply:**
- 新規ツール開発時にClaude API/外部LLMを使わない
- LLM Gateway経由のモデル指定はOllamaモデル名のみ（claude-*は不可）
- `AGENT_FALLBACK_TO_CLAUDE=false`（フォールバックも無効）

## モデル構成（2026-04時点）

| 役割 | モデル | VRAM | 用途 |
|---|---|---|---|
| quality lane | `qwen3.5:9b` (Q5_K_M) | ~6.5GB | 高品質推論、OCR/文書理解、構造化抽出全般 |
| fast lane | `gemma4:e4b` | 軽量 | 分類、一次要約、テーマ仮説 |
| challenger | `qwen-vl-financial` | — | 評価専用、本番昇格なし |

## 廃止済み

- `qwen3-vl:8b` → Qwen3.5:9bに統一（VLM専用モデル廃止）
- `qwen2.5vl:7b` → 同上
- Claude API全般 → コスト方針により廃止
- `nlp_sentiment_model_default/premium` のClaude系モデル名 → Ollama系に変更済み
- `law_tracker` のClaude系モデル名 → Ollama系に変更済み

## ハードウェア

RTX 5070 Ti (16GB VRAM)。Qwen3.5:9b単独で~6.5GB、fast laneとの並走も可能。

## 正本ドキュメント

- `docs/local_llm_strategy.md` — モデル選定・役割ルール
- `docs/decisions/local-llm-desktop-control-plane.md` — LLM経路のADR
- `docs/decisions/kpi-extraction-decisions.md` — ローカルLLM固定の採択記録
