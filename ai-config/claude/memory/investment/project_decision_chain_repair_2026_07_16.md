---
name: project-decision-chain-repair-2026-07-16
description: 判断段通電修理完了 (07-16)。decision_runner/sizing/gate0/guardrail の4系統。E2E確認は financial_unifier 復旧待ち
metadata: 
  node_type: memory
  type: project
  originSessionId: 0b4cfd7b-51a4-460d-9c82-faa587960441
---

# 判断段の通電修理 (2026-07-16 完了)

7/15 監査所見 5-2/5-3/5-4/3-8/4-5（DECISION-RUNNER-01）を1セッションで修理。正本: docs/worklogs/20260716-decision-chain-repair.md

## やったこと
- **decision_runner**: decision_outputs へ ON CONFLICT DO NOTHING + `normalize_candidates`（不正コード drop・先勝ち dedup、41466 は切り詰めず落とす）+ 戦略毎 commit/rollback（`_run_strategy` 抽出、失敗マーカー run、status ok/partial）
- **sizing**: insufficient_history VaR を `determine_pf_mode` で CAUTION cap。実測で 7/16 から pf_mode=caution（7/10〜15 は freeze 固定だった）
- **gate0**: 書き込みを列適応型化（information_schema 1クエリ・キャッシュなし=DDL適用の瞬間に自動切替）。5列追加 DDL は**手順書のみ**（worklog 内）— 並行セッションの未コミット alembic 群がコミットされてから
- **guardrail**: 幽霊参照 analytics.ml_guardrail_snapshots を廃止し ops.ml_* に結線（dc/pit=7日窓、他=35日窓）。部分計測の go は degraded に降格（fail-closed 維持）。producer は earnings_post_return_5d に `daily-run` 新設、manifest args を record-run→daily-run（Windows 再登録不要）。実測で 23戦略 hold→degraded

## 知見・罠
- **[[bugs-module-split-monkeypatch-binding]] 系**: runner.py が凍結サイズ予算超過→ guardrail_checks.py 分離。循環は関数内 lazy import で回避
- **init_db の全契約チェックは経路過剰**: earnings_post_return_5d の init_db が未適用 migration の列 (core.events.*) まで要求し、無関係な計測経路を fail させる。record_* 関数は自己ガード済みなので計測経路では init_db を呼ばない設計にした
- **shared/db/pool.get_connection は中間 commit/rollback 可**（アダプタが公開、返却時 rollback+RESET）→ 戦略毎トランザクション分割はプール変更なしで実現
- **新規実データ所見**: ML dataset の flow/fx/rates/macro シグナルが 15,544 行全 NULL（dc=warn high_null_rate）。feature store 凍結（所見 10-4）と同根疑い。#44 で扱う

## Handover
- decision_runner の実データ E2E は financial_unifier 復旧（PG-REINDEX-01、別担当）後の夜間バッチで確認
- gate0 5列 DDL は worklog の手順書どおり alembic 一本化後に適用
- pytest 全体の残 3 failed は並行セッション由来（file_size_budget / indicator catalog_version / DecisionListItem）
- 通電後の guardrail 定常は「degraded」。完全 GO は #44（evaluation/calibration/drift 定期化）完了まで出ない設計
