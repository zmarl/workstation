---
name: project-phase-b-screening-completion-2026-07-23
description: Phase B スクリーニング強化 全14項目完遂 + 本番適用 (07-20〜23)。新 lifecycle (publish-pr/finish-pr/EnterWorktree) と repo-guard 消去の経緯、vw_daily_valuation 11週 stale 事故の発見と修理
metadata: 
  node_type: memory
  type: project
  originSessionId: 165b915a-77e5-4e9f-a0fc-444cc116cf25
  modified: 2026-08-15T23:06:40.773Z
---

# Phase B スクリーニング強化 完遂 (2026-07-20〜23)

計画正本: plans/steady-juggling-stream.md（14 PR）。[[project-desktop-design-reform-2026-07-19]] の続き。

## 結果

- **全 14 項目 main 着地**: P1#112 P2#136 P3#134 P4#132 P5#115 P6#109 P7#113 P8#118 P9#121(peer版採用) P10#122 P12#124 P13#116 P14#125 P11#(最終、datatable-virtualization-landing 経由)
- **本番適用済み (07-22 深夜、ユーザー承認 9 revision 一括)**: alembic head=20260720_05。screening base MV 化で COUNT 66.3s→0.017s（~3900 倍）。MV 3550 行 == _def 一致検証済み
- **重大発見: mart.vw_daily_valuation に日次 refresh が存在せず 11 週 stale だった**（MAX(trade_date)=05-01。時価総額/PER/PBR の正本）。P3 で daily-valuation-refresh-daily + screening-custom-base-refresh-daily (21:50/21:55) を manifest 配線、初回 refresh は非 CONCURRENT で 2h40m（CONCURRENT は 1h でタイムアウト→killed でも server 側クエリ残存→pg_cancel_backend で掃除してから再走が正）。**Windows タスク登録はユーザー後日一括（未登録）**

## 新 lifecycle（07-22 Codex 導入、以後の正）

- worktree: **EnterWorktree ツール**（WorktreeCreate hook が agent-session-v2 claim を session 紐付けで作成。DDL は名前を `ddl-*` にすると排他 resource 付与）→ 実装 → gate → **`sync_repo.py publish-pr`**（push+PR。生 git push/gh pr create は禁止）→ **`finish-pr`**（SHA 固定マージ+remote/local branch+worktree 自動削除）
- claim 情報は `.git/worktrees/<name>/locked` に JSON metadata（worklog パス必須・commit 済みが publish-pr の前提）
- 旧 v1 claim (`agent-session:claude:...`) の worktree は新 hook 下で操作不能 → **検証済みコミットを新 worktree へ cherry-pick して着地させるのが移行の正**（P2/P11 で実証）
- merge-pr/finish-pr は「マージ時点で origin/main == tested_base」を要求 → gate(~50分) 中に main が動くと必ず作り直し。**マージ直後の窓で即 rebase→gate 投入が最有効**（P4 は 8 回目で成立）
- **publish-pr の 3 つの引数制約（2026-08-16 実測、全部エラーメッセージが分かりにくい）**:
  1. `--body-file` は **target worktree 内かつ gitignore 対象**でなければならない。scratchpad (`D:\DevTemp\...`) を渡すと `evidence path escaped its repository` という無関係な文言で落ちる。`data/runtime/<name>.md` が安全（`.gitignore:46 data/runtime/*`）
  2. `--worklog` は **claim に登録済みのパスと完全一致**が必要。不一致だと `worklog does not match the worktree claim`。EnterWorktree hook は `docs/worklogs/<YYYYMMDD>-claude-<task>-<hash>.md` を自動登録するので、worklog はその名前で作る（`status --json --include-claim-id --worktree <abs>` で確認できる）
  3. `finish-pr` は **target worktree の外から**実行する（中から実行すると `run this command from outside the target worktree`）。worktree 隔離セッションでは ExitWorktree(keep) してから main checkout で実行する
- `status --include-claim-id` は `--json` と**単一の絶対 `--worktree`** の同時指定が必須。全件一覧では claim_id を出せない
- **`cleanup --apply` は exact head が origin/main の祖先であることを要求**する。rebase/amend 後にマージされた exact-head runner では構造的に通らない（`not proven merged: ..., unmerged-commits`）。この種の回収は `git worktree unlock` + `git worktree remove` が代替（ユーザー承認が前提）

## repo-guard hook（07-23 ユーザー指示で PreToolUse 配線消去、PR #143）

- スクリプトは `.claude/hooks/claude-repo-guard.py`（WorktreeCreate 用に存続）。誤検知 3 件修正済み: publish-pr 自己ブロック / ハイフン名の rm・mv 誤検知 / 2>&1・>&2 の redirect 誤検知
- **再配線する場合は Edit/Write の repo 外ブロックに plans/auto-memory/scratchpad の除外が必要**（未修正の意図的設計。配線中は memory 保存・プランファイル更新が不能になる）
- commit trailer の `<...>` は redirect 誤検知が残る → `git commit -F <file>` で回避

## 教訓

**Why:** 並行セッション時代の base race・環境要因赤・二重実装を全て実測した。再発時の対処時間を短縮する。

**How to apply:**
- gate 赤の切り分け順: ①evidence の base/head_unchanged（race なら rebase 再走のみ）②環境要因（worktree の desktop/node_modules 不足 → check_desktop_api_client_usage が「TypeScript analysis invalid JSON」で落ちる。npm --prefix desktop install で解消）③実赤
- 新 DDL revision は `db/baseline/LOCAL_COMPOSE_BOOTSTRAP_FINGERPRINTS.json`（#131 新設の指紋契約）への追随必須。再生成: `uv run python -m tools.db_admin.local_compose_bootstrap.main generate-fingerprints --json` → contract を JSON へ書き戻し
- 本番 alembic は runtime_safety が identity 3 点 (`-x investment_expected_pg_database/user/system_identifier`) を要求。値は current_database()/current_user/pg_control_system()
- 並行セッションが同一計画を走らせる二重実装事故: 着手前に `git branch -a` と worktree fleet で同名系 branch を確認。peer の停止は「rebase コミットにコンフリクトマーカー残存」のような単純破損のことがある（P11）
- 別トラック: 財務可視化 A5 は別セッション進行中（07-23 時点）。[[project-financial-viz-kpi-orders-roadmap-2026-07-19]]

## 完遂後の追記 (07-23 夜)

- **P11 も #144 で着地 → Phase B 全 14 項目 main 完了**。peer 停止の真因は rebase コミット内の未解消コンフリクトマーカー（IndustryLeagueTable.test.tsx）だった
- **DoD 全 7 項目の実画面 QA 合格**（実 BFF + vite 1420 + Playwright）。業種 3 エンドポイント 0.04〜1.8s / 500 件検索 0.2s + 仮想化（描画 27 行 + spacer）実証。証跡 PNG: session scratchpad qa-*.png
- **repo-guard PreToolUse は #143 で配線消去**（ユーザー指示）。誤検知 3 件修正済み・再配線時は harness ディレクトリ除外が必要
- **baseline 再生成は意図的に見送り**: earnings-gate3 リハーサル契約 (tools/db_admin/earnings_migration_rehearsal/contract_spec.py) が旧 baseline 起点 + 9 revision 経路を厳密ピンしており、再生成すると彼らの CaptureError になる。**gate3 トラック完了後に実施**（手順は再生成→fingerprint 契約→18_views 等の番号繰り上がりで tests/db の 2 pinned テスト追随、実測済み）
- 検索実行には指標の下限/上限入力が必須（QA での学び。空のまま検索は validation で止まる仕様）

## 全クリア (07-23 夜、ユーザー指示「残っている作業をクリアしよう」で完遂)

- **旧 worktree 5 本削除済み**（content-equivalence diff 確認後、`git worktree remove -f -f`＝claim lock は二重 force が必要）
- **新タスク 2 本 Windows 登録済み**: \Investment\DailyValuationRefreshDaily (21:50) / ScreeningCustomBaseRefreshDaily (21:55)、両方 Ready。初回実行は 07-23 夜 → **翌日成否確認推奨**。scheduler_integrity の strict_failure 17 件は既存 drift（07-12 一括登録方針の残骸）で本件と無関係
- **Tauri release 配布ビルド済み**: investment-desktop.exe 13.1MB + installer、デスクトップショートカット更新済み
- **Git Bash の罠**: `schtasks /Query` は MSYS パス変換で壊れる（/Query→C:/Program Files/Git/Query）→ PowerShell の Get-ScheduledTask を使う
- 未了は baseline 再生成（gate3 完了待ち、上記手順メモ参照）のみ

## rebase 後の再着地（08-31 実測、次に必ず踏む）

- **生の `git push --force-with-lease` は harness policy で拒否される。** rebase 後は
  **`publish-pr` をもう一度そのまま実行する**のが正規経路。既存 PR を検出すると
  `--force-with-lease=<ref>:<observed_head>` の exact lease で push し直し、title/body も更新して
  同じ PR 番号を保つ（`repo_lifecycle_pull_requests.py:265` 付近）。
- **Ready gate evidence は `base_unchanged: True` / `head_unchanged: True` / `overall_status: "passed"` の
  3 つが揃わないと merge-pr が受理しない**（`repo_lifecycle_evidence.py` の v4 検証）。全 pack が
  `status=pass` でも、実行中に origin/main が動けば `overall: failed` になる。
  main が 5〜10 分間隔で進む時間帯（複数セッション稼働中）は **直前の merge が入った直後に gate を撃つ**。
  gate は約 7 分。撃ち直しは rebase → gate → 即 publish-pr → 即 finish-pr を一続きで回す。
- `finish-pr` は `merge-pr` + main 同期 + cleanup を一括で行い、成功すると worktree と branch まで消える
  （`removed=<path> branch=<branch>`）。ExitWorktree 後に main checkout から実行すること。
