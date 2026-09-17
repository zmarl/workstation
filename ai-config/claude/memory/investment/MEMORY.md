# Investment Project Memory

## Architecture (要約)

- **Desktop**: Tauri 2 + React 19 + Vite 7 (`desktop/`)、Zustand + TanStack Query/Router、Tailwind
- **境界**: Desktop → FastAPI BFF (127.0.0.1:8010) のみ。他への直アクセス禁止
- **3層 (2026-07-11 確定)**: PostgreSQL (write 唯一 + serving) / FilesystemObjectStore (durable SoR) / DuckDB (read-only 分析)。ClickHouse 退役済み。正本: docs/design/DBレイヤー契約.md
- **LLM**: `Desktop → FastAPI → LLM Gateway → vLLM/Ollama` のみ。外部 API 直叩き禁止
- 詳細: @./architecture.md

## Known Issues
- **psycopg: `%` エスケープは params 前提でしか正しくない／`?`→`%s` 変換は `execute`/`executemany` だけで `.cursor()` は素通し**（cursor 経由は `%s` 直書き）。詳細: @./project_known_issues_patterns_2026_08.md
- PostgreSQL DDL: `DOUBLE`→`DOUBLE PRECISION`、`INTERVAL 1 DAY`→`INTERVAL '1 day'`、VIEW カラム順序変更は DROP+CREATE
- スケジューラ exit code 65 = SUCCESS_MISMATCH、66 = 依存の新鮮な成功なし、70 = ラッパー自体の停止
- **DSN は 127.0.0.1 明示**（`localhost` だと IPv6 先行で30秒ハング→PoolTimeout 全滅）
- **wsl --shutdown 後は 5432 の port 転送が壊れることがある**→`docker restart investment-postgres`。監査が evidence 失敗+safe レーンのログ 0 バイトならまず host→5432 を疑う
- financials は**円**、IFIS/コンセンサスは**百万円** → 比較時 ×1,000,000
- tdnet_earnings_reports.company_name 不完全あり → stocks.name 優先
- shares_outstanding 正本: `jquants.shares_outstanding_daily` + `public.edinet_shares`。`main.shares_outstanding` だけ `date`/`shares_outstanding` 列名
- DuckDB: `DO UPDATE SET` 内 CURRENT_TIMESTAMP 不可→`now()`。PostgreSQL: `ROUND(dp, n)` 不可→`::NUMERIC`
- `raw.ingest_runs.status` CHECK: running/success/partial/failed のみ
- FRED Gold 廃止 → Yahoo `GC=F` 代替。EDINET大量保有: docType 350/360
- EDINET財務抽出: doc_type {120/140/160} のみ、FY=決算期末年、再構築は --since 必須。詳細: @./project_edinet_extraction_corruption_fix_2026_06.md

## Decisions
- `shared/performance.py` でホストスペック自動検出。電源プランは高パフォーマンス
- deny `Read(.env)` は .env.example に誤ヒット → deny から削除済み
- PowerShell `Set-Content` は日本語UTF-8を破壊 → Python `write_text(encoding='utf-8')`

## Patterns & Tips
- **観測できない失敗の 4 類型**（A 記録前に落ちる／B 記録機構が壊れている／C 記録経路がない／D 記録は正常で外形が同一）。**成功の記録は成功したことすら証明しない**。詳細: @./project_known_issues_patterns_2026_08.md、道具: @./project_observability_failure_taxonomy.md
- tracking 系ヘルパーの `@patch` は **`autospec=True`**
- merge guard の `selection_digest` は `selection.selection_map_sha256`／`repair_audit` の成立条件 4 つ。詳細: @./project_known_issues_patterns_2026_08.md
- **scratchpad スクリプト名が import を乗っ取る**。`probe_`/`edit_` 前置。原因不明の例外はまず traceback 全フレーム
- **worktree セッションの Bash guard は heredoc・`$(...)`・算術展開・powershell を拒否**。編集/調査は scratchpad にスクリプトを書いて `uv run python <path>`。ラッパー実行は main checkout から
- IFIS HTMLテーブル: 数値と%結合 → `\d{1,3}(?:,\d{3})*` で先頭抽出。コンセンサスは IFIS のみ
- loguru: `{}` 使用。pytest キャプチャは `logger.add(StringIO())` sink
- `shared/cli.py` は削除済 → `shared.tooling.cli.output`。upsert は `shared.tooling.repository.upsert`
- Ingest tracking: 全ツール `shared.raw_ingest_tracking`。T20 (flake8-print) 有効
- テストフィクスチャ: `tests/fixtures/`。Pillow は絵文字フォント非対応

---

## サブファイル索引

### 進行中 / 計画 (2026-08〜09)
- @./project_ubuntu_workstation_kit_2026_09_17.md — **【09-17 最新】新 Ubuntu PC の作業環境キット `D:\Dev\workstation`**（非公開 `zmarl/workstation` 予定）。オーナーは組立・OS 導入・パスワード・ログインだけ、他は AI が `AGENTS.md` の順で。Claude/ChatGPT アプリは公式 Linux 版あり、CUDA 13.4 の R615 は 26.04 に未提供。罠: root 台本が `~/.local` を root 所有にする／`\| grep -q` の SIGPIPE
- @./project_ai_stack_survey_2026_09_17.md — **【09-17 最新】AI スタック調査レポート（PR #454）+ 改訂 2 と ODR-0044（PR #455）**。**決定: vLLM 主・llama.cpp 予備、Ollama 廃止、外部有料 OCR 全停止、PGroonga、MCP 標準装備（許可一覧・承認）、Phoenix、RAPIDS + cutile-rs、IV スキューマップ試金石。Linux 着手の凍結は継続**。TradingView は公式 MCP あり（オプションなし）。**日経225 IV は 1,050 万行あるが型付き列が全 NULL（rename_map が旧 API 名）→ payload_json から埋め戻し**。罠: gate の expected-head は 40 桁／worktree 初回は `uv run`（sync）／子エージェント Bash 全拒否
- @./project_docs_consolidation_2026_09_16.md — **【09-16 最新】文書集約**。docs/ 一本化、`docs/audits/` を現状レビューの家として新設し外部レビュー 16 本を回収（ODR-0038 の根拠が版管理外だった件を解消）。9/15 総点検 HTML を Markdown 化。罠: `--rewrite-links` は .md のみ／worklog 履歴化で `RES-WORKLOG-ARCHIVE.content_hash` が落ちる／registry は絶対パス禁止／「未分類0件」は .txt を数えていないだけ
- @./feedback_review_placement_markdown_canonical.md — **現状レビューの正本は `docs/audits/` の Markdown。読み物 HTML は正本にしない**（手で維持する実体を 1 つに減らす）
- @./project_overall_design_doc_2026_09_17.md — **【09-17 最新・全体設計書】『Linux ネイティブ・AI ネイティブ・ローカル LLM ネイティブな作り直し』**（`Investment_設計資料/全体設計書_LinuxネイティブAIネイティブ_2026-09-17.html`、19 章・図 19 点）。ODR-0044 と改訂 2 に依拠。**完全刷新（土台は残し上物は 1 から、旧 BFF/画面は Linux で起動しない）**、`app/ web/ ml/ gpu/` の「1 機能 = 1 フォルダ」、計算レーンの型、PL シート 3 層（純利益まで、GPU 不要）、KPI 抽出 3 層、GPU は「別モデルを丸ごと」、論理名 11 種、学習 4 本、音声 2 モード、BitLocker は復号推奨。未回答 11 問は第 17 章
- @./project_linux_rebuild_report_2026_09_15.md — **【09-16 最新・第 4 版が正本】現状総点検と Linux 再構築計画レポート**（`Investment_設計資料/現状総点検とLinux再構築計画_2026-09-15.html`、16 章）。**数日以内に新 PC を組んで即 Ubuntu 移行**（暦の制約は撤回済み）。5070 Ti あり・旧 4TB が運搬手段（旧 PC は M.2 2 本で満杯）・NAS 2TB・PG は 16.15+vector 0.8.6 → 18.6 を `--link` で。**新方向「私の代わりを務める AI ネイティブなアプリ」+ 個人知識ベース（第 9・10 章）**、ODR-0030 は維持推奨。自律度は操作の種類ごとの目盛り。オーナー未回答 13 問は第 14 章
- @./project_debt_triage_2026_09_13.md — **【09-13 最新】技術的負債レポート照合と改善計画（Lane A〜E）**。ODR-0039 の 6 問はオーナー回答済み（全て推奨案、ODR の Accepted 化は未着手）。A-1 は PR #445 で着地。罠: runlog は BOM 付き／Ready 再実行は新 job を積む／finish-pr の削除が uv hardlink で拒否／claim worklog 名は固定
- @./project_product_lanes_2026_09_07.md — **【09-07 製品レーン】macro 索引破損は amcheck XX002（承認待ち修復パック）／Qwen 27B が動かない真因は Tauri の `-lv 4` 欠落／HOLD 80 は 3 群／閉ループは作業しない／**ODR-0039 保有スナップショット草案 (PR #423) はオーナー 6 問回答待ち**
- @./project_harness_freeze_iteration1_2026_09_07.md — **【09-07 凍結第 1 反復】PR #413〜#417 着地**。罠: worktree の Bash 隔離は ExitWorktree(keep)→cd で回避／統合順番待ちは再試行／全体停止中は gh merge→after-merge／新 task は登録前 `scheduler_binding: optional`／write_text は CRLF
- @./project_integrated_assessment_plan_2026_09_07.md — **【09-07 統合計画】5 本の評価を 1 本に統合**。ハーネス 30 日凍結・止める機構 2 つ・製品復帰。次の ODR 番号は 0038（0037 採番済み、0030 重複）。harness_kpi.py は 3 分で返らない
- @./project_unmerged_work_landing_2026_09_06.md — **未統合作業の棚卸しと着地 (09-06〜07)**。PR #366/#299/#380/#352/#351 着地、重複 10 本 close、worktree 60→16。**finish-pr の罠 3 つ**（worktree 内実行拒否／古い needs_attention intent→merge-pr／自分の merge が並行 gate の base を動かす）、**remote branch 削除を `--merged` から機械生成して過剰削除した反省**
- @./project_acquisition_health_2026_09_04.md — **【最初に読む】データ取得系総点検 (09-04/05)**。着地 10 PR（#360〜#381）、本番 alembic 20260813_01 まで適用（未適用 2 本）、**銘柄台帳の 4 か月凍結を解除**（25 社超の滞留は通常ゲートで永久に追いつけない→監督下の追いつき）、全国 IIP をダッシュボード API で 2026-07 まで復旧、資本コスト開示 2,348 行初取得。**判断待ち: PRO Market 186 社・TDnet 抽出停止の依存 4 タスク・未適用移行 2 本**。罠: global stop 中の代替マージ／日付またぎで claim の worklog 名が変わる
- @./project_acquisition_recovery_2026_09_04.md — データ取得復旧 (09-04)。**PR #368 gate green・未マージ**。`/equities/master` bulk が `main.stocks` を上書き／btree 破損 1 件未修復（承認待ち）／マージ全体停止の真因 = proof pack queue の v1/v2 不整合
- @./project_jquants_standard_acquisition_2026_09_04.md — **J-Quants Standard 総点検 (09-04/05)。PR #370/#374/#384 マージ済み**。財務サマリが窓ごと消える真因 2 件（**7203 配当総額 1.24 兆円の桁あふれで 3,607 行の窓が丸ごと失敗**／**400 で endpoint 遮断→314+307 窓 skipped**）を修理し catch-up で 2024-05/2025-02/2025-05/2026-05 を回復。新 endpoint 3 本（決算発表予定日・大株主状況・政策保有）と新列は **Alembic 20260904_01 の本番適用が別承認で未実施**（間に 20260813_02・20260827_01）。**09-28 に信用残高が日次化**。harness 障害時の代替着地手順と worker 起動の罠
- @./project_pr353_gate_handoff_2026_09_05.md — **PR #353 引き継ぎ着地 (09-05、merge 済み)**。罠: `--scope desktop` は非同期 rust pack を足して pending_async にする／publish-pr は claim worklog が Verifying 必須／hook worktree で既存 branch は checkout -B／force push は deny だが publish-pr が exact lease で push／global stop 中は gh merge → after-merge（post-merge 監査 enqueue は失敗、`a57a49f5` の full_audit job なし）／financial panels テスト 45〜105 秒は main でも同じ
- @./project_docs_cleanup_tdnet_kpi_qwen_2026_09_04.md — 文書整理 4.5 (09-04)。PR #366 未マージ。旧 KPI 抽出 3 文書が ODR-0024 と矛盾。推奨 3 点はオーナー回答待ち
- @./project_codex_issue_remediation_plan_2026_09_04.md — Codex 現状報告 (09-04) の裏取り。真因 4 件・誤診 8 件
- @./project_data_gap_repairs_2026_08_31.md — データ欠損修理 6 件 (08-30/31)。未反映 = PR #299（db-fresh 停止）。判断待ち 5 件
- @./feedback_ask_dont_infer_authorization.md — **授権の範囲は推測で埋めず聞く**。稼働状態を変える操作は包括許可があっても確認する
- @./project_data_gap_inventory_279_2026_08_30.md — データ欠損の全数棚卸し (08-30)。起点は run_manifest の active タスク(279)。鮮度判定の前に `disabled_tasks` を引く
- @./project_observability_failure_taxonomy.md — 観測できない失敗の 4 類型と AST 検出の道具
- @./project_jquants_large_holdings_2026_08_29.md — 大量保有 J-Quants 化完了 (PR #275)。worktree 実測は npm ci + .env 必須／未マージ branch を main と誤認する罠
- @./project_weekly_audit_otel_silent_stop_2026_08_30.md — 週次監査 3 連敗で 12 時間マージ不能 (08-30)。真因 otel port 転送、増幅器 = 64MiB/16MiB 非対称
- @./project_clickhouse_retirement_landing_2026_08_28.md — ClickHouse 退役+.wslconfig (PR #260)。ready_async 着地の罠 5 件
- @./project_architecture_review_2026_08_28.md — 設計・構造の総点検 (08-28)。バックアップ未稼働。要判断 3 件（財務ソース序列・コンセンサス・バックアップ先）
- @./project_weekly_audit_guard_perjob_2026_08_27.md — merge guard の per-job 寛容化 (PR #242)。finish-pr は実行元 checkout の guard で評価
- @./project_session_resume_2026_08_24.md — 2026-08-24 再開手順
- @./project_weekly_audit_repair_2026_08_24.md — 週次監査の原因 11 件修理 (08-24)。同型未修理 2 件残。vitest は `--root desktop`
- @./project_harness_redesign_phase0_2026_08_23.md — ハーネス再設計 Phase 0+1 完了、Phase 2 進行中。新 gate の罠: 未分類 path 停止／db/** は async 必須
- @./project_worktree_disposition_completion_2026_08_22.md — worktree 処分完了 93→4 本 (PR #200〜#204)。TaskStop で gate 中断→コンテナ残骸
- @./project_ops_verify_law_tracker_fix_2026_08_21.md — law_tracker 修理 (PR #199)。J-Quants 08-22 再契約で復旧
- @./project_worktree_landing_batch7_2026_08_21.md — EDINET 世代リース/マクロ統計着地 (PR #195/#196)。長い rebase は追加全行の残存を機械照合
- @./project_invariants_mechanism_removal_2026_08_20.md — 不変条件機構の物理削除 (PR #193)
- @./project_stalled_fix_landing_2026_08_20.md — 滞留修正 5 本着地 (PR #189〜#194)。各 lane は `--maxfail=1`
- @./project_valuation_capital_landing_2026_08_17.md — 資本政策+時価評価マイグレーション着地 (PR #188)。新 Alembic revision 追随 3 点
- @./project_scheduler_manual_only_drift_2026_08_17.md — 規制 LLM タガー 15 分毎失敗の解消
- @./project_worktree_inventory_cleanup_2026_08_16.md — worktree 93→32 本 + ODR-0002。publish-pr body-file は worktree 内+gitignore
- @./project_owner_direction_intake_2026_08_10.md — ODR-0001 取込 (PR #166)。正本 docs/OWNER_INTENT.md
- @./ci_new_manifest_task_contracts.md — manifest 新 task 追加時の CI 連鎖: tool_tiers + docs 4区分数 + budget ratchet
- @./activist_monitoring.md — アクティビスト監視、大量保有パーサ修復未対応
- @./project_edinet_extraction_corruption_fix_2026_06.md — EDINET 3系統バグ修正 + 再構築手順
- @./project_db_lane_failclosed_test_repair_2026_07_18.md — fail-closed DB契約化後のテストレーン修理パターン集
- 2026-06〜07 の完了バッチ群は @./project_history_index.md と @./project_known_issues_patterns_2026_08.md へ移設済み

### 方針 / フレームワーク
- @./project_monitoring_gate_phase1_2026_07_04.md — 監視ゲート整備 Phase 1。never-run/SLA sanity/NO_DATA 合成
- @./framework_ssot.md — 21戦略・G1-G5ゲート・レジーム配分・サブセクター4階層
- @./project_framework_docs_overhaul_2026_06.md / @./adr_changes_2026q2.md — 文書総点検・ADR 変更ログ
- @./architecture.md / @./task_classification.md — 境界契約と5層／manifest 4区分
- @./reference_product_policy_adr.md / @./feedback_reit_etf_exclusion.md — ETF/ETN/REIT 恒久除外、入口 filter 必須
- @./s3_deprecation.md / @./jquants_standard_plan.md — S3 廃止（durable は filesystem）／J-Quants Standard エンドポイント
- @./freshness_sla_coverage.md / @./data14_vendor_readiness.md — registry↔SLA↔ingest_runs 整合ゲート／DATA-14 vendor scaffold

### Desktop / BFF
- @./project_design_reform_phase1.md / @./project_design_reform_phase2.md — デザイン改革 P1+P2 着地。P3 申し送り
- @./bff_endpoint_coverage.md / @./desktop_unlinked_pages.md — ※ステール: 51 ルーター全配線・501 ルート／未リンク Pages 13 本
- @./desktop_test_patterns.md — useQuery エラー経路テストパターン
- @./pure_supply_chain_diagram.md / @./company_relationship_graph.md — Supply Chain 図解使い分け／企業相関図ビジョン
- @./project_startup_progressive_redesign.md — 起動即時表示化 + BFF 自動起動。run_hidden_bat は常駐禁止
- @./desktop_launcher_shortcut.md — Desktop起動ショートカット単一化。primary=`Investment Control Tower.lnk`

### Business Model / Supply Chain
- @./business_model_index.md — 全フェーズ索引（Phase 1〜21 完了、available 181/182）

### LLM / 環境
- @./qwen35-local-llm.md / @./perf-tuning-progress.md / @./reference_codex_model_locations.md — Qwen 3.5 ローカル LLM／PC 最適化進捗／Codex モデル ID 所在

### バグ / 仕様
- @./bugs.md — バグ修正の知見
- @./bugs_apply_db_baseline_stamp_production.md — apply_db_baseline の stamp が本番 DSN を汚染 (修正済)。alembic サブプロセスは POSTGRES_DSN を env 固定
- @./bugs_hot_table_ddl_lock_pileup.md — 稼働中テーブルへの DDL がロック行列化。DDL は lock_timeout 必須（env.py が 5s 強制）
- @./bugs_refactor_tooling_footguns.md / @./bugs_module_split_monkeypatch_binding.md — リファクタ道具の罠4件／巨大 py/テスト分割の4大罠
- @./bugs_desktop_undefined_tailwind_tokens.md — Desktop 未定義 Tailwind トークン無色バグ。probe ビルドで検出
- @./bugs_desktop_spacing_eslint_ban.md — **Desktop eslint が大きめ余白直書きを禁止** (gap-4+/p-6+/m-4+/space-y-4+)
- @./reference_sector_market_cap_source.md — **時価総額の正本は mart.vw_daily_valuation (百万円)**。MAX(trade_date)-30日窓
- @./bugs_consensus_collector_starvation.md — コンセンサス収集沈黙停止 (修理済)。no_data=N 毎日同値=打ち切りシグネチャ
- @./bugs_manifest_argparse_order.md — manifest 引数順で37タスク全滅 (修正済)。DONE 0.2秒連続=パース即死
- @./bugs_feature_store_rollback.md — 後続グループ失敗が先行 upsert をロールバック→グループ毎 commit 化
- @./bugs_tdnet_watchdog_escape.md / @./bugs_tdnet_table_json_escape.md / @./bugs_alembic_screening_alert_rules_missing.md / @./bugs_core_instruments_market_reform_stale.md / @./bugs_segment_extractor_6301_komatsu.md — 修正済/仕様
- @./edinet_text_extraction_regex.md / @./feedback_tdnet_segment_heuristics.md / @./session_expired_batch_pattern.md — 会社名 regex ノイズ／短信セグメント表抽出／degraded 伝搬
- @./bugs_sronly_absolute_page_pan.md — sr-only(absolute) がページ横パン (根治)。スクロール枠には relative 併記
- @./bugs_scheduled_tasks_lock_dirty_main.md — scheduled_tasks.lock 誤追跡で merge-pr 停止 (根治)
- @./bugs_posttooluse_hook_stdout_corruption.md — PostToolUse hook が stdout 上書き → ファイルリダイレクト+Read 回避
- @./bugs_vitest_reactquery_rejection.md / @./bugs_vitest_mocked_api_type_strictness.md / @./bugs_happydom_raf_focus.md — desktop error 経路は useQuery をモック／`mockOf()`／happy-dom は rAF focus 不発
- @./bugs_business_model_industry_panel_wiring.md — 業種別BMパネル配線5層手順
- @./reference_utf16_sql_files_unreadable.md — 一部 DDL/YAML は UTF-16 BOM で Read 不可
- @./project_tdnet_feed_empty.md / @./project_embedding_indexer.md / @./serving_repository_proxy_module_split.md — tdnet feed 空問題／embedding indexer／serving 分割時の proxy 注入
- @./bugs_cross_audit_convention_false_positives.md — cross-audit 年度オフバイワン誤検知2件と降格ルール
- @./feedback_sector_page_visualization.md — **可視化の掟**: 面積=時価総額／専門図には「この図の見方」日本語開示必須

### 通知 / 配信
- @./feedback_earnings_notification.md / @./feedback_strategy_notification.md — リッチ通知フォーマット (決算短信 / 中計)

### 運用方針 (応答スタイル / モード)
- @./feedback_scheduler_bulk_registration.md — **Windows タスク登録は後日ユーザー一括**。セッションは register_schedules.ps1 追記まで
- @./feedback_no_extra_billing.md — **サブスク外課金禁止**。billed 機能は提案しない
- @./feedback_natural_language_only.md / @./feedback_auto_mode.md / @./feedback_multiagent_auto.md — 日本語自然言語のみ／auto mode 不使用・bypass permissions のみ／サブエージェント自律活用
- @./feedback_parallel_session_worktree.md / @./feedback_shared_worktree_multiagent_commits.md — **並行セッションは worktree 分離必須**／**git add -A / stash 禁止**
- @./feedback_worktree_cleanup_discipline.md — **作業終了後の worktree/branch 整理を毎回徹底**
- @./feedback_feat_ratio_not_target.md — ODR-0018 の feat25% はオーナー目標ではない
- @./feedback_terminal_commands.md / @./feedback_password_prompt_window.md / @./feedback_full_automation_only.md — コマンド手順は md へ／パスワード/UAC は skill `$scheduler-registration`／ops は scheduler 完全自動前提
- @./feedback_authorization_scope_inference.md — **授権は答えた問いの範囲でしか有効でない**
- @./feedback_rule_protects_something.md — **邪魔な規則は、外す前に「何を守っているか」を探す**（規則を緩めず経路を変える）
- @./feedback_react_refresh_export_separation.md / @./feedback_disclosure_kpi_loader_mapping.md — 非コンポーネント export は `*-utils.ts` 分離／pack confidence は sample + SAMPLE_MAPPINGS

### 完了済みプロジェクト履歴
- @./project_history_index.md — JPX 銘柄マスター / 政策インテリジェンス / 2026-05 改革バッチ群の索引
- @./project_known_issues_patterns_2026_08.md — 2026-07 完了バッチの索引（Phase B スクリーニング・財務可視化・大統合・PG index 修復ほか）
- @./project_design_reform_phase3.md / @./project_decision_round3_2026_07.md — デザイン改革 Phase 3／意思決定改革 Round 3 着地
