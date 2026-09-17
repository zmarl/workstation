---
name: project-reform-program-202607
description: 構造改革プログラム 202607。Stage 1 土台固め + Stage 2 DB 正本化を承認済み、ユーザー4決定（alembic一本化/features再編/PG一本化/着手範囲）確定
metadata: 
  node_type: memory
  type: project
  originSessionId: db4670bd-5918-4c2b-abfa-f006083adc6c
---

# 構造改革プログラム 202607（2026-07-03 プラン承認）

プラン正本: `C:\Users\kazum\.claude\plans\fable5-delightful-beaver.md`。精査は Explore×3 + Plan×3 で実施済み。

**核心診断**: 機能開発は健全だが「改善が本流に合流しない」「正本が分裂」という統治問題が構造問題（巨大ファイル・二重管理）を再生産している。

**ユーザー決定（2026-07-03）**:
1. DB 正本 = alembic 一本化 + db/baseline/ 生成物化（greenfield/foundation 112+52 ファイルは検証後削除・要承認）
2. Desktop = features/ 機能別再編採用（バケツ単位 move-only）
3. 読み取り経路 = **PostgreSQL 即一本化**（ClickHouse 切替棚上げ、dual_shadow/clickhouse_primary 分岐削除）
4. 今回範囲 = Stage 1（統合）+ Stage 2（DB 正本化）。Stage 3 BFF / Stage 4 Desktop は次回以降

**裏取り済み事実（過去メモリのステール訂正）**:
- 現ブランチは origin/main +66/−1 のみ（local main は 4/7 停止の古参照、固有 8 コミットは rescue タグ保全済み）
- alembic は単一 head（20260613_03、single-head CI ゲート配線済み）。「4 head」は誤り
- BFF「181 未配線」は解消済み（51 ルーター全配線、501 ルート）
- guardrails ブランチとの差分は P1/P2/P3 の 3 コミットのみ（29b07af2/a4b13529/df0459c7）。P3 merge のコンフリクトは未コミット tools/api 23 ファイルに局在

**進捗 (2026-07-04 時点)**:
- S1-0/S1-1/S1-4/S1-5/S2-1 完了。S1-2 は**ユーザー決定で不要化**（guardrails ブランチ破棄、ゲートは負債返済バッチが再着地）
- S1-3 進行中: PR #13 (feat/reform-phases-batch → main)。凍結既存失敗3件根治（IFRS concept 列挙 + テスト日付 rot）。CI 4系統の根本修正投入済み: alembic 依存宣言 / rust-parity maturin (uv venv に pip 無し) / tool count 297 / **package-lock は npm@10 で生成必須**（npm 11 と npm 10 で oxc wasm デップの ideal tree が異なる → `npx npm@10 install --package-lock-only`）
- rust-parity の実テスト2件修正（PATH テストの drive-letter が Linux で ':' split 事故 / boj revive テストが実 DSN 到達）
- S2-1 完了: mergepoint ラチェット（scripts/alembic_merge_baseline.txt 11件凍結 + check 拡張 + run_check_suite/pre-commit/CLAUDE.md/skill 配線）
- 掃除完了: worktree 2本+一時ファイル+旧ブランチ12本削除（rescue タグ保全済み）。残 worktree は phase6 のみ
- 承認済み: 承認③ CI 全緑で自動マージ / 承認⑤ 掃除。承認②は不要化（main==origin/main 確認済み）
- REVIVE-01..06（旧ブランチ未回収機能6件）を reform-program Track D に登録済み
- **注意: main tree は別セッションが feat/functional-uplift-p1 で使用中**。Stage 2 残り (S2-2〜) はマージ後に専用 worktree で

**並行トラック: 負債返済バッチ (別セッション、2026-07-03 承認)**: ゲート強化 + デッドコード削除 + T20 burn-down（プラン: `proud-kindling-yeti.md`）。guardrails ブランチはユーザー決定で**破棄**（参照のみ）、ゲート3本 (`scripts/check_file_size_budget.py` / `check_tools_dependency_policy.py` / `check_t20_ratchet.py`) + baseline 3種 + ADR コピーを現行 tree に untracked で追加済み。pyproject.toml の T20 stale 免除 2 件 (shared/cli.py / tools/notion) 削除も同セッションの編集。BFF endpoint 削除はこの memory の「181 未配線解消済み」を受けて取り下げ、DB 系削除は Stage 2 に譲る。baseline 最終確定は他セッションの編集静止後に再生成予定。

**S2-2 実測の重大発見 (2026-07-04)**: alembic 履歴は自己完結せず、空DB再生は 20260415_03 で停止（pre-alembic 基盤前提）。missing_in_alembic 4,982（tables 1,000）、foundation も不完全（apply error 20、production_only 4,125）→ **完全なスキーマ定義は本番DBのみ**。S2-3 の baseline 生成元を「alembic 再生」から「本番 pg_dump --schema-only」へ変更（alembic 一本化の決定は不変、以降の変更入口として機能させ、ゲートは「baseline+新revision==本番」の継続検証）。parity checker: scripts/check_ddl_baseline_parity.py（feat/reform-stage2-db ブランチ、レポート docs/worklogs/20260704-ddl-parity-report.md）

**CI 緑化の知見 (2026-07-04)**: CI Test&Lint は 2026-05 以降 alembic 収集エラーの陰で DB/Ollama/ffmpeg 依存 44 テストの失敗が隠れていた → `requires_local_infra` マーカーで隔離（ローカルは従来通り実行、CI は -m 除外、CI-HERMETIC-01 として台帳登録、S2-3 後に解除可能）。visual baseline は workflow_dispatch update_snapshots=true → artifact linux-baseline-png をコミットする方式。

**着地 (2026-07-04)**:
- **Stage 1 = PR #13 マージ済** (main=3922de63、115 コミット、CI 全6系統緑)。道中根治: IFRS BS ラベル / .bat \r 破損 8 本 / **F.4 Rust カーネル重み乖離**（Python 入れ子式の線形展開 tsy.3175/fcf.31/dps.0975/streak.135/div.10/payout.04 に再同期、中間 round(4) 撤去必須）/ rust-parity 集計ゲート最低 20 比較
- **Stage 2 前半 = PR #14 マージ済** (main=c9b1a06b)。db/baseline/ 22 ファイル（本番 pg_dump 正本、決定的生成、本番とカタログ完全一致実証）+ manifest チェッカ + --leg baseline 恒久ゲート + bootstrap 切替（baseline 適用 + alembic stamp head）。ライブラリ分割で 800 行予算対応（check_ddl_baseline_parity + ddl_baseline_parity_lib）
- **残 (承認待ち)**: S2-4 旧 DDL 2 系統削除（承認④）/ S2-5 生 SQL 49 本アーカイブ + authority map 同期（承認⑥）/ 本番の無効インデックス 3 本 DROP。worktree D:/Dev/Investment-ci-fix (feat/reform-stage2-db) が main 追従済みで待機
- 次バッチ: Stage 3 (BFF 再設計 + PG 読取一本化) / Stage 4 (Desktop features/ 再編) / CI-HERMETIC-01 (44 テスト復帰、S2-3 済で着手可能)

**S2-4/S2-5 着地 (2026-07-04)**:
- **工程1（S2-4 本丸）= push 済み** (`feat/reform-stage2-db` `1dd715fb..8efa17d1`、6コミット)。旧DDL 2系統 `db/greenfield_postgres`(91)+`db/foundation_postgres`(46) 削除。検証: フル CI相当 pytest **11047 passed / 0 failed**、ruff/file_size_budget/manifest/`--leg baseline` 全 ok。push go は team-lead 明示（案1=6コミット全push）
- **致命バグ発見・修正**: revision 4本 (20260517_01 / 20260424_05 / 20260424_06 / 20260506_02) が upgrade() 実行時に旧DDL を read_text+sha256 検証して適用していた → 削除で `alembic upgrade head` が壊れる罠。pinned SQL 5本を `db/alembic/versions/_pinned_sql/` へ移し意味保存で自己完結化。将来ゲート候補「revision は db/alembic/versions/ 外を読まない」
- greenfield は duckdb 互換テストDDLキットを兼ねていた（runtime_schema.py が ~40 テスト bootstrap に使用、baseline pg_dump は duckdb 非互換）→ **案A採用**: curated 30本を `tests/fixtures/ddl/` へ移設（README「正本ではない」明記 + 各ファイル1行コメント、TEST-DDL-DRIFT-01 台帳登録済み）
- financial_unifier `--include-marts` ランタイムDDL適用は廃止（deprecation + `mart.vw_financials_unified` 存在アサーション + `alembic upgrade head` 案内）。他ランタイム生SQL消費者は RUNTIME-DDL-RETIRE-01 として Stage 3 db_init DDL全廃と同枠
- 本番無効インデックス 3 本 DROP 済み / authority map 19 スキーマ同期済み (`1dd715fb`)
- 正本定義統一済み: CLAUDE.md「DDL canonical source」= alembic 唯一入口 + db/baseline 機械生成正本 / skill `ddl-migration-scaffold` 新ワークフロー（alembic revision → upgrade head → generate_db_baseline → manifest チェック、greenfield/foundation 二重追加撤去）
- **残（引き継ぎ書 `docs/worklogs/20260704-stage2-closeout-handoff.md` に実装者向け粒度）**: 工程2 = `db/greenfield_duckdb`→`db/baseline/duckdb` + `db/foundation_clickhouse`→`db/baseline/clickhouse`（消費者4本追随）/ 工程3 = `db/alembic_revisions` 48本の部分アーカイブ（消費者ゼロのみ mv + INDEX.yml、稼働消費者ありは残置 + RUNTIME-DDL-RETIRE-01、hybrid governance 両走査追随）。次エージェント担当

**Stage 2 完了 (2026-07-04)**: PR #15 マージ (main=18082b05、CI 全9チェック緑)。旧 DDL 2 系統削除・正本一本化（alembic 唯一入口 + db/baseline 本番由来生成物）が本流で確定。生 SQL 39/48 アーカイブ、duckdb/clickhouse は db/baseline/ 配下へ。繰越: RUNTIME-DDL-RETIRE-01（ランタイム生SQL消費者 9 本の存在アサーション化、Stage 3 db_init 全廃と同枠）/ BASELINE-REGEN-01（本番 head=20260704_02 の並行セッション作業マージ後に baseline 再生成）/ CI-HERMETIC-01 / TEST-DDL-DRIFT-01。**次バッチ = Stage 3（BFF 再設計 + PG 読取一本化 + shared/db 統合 + LLM 入口統一）or Stage 4（Desktop features/ 再編）**。worktree D:/Dev/Investment-ci-fix は main 追従済みで再利用可

**Stage 3a 完了 (2026-07-04)**: PR #16 マージ (main=f8d8a636、CI 全9緑)。shared/db パッケージ統合（旧5ファイルは sys.modules シム、同一性テスト付き）/ DDL-in-code 全廃（bootstrap 4系統21テーブル→存在アサーション+alembic案内）/ RUNTIME-DDL-RETIRE-01 done / LLM 入口一本化（llm_gateway パッケージ化+Ollama内部プロバイダ化、直import 11消費者移行、single-entry ラチェット baseline 0）。**Stage 3b（BFF大再編+serving_read_mode PG一本化）と Stage 4（Desktop features/）は並行セッション feat/functional-uplift-p1（Desktop 554ファイル+BFF app/registry/_market 接触）のマージ待ち**。独立残: CI-HERMETIC-01（CI に PG service+baseline 導入で DB 依存テスト復帰、S2-3 済で着手可）/ BASELINE-REGEN-01（uplift マージ後）

**CI-HERMETIC-01 完了 (2026-07-04)**: PR #17 マージ (main=779bd720)。CI test ジョブに pgvector/pgvector:pg16 service + db/baseline 適用 + `alembic stamp head --purge`（並行ドリフト回避）。隔離 44 テスト中 38 を `requires_db` で CI 復帰、残 6 は真の local-only（ffmpeg 2 / 実 Ollama 4）。適用ロジックは apply_sql_files_multipass に共通化（bootstrap/parity/CI 3者共有、CLI: scripts/apply_db_baseline.py）。教訓: stock postgres:16 に vector 拡張なし→pgvector イメージ必須。27/38 は完全 mock で将来 no-DB 降格可。
**セッション総括 (2026-07-03〜05)**: PR #13/#14/#15/#16/#17 の 5 本を CI 全緑でマージ。Stage 1 + Stage 2 + Stage 3a + CI-HERMETIC-01 完了。**残: Stage 3b（BFF 大再編 + serving_read_mode PG 一本化）/ Stage 4（Desktop features/ 再編）/ BASELINE-REGEN-01 — すべて並行セッション feat/functional-uplift-p1 のマージ待ち**。worktree D:/Dev/Investment-ci-fix は再利用可（不要になったら `git worktree remove`）

**2026-07-05 着地分**: PR #18（functional uplift 53+コミット、budget 超過6本復帰・visual 10枚再生成・BASELINE-REGEN-01 消化）/ PR #19（policy phase6 最終、reg_kpi は alembic revision 化・tool count 297→298・tier 3件登録）/ PR #20（reg_kpi 本番適用後の baseline 再生成）マージ。**長期滞留ブランチ = ゼロ達成**。本番=repo head=baseline=stamp の4者一致（head 20260523_01_reg_kpi_snapshot ※ID は日付逆順だが直列）。**Stage 3b は保留中**: 別セッションが refactor/structural-cleanup-202607（worktree D:/Dev/Investment-refactor）で BFF 再編・デッドコード削除等 Stage 3b 相当を活発に実施中のため衝突回避で待機。着地後に残スコープ（read_mode PG 一本化 / extensions 移送 / company 84 GET 分割等）を再評価。**解決済 (2026-07-05)**: local main 直コミット2本は PR #21 で載せ替えマージ完了（main=1e663bb8、typed scope 510・typegen 再生成込み）。メインツリーは main 最新に整合、直コミット問題ゼロ

**Stage 3b 着地経緯 (2026-07-05〜09)**: PR #24（Phase A read_mode 撤去 + Phase B シム9本削除、feat/reform-stage3b）を作成したが、**並行セッションの PR #23 (structural-cleanup-p2) が Phase B 相当（シム削除）+ Phase C 相当（B9: serving/_decision・_market のサブパッケージ分割）を先に main へマージ**し 171 ファイル conflict 化 → PR #24 クローズ。main 新レイアウト上に Phase A のみ再適用 = **PR #27（feat/serving-pg-only、worktree D:/Dev/Investment-stage3b2）**。再適用手法: B9 未接触ファイル（serving 15 + テスト 8 + 露出面/docs/CLAUDE.md/skills）は `git diff a35d2d4e origin/main -- <f>` で main 側変更が import 行のみと検証して旧ブランチから checkout 流用、market/ サブパッケージ 9 ファイル + serving_repository.py + テスト 7 本は新規移行。**副産物: main 既存故障の修理** — desktop-ops-ui-contract ゲートが PR #22 の api-client ドメイン分割に未追随で main 上 red（PR #24 の manifest-contracts fail の真因）→ マーカー参照先を lib/api/catalog.ts へ更新。検証: フル pytest 11,644 green / openapi・d.ts diff ゼロ / 全ゲート PASS。**PR #27 マージ済み (2026-07-09, main=dea334be)** — D-3 read_mode PG 一本化が本流確定。**教訓: 並行セッションが activeな間は同領域の PR を寝かせない（4日放置で丸ごと供養になった）。再適用時は「旧fold流用の可否 = main側diffがimport行のみか」で機械判定できる**。**追加教訓: main の push 時 CI は E2E smoke のみでフル gate は PR 時しか回らない → 複数 PR が近接マージされると相互作用の赤が main に潜伏し、次の PR の merge ref で顕在化する**（PR #25/#26 で実際に発生: consensus テスト赤 / tool_tiers 2件欠落 / manifest counts 336→338 drift / budget 超過2件 → PR #27 で継承修理。consensus 修正は別セッションの local main 未push コミット 1f018639 を cherry-pick、同一 patch-id なので相手 push 時に自動去重）。**Stage 3d = PR #28 マージ済み (2026-07-09, main=a0d10044)**: routers/company.py 4,091行・89ルート → routers/company/ 19 サブモジュール（openapi バイト一致・EndpointSpec 無変更・全ファイル800行以下・monkeypatch 32名×2+setattr 9 を定義モジュールへ再指向）。**A-3 = done**（roadmap 更新済み、worklog: docs/worklogs/20260709-stage3b-serving-pg-only-and-company-router-split.md）。極小ルーター統合は見送り決定。worktree stage3b/stage3b2 とブランチは削除済み。**残る Stage = A-4 Stage 4（Desktop features/ 再編。ただし PR #22/#23 で components ドメイン別整理・巨大ページ/クライアント分解が進み、残る対象は pages/ 約70本フラットのみ — 価値再評価してから）と A-5/A-6**

**A-4 + A-5 完了 (2026-07-09〜11)**: Stage 4 仕上げ = PR #29（desktop CI 配線: eslint + vitest 2,388/design-guard + typegen drift ゲート、desktop-test は TZ=Asia/Tokyo 必須）/ PR #30（pages 19 本 move-only 整理 + **D-2 features/ 移行の正式撤回**）/ PR #31 Dashboard 2,080→222 / PR #32 LatestEarnings 1,682→849（テスト無改変原則で解体、CompanySnapshot 第2段・FrameworkView は PR #23 が先取り済みだった）。A-5 = PR #33 三者照合ゲート `check_manifest_scheduler_parity`（4ノード閉包、bat_taskid_mismatch が本命）/ PR #34 .bat 340 本を `generate_task_wrappers` で manifest 駆動生成化（rename/delete ゼロ = Task Scheduler 再登録不要を機械証明、wrapper_bat/wrapper_managed フィールド新設）/ PR #35 manifest を `scripts/manifest/*.yaml`（source_type 軸 14+meta+misc）に分割し `build_run_manifest` で生成物コミット（消費者無変更・safe_load 完全等価）。**タスク追加の新フロー: ドメイン yaml 追記 → build_run_manifest --write → generate_task_wrappers --write**。道中の知見: PR #30 で pages 移動時に desktop-ops-ui-contract ゲートのパス追随が必要だった / GitHub hosted runner 供給枯渇で run が 15 分 cancel される事象あり（rerun で回復）。申し送り: knip block 化（台帳 B' 判断後）/ graph 系解体（BusinessModelGraphV2Panel・CompanyPL）/ register 未登録 weekly 2 タスクの judgment / register_schedules.ps1 駆動化再評価 / desktop-test の required checks 追加は GitHub 設定側。**残 = A-6（backlog: tools 近縁ペア統廃合 + tests 二重ツリー一本化 + alembic squash 208 rev）のみ**

**A-6 完了 = Track A 全ステージ完了 (2026-07-11)**: PR #38（tests 二重ツリー一本化: tests/unit 60 + tests/market_data 155 を tests/tools ミラーへ move-only、collect 12,654 で欠損ゼロ、diet_bills の重複は「両立設計」と判明し test_parser_live_211.py へ改名共存、`check_test_tree_layout` ゲート CI 配線）+ PR #40（近縁ペア 6 クラスタ実測 = **真の統合候補ゼロ**を ADR 化、死にシム daily_review_agent / earnings_quality_scorer 除去で tool count 298、**alembic squash は見送り決定**（baseline+stamp head 方式で目的達成済み、ADR: docs/decisions/20260711-a6-tools-consolidation-and-alembic-squash.md）。同日 PR #36（滞留 12 コミットの landing、company.py 分割・CompanySnapshot 分割・manifest 生成化との 3 系統コンフリクトを新構造側へ再表現して解消）と PR #39（P0/P1 修理バッチ、worklog: docs/worklogs/20260711-p0p1-repair-batch.md）も着地。**EDINET-FIX Phase 2-3 は 2026-06-19 実施済みだったことを実 DB で確認**（86,224 行一致・bogus 0・7203 NI 4.765兆円）し台帳 closeout — 破壊的再抽出は不要だった。残 follow-up: thesis_tags 書き込み経路 / VFU-PERF-01 実体化（index 無効を実測済み）/ EARN-EVAL-BOUNDARY-01 / EQ-PROGRESS-SEASONALITY-01（後2者は Codex 決算再設計の着地待ち）。

**Why:** 複数セッション並行のため、分担と決定事項の正本をここに固定。
**How to apply（新セッションの再開手順、2026-07-05 更新）:**
1. まず `git worktree list` と `refactor/structural-cleanup-202607`（worktree D:/Dev/Investment-refactor、別セッション）の着地状況を確認。**着地済みなら Stage 3b の残スコープを再評価して着手**（read_mode PG 一本化 / serving_repository_extensions 104関数移送 / routers/company 84 GET 分割 / 極小ルーター11本統合 — refactor セッションが先取りした分を差し引く）。未着地なら衝突回避で待機し、独立課題（Track B: T1 EDINET-FIX Phase 2-3(要承認・破壊的) / T3 / REVIVE-01..06）へ
2. 実行パターンは確立済み: main から worktree + ブランチ → 実装エージェント委任（編集禁止ファイルを明示）→ フル検証（ruff + pytest -m "not audit and not db and not e2e and not llm and not slow and not requires_local_infra" + 必要なら desktop tsc/vitest）→ push → PR → gh pr checks 監視（Monitor）→ 全緑でマージ → main 追従
3. DDL 変更時: alembic revision（heads 1本厳守）→ 本番適用 → generate_db_baseline.py → check_db_baseline_manifest ok。ドキュメントゲート: tool count / manifest counts / tool_tiers / typed scope(510) / typegen / file size budget は変更のたび追随
4. 計画正本 = docs/roadmap/reform-program-202607.md、状態 = docs/backlog/次アクション管理台帳.md。プラン: `C:\Users\kazum\.claude\plans\fable5-delightful-beaver.md`
関連: [[project-structure-guardrails-roadmap]] [[project_repo_update_roadmap_202606]]
