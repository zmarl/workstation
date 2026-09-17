---
name: project-product-lanes-2026-09-07
description: 2026-09-07 の製品レーン（macro 索引破損診断 / Qwen 27B sidecar が動かない真因 / HOLD 80 の 3 群 / 決算閉ループの現況）の確定事実と、修復・次工程の入口
metadata: 
  node_type: memory
  type: project
  originSessionId: 18e0a477-b9bf-4062-8b25-ed94690f19f2
  modified: 2026-09-07T12:25:08.149Z
---

ODR-0038 の製品復帰レーンで 2026-09-07 に確定した事実。

- **macro 索引破損（PR #419 で診断記録）**: `core.macro_metrics_pkey` と `raw.macro_metrics_raw_pkey` が amcheck `bt_index_check(heapallindexed)` で `XX002`。索引経路は全走査より件数が少なく最新日が古い（日本 GDP 0/7、米失業率 2026-03 vs 2026-08）。主キー重複は core 5 組（値同一、古い方が敗者）・raw 15 組（raw の PK は source_name/source_record_key/metric_name/revision_tag で、観測日あたり複数行は改訂履歴なので重複ではない）。修復手順（COPY 退避→単一 Tx DELETE→REINDEX CONCURRENTLY→再検査）は worklog `20260907-claude-macro-index-diagnosis-*.md` §5。**オーナー承認待ち**。読み取り診断スクリプトは scratchpad の `probe_macro_index.py` / `probe_macro_dups.py`（DSN は `shared.config.get_settings().postgres_dsn` + `_prefer_ipv4_loopback`、`prepare_threshold=None`、REPEATABLE READ READ ONLY）。
- **Qwen 27B sidecar が動かない真因**: Tauri の `wait_for_full_gpu_offload`（`desktop/src-tauri/src/qwen_runtime.rs`）は llama-server ログの `offloaded 66/66 layers to GPU` を 180 秒待つが、llama.cpp b10566 はこの行を `-lv 4` でしか出さない（ベンチマーク README:77 に明記）。Tauri の起動引数に `-lv` が無く、毎回 kill → worker 未起動 → queue 0 行。`.env` の `LLM_PROVIDER` 等は原因ではない（worker は Tauri が env 注入）。修正は `llama_server_args` に `-lv 4`（L-Q PR）。観測は `data/runtime/qwen38_agent/{llama-server,agent-worker}.log` と BFF `GET /api/v1/earnings/agent-runtime`（header `X-Decision-Token` に `settings.decision_api_read_token`）。
- **HOLD 80 の 3 群**: 第 1 群 32 本はポジションを読まない（依存先停止のみ）。第 2 群 33 本は読み手、第 3 群 12 本は書き手で、`core.positions` に出所・時点・口座網羅性の列が無いためスキーマ ODR が先。解除 PR は manifest 移動 + `register_schedules.ps1` の `$script:DisabledTaskPolicies` 行削除 + `scheduler_expected_task_ids.txt` / `meta.yaml` + `.bat` を 1 commit で。**登録行は登録直前の別 PR**（登録前に入れると live drift が error）。`depends_on` は隔離前 commit `3160085f3^` から復元。`earnings-carry-*` は OWNER_INTENT §4 の hold 維持。
- **決算閉ループ（作業しない）**: DecisionCase の 3 revision は本番に適用済み（記録なし、本番は `20260827_01`）。shadow は revision 完全一致検査・未設定の Ed25519 署名鍵・適用証明パケット生成ツール不在で起動不能。Gate 3 は validator 未実装。オーナーは Qwen 最優先、閉ループは取りやめの可能性。
- **旧 9B 系 4 task の停止**は別 Claude セッションの worktree `claude/tdnet-llm-off-355e501e7c`（未 publish、最終 commit 09-07 09:19、gate 証拠 14:04）。peer なので触らない。

**着地状況（2026-09-07 20:05 時点）:** PR #419（macro 診断）・#420（Qwen `-lv 4`）・#421（HOLD 6 本復元）を merge。3 task は Scheduler 登録済み（初回 9/8 08:55 / 19:00 / 22:10）。Qwen 修正の Desktop build はオーナーがアプリを閉じるのを待っている。
**L-1b の実態:** 残り第 1 群 14 本のうち依存先がすべて稼働中なのは `investment-judgement-run`（依存なし・Scheduler 名なし）だけ。他 13 本は第 2 群（`earnings-quality-label-pending`、`candidate-universe-refresh-daily`、`feature-store-daily`、`behavioral-*`）や第 3 群（`sizing-calculate-daily`、`decision-runner-daily`、`position-recorder-daily`）、`daily-screener-run` に依存する。第 1 群 32 本を全部戻す前提は成り立たず、次は第 2 群のスキーマ ODR（`core.positions` に出所・時点・口座網羅性、`position_state_daily` の Decimal 化）が必要。

**着地状況（2026-09-07 21:25 時点、追記）:** macro 修復完了（PR #422、amcheck 合格、退避 CSV `data/db_backups/*_dedup_removed_20260907T120241Z.csv.gz`）。Qwen は build → 再起動で `offloaded 66/66`・worker 稼働（実決算待ち）。**ODR-0039 草案（保有スナップショット契約）を PR #423 で merge、`status: Proposed`。オーナーの 6 問回答待ち**（鮮度窓／時価の出所／口座粒度／`position_state_daily`／CSV 範囲／解除順序）。回答後: ODR を Accepted + OWNER_INTENT §7 追記 → `ddl-position-snapshot` worktree で Alembic + projection + DB テスト → Desktop 宣言 UI → 束ごとの解除 PR。ファイル: `docs/decisions/20260907-position-snapshot-attestation.md`。

**Why:** 3 レーンとも「設計はあるのに実データで動いていない」型で、原因がコードの 1 行（Qwen）や索引破損（macro）など小さい。次のセッションが再調査せず修復・観測から入れるように。

**How to apply:** macro 修復はオーナー承認後に worklog §5 の SQL を逐語で実行（macro 書き手 01:50 JST の外、`lock_timeout=5s`）。Qwen は merge 後にローカル build（`desktop/build-tauri.ps1 -release -NoBundle`、実行中 exe は上書き不可なのでオーナーがアプリを閉じてから）→ 再起動 → ログと BFF で確認。関連: [[project-integrated-assessment-plan-2026-09-07]]、[[project-harness-freeze-iteration1-2026-09-07]]。
