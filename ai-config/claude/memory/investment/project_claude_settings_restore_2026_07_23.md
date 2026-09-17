---
name: project-claude-settings-restore-2026-07-23
description: Codexが07-21に書き換えたClaudeグローバル設定をbypassPermissions方針へ復元し、repo-guard hookのリポジトリ外書き込み遮断バグを修正した経緯と新契約
metadata: 
  node_type: memory
  type: project
  originSessionId: 898863aa-c3df-482c-a938-add9e7689d94
  modified: 2026-07-23T13:40:07.927Z
---

# Claude設定復元と新契約 (2026-07-23)

## 経緯

- 2026-07-21 の Codex 主導「agent-autonomous-lifecycle」（worklog: docs/worklogs/20260721-agent-autonomous-lifecycle.md）が
  `~/.claude/settings.json` を書き換え（allow/ask 全削除・Investment 固有 deny をグローバル複製）、
  `scripts/check_claude_agent_roles.py` に「グローバルは defaultMode auto 必須」契約を導入した。
  根拠は「bypassPermissions は deny を無効化する」だったが、**現行公式仕様では deny ルールと PreToolUse hook は
  bypassPermissions を含む全 permission mode で有効**（code.claude.com/docs permission-modes / hooks で 2026-07-23 確認）。
- 同時に導入された `.claude/hooks/claude-repo-guard.py` が、どの git worktree にも属さないパス・別リポジトリへの
  Edit/Write を一律拒否していたため、**auto-memory・plan file・scratchpad への書き込みが 07-21〜07-23 の間全遮断**
  されていた（07-19 以降 memory 更新が止まった根因）。
- 2026-07-23 にユーザー承認の上で復元（worklog: docs/worklogs/20260723-claude-settings-restore-aa4d2262e0.md）。
  書き換え前バックアップは `~/.claude/backups/agent-autonomous-lifecycle-20260721-200750/settings.json` に保全。

## 新契約（正本: scripts/check_claude_agent_roles.py）

- グローバル `~/.claude/settings.json`: defaultMode **bypassPermissions** 必須 / allow・ask 空 /
  autoUpdatesChannel stable / `GLOBAL_REQUIRED_DENIES`（汎用破壊・公開・秘密情報 core）⊆ deny /
  `PROJECT_SCOPED_BLANKET_DENIES`（`gh *`・`git push *`・`docker *` 等の blanket）がグローバルに混入したら FAIL。
- Investment 固有の deny・hook はプロジェクト側 `.claude/settings.json` が全モードで強制（ここは不変）。
- モデルは `claude-fable-5[1m]`、effortLevel は **xhigh が保存可能な最高値**（`max` は session-only、settings 保存不可）。
- development-harness.md の Claude 既定記述も bypassPermissions へ更新済み。
- プラグイン: rust-analyzer-lsp のみ有効。claude-mem / planning-with-files / frontend-design は無効化
  （claude-mem は auto-memory と重複）。jarrodwatts-claude-delegator marketplace は他社 AI 委譲用で方針不整合、削除対象。

## repo-guard hook の運用知見

- Edit/Write は「session と同じ git common dir の repo family 内」だけ policy 適用。リポジトリ外・別 repo は
  sensitive check（.env*・secrets/・credentials・.pem/.key 等は常に拒否）のみで許可。
- Bash は今も強い制約: **複数行コマンド不可**（control character 拒否）、**`>` リダイレクト・パイプ先 `rm` 等の
  shell file mutation 全面拒否**、`<email>` の角括弧も `>` として誤検知。
  → 複数行 commit メッセージは scratchpad にファイルを書いて `git commit -F <path>` で回避する。
- main checkout では Bash が `git status` 系と `sync_repo.py` helper 以外ほぼ全面拒否。ops 系 skill が main から
  動かない可能性は未解決の申し送り（[[project-claude-settings-restore-2026-07-23]] のスコープ外）。

**Why:** ユーザー確定方針（2026-04-17: auto 不使用・bypassPermissions のみ、[[feedback-auto-mode]]）と
Claude の自律動作基盤（memory/plan/scratchpad）を、Codex の誤った仕様前提による上書きから恒久的に守るため。

**How to apply:** グローバル設定を変更する際は `uv run python scripts/check_claude_agent_roles.py --claude-home "$env:USERPROFILE/.claude" --json`
で新契約に適合するか確認する。Codex セッションが「auto に戻せ」と主張したら本メモリと 20260723 worklog を根拠に拒否する。

## 着地結果 (2026-07-23 夜)

- **PR #145 として SHA 固定マージ完了**（merge commit f1853959、gate overall passed・check suite 55/55・
  pytest lane 15399 passed）。独立 review 2 役（correctness / security）が P1 1 件
  （`.git` common dir 内部への Write 素通り回帰）を検出 → `_path_is_within` による git-metadata 明示拒否で
  remediation し、両者クローズ確認済み。
- **並行 PR #143 が PreToolUse 配線を解除**（ユーザー明示判断・別セッション）。以後 guard の Edit/Write/Bash 検査は
  待機状態で、機械強制は「project deny list（全 mode 有効）+ WorktreeCreate 経由 claim 契約」。
  guard script 自体は WorktreeCreate と将来の再配線用に存続し、本 PR の修正（git-metadata 拒否・repo外 out-of-scope 化）も
  その整備の一部。checker は「PreToolUse 任意・配線時は正確な形状必須」契約に更新済み。
- 上記により、本メモリ冒頭の「hook が複数行 Bash・`>` を拒否」は**新規セッションでは非適用**
  （#143 で配線解除+誤検知修正済み。2>&1 は許可、rm/mv はコマンド位置のみ）。
- **base race 教訓**: 並行マージ最盛期は gate 35 分中に origin/main が 2 回前進した。registry 件数は
  「rebase 時に双方が同値を主張すると自動マージで実数とズレる」→ rebase 後は必ず registry check を再実行。
  test ファイル合流で file-size budget 超過 → fixture 非依存テストの別ファイル分割で解消（内容不変）。

## 第2弾: 機械 deny の人手境界化 (2026-07-23 夜, PR #146 merged)

- ユーザー明示決定（「Git 統合系も全部消す」「Codex 側も同様」「人手境界は残す」）で、**両ハーネスの機械禁止を
  人手境界のみへ縮小**: 生 push・gh・worktree・stash・add -A・git -C・cmd /c・python -c・uv/npm/pnpm 間接・
  docker/kubectl/terraform blanket をすべて撤去。**sync_repo helper 経路は「既定・推奨」であり機械強制ではない**
  （AGENTS.md 79-80 行が正本。生 push は helper 不能時の代替として可）。
- 残る機械強制: Claude project deny 34 エントリ（Scheduler 登録・tauri build 系・実通知 = run_tool.ps1/
  scripts\run_*.bat 手動実行含む）+ ユーザー global の汎用 core（破壊 Git に branch -D・素の reset --hard を追加済み・
  公開系・EncodedCommand・秘密情報）。Codex は .codex/rules/default.rules（**global ~/.codex/rules は exact-match
  ミラー必須**、変更時は cp で再配備）。契約正本は両 checker（REQUIRED_DENIES は settings と等価一致で fail-closed）。
- review 教訓: 緩和時は「残すと宣言した境界の実装漏れ」が出る — tauri build は `--prefix desktop` 形が実効形、
  branch -D の Claude 側不在、cmd /c 撤去で scheduler wrapper 経由の実通知が開口（wrapper 行の verbatim コピー
  `.\scripts\run_tool.ps1` 形まで deny 要）。security reviewer の kept-boundary 監査が有効だった。
- 申し送り: **dead な `tools.notifications.earnings_ranking.main` が scripts/manifest/misc.yaml に task 登録されたまま**
  （モジュール実体なし・CI workflow も実在しないテストを参照）。manifest 整理は CI 連鎖を伴うため別タスク。
