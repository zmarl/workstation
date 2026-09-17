---
name: project-owner-direction-intake-2026-08-10
description: "ODR-0001 方向確定の取込 Phase 0 完了 (PR #166) と、その過程で得た gate/worktree 運用の罠 5 件"
metadata: 
  node_type: memory
  type: project
  originSessionId: fd8195c5-536a-4f67-aa3e-8156248116e5
  modified: 2026-08-10T20:12:25.187Z
---

# ODR-0001 方向確定の取込 (2026-08-10〜)

## 状況

- オーナーの 2026Q3 方向確定は **`docs/decisions/20260810-owner-direction-2026q3.md`(ODR-0001)** と **`docs/OWNER_INTENT.md`** が正本(PR #166、2026-08-11 マージ)。OWNER_INTENT は**タスク着手時に確認**(AGENTS.md 参照表・docs/README 読み順 1 番に登録済み)。
- 実行計画の原本はリポジトリ外 `D:\Dev\Investment_設計資料\取込パック_20260810\実装指示書_方向確定の取込_2026-08-10.md`(registry の RES-OWNER-DIRECTION-202608 で追跡)。**Phase 0(PR-A=PR #166)・Phase 1 PR-B(台帳復旧=PR #167)・PR-D(worklog テンプレ Harness 欄=PR #168)完了(2026-08-11)**。台帳は 7/22〜8/10 の worklog 25 本を done 登録(task_count 191)・Superseded 出典 15 箇所付替え・14日アーカイブ再開(170件移動)。worklog Metadata に Harness 欄(codex/claude/human、worklog-starter が自動記入)導入済み。**残: PR-C(worklog⇔台帳ゲート新設+supersedes 必須検査=Codex 分担目安。新 check script は development_test_selection.yaml への登録を忘れない)→ Phase 2(PR-E 全体設計 Accepted 化、直列)→ Phase 3〜7**。分担目安: Codex=B/C/E/F/G/H/K/L/M/N/O/P、Claude=A/D/I/J/Q/R/S。PR-B レビューの P2 申し送り(Phase 7 行き): scripts/manifest/meta.yaml:244 の archived worklog 参照・scripts/tests の docstring 内旧 worklog パス 7 件・台帳旧行の生パイプ形式負債 7 行。
- 台帳 TaskID: `20260810-owner-direction-intake`(done)。worklog: `docs/worklogs/20260810-claude-owner-direction-intake-68c2f7d8fd.md`(適合表=外部資料取込標準手順の第1回実施例を含む)。

## 運用の罠(このセッションで実測)

1. **main dirty で EnterWorktree が必ず失敗**: `create-worktree` は main の非 runtime 変更を fail-closed で拒否。今回の dirty 源は (a) `config/jpx_protected_codes_review_history.yaml` へのスケジューラ機械追記(追跡ファイル! 退避は `salvage/main-dirty-20260810` branch)、(b) `data/kpi_audit_diff.json` の runtime 削除(worktree からの cp で復元可)、(c) 0 バイト事故ファイル `[r.task_id`。**恒久処置は Phase 7 スコープ**(untrack or 定期 commit 経路化)。再発時: 保全(salvage branch + scratchpad コピー)→ `git restore` → 退避、の順。
2. **gate selector の cp932 バグは PR #166 で修正済み**: `run_changed_test_plan.py` の JSON は ensure_ascii=True 必須(日本語ファイル名「表」等の 0x5C 終端バイトが gate 親の UTF-8 parse を破壊していた)。**このファイルはちょうど 800 行の file_size_budget 上限**にあり、1 行でも足すと budget 赤(baseline は shrink-only で追加不可)。
3. **fresh worktree で T3 gate は desktop 検査が構造的に赤**: t3-static(desktop AST 検査を含む)が scope-desktop-dependencies(npm ci)より先に走る。**回避: gate 前に `npm --prefix desktop ci` を手動実行**。"AST analysis returned invalid JSON: Node.js vXX" が起動不能のシグネチャ。
4. **T3 gate は約 75 分**(t3-python 単独で約 60 分)。実行中に他 PR がマージされると最後の `base_unchanged=false` で全体 fail → rebase して全再実行。**開始前に `gh pr list` で残 PR 数を確認**し、マージ直後の静かな時間帯に流すのが安全。ready mode は diff に `scripts/`(unknown/runner_gate 分類)が入ると t3 を要求する。
5. **contract_scope.yaml / registry.yaml は base race の常連**: md ファイル追加は `expected_managed_markdown_count` の追随が必要(rebase 毎に再実測)。台帳更新時は `sync_task_status_snapshots.py --write` と `backlog_scanner scan --write`(Layer-B)も再生成しないと parity/scanner が赤。

関連: [[project-phase-b-screening-completion-2026-07-23]](lifecycle 運用正本)、[[feedback-parallel-session-worktree]]
