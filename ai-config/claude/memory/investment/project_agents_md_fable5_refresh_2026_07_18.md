---
name: project-agents-md-fable5-refresh-2026-07-18
description: AGENTS.md単一正本化・skills両ハーネス共用化の完了記録と、指示ファイル更新の新ルール
metadata: 
  node_type: memory
  type: project
  originSessionId: d858c1bf-4c0c-4773-bcd5-4352c31d9719
---

# AGENTS.md / CLAUDE.md 大規模刷新 (2026-07-18, PR #64 **merged**)

## 並行セッション運用（第2バッチ、ユーザー明示承認の新方針）

- **マージ権限変更**: 「最新 origin/main に rebase 済み + ruff green + gate 赤が既存 baseline と同一」なら
  エージェント判断で `gh pr merge --merge` まで実行してよい（都度承認不要）。
  共有DB/本番適用・実通知・Scheduler 登録・Desktop 配布は従来どおり承認必須。
- 1タスク=1worktree。main checkout `D:\Dev\Investment` は常に main・クリーンに保つ方針
  （**2026-07-18 時点では codex ブランチ+DIRTY で別セッション作業中 → 全部着地後に main へ戻す移行が未了**）。
- `scripts/dev/sync_repo.py`: status / sync-main / cleanup [--apply] / after-merge。DIRTY・未マージ commit は自動保護。
- Desktop 起動チェーン（.lnk → VBS → run_desktop_phase_a_launcher.ps1）に repo_update 段を追加済み:
  起動時 main+clean なら `git pull --ff-only`（fail-open, -SkipGitPull）。pull 後は既存の mtime 差分機構が
  BFF 再起動と Desktop exe 再ビルドを自動処理（起動チェーンは git を見ず mtime で判定する設計）。
- **force push は permission deny**。rebase 後に push できない時は `git merge -s ours <旧remote tip>` で
  系譜を統合すると tree 不変のまま fast-forward push できる（gate は新 SHA で再実行が必要）。

- **指示ファイルの正本は AGENTS.md（日本語・104行）に一本化**。CLAUDE.md は `@AGENTS.md` import + Claude固有差分14行のみ。今後の指示更新は AGENTS.md 側だけを編集する（CLAUDE.md への直接追記はドリフト再発）。
- ネスト構成: `desktop/` `tools/` `db/` に AGENTS.md + 1行 CLAUDE.md（`@AGENTS.md`）。領域固有ルール（vitest作法・BMフレームワーク3点セット・Alembic/PG方言）はそちらへ。
- **skills は正本 `.agents/skills/<name>/SKILL.md`（14本）+ `.claude/skills/` `.codex/skills/` に同一frontmatterのポインタスタブ**。skill 本文の更新は .agents 側だけ。Windows symlink 不可のための設計。
- 文体: Fable 5 / GPT-5.6 世代は MUST乱用・全列挙が品質を下げる（公式明言）→ 簡潔な原則文へ書き換え済み。旧文体に戻さない。
- 設定分離: 恒久 permissions/hooks は `.claude/settings.json`（コミット対象）、一時 allow は settings.local.json。Notion MCP 有効化残骸は除去済み。
- `.codex/config.toml` の developer_instructions は Codex 固有2項のみに縮小（Codex は AGENTS.md を直接読むため重複禁止）。
- **run_local_pr_gate.py は `--expected-base` `--expected-head` が必須引数**。
- **main の hermetic lane 既存赤は 8 件**（2026-07-18 base=bcd0a7a4 で実測）: test_screening×5 / test_decision::signed_identity_context / test_ops_hub::test_returns_dataset_items / **test_decision_surface_candidate_classifications::test_catalog_exactly_matches...（PR #65 change-dashboard 以降）**。gate 赤の差分判定はこの8件を基準に。[[project-hv-double-annualisation-fix-2026-07-18]] の「5件」記載はこれで更新。
- 公式カタログ採用候補（未導入・提案のみ）: xlsx（Anthropic公式, 数表のExcel出力）/ jupyter-notebook（OpenAI公式, DuckDB read-only探索）。
- 削除候補として残置: `.agents/skills/imagegen-asset-direction`（低価値だが無害）。
