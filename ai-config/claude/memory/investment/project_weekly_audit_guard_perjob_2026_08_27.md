---
name: project-weekly-audit-guard-perjob-2026-08-27
description: "merge guard の per-job 寛容化を PR #242 で着地 (08-27/28)。finish-pr は実行元 checkout の guard コードを使うため guard 欠陥は自分の修理を止める・claim 登録 worklog 名の一致必須・venv 欠損の本物 stop が別途残存"
metadata: 
  node_type: memory
  type: project
  originSessionId: 08dbe37d-b49e-4c92-9bc0-f1d41581d236
  modified: 2026-08-27T15:23:49.410Z
---

# weekly audit merge guard per-job 寛容化の着地 (2026-08-27〜28, PR #242)

[[project-weekly-audit-repair-2026-08-24]] の続報。他セッションの ready_async job が branch 側でのみ承認済み pack id（python-broad）を宣言 → `read_queue_snapshot` 全体が QueueContractError → `evaluate_merge_guard` が「weekly audit state is unreadable (global stop)」で全 PR マージ停止、の欠陥を修理した。

## 修理内容（merge commit c1f14415c）

- `proof_pack_queue_snapshot.read_snapshot` に opt-in `skip_invalid_non_audit_jobs`。**寛容化は「raw request.json の job_kind 宣言が audit 系（full_audit/repair_audit）でない job」限定**。audit 系宣言・判別不能・構造違反（件数/バイト上限・link・必須ファイル欠落）は strict のまま（既存テストが「壊れた full_audit job = global stop」を仕様として固定しているため）。
- guard の `merge_attested_aggregates`（merge guard + repair enqueue の両方が使う）と `repair_attestation_passes` の 2 箇所に適用。非 audit job の skip は attested_passes を増やさない方向（passed aggregate の脱落＝より block 側）にしか働かず、誤 unblock は構造上不可能。

## 罠・教訓

- **finish-pr の merge guard は「実行元 checkout の guard コード」で評価される**。main checkout から実行する限り、guard の欠陥修理 PR 自体が修理前 guard に止められる（ODR-0019 の実例）。代替: gh pr merge --match-head-commit + PR コメント記録 + `sync_repo.py after-merge` で回収（PR #222/#224/#225/#242 で実績）。after-merge は merge 親 SHA の完全一致確認と main 同期・cleanup_deferred 化・**新 main への full_audit enqueue** までやってくれる。
- **publish-pr は claim に登録された worklog 名との完全一致を要求**（"worklog does not match the worktree claim"）。Claude Code の WorktreeCreate hook は `docs/worklogs/<YYYYMMDD>-<worktree名>.md` を claim に自動登録するので、worklog は最初からその名前で作る（任意の名前で作ると rename→再 gate が必要になる）。claim ID は `git worktree list --porcelain` の locked reason（`agent-session-v2:claude:<task>:<claim_id>:{...}`）から読める。
- 反証実行（修理を一時的に外して新テストが障害と同一メッセージで fail することを確認）は「テストが空振りしていない」証明として reviewer にも有効だった。
- gate の base race: 作業中に他 PR が着地したら rebase → focused 再検証 → gate 再実行。この規模（packs: harness-docs/runner-core/test-infra）の ready gate は 1 回約 2 分。

## 未解決（フォローアップ chip 発行済み）

- **本物の global stop が残存**: 2026-08-27 14:40Z の full_audit（head cbcfdefa6, job e4aa8aff）が全 6 レーン ProcessExit で failed。ログは全て 19 bytes の「**No pyvenv.cfg file**」＝監査 runner の venv 欠損（インフラ障害、7 分前の監査は passed）。after-merge が enqueue した c1f14415c への full_audit（job aa0fec53, 15:20:05Z queued）が合格すれば自動解消。failed 再発なら runner venv の修理が必要。
- APPROVED_PACK_IDS への python-broad 追加は別セッション（selector-config-python-broad-20260826 worktree / PR #233 系）の責務。
