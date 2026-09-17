---
name: project-unfinished-completion-batch-2026-07-04
description: 未完了完成バッチ (2026-07-04)。NOTIF-STD-03 failure inbox 再構築 + NOTIF-STD-04 Wave 1 (55.2%→60.3%) + 実装不整合修理6件。worktree D:\Dev\Investment-followups で実施、統合待ち
metadata: 
  node_type: memory
  type: project
  originSessionId: 1b2e6834-e69b-4603-83be-7f4cf5b13b35
---

# 未完了完成バッチ (2026-07-04)

全リポジトリ棚卸し（Explore×3 + Plan×2）で「やりかけ」を列挙し、他ターミナル直近作業（reform-program / 負債返済 / スケジューラ登録）を除外して2系統を完成させた。プラン: `C:\Users\kazum\.claude\plans\3-jaunty-shore.md`。

**実施場所**: worktree `D:\Dev\Investment-followups`（ブランチ `feat/unfinished-completion-batch`、起点 513b4f89）。[[feedback-parallel-session-worktree]] 準拠。

## 系統A: 通知標準化の完成（commit aa452124）
- **NOTIF-STD-03 done**: failure inbox 再構築（6/20 実装が並行上書きで消失していたもの）。`GET/POST /api/v1/ops/failure-inbox(/actions)`、Ops Hub「失敗インボックス」タブ、Dashboard「夜間失敗 N」バッジ。inbox 状態は `data/runtime/ingest_failure_inbox_state.json`（DDL 凍結中のため file-based、ADR 追記済み）。severity 分類は bridge から import で単一ソース化。ack より新しい失敗は自動 unread 復帰
- **NOTIF-STD-04 in_progress (Wave 1 done)**: 15ツール（analytics 9 / quality 4 / DOC-REG-09 系 2）へ `run_entrypoint` 導入。カバレッジ 164/297 (55.2%) → 179/297 (60.3%)。残 118 は並行セッション収束後
- **DOC-REG-09 再分類**: 6系統中、継続失敗は estat_tracker の partial のみ（他5系統は回復済み）。bridge dry-run 168h で直近週 247 失敗 / 21 groups / critical 202
- live smoke: 実 DB で未読14件表示、ack→13、reopen 復元を確認

## 系統B: 実装不整合修理6件（commit d5cdc762）
- pf_risk_monitor / sizing_engine: 「モジュール未存在」前提の陳腐化 except を解消（両モジュールとも実在済み）。ログ付き degrade ヘルパーに抽出
- sector_fund_flow (SFF-P2-01→blocked): `_jpy` hydration は**不可能**と確定 — `raw.supply_demand_daily.foreign_buying/selling` は 546,608 行**全行 NULL で writer 不在**。全 NULL 窓は NULL/neutral 出力の正直セマンティクスへ
- BMPH-REG-01 done: manifest の business-model-panel-health-daily が旧 module を誤配線 → `_daily` へ切替（bat 経由のため Task Scheduler 再登録不要）
- 台帳同期: DESIGN-P2/P3 → done（worklog 着地済みなのに todo のままだった）
- api-client regulationIngestStatus: 404→偽 fresh 吸収を削除（BFF は実装済み）

## 知見・ハマり
- **BFF エンドポイント追加の登録先は4箇所**: routers ファイル + app.py include_router + app.py の READ/RUN_TOKEN_PROTECTED_ROUTES frozenset + endpoint_registry.py EndpointSpec + `scripts/decision_api_typed_response_scope.txt`（テストの期待件数 498→500 も更新要）
- **worktree での run-token POST は 503 serving_degraded_read_only**: `.env` が clickhouse_primary の場合、untracked の `data/runtime/evidence/serving_path_cutover_host_preflight.json` を本体からコピーする必要あり
- desktop テストは tsc -b の対象（@ts-nocheck なしで書くなら strict null 対応必須）。useMutation の mutationFn は第2引数付きで呼ばれる（toHaveBeenCalledWith 不可、mock.calls[0][0] で検証）
- 既存失敗（起点 513b4f89 時点から）: scheduler_integrity の news-detector-stale-check 未追随、case_study/supply_chain schema 3件、template_codegen 1件 — 並行セッション由来

## 統合完了（2026-07-04 同日）
- merge commit **380206a5** で `feat/functional-uplift-p1` に統合済み（conflict なし）。worktree 削除・ブランチ削除済み
- merge 後検証 green: ruff / endpoint contract 28 / 修理系 273 / typegen ok / typecheck / desktop 36 tests
- **統合時に判明した本流側（uplift 由来）の未解決**: ①file_size_budget 4違反（revision_predictor calculator 801行新規 / test_serving_repository / test_revision_calculator / _market.py — commits 46cb2a94, 43d7eda5）②scheduler_integrity 4エラー（strategy-conflict-resolver / segment-value-anomaly-quarantine / consensus-revision の register 未マッピング + canslim 依存タイミング）③repo-wide 既存失敗6件（scheduler_integrity news-detector / run_tool wrapper 市場指標8bat / case_study・supply_chain schema 3 / template_codegen）— いずれも uplift の handover items
- **稼働中 BFF (8010) は merge 前のプロセス** → failure inbox endpoint は BFF 再起動後に有効（Desktop 起動時の自動起動で反映）
