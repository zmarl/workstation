---
name: project-skills-refresh-2026-07-18
description: "repo-local skills 鮮度修正+stub機械生成化+pr-ready-gate新設 完了 (07-18, PR"
metadata: 
  node_type: memory
  type: project
  originSessionId: ee91be77-1283-4e10-a67b-19e0f4c0f60e
---

# Skills 最適化アップデート (2026-07-18 完了)

- **スキル正本は `.agents/skills/` (15本)**。`.claude/skills/` / `.codex/skills/` は機械生成 stub。
  編集は正本 → `uv run python scripts/build_skill_stubs.py --write`。drift は gate の
  `skill_stub_sync` check (run_check_suite.py, local-pr プロファイル) で fail-closed 検知。
- **新スキル `pr-ready-gate`**: worktree 作成→rebase→exact-head gate→evidence→マージ→
  sync_repo after-merge の中核フローを手順化。evidence の head SHA は PR body 側に書く
  (worklog 追記 commit で head が変わる循環を断つ運用で固定)。
- 修正済み: ops-diagnose failure-classes 全面書き直し (実7分類: none/timeout/overlap_prevented/
  config_error/external_dependency/data_quality/runtime_error + exit 65=SUCCESS_MISMATCH/70/75/124)、
  ops-market-brief (`/api/v1/screening/latest`・daily_review)、worklog-starter の ~/.codex/skills 依存排除、
  8本の description に Use when トリガー追加 (skill 起動判定は description のみ)。
- **main の pre-existing 赤は 7 件に収束** (07-18 実測、pr レーン): test_decision.py::
  test_signed_identity_context… 1 / serving_repository/test_screening.py 5 / test_ops_hub_repository.py
  ::test_returns_dataset_items 1 (時刻依存 stale 判定)。gate 判定時はこの集合と突き合わせる。

**Why**: スキル自動起動は frontmatter description だけで判定される。stub 手動同期は必ず drift する。

**How to apply**: スキル変更時は正本のみ編集し --write 再生成。gate red を見たらまず上記 7 件か確認。
Ready 化手順は [[pr-ready-gate]] スキル自体を呼ぶ。罠: force push は deny されるので rebase 後に
push できない場合は新ブランチ名で PR を作り直す (今回 #72→#73)。scheduler-registration の
description のような未クォート YAML は strict parse で落ちる (ハーネスは寛容)。
関連: [[project-agents-md-fable5-refresh-2026-07-18]]
