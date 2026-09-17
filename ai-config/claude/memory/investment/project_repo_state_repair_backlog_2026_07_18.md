---
name: project-repo-state-repair-backlog-2026-07-18
description: "リポジトリ状態修復 完了 (07-18 夜): main checkout復帰・既知赤着地(PR #75)・退避branch 3本・Codexスキルstub化。残: worktree棚卸しの未マージ群・db レーン"
metadata: 
  node_type: memory
  type: project
  originSessionId: ee91be77-1283-4e10-a67b-19e0f4c0f60e
---

# リポジトリ状態修復 (2026-07-18 夜 完了)

07-18 夕方の申し送り4項目を同日夜のセッションで実行完了。worklog 正本: docs/worklogs/20260718-repo-state-repair.md

## 完了内容

1. **main checkout 復帰**: `D:\Dev\Investment` = main・クリーン・origin/main 同期。dirty 12+未追跡2は分類の上 `salvage/root-dirty-20260718` へ退避 push（HV 4本=PR #60 とバイト同一 / EDINET系=opsブランチ包含済み / test_screening 83行=ops版と別実装で不採用記録）。
2. **既知赤の着地**: PR #60(HV, 並行セッションがマージ) + PR #75(app refresh 25コミット, 本セッションが base refresh・競合解消・registry修復・exact-head gate green でマージ)。旧既知赤エリア main で 130 passed / 0 fail。check_suite の大半・typegen も #75 で解消。
3. **gate3 PR0 docs 着地**: cf6ef2af の docs 残余(gate3 worklog + INST-G3 台帳2行 + ORDER-INT-02 done)を docs PR で着地。コード部分は #75 にバイト同一で包含済みだった。
4. **Codex グローバルスキル**: `~/.codex/skills/` 旧 investment 系6本を stub 置換（正本 = .agents/skills/ + AGENTS.md）。ユーザー承認済み。

## 実行時の重要知見

- **並行 Codex セッション 3本が同時稼働していた**（app refresh 最終検証 / PR #60 着地 / earnings-reference-dashboard 開発）。着地は「8分書き込みゼロ」Monitor で静止確認してから。ops セッションはローカル main を自ブランチ tip へ ff する「ローカル適用」工程を持つ（main が origin と乖離して見えても branch 群に保全されていれば正常収束する）。
- **md ファイル追加 PR は docs/research/registry.yaml の expected_managed_markdown_count 追随必須**。PR #60 が漏らして main の docs_research_registry を赤化（#75 で修復）。
- **run_local_pr_gate.py はシェル exit 0 でも overall: failed があり得る** → 判定は evidence JSON の `overall_status` で行う。
- BFF 常駐 (port 8010) の CWD は main checkout。worktree 削除はランタイム非影響（psutil の `Process.cwd()` で確認する手法）。

## 残課題（申し送り）

- worktree 棚卸し: 未マージ・DIRTY の worktree 群（gate3-dev 37件 / earnings-dashboard 137件 / api-v2 / db-baseline×2 / integrated-functional-repair×3 / book-knowledge 等）は各作業トラックの持ち物で削除不可。merged 分のみ cleanup 済み。
- `D:\Dev\Investment-wt-maincheck` 残骸はユーザー手動削除待ち（エージェント権限で削除不可）。
- db レーン 69 fail / EDINET 定刻実行成否 → [[project-next-session-followups-2026-07-18]] 参照。
- salvage/root-dirty-20260718 は着地確認後に削除可（test_screening 別実装の参考のみ残存価値）。
