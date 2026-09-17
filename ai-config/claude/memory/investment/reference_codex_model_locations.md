---
name: Codex / GPT Expert モデル設定の場所
description: Claude Code から GPT Expert (codex-delegation) を呼ぶ際のモデル ID は3箇所で管理。新モデル切替時はすべて更新する
type: reference
originSessionId: de1bafcf-de6e-438a-bb89-c0be0d0b8b8a
---
# Codex / GPT Expert モデル設定の所在

Claude Code から GPT Expert（codex-delegation skill 経由 = Codex MCP server 委任）を呼ぶ際のモデル指定は、以下の3箇所に分散している。新モデルがリリースされた際は、ユーザーから依頼があれば3箇所すべてを同じバージョンに揃える。

| 役割 | ファイル | 該当キー |
|-----|---------|---------|
| MCP server 起動引数（Claude Code → codex 呼び出しで実効的に効く） | `C:\Users\kazum\.claude\.mcp.json` | `mcpServers.codex.args` の `-m` 直後 |
| Codex グローバル既定（ターミナルから `codex` 直接起動時） | `C:\Users\kazum\.codex\config.toml` | トップレベルの `model =` |
| Codex orchestrator profile | `C:\Users\kazum\.codex\config.toml` | `[profiles.orchestrator]` の `model =` |
| Investment プロジェクト override | `D:\Dev\Investment\.codex\config.toml` | トップレベルの `model =` |

**現状（2026-05-10 時点）**: 4箇所すべて `gpt-5.5` に統一済み。

**重要な仕組み**:
- Codex / MCP には "latest" のような自動エイリアスが**ない**。固定モデル ID を書く必要がある。
- `.mcp.json` の `-m` 引数は MCP server 起動時に渡されるため、project の `.codex/config.toml` より優先される。Claude Code 経由の呼び出しを最新化したいときは `.mcp.json` の更新が必須。
- ターミナルから `codex` を直接実行した場合は、project の `.codex/config.toml` → グローバル `~/.codex/config.toml` の順で解決される。

**新モデル更新手順**:
1. ユーザーが「最新モデル X に更新して」と依頼したら、上記 4 箇所すべての `gpt-5.5` を `X` に置換する。
2. Claude Code セッションを再起動して MCP server を再起動する（`.mcp.json` 反映のため）。
3. 簡単な codex-delegation 呼び出しで応答ヘッダーのモデル名を確認する。

**参考**: `~/.codex/config.toml` の `[tui.model_availability_nux]` セクションに、現在 Codex で利用可能なモデル一覧が書かれていることがある（更新リリース時の確認用）。
