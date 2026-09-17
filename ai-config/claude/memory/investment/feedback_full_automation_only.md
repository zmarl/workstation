---
name: 完全自動運用前提・半自動 UI は不要
description: ops 系・運用系機能は scheduler 駆動の完全自動が前提。UI からボタン押下で起動する半自動経路は価値がない
type: feedback
originSessionId: 4b0b3b78-3400-4de5-ac63-7269ed38ea8e
---
ops / 運用系の機能は **scheduler 駆動の完全自動運用** が前提。Desktop UI
から手動ボタンで起動する「半自動」経路はユーザー価値がない。

**Why:** ユーザーは Investment Tools を「自分で操作するダッシュボード」では
なく「自動で動く意思決定支援システム」として運用している。半自動だと
「人間が押すのを忘れる / 押すタイミングを判断する」コストが残り、
完全自動でないと意味がない、と 2026-05-11 に Phase 14 smoke test 中に明示。

**How to apply:**

- 新機能を提案するときは「scheduler / autonomous loop で起動するか、
  完全自動経路があるか」を最初に確認する
- OpsActionPanel の morning-check / market-brief / diagnose ボタンの
  ような手動トリガ UI は新規追加しない
- **既に存在する手動ボタン** (Phase 7-12 で配線済) は撤去判断はユーザーに
  委ねる。新規拡張はしない
- 「smoke test を Tauri dev で手動操作してもらう」設計は避け、scheduler に
  乗せて run_manifest 経由で検証する形に切り替える
- **意思決定アクション (decision_*, thesis_* 等) は半自動許容**: これは
  ユーザーが「いつ売買するか」を判断する本質的な操作なので除外。ops 系
  (morning-check, market-brief, diagnose) と区別する
- agent_actions / command_runs を Desktop UI で**閲覧**するのは OK
  (自動化された ops の結果を見るため)
- audit / retention / scheduler 登録 / 統計集計などの裏方は今後も価値あり
