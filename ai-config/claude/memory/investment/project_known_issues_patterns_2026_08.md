---
name: project-known-issues-patterns-2026-08
description: MEMORY.md から移した長文の既知問題（psycopg の % と ? 変換・5432 転送破損）、観測できない失敗の 4 類型、repair_audit の成立条件、scratchpad の import 乗っ取り、2026-07 完了バッチ索引
metadata: 
  node_type: memory
  type: project
  originSessionId: 4536797c-cfe8-41ab-8cb0-896ec79630fc
  modified: 2026-09-05T00:16:50.920Z
---

# 既知問題（詳細）

- **`%` エスケープは params を渡す前提でしか正しくない**（08-30 実測・未対処）: `_escape_percent` が `%`→`%%` にするが、**psycopg は params が無いとエスケープを戻さない**（`SELECT 'a%%b'` → 値は `a%%b`、params 付きなら `a%b`）。`LIKE 'x%'` は一致集合が変わらず無害だが、**正規表現や等値比較に `%` があると結果が静かに変わる**。手書き `%%` は逆に `%%%`（奇数）になり params 付きで `ProgrammingError: only '%s','%b','%t' are allowed as placeholders`
- **`?`→`%s` 変換は connection の `execute`/`executemany` だけ**（08-30 実害）: `shared/db/pool.py` の `_PostgresConnectionAdapter` は該当 2 メソッドでしか `_normalize_sql` を通さず、`__getattr__` が **`.cursor()` を生 psycopg へ素通し**する。`with conn.cursor() as cur: cur.execute("... ? ...")` は `ProgrammingError: the query has 0 placeholders` になる。`instrument_master_cross_audit` はこれで 3 週間 0 行を書き続け、writer の `except Exception` が warning に潰して run は success 報告していた。**cursor 経由で書くなら `%s` を直書きする**
- **wsl --shutdown 後は 127.0.0.1:5432 の port 転送自体が壊れることがある**（08-29 実害）: TCP accept 直後にサーバ側切断・0 バイト応答（コンテナ内 psql は正常、pg_isready も通る）。復旧は `docker restart investment-postgres`。この状態で週次監査を走らせると safe-fast のマーカー外テストが数百件失敗→出力 16 MiB 超→ **AttemptLogStore の raise（未修理の非対称）が診断ゼロの evidence/EvidenceContractError global 停止に変換**して原因が見えなくなる。監査が evidence 失敗で safe レーンのログが 1 バイトも無いときはまず host→5432 接続を疑う

# パターン（詳細）

- **観測できない失敗には 4 類型ある**（08-30 に計 11 例）。新しい経路を足すたびに 4 つとも通すこと。**類型 D = 記録は正常なのに外形が同一**（`success/err=0/out=0` は 404・退役済み・上流停止の共通の外形）。**成功の記録は成功したことすら証明しない**。詳細と検出の道具: [[project-observability-failure-taxonomy]]
  - **類型 A: 記録より手前で落ちる**（失敗の事実が消える）— otel probe の 1 例外捕捉漏れ／`AttemptLogStore` の attempt 記録前 raise／`start_raw_ingest_run()` 前のブロックで 45 日不可視。対策は「痕跡を残してから落ちる」
  - **類型 B: 記録機構自体が壊れている**（成功しているのに記録だけ失われる）— `anomaly_calendar` が誤った引数名で呼び **DB に触れる前に TypeError**、`except Exception:` が例外を捨てるので**本体は毎日 success を報告し続けた**。**握り潰すなら何を握り潰したかを書く**
  - **類型 C: そもそも記録経路を持たない**（成功も失敗も最初から存在しない）— `raw.ingest_runs` 起点の調査は **active 279 タスク中 114 ソースしか見えない**。`attribution` は毎週 FAILED し RECOVERY_HINT まで出していたのに視野の外だった。**大きく失敗していても記録経路が無ければ見えない**
- **素の `MagicMock` は任意のキーワードを受け付ける**ので引数名の誤りを原理的に検出できない。tracking 系ヘルパーの `@patch` は **`autospec=True`** にする（08-30 に実害）
- **merge guard の `selection_digest` は gate 証跡のトップレベル同名フィールドではない**（08-31 に誤読）。`sync_repo.py:690` が `selection.selection_map_sha256` を取り出して渡すので、**同じ証跡に別値の `selection_digest` が並存する**。repair_audit の照合はこちらを見る。なお `weekly_test_audit.selection_digest()` は base が違っても同値なので、main で作った repair digest が PR の gate と一致するのは構造的
- **`repair_audit` の成立条件は 4 つ**（08-31、2 回空振り）: ①`tested_head` に居る **claim 付き worktree が実在**（`_source_worktree` が `head==head_sha` で照合。無いと `runner-create-start` 到達前に 4 秒で `QueueContractError`）／②停止が blocked／③`request.base_sha==head_sha==` **PR の head**（現 main ではない）／④上記 digest 一致。**ancestry だけ確認して「1 本で足りる」と判断すると①で落ちる**
- **scratchpad の調査スクリプト名が import を乗っ取る**（08-31 に同一セッションで 2 回）。スクリプトのあるディレクトリは `sys.path` 先頭に入るので、`attr.py` が `attrs` の内部 import を、`concurrent.py` が `concurrent.futures` を覆った。症状は**まったく無関係な場所での例外**（`attrs` 経由で psycopg の `ProgrammingError`）で、**そのモジュールの中を探しても虫は居ない**。使い捨てスクリプトでも `probe_` / `sweep_` 等を前置し、標準・依存パッケージ名を避ける。**原因不明の例外はまず traceback の全フレームを見る**

# 完了済み 2026-07 バッチ（索引から移設）

- [[project-phase-b-screening-completion-2026-07-23]] / [[project-claude-settings-restore-2026-07-23]] — Phase B スクリーニング完遂+**新 lifecycle (EnterWorktree/publish-pr/finish-pr) 運用正本**／設定復元+**機械denyの人手境界化（helper経路は既定であって強制ではない、~/.codex/rules は exact-match ミラー必須）**
- [[project-financial-viz-kpi-orders-roadmap-2026-07-19]] — 財務可視化 16PR ロードマップ。**guidance 意味論: Q4行=終了FY最終予想、翌期は next_guidance_*→resolveForecastGuidanceRow**。計画正本 plans/pl-bs-cf-kpi-kpi-linked-heron.md
- [[project-desktop-design-reform-2026-07-19]] / [[project-financial-backlog-session-2026-07-19]] / [[project-next-session-followups-2026-07-18]] — Desktop デザイン Phase A 完了（続き=Phase B）／財務バックログ優先1+2完遂／後続バックログ（派生指標ビュー画面接続・EPS偽中立ほか）
- [[project-repo-state-repair-backlog-2026-07-18]] / [[project-skills-refresh-2026-07-18]] / [[project-agents-md-fable5-refresh-2026-07-18]] — リポジトリ状態修復・skills stub機械生成（正本 .agents/skills → build_skill_stubs.py --write）・AGENTS.md 単一正本化（マージはgate baseline一致でエージェント可）
- [[project-hv-double-annualisation-fix-2026-07-18]] / [[project-financial-change-tracking-2026-07-18]] — HV二重年率換算修正（**pool の ?→%s 変換は jsonb `?` も壊す→jsonb_exists()**）／「変化を追う」ロードマップ（単Q SQL 正本化）
- [[project-repo-consolidation-2026-07-16]] / [[project-pg-index-corruption-repair-2026-07-16]] / [[project-decision-chain-repair-2026-07-16]] — 大統合（**alembicフォークは本番適用状態を正として付け替え**）／PGインデックス破損修復（**壊れたユニークindexは重複素通し・テーブル単位REINDEXが確実**）／判断段通電修理
- [[project-functional-completeness-audit-2026-07-15]] — 機能不完全性監査（正本 docs/audits/20260715）。**run_tool.ps1 の ExitCode null 罠と safe_args 無視**
- [[project-news-report-source-batch-2026-07-14]] / [[project-ui-ux-reform-202607]] — Reuters復旧・Bloomberg廃止（serve 常駐は schtasks /End でも子python生存）／UI/UX 大改革（Phase3構造統合・Phase4残）

ファイル名は index の `project_*.md`（スラッグのハイフンをアンダースコアに読み替え）。
