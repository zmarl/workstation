# 製品レーン第 1 反復（2026-09-07 承認待ち）— HOLD 解除・Qwen 日次運用・macro 索引診断

## Context

ハーネス凍結の第 1 反復（PR #413〜#418）は完了し、夜間回帰の Scheduler 登録も済んだ。ODR-0038 D6 に従い製品作業へ復帰する。オーナー回答（2026-09-07）:

- HOLD 80 タスクは「第 1 群 32 本を 2 回に分けて復旧」。
- 決算閉ループ（DecisionCase shadow）は**着手しない**。オーナーは Qwen 決算分析の日次運用を最優先とし、閉ループは運用取りやめの可能性がある。調査で判明した事実（migration は記録なしで本番適用済み・shadow は revision 完全一致検査と未設定の署名鍵で起動不能・Gate 3 は検証器未実装）は記録だけ残す。
- macro_metrics 索引は「読み取り診断 → 承認パック → 承認後に修復」。

**決算閉ループとは**（オーナーの質問への回答）: 1 社の決算を「発表前の予想（ForecastSnapshot）→ 判断（Decision）→ 次に追う項目（Monitor）→ 結果（Outcome）→ 学び（Lesson）」まで 1 案件（DecisionCase）として DB に記録し、予想と結果を突合する仕組み（`docs/design/裁量投資判断OS_全体設計.md:165`）。判断はオーナー、システムは記録と突合のみ。Qwen 決算分析 sidecar とは ODR-0024 で分離済みで、Qwen の結果は `decision.earnings_agent_evaluations` に独立保存され BFF・会社ページで表示される。閉ループが動かなくても Qwen 側は使える。

## 調査で確定した前提

| レーン | 事実 | 出典 |
|---|---|---|
| HOLD | 80 本のうち第 1 群 32 本はポジションを読まず、依存先停止だけで止まっている。`depends_on` は 2026-08-11 の隔離で削除済み（復元元は隔離前 commit `3160085f3^`）。第 2 群 33 本・第 3 群 12 本は `core.positions` に出所・時点・口座網羅性の列が無くスキーマ設計（ODR）が先 | explore-hold §A/§B |
| HOLD | 解除 PR は 1 commit で manifest 移動 + `register_schedules.ps1` の `$script:DisabledTaskPolicies` 行削除 + 登録行追加 + `scheduler_expected_task_ids.txt` / `meta.yaml` 期待 ID + `.bat` を揃える必要（`check_scheduler_integrity.py:670-738` が双方向に検査）。登録前に登録行を入れると live 検査が drift を error にするため、**登録行は登録ウィンドウの直前 PR**（PR #418 と同じ型） | explore-hold §D、PR #418 |
| HOLD | 6 本は `scheduled_task_name` が無い（`candidate-universe-refresh-morning`、`screening-snapshot-morning`、`investment-judgement-run`、`expectation-gap-analyze-all`、`screening-alert-dispatcher-morning/evening`）。`earnings-carry-*` 3 本は OWNER_INTENT §4 の hold（並走データが貯まるまで）で対象外 | explore-hold §A、OWNER_INTENT §4 |
| Qwen | パイプラインは TDnet 取込 → pack → `ops.local_llm_agent_tasks` へ enqueue → worker → `decision.earnings_agent_evaluations` → BFF → 会社ページ → Discord（`earnings_finance`）まで実装済み。**enqueue と worker は Tauri（Desktop）起動時にだけ動く**（`desktop/src-tauri/src/qwen_runtime.rs:143-156`）。Scheduler 経路は無い（ODR「local-llm-desktop-control-plane」の設計どおり） | explore-qwen §A |
| Qwen | `.env` の `LLM_PROVIDER` / `LOCAL_LLM_RUNTIME_BACKEND` / `LOCAL_LLM_OPENAI_BASE_URL` が既定（disabled / ollama_native / :1234）のままだと `runtime_status()` が `runtime_stopped` になり全 task が `waiting_gpu` で止まる（`runtime_profile.py:62-72`）。実 TDnet 決算の日次処理・Discord 送信の証拠はまだ無い（7602 の固定分析 1 件のみ） | explore-qwen §D/§E |
| Qwen | 旧 9B 系 4 task（`tdnet-extractor-daily` の `--qwen35-mode shadow`、`tdnet-ollama-runtime-check-daily`、`tdnet-extractor-morning-daily`、`earnings-quality-llm-check-daily`）がまだ active。停止修正は別 Claude セッションの worktree `claude/tdnet-llm-off-355e501e7c`（未 publish、`Verifying`）にある | explore-qwen §B |
| macro | 2026-09-05 の同一 REPEATABLE READ READ ONLY スナップショット比較で `core.macro_metrics` の日本 GDP 0/7、日本失業率 22/28、米 CPI 7/30（重複 2 行）、米失業率 24/32（重複 3 行）。`raw.macro_metrics_raw` も同型。7 月の EDINET 前例は「COPY 退避 → 単一 Tx で DELETE → 件数確認 → REINDEX」。既存の `edinet_recovery` の allowlist は backup/restore 契約と一体で macro へ流用しない | explore-macro §A/§B |
| 閉ループ | 本番 alembic は `20260827_01`（`20260731_01〜03` は祖先として適用済み、適用記録なし）。shadow 起動は `alembic_version == [20260731_03]` の完全一致検査（`shared/decision_case_shadow_activation.py:211-215`）と未設定の署名鍵（`shared/decision_case_owner_approval.py:10-12`）で不可能。Gate 3 は stage validator 未実装 | explore-decisioncase §A/§E |

## 実施方針

- このセッションが直列に担当: **L-3（macro 診断）→ L-Q（Qwen 運用の実測と設定）→ L-1a（HOLD 第 1 群 前半）→ L-1b（後半）**。各レーン 1 worktree・1 worklog、`pr-ready-gate` の手順。凍結中なのでハーネスには触らない。
- 共有 DB への書き込み（macro 修復、HOLD 解除後の初回実行）は承認範囲外の人手境界。**解除した task の初回実行は Scheduler の定時実行で観測し、手動実行はしない**（dry-run / `--help` のみ）。
- Scheduler 登録は各レーンの最後に登録ウィンドウ 1 回（PR #418 と同じ「登録行 PR → skill で登録 → live 検査」）。

---

## L-3: `core.macro_metrics` 索引診断（読み取り専用、1 日）

1. worktree `macro-index-diagnosis`。scratch の読み取り専用スクリプト（`uv run python`、DSN は `127.0.0.1` 明示、`prepare_threshold=None`）で 1 つの `REPEATABLE READ READ ONLY` トランザクション内に、対象 4 系列 + `raw.macro_metrics_raw` の 5 系列について (a) 索引経路と (b) `enable_indexscan/indexonlyscan/bitmapscan=off` の全走査で `count(*)` / `max(as_of_date)` / 重複 `(source, metric_key, as_of_date)` を取り、EXPLAIN でノード種別を記録。`SELECT 1 FROM pg_extension WHERE extname='amcheck'` を確認してから `bt_index_parent_check('core.macro_metrics_pkey', heapallindexed => true)`（ShareLock。深夜帯に実行）。
2. 結果を `data/runtime/evidence/macro-index-diagnosis/*.json`（ignored）に保存し、worklog（Full）に件数表と結論を記録。
3. 承認パック（worklog §5）: 修復 SQL を逐語で提示。`COPY (重複の敗者 = ctid 昇順) TO data/db_backups/macro_metrics_dedup_removed_<date>.csv.gz` → 単一 Tx で `DELETE … WHERE ctid IN (…)` → 件数アサート → `REINDEX INDEX CONCURRENTLY core.macro_metrics_pkey`（重複が残ると失敗するので順序固定）→ `bt_index_parent_check` 再実行。`lock_timeout='5s'`、想定所要、rollback（退避 CSV からの再投入）、実行ウィンドウ案。`raw.macro_metrics_raw` も同じ型なら同じパックに含める。
4. `docs/backlog/次アクション管理台帳.md` の `20260905-macro-query-consistency` 行を `blocked` → `in_progress` に更新し、DoD に診断証拠を接続。
- 触るファイル: worklog、台帳 1 行。コード追加なし。検証: 証拠 JSON と EXPLAIN。修復の実行はオーナー承認後の別作業。

## L-Q: Qwen 決算分析の日次運用を「実 1 件が Discord に届く」まで（実測 → 設定 → 観測）

1. **実測（読み取り専用、worktree `qwen-daily-ops`）**: この PC の `.env` から非秘密キー 4 つ（`LLM_PROVIDER`、`LOCAL_LLM_RUNTIME_BACKEND`、`LOCAL_LLM_OPENAI_BASE_URL`、`TDNET_QWEN35_MODE`）だけを `grep -E '^KEY='` で読む（値は非秘密）。Desktop が起動中なら BFF `GET /api/v1/earnings/agent-runtime` で runtime / queue 状態を読む。`ops.local_llm_agent_tasks` と `decision.earnings_agent_evaluations` の件数・最新時刻を read-only で読む。結果を worklog §2 に「動いている / 止まっている理由」として記録。
2. **設定（人手境界）**: `.env` の編集は私には deny。必要な値（`LLM_PROVIDER=local_runtime`、`LOCAL_LLM_RUNTIME_BACKEND=openai_compat`、`LOCAL_LLM_OPENAI_BASE_URL=http://127.0.0.1:8081/v1`）と、`DISCORD_WEBHOOK_EARNINGS_FINANCE` の設定有無を worklog に提示し、オーナーが `.env` を編集する。
3. **観測**: Desktop を通常起動（Tauri が llama-server と worker を自動起動）→ 直近の実 TDnet 決算が pack → enqueue → 分析 → 保存 → 会社ページ表示 → Discord まで通るかを、`agent-runtime` と `decision.earnings_agent_evaluations`、Discord の到達で確認。通らない hop を 1 つずつ修理（各 1 PR、局所変更）。
4. **旧 9B の停止**: 別セッションの worktree `claude/tdnet-llm-off-355e501e7c` が担当。そのセッションが終了済みならオーナー承認のもとで引き継ぎ（`claim-worktree`）して Ready → merge → 登録ウィンドウ（`TdnetOllamaRuntimeCheck` の登録解除）。稼働中なら触らない。
5. spec §9 の 12 項目は本反復では着手しない（マイルストーン達成後に P0 から）。
- 触るファイル: worklog、必要なら `tools/decision_support/earnings_evaluation_assistant/*` の局所修理。検証: 実 1 件の end-to-end 証拠（evaluation 行・BFF 200・Discord 投稿）。

## L-1a: HOLD 第 1 群 前半（利用者が日々見る 15 本）

対象: `daily-screener-run`、`daily-screener-refresh-morning`、`screening-snapshot-morning`、`screening-snapshot-evening`、`screening-alert-dispatcher-morning`、`screening-alert-dispatcher-evening`、`screening-rule-optimizer-daily`（observe-only のまま）、`earnings-schedule-daily`、`earnings-event-evaluate-pending`、`earnings-event-evaluate-intraday`、`earnings-prospective-validation-daily`、`earnings-outcome-fill-daily`、`earnings-post-action-short-cycle`、`market-expectation-surface-daily`、`hypothesis-note-seed-daily`。

手順（worktree `hold-unlock-1a`、worklog Full）:
1. 各 task について隔離前 commit `3160085f3^` の manifest から `depends_on` / `fresh_success_dependencies` / `schedule` を復元し、依存先が active であることを確認（依存先が第 2 群なら本 tranche から外して記録）。`scheduled_task_name` が無い 4 本には既存命名規則で名前を付与。
2. `scripts/manifest/*.yaml` で `disabled_tasks` → `tasks` へ移動（`disabled_since` / `disable_reason` / `restore_condition` / `scheduler_registration_eligible: false` / `pipeline_mode` を削除）、`build_run_manifest.py --write`、`generate_task_wrappers.py --write`（`daily-screener-run` は `wrapper_bat: run_daily_screener.bat` の既存 wrapper を確認）、`scripts/scheduler_expected_task_ids.txt` と `scripts/manifest/meta.yaml` の期待 ID、`tool_tiers.yaml`。
3. `scripts/register_schedules.ps1` の `$script:DisabledTaskPolicies` から該当 15 行を削除。**登録行は入れない**（PR #418 型: 登録ウィンドウ直前の別 PR）。
4. テスト更新: `tests/scripts/test_scheduler_integrity.py:578-612` の「disabled のまま」を主張する 3 本のうち対象分（`screening-rule-optimizer` は observe-only 主張を残しつつ `tasks` 側を見る形へ、`market-expectation-surface` は active + depends_on ありへ）。`tests/scripts/test_daily_briefing_manifest_contract.py` は briefing が第 2 群なので変更なし。
5. 各 module を `--help` と（あれば）`--dry-run` で起動確認。共有 DB への書き込みを伴う手動実行はしない。
6. gate → publish → finish。続けて登録行 PR（15 行の `Update-InvestmentTask`）→ merge → 登録ウィンドウ（`-OnlyTaskNames` に 15 名）→ live 検査 drift 0。
7. 翌朝 `ops-morning-check` で初回定時実行の結果を確認。失敗した task は個別に 1 PR で修理するか `disabled_tasks` へ戻す（理由を明記）。

## L-1b: HOLD 第 1 群 後半（残り 14 本）

`story-builder-review-daily`、`story-builder-batch-draft-weekly`、`investment-judgement-run`、`workflow-orchestrator-daily`、`execution-rewrite-check-daily`、`execution-override-check-daily`、`expectation-gap-analyze-all`、`nlp-earnings-sentiment-daily`、`investor-skill-daily`、`market-situation-build`、`short-squeeze-warning-daily`、`execution-quality-analyze-daily`、`hidden-edge-weekly`（float 精度が理由。復元条件を再確認）、`earnings-shadow-readiness-daily`。手順は L-1a と同じ。`earnings-carry-*` 3 本は OWNER_INTENT §4 の hold を維持。

L-1a の初回実行が 3 営業日安定してから着手する。

## 記録だけ行うもの（作業しない）

- 決算閉ループ: 本番 alembic が `20260827_01` で `20260731_01〜03` が記録なしに適用済みであること、shadow 起動を阻む 3 点（revision 完全一致検査・署名鍵・適用証明パケット生成ツール不在）、Gate 3 検証器未実装を、L-Q の worklog Discovery と `docs/backlog/次アクション管理台帳.md` の `INST-G3-PROMOTION` 行（`blocked` のまま、理由を現況へ更新）に残す。OWNER_INTENT §3-1 の文言変更は、運用取りやめの判断が出てから ODR で行う。
- 第 2・3 群のスキーマ設計（出所・時点・口座網羅性の列、`core.position_state_daily` の Decimal 化）は ODR 草案の対象。L-1b の後にオーナーへ提示。

## 検証と判定

- L-3: 証拠 JSON に 5 系列 × 2 経路の件数と EXPLAIN、amcheck 結果。承認パックの SQL が逐語で揃う。
- L-Q: 実 TDnet 決算 1 件の evaluation 行、BFF 200、Discord 投稿の 3 点。
- L-1a/1b: `check_scheduler_integrity` live で drift 0、翌朝の runlog で対象 task が成功、`ops-morning-check` に赤なし。HOLD 残数 80 → 65 → 51。
- 週次: ODR-0038 D8 の 6 数字（月曜）。

## やらないこと

決算閉ループの shadow 起動・Gate 3 の実装、第 2・3 群の解除、macro 修復の実行（承認前）、旧 9B 停止 worktree の無断引き継ぎ、ハーネス変更（凍結中）、`.env` の編集（deny）。
