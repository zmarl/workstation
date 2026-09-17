# 技術的負債レポート（2026-09-08）の現状照合と改善計画

## Context

- 入力: `技術的負債レポート_20260908.md`（別セッションの調査）。本セッションで 2026-09-13 の main（`c0b06f632`）と照合し、オーナーと壁打ちして方針を確定した。
- 制約: ODR-0038 ハーネス凍結（09-08〜10-07）。`scripts/dev`・`scripts/ci`・`tests/scripts`・`.agents`・`.claude`・`docs/runbooks` は「赤→緑の 1 日修正」と「削除・降格・通知化」だけ。新しい検査・台帳・queue・hook・ODR は追加しない。人手境界（Scheduler 登録・実通知の設定変更・共有 DB 適用）は明示承認の範囲でだけ実行。
- 既存計画との関係: `data/runtime/plans/20260905-repository-refactoring-master-plan.md`（Codex のデータ・決算レーン）と `20260904-codex-issue-remediation-plan.md`（Wave 0〜4）に帰属する項目は重複起票せず、本計画から参照する。
- 運用: 1 セッション = 1 タスク = 1 claimed worktree = 1 worklog。同時 writer 3 本、DDL は 1 本。各 PR は `worklog-starter` → 実装 → focused test → `pr-ready-gate`。

## 1. 照合結果（要約）

### 変化があったもの（3 件）
- EDINET 反映の有効化ファイル必須: PR #439（09-12）で activation 無しでも進む分岐が入った。ただし実機反映は未完で、`financial-unifier-daily` / `daily-valuation-refresh-daily` / `edinet-normalized-facts-refresh-daily` は 09-12 まで exit 66（上流の新しい成功なし）で継続。
- 再取得ワーカー: SQL 層は `shared/tooling/repository/reingest_queue.py` に共通化済み。ループ・通知部分は 21 本重複のまま。**レポートの「スケジュール実行は boj だけ」は誤り**（`ingest-recover-*-daily` 20 本登録済み）。
- バックアップ: PR #441 で保存先を NAS UNC 必須化（ローカル代替なし）。リポジトリ側の復旧 5 タスクは runlog 0 件・WAL spool 空（07-25 から）。オーナーは NAS 側のフォルダコピーで取得中（本セッションで確認）。

### レポート後に悪化・新たに判明
- worklog `Verifying` 163 → 183 件。
- ODR-0038 指標（09-08 以降）: feat 比率 1.3%（合格線 15%）、ハーネス path 純増 +676 行（合格線: 週ごと純減）、`tests/scripts` 70,970 行（合格線 40,000）。D8 の毎週月曜報告の痕跡なし。
- `thesis-monitor-daily`: 9 月全滅の真因は `decision.thesis_health_snapshots` に無い `detail` 列を読み書きする SQL（`tools/decision_support/thesis_monitor/repository.py:75-91, 174`）。HOLD 解除（09-07）で顕在化。
- `earnings-schedule-daily`: 08-12 から失敗の真因は JPX の固定 URL `kessan.xlsx` が 404。現在は `kessan07_0904.xlsx` / `kessan08_0904.xlsx` のように月別ファイル名（`jpx_source.py:18, 261`）。
- `NightlyRegressionPytest`: **未登録ではなく登録済み**で毎晩 02:30 に起動。単一プロセス pytest（`tools/quality/nightly_regression/main.py:65-70, 129`）が 3 時間の上限で強制終了（result 267014）され、Discord 要約は一度も届いていない。
- `skip-tracker-daily`: **4 か月停止ではなく毎日起動**。ただし `scripts/run_skip_tracker_daily.bat` が手書き（03-29）で `track` だけを直接実行し、manifest 定義（`daily-pack --notify --max-days 120`）と乖離、runlog も残さない。
- 日米 10 年金利: US 10Y は `raw.rates_metrics_raw`（`series_key='rates.us.10y_yield'`）に毎日入っている。JP は `main.rates_daily.jgb_10y_yield`。読み手 `tools/quality/routine_runner/collectors.py:254-276` の候補名が両方とも合っていない。
- 「前日未成功タスク」通知: `scheduler-audit-daily` は毎日 227 件の失敗を `data/routine_logs/scheduler_audit_report.md` に書くが Discord へは何も送らない（`_run_scheduler_audit`, `tools/quality/routine_runner/main.py:1376`）。
- 週末（09-12, 13）は平日タスクが動かないだけで、thesis / earnings-schedule の「09-12 以降起動なし」は劣化ではない。

### 未着手（レポートどおり）
- 第 1 部: pool.py `%t` 正規表現（`shared/db/pool.py:185`、`'%tdnet%'` 2 か所・`'%theme%'` 1 か所現存）、screener else 分岐（`daily_screener/main.py:100`、現在は潜在）、thesis しきい値名（`health_checker.py:133-135` vs `shared/config.py:540-542`、実効 50% ≠ 設計 30%）、reingest note の型混在、`information_schema.tables` 100 か所。
- 第 2 部: serving 5 関数の空返し（`tools/api/decision_api/serving/_strategy_analytics.py:169-389`）、空返し契約テスト 10 件、ruff BLE/TRY/S 無し・型チェッカ無し、`shared/control_plane_audit.py` の DEBUG 握りつぶし 5 関数、`depends_on` 111 件が実行時無効（`run_tool.ps1` 未参照）。
- 第 3〜4 部: HOLD 74 本、CI 死参照 14 件 + `scripts/check_desktop_release_contract.py:337-346` の自己参照、file size 違反 107 件、timeout 監査の 1〜720 分上書き（`scripts/manifest/meta.yaml:2-14`）、easyocr/torch/torchvision/anthropic が main 依存・uv.lock 08-29・dependabot/pip-audit 無し、未読設定（`tdnet_ocr_fail_open` 等）、リスク上限二重化（compliance 8% vs sizing 20%）、Notion view 参照 4+8+6、`_query_clickhouse` 未定義参照（`serving/_portfolio.py:93`）、金額リテラル 79 件、Desktop 円整形 10 実装超（兆分岐なし: `business-model-builder.ts:145`, `partner-display-utils.ts:120`, `HeatMap.tsx:40`）、TradingView 3 点、argparse 私有 API 橋渡し、knip は no-exit-code。

### レポートの訂正
- Desktop `& unknown` 交差型: 現在 0 件。品質ゲート runbook のスクリプト 8 本: 全て実在。再取得ワーカー: 20 本がスケジュール実行。円整形: 3 実装ではなく 10 超。

### 中途半端なもの
- open PR 4 本: #410（PRO Market 186 社除外漏れ、98 行、MERGEABLE、main から 160 commit 遅れ）、#411（docs wave1）、#230（08-25 Desktop テスト競合修正 73 行）、#438（Codex、+17,774 行、09-10 更新）。
- worktree 30 本: main 以外 29 本。HEAD が main に取り込み済み 5 本（qwen38-initial / framework-owner-dialogue / macro-statistics-data-recovery / qwen38-deep / tdnet-conflict-completion-repair。うち 3 本はオーナー「稼働不明・触らない」の討議用）、proof-pack-async-v2 detached 8 本、2026-08 起点の未マージ 4 本（ir-quant / book-knowledge / desktop-app-test-isolation / desktop-graceful-update）、Codex 09-08〜12 の進行中 6 本、Claude 09-07 の 4 本（うち 2 本は PRO Market）。
- Codex remediation plan 未完: Wave 0-A、1-C、2-F〜L、3-M/N/O、4-P/Q。master plan: Qwen 実分析は出力形式エラーで未完。

## 2. 壁打ちで確定した決定（2026-09-13）

1. 優先軸: 止血 → 気づける化 → 構造。
2. ODR-0039（保有スナップショット）6 問: 鮮度窓 5 営業日／時価は J-Quants 終値から導出／口座は `main` 1 つ／`core.position_state_daily` は導出 view に寄せて退役／証券会社 CSV は触らず手入力＋宣言／最初の束は「出口監視・PF リスク・VaR」。→ ODR を Accepted に更新する。
3. バックアップ: NAS 側のフォルダコピーで取得中。稼働中 DB フォルダのコピーは整合しない恐れがあるため、復元テストを計画に含める。
4. 片付け: PR #410 マージ、古い PR 3 本の処遇提案、worktree 30 本の棚卸し表、worklog Verifying の機械整理（ODR-0038 D5 は機械更新を 10/7 以降と定めるが、一回限りの docs PR として実施。了解済み）。
5. 到達しない 3 領域（blog_scrapers / converters / benchmarks）: 今回は触れない。TradingView と Rust 橋: 現状のまま凍結（再開時に修正）。
6. 見送り銘柄追跡: 定義どおりの一式（通知あり）に戻す。
7. DecisionCase: 9/14 期限の「本番 DB 適用状態の読み取り確認と承認パック作成」を本計画に含める（適用は別承認）。

## 3. 改善計画

### Lane A 止血（製品側・判断不要・各 PR は数十行）

**A-1 個別バグ束（1 PR、worktree 1 本）** コストカード: 触るファイル 8／追加テスト 6／新機構なし／worklog 1 日
- `tools/decision_support/thesis_monitor/repository.py`: `detail` 列を `alerts`（jsonb）へ。INSERT/UPSERT（:75-91）と SELECT（:174）の両方。既存の `alerts jsonb` の意味（警告一覧）と snapshot JSON の内容差を確認し、必要なら `hypotheses_*`/`staleness_days` 列へ分解して書く。
- `tools/decision_support/thesis_monitor/health_checker.py:133-135`: getattr 名を `thesis_staleness_warning_days` / `thesis_staleness_critical_days` / `thesis_pre_invalidation_threshold` に修正（実効しきい値 50% → 設計 30%）。残る不一致 6 件（`serving_*`）は ClickHouse 残骸なので Lane E-6 へ。
- `shared/db/pool.py:185` `_escape_percent`: 正規表現をやめ、`?` で分割 → 各片の `%` を全て `%%` → `%s` で結合、に置き換える。手書き `%%` と `%(name)s` が app SQL に無いことを grep で確認し、`'%tdnet%'` / `'%theme%'` / `(persons?|people)$` / `%%` 混在の 4 ケースを `tests/shared/db/` に固定。
- `tools/decision_support/daily_screener/main.py:100`: else 分岐で `composite_score` 不在時に生成する（`.get` 統一）。
- `tools/quality/routine_runner/collectors.py:254-276`: 候補に `main.rates_daily.jgb_10y_yield` と `raw.rates_metrics_raw`（series_key `rates.us.10y_yield`、`metric_value`）を追加。`_collect_series_change` に series_key 指定の経路を足す。
- `tools/notifications/earnings_schedule/jpx_source.py`: 固定 URL を廃止し、`https://www.jpx.co.jp/listing/event-schedules/financial-announcement/index.html` から `kessan\d\d_\d{4}\.xlsx` を全て集めて取り込む（月別ファイルが複数あるため当月・翌月を両方読む）。取得失敗時の例外メッセージに URL を含める。
- `tools/api/decision_api/serving/_portfolio.py:93`: 未定義 `_query_clickhouse` の経路を削除し、`clickhouse_primary` モードでは `RepositoryUnavailableError` を上げる。
- `shared/control_plane_audit.py` の握りつぶし 5 関数（:155, :229, :334, :419, :470）: `logger.debug` → `logger.warning`（挙動は変えない）。
- 受入: 翌営業日の `thesis-monitor-daily`・`earnings-schedule-daily` runlog が success。日次レビューの JP/US 10Y 観測に値が入る。

**A-2 Desktop 円整形の兆分岐（1 PR）** コストカード: 触るファイル 4／追加テスト 3／新機構なし／worklog 0.5 日
- `desktop/src/components/company/business-model-builder.ts:145`、`partner-display-utils.ts:120`、`desktop/src/components/HeatMap.tsx:40` を、兆分岐を持つ既存実装（`lib/earnings-financial-change-format.ts:125`）へ寄せる。10 実装の一本化は Lane E-5。
- 受入: 5 兆円が「5.0兆円」と出る Vitest。ローカル build + 該当画面の実表示確認（ODR-0038 で許可済み）。

**A-3 見送り銘柄追跡のラッパー正常化（1 PR）** コストカード: 触るファイル 2／追加テスト 0／新機構なし／worklog 0.5 日
- `scripts/generate_task_wrappers.py` が `scheduler_binding: optional` を対象にするか確認し、`scripts/run_skip_tracker_daily.bat` を生成物（`run_tool.ps1 -TaskId skip-tracker-daily`）へ置換。bat 名は同じなので Scheduler 再登録は不要。
- 受入: 翌営業日 03:27 の runlog が存在し、`daily-pack` の 4 工程が記録される。通知は Discord の既存チャンネル（承認済み）。

**A-4 再取得キュー note の型統一（1 PR、market_data 横断）** コストカード: 触るファイル 約 18／追加テスト 4／新機構なし／worklog 1 日
- `shared/tooling/repository/reingest_queue.py:53` `compose_worker_note` を JSON 追記（`{"prefix":..., "history":[...]}`）に変え、`infer_reason_scope`（:26）を JSON 優先・平文は後方互換で受ける形に。書き手 `boj_tracker/ingest.py:488, 692, 1031, 2513, 2539` と読み手 `macro_tracker/ingest.py:1159` ほか 12 種を同時に切替。
- 受入: 失敗 → 再投入の往復で範囲が全範囲へ広がらないことをテストで固定。

**A-5 PR #410 の着地** 既存 claim `claude/pro-market-policy-label-29e04dd359` で main へ rebase → focused test → `pr-ready-gate` → `finish-pr`（main checkout から）。

### Lane B 気づける化（既存機構の修理・通知化。凍結中でも許される範囲）

**B-1 夜間回帰を完走させる（1 PR）** コストカード: 触るファイル 2／追加テスト 2／新機構なし／worklog 0.5 日
- `tools/quality/nightly_regression/main.py`: `pytest_command` に `-n <workers>`（`scripts/dev/run_pytest_lane.py:38-76` と同じ環境変数上限・xdist 検出を再利用）。`capture_output` をやめ log ファイルへ逐次書き出し。`subprocess.run(timeout=160 分)` で Scheduler の 3 時間より先に打ち切り、「中断」要約を送る。
- 受入: 翌朝 Discord に `[夜間回帰 ...]` が届く。ODR-0038 の「連続緑日数」計測が始まる。

**B-2 前日未成功タスクの Discord 要約（1 PR）** コストカード: 触るファイル 3／追加テスト 3／新機構なし（既存監査への送信追加）／worklog 1 日
- `tools/quality/routine_runner/main.py:1376` `_run_scheduler_audit` に `--notify-discord` を追加。内容: 窓内で 1 度も成功しなかった task_id（failure_class 別: `data_quality`=異常検出の非ゼロ終了／`runtime_error`=プログラム故障／`timeout`／`external_dependency`）、missing expected、失敗件数。`shared/notifications/delivery.py:144 deliver_text` を quality webhook で使う。`scripts/manifest/quality_audit.yaml:88` の args に追加。
- 監査本体が 15 分制限のうち 13 分 50 秒かかっている点は、runlog 走査の範囲（24h に絞る）を先に確認。
- 受入: 翌日 21:25 以降に Discord へ 1 通。thesis / earnings-schedule / financial chain がそこに現れる。

**B-3 ODR-0038 D8 の週次数値** 本セッション末に `docs/OWNER_INTENT.md` §3 の計算式で今週分を出し、オーナーへ 1 行報告（09-08 以降: feat 1/78、ハーネス純増 +676、`tests/scripts` 70,970、open PR 4）。コードは書かない。悪化の扱いは 10/7 判定に委ねる。

**B-4 NAS コピーの復元テスト（オーナー入力が要る）**
- 必要な入力: NAS ジョブのコピー元フォルダ（Docker volume か `D:\...` か）と頻度。
- 手順: 直近コピーを隔離 PostgreSQL（既存の隔離 DB 枠）へ展開し起動できるかを 1 回確認。起動不能なら「稼働中フォルダのコピーは復元不能」と結論し、`postgres-recovery-*` 5 タスクの NAS 設定 + 初回 base backup を登録ウィンドウで実施する案へ切り替える（Codex plan の順序 11 と接続）。
- 受入: 復元手順と結果を `docs/runbooks/postgres-recovery.md` へ 1 節追記。

### Lane C 判断パイプライン復帰（ODR-0039 実装 + DecisionCase）

**C-0 ODR-0039 を Accepted に（docs PR）** `docs/decisions/20260907-position-snapshot-attestation.md` の「一次記録」に 6 問の回答（2026-09-13、Decider: Project owner）を逐語で記録し、`status: Accepted`。`docs/OWNER_INTENT.md:89` の未決行を更新。

**C-1 DDL（worktree `ddl-position-snapshot`、DDL は 1 本のみ）** `ddl-migration-scaffold` skill。
- 新表 `decision.position_snapshots`（`snapshot_id, account_label='main', as_of_date, price_date, source, attested_complete, attested_at, note, created_at`）、`decision.position_snapshot_items`（`snapshot_id, instrument_id, quantity numeric(20,6), avg_cost_yen numeric(20,6)`, UNIQUE）。追記のみ。
- `core.positions` に `snapshot_id FK, source, price_date, attested_complete` を追加。`core.position_state_daily` は型変更せず、読み手を導出 view `analytics.v_current_positions`（時価は `mart.vw_daily_valuation` の `price_date` 終値）へ寄せる。
- `db/baseline` 再生成、governance yaml、freshness SLA 登録。`lock_timeout` は env.py の 5s。**本番適用は別承認**（適用ウィンドウ・rollback 手順を PR 本文に）。

**C-2 書き手と読み手（BFF、`bff-endpoint-scaffold`）**
- `tools/api/decision_api/managed_repository.py` の held 経路を snapshot 確定時の単一 Tx projection に置換。`POST /api/v1/decision/portfolio-snapshots`（宣言）と `GET .../latest`。
- 読み手 `held_position_*`（13 ツール・22 関数）を「attested_complete かつ as_of_date が 5 営業日以内」の判定に寄せ、古ければ HOLD 理由 `complete_current_position_source_unavailable` を返す。`tests/db/` に Decimal 往復・UNIQUE・単一 Tx・N 行目失敗 rollback・鮮度拒否。
- 数量・単価・損益・PF 比率は `private_financial`（ログ・通知・PR・worklog に値を書かない）。

**C-3 Desktop 宣言 UI（`desktop-component-scaffold`）** Portfolio 画面（`desktop/src/pages/portfolio`）に「この一覧は口座の全保有です（時点: 日付）」ボタンと「最終宣言: 日付」表示。BFF-only。ローカル build + 実画面確認。

**C-4 最初の宣言と第 1 束の解除** オーナーが Desktop で宣言 → `scripts/run_manifest.yaml:5598` `disabled_tasks` から「出口監視・PF リスク・VaR」の束を `tasks` へ戻す PR（PR #421 と同型）→ 登録ウィンドウ（`scheduler-registration` skill、人手）→ 初回定時実行の確認。**解除は「戻して直す」作業**（thesis の例のとおり停止中の変更で壊れているものが出る前提）。以降の束は初回成功を見てから。

**C-5 DecisionCase 読み取り確認と承認パック（9/14）**
- 読み取り専用で本番 `alembic_version`、`decision.decision_cases` 系リレーション（revision `20260731_01..03`）の存在、`DECISION_CASE_SHADOW_ENABLED`（`.env` は読まず `shared/config.py:161` の既定と BFF `/api/v1/system/ping` 等で判定）、封印証拠 path の有無を確認。本番が `20260827_01` 適用済みなら DDL は適用済みのはずで、残るのは activation evidence + flag。
- 承認パック: 適用ウィンドウ・rollback・検証手順・Gate 3 縮小版の要否を `data/runtime/plans/` に A4 1 枚。適用・flag ON は別承認。

### Lane D 片付け

**D-1 古い PR の処遇提案（オーナー判断）** #411: main へ rebase して merge を推奨（docs のみ）。#230: 対象テストが現 main でまだ不安定なら rebase して merge、解消済みなら close を推奨（PR #412 以降の Desktop テスト変更を確認）。#438: Codex 進行中（09-10 更新）なので担当に戻す。
**D-2 worktree 棚卸し表** `data/runtime/plans/20260913-worktree-inventory.md` に 29 本を「取り込み済み／未マージ（最終 commit 日）／detached 残骸／討議用（触らない）」で分類。削除候補: proof-pack-async-v2 8 本（`harness_status.py --summary` で job 無しを確認してから）、取り込み済みで討議用でない 2 本（macro-statistics / tdnet-conflict）。**削除は提案のみ、実行は別承認**。所有外 process・lock は触らない。
**D-3 worklog Verifying の一括整理（docs PR 1 本）** scratchpad スクリプトで 183 件を (a) PR 本文に worklog パスがある merged PR、(b) Task ID を含む branch の merged PR、に照合し、該当分の `Status` を `Done` に更新（1 行の理由: `merged PR #N, 2026-09-13 一括更新`）。未照合分は Verifying のまま一覧を残す。ODR-0038 D5 との差（機械更新は 10/7 以降）は一回限りの docs 変更として PR 本文に明記。

### Lane E 中期構造（凍結明け 10/7 以降、または製品側で凍結に触れないもの）
- E-1 serving 空返し → `RepositoryUnavailableError`（`_strategy_analytics.py` 5 関数から着手、次に 27 か所）。同時に空返し契約テスト 10 件を 503 期待へ差し替え。Desktop 側の 503 表示を実画面で確認。
- E-2 `depends_on` の決着: 実行時強制は `fresh_success_dependencies` に一本化し、`depends_on` は静的順序検査専用と文書化するか削除。Codex plan Wave 1-C（financial-unifier の依存）を先に着地。
- E-3 依存整理: `easyocr`/`torch`/`torchvision`/`anthropic` を optional group へ、`uv lock` 再生成、`defusedxml` 導入。pip-audit は「新しい検査」なので 10/7 以降に助言タスクとして。
- E-4 CI 死参照 14 件: `.github/workflows` 2 本 + `scripts/check_desktop_release_contract.py:337-346` のマーカーを 1 コミットで削除（削除なので凍結中も可）。
- E-5 金額単位: `shared/financial_units.py` へ 79 リテラルを寄せる。Desktop 円整形 10 実装を 1 本化。
- E-6 ClickHouse 残骸 1,002 行・`serving_*` getattr 6 件・Notion view 参照（BFF 4 + registry 8 + readiness 6）の退役（非交渉条件 6: shadow/rollback 証拠を揃えてから）。
- E-7 型チェッカ（pyright or ty）の advisory 導入、ruff `BLE`/`TRY` の advisory 化、`information_schema.tables` 100 か所の `to_regclass` ヘルパ化。
- E-8 timeout 監査の上書き帯（`meta.yaml`）と file size 台帳 107 件は 10/7 判定で扱う。

## 4. 実行順序

1. 本セッション（承認後）: A-1 → A-5（#410）→ B-3 の数値報告。worktree は A-1 用 1 本。
2. 翌セッション以降（並列 3 本まで）: A-2 / A-3 / B-1 / B-2（各 0.5〜1 日）、C-0 + C-5（9/14）、D-2 表と D-1 提案。
3. その後: C-1（DDL 1 本）→ C-2 → C-3 → オーナー宣言 → C-4 第 1 束。A-4、D-3 は空き枠で。
4. 10/7 以降: Lane E。

## 5. Verification

- A-1: `uv run pytest tests/tools/decision_support/thesis_monitor tests/shared/db tests/tools/quality/routine_runner tests/tools/notifications/earnings_schedule -q`。翌営業日の runlog（`logs/runlogs/thesis-monitor-daily-*`, `earnings-schedule-daily-*`）が success。
- A-2 / C-3: `npm --prefix desktop run test` の対象 + ローカル build + 実画面。
- A-3: 翌 03:27 の runlog と Discord 通知。
- B-1: 翌朝の Discord `[夜間回帰 ...]`。B-2: 翌 21:25 の Discord 要約。
- C-1: 隔離 PostgreSQL で upgrade/downgrade 往復、baseline parity。C-2: `tests/db/` 新規 5 件 + BFF テスト。C-4: 第 1 束の初回定時 runlog success。
- 各 PR: `pr-ready-gate` の Ready 証拠（exact SHA）。GitHub Actions は正本にしない。
- D-3: `uv run python scripts/check_md_links.py`（docs 検査）と Status 集計の前後差。

## 6. 触らないもの
- blog_scrapers / converters / benchmarks、TradingView、Rust 橋、討議用 worktree 3 本、Codex 進行中の worktree・PR #438、共有 DB への適用、Scheduler 登録（C-4 の登録ウィンドウは別承認で人手）。
