# 計画: 現状総点検 + Linux 移行・再構築レポート（HTML）

## Context（なぜこの作業か）

オーナー（非技術者・単独・AI 全委任）から、次の 2 点を 1 本のレポートにまとめる依頼を受けた。

1. **現状のアプリの状態を人が読める形でまとめる**。機能ごとの設計思想、全体構成、動いているもの／止まっているもの、データが正しく取れていない箇所、表示できていない箇所を、オーナー自身が把握できていない現状を解消する。
2. **Windows + WSL2 から Linux へ移行し、1 から作り直すならどう計画するか**。技術スタック・設計構成の見直し、ローカル LLM をアプリ内エージェントとして組み込む思想（RAG／ベクトル DB を含む）、Docker 構成の見直しを含め、議論を進められる材料にする。

オーナー回答（2026-09-15）で固まった前提:

| 論点 | 回答 |
|---|---|
| 移行先 | **新しい Linux 専用機**を中核にし、この Windows PC は薄いクライアントとして残す |
| エージェント像 | 対話分析アシスタント（RAG）／定期的な自律分析／道具を使う多段調査、の 3 つ。開発作業はフロンティアモデル主体、将来は正しくできる範囲でローカル LLM にも委ねる |
| 納品形式 | ローカル HTML 1 本を `D:\Dev\Investment_設計資料\` に保存（外部公開なし） |
| DB の扱い | **スキーマも設計し直し、必要データだけ移す**（約 870GB・792 表を丸ごと移送しない） |

### 調査で確定した重要事実（レポートの前提）

- **Linux 移行は現在「凍結リスト」に載っている**（`docs/OWNER_INTENT.md` §4「Gate 5〜6 相当（durable queue / dataset別storage / Linux移行 / Mac worker）への着手」は Phase 1 実運用が回るまで凍結。`docs/roadmap/reform-program-202607.md` Gate 6 も「Linux中核へのcutoverはPhase 1実運用と別ODRまで凍結」）。ハーネスも ODR-0038 で 9/8〜10/7 凍結中。**本レポートは議論用の設計資料であり、凍結解除（新 ODR）はオーナー判断**。レポート自体はリポジトリ外に置くので凍結には抵触しない。
- 既存 ADR（`docs/decisions/20260712-single-server-analytical-modular-monolith.md`）は「目標=専用 Linux 中核 + 薄い Tauri client、big-bang rewrite はしない」と定めている。今回の「1 から作り直す」は**この ADR の『big-bang 禁止』と正面から衝突する**ため、レポートでは「作り直し」と「strangler（並行構築→段階切替）」の両方を比較し、推奨を示す必要がある。
- 2026-09-07 の統合評価（`Investment_設計資料/統合現状評価と改善計画_2026-09-07.md`）は「対策は『もう一度きれいに作り直す』ではない」と結論していた。今回はオーナーの問いが変わった（Linux 専用機 + スキーマ再設計）ので、その結論を再検討する位置づけになる。
- 規模: Python 約 150 万行・TS 約 38 万行・DB 792 表 / 286 ビュー / 1,076 索引 / 約 870GB・Alembic 255 revision・BFF 556 エンドポイント・Desktop 25 ワークスペース + 銘柄タブ約 60・manifest タスク active 274 / disabled 98（80 本が 8/11 から HOLD）・docs 1,600 本・worklog 1,400 本超。
- 動いていない／壊れている主要点（既存レポートで確定済み）: 判断パイプライン 80 タスク HOLD（8/11〜、保有スナップショットの正本欠如が構造原因）、決算閉ループ shadow 並走ゼロ（9/8 に再設計待ちへ方針変更）、データ取得の静かな失敗群（J-Quants 配当桁あふれ・EDINET 2/20 停滞・e-Stat 0 件 success 等、修正の多くは着地済みだが実運用確認は部分的）、バックアップ実効なし（NAS 導入後、C ドライブ設計廃止 PR が Verifying）、価格の分割調整が自己修復しない（DB 診断 D-01）、財務ファクトの正本二重化（D-02）、naive timestamp 500 列（D-04）、ハーネス肥大（scripts/dev+ci 4.8 万行、tests/scripts 7.2 万行）。
- LLM/RAG の現状: Qwen3.8-27B Q8 64K を llama.cpp（127.0.0.1:8081）で Tauri が sidecar 起動、Gateway 経由。用途は決算詳細分析のみ（実 TDnet 決算の日次自動処理は接続作業中）。**pgvector `knowledge.embeddings`（768 次元・HNSW）は存在するが ANN 検索を使うクエリは 1 本もない**（書くだけ）。Ollama は nomic-embed-text の埋め込み用途だけ維持。エージェント（tool use / 多段調査 / 対話）は製品側に存在しない。開発ハーネス側の `.agents/`・`.claude/agents/` は開発用で製品エージェントではない。
- Windows 依存: Windows Task Scheduler（`register_schedules.ps1`・生成 .bat 340 本超・パスワード/UAC 人手境界）、Docker Desktop + WSL2 の named volume（VHDX 1.6TB、スリープ復帰バグ、Purge で全損）、PowerShell スクリプト群、Tauri の Windows ビルド、`D:\` 固定パス、CRLF 問題。
- 外部期限: 11 月中旬 Q2 決算集中期（決算分析の次の実観測機会）。

### 探索 A（構成・インフラ）で確定した追加事実（2026-09-15、main `8aec1a563`）

- 規模の実測: tracked 11,044 ファイル、`tools/` 349 パッケージ（16 カテゴリ）、BFF 429 py / routers 78 ファイル、Desktop 1,175 tsx + 422 ts + Rust 3 ファイル（`lib.rs` 3,777 行 + `qwen_runtime.rs` 970 行）、Alembic 255、`scripts/` に **.bat 408 本（383 本が生成物）・.ps1 33 本**、`scripts/dev+ci` 47,661 行、`check_*.py` 約 90 本、docs 1,878 本（decisions 87）、tests 2,105 py、`logs/` 2.3GB・runlog JSON 98,128 件（ローテーションなし）。
- **Windows 依存の核心は 4 点**: ① `scripts/run_tool.ps1`（全タスクの汎用実行器: manifest 解決・env 注入・runlog・依存鮮度・ロック・timeout・process tree kill）、② `scripts/register_schedules.ps1`（1,973 行、`D:\Dev\Investment` 固定、パスワード Read-Host、約 40 タスクの無効化方針を内包）、③ **実行時刻の正本が 3 か所に分散**（manifest の `cron` 12 件・`schedule` 13 件・残り約 206 件は register_schedules.ps1 内のトリガーにしかない）、④ `scripts/dev/proof_pack_queue_windows.py`（kernel32 ハンドル API 直叩き、POSIX 分岐なし）。加えて Python から PowerShell を呼ぶ箇所が約 17 ファイル（LLM runtime の port 所有確認、scheduler 棚卸し、Scouter/コンセンサスのブラウザ認証等）。
- **すでに Linux で動く部分**: GitHub Actions 9 本のうち 8 本が `ubuntu-latest`（Python + TS のテストは Linux で通っている）。`shared/performance.py` は POSIX フォールバックあり。Tauri の Rust 依存（single-instance / autostart）は linux 対応済み。`.claude/hooks/post-edit-lint.sh` は bash 前提。
- PostgreSQL は Docker Desktop（WSL2 backend）のコンテナ `investment-postgres`（pgvector 版 PG16 + zstd、named volume、`127.0.0.1:5432`、WAL archive を D: の spool へ）。compose の他サービス: otel-collector（**debug exporter のみ、実バックエンドなし**）、`llm-gateway`（**`python -m http.server 8090` のスタブ**、bootstrap の必須サービス扱い）、polaris（profile `iceberg`）、caddy（profile `phase-b`）。vLLM/Ollama はコンテナではなく Windows ネイティブ。`.wslconfig` は memory=20GB / swap=8GB。
- LLM Gateway は「名前だけ 3 つ」: `shared/llm_gateway/`（`current_runtime.py` + `ollama.py` のみ）、`tools/llm_gateway/`（`narrative_runner.py` のみ）、compose のスタブ。実運用経路は Tauri `qwen_runtime.rs` → `uv run runtime_supervisor` → `D:/Tools/llama.cpp/b10566/llama-server.exe`（win-cuda）→ `D:/Models/Qwen3.8-27B/*.gguf`。vLLM は設定名と文書にだけ残る（起動手段なし）。`shared/llm_prompts/` は空パッケージ。
- Desktop の BFF 起動は 3 経路すべてが `scripts/run_desktop_phase_a_launcher.ps1`（1,785 行: Docker Desktop 自動起動→compose up→pg_isready→mutex→8010 の残留 kill→`uv run python -m tools.api.decision_api.main`）に収束。Tauri 側は `DEFAULT_INSTALLED_RUNTIME_ROOT = r"D:\Dev\Investment"` を固定し PowerShell を spawn する。
- 設定: `shared/config.py` は単一 Settings 484 フィールド、`.env.example` 406 キー。`postgres_statement_timeout_sec` は 0（無効、実測 2.86 時間の文があるため）。`aws_glue_*`/`bloomberg_*`/`refinitiv_*` は未実装の予約枠。
- 通知は Discord webhook のみ（LINE/メール/Slack なし）。
- 陳腐化・残骸: `.venv-wsl/`（未参照）、`domains/ labs/ orchestration/ artifacts/ output/`（tracked 0）、`data/runtime/documentation-governance-historical-migration-residual-20260830/`（**リポジトリ全体の第二コピー**）、`docs/README.md` §3 の architecture 索引が実ディレクトリと不一致、`.agents/skills/` と `.claude/skills/` の二重生成。

### 探索 B（機能一覧・稼働状態）で確定した追加事実

- **稼働実態（`logs/runlogs/`、2026-09-08 以降 5,057 run）**: 成功 3,744 / **失敗 1,313（26%）**。失敗分類は data_quality 1,040・runtime_error 159・external_dependency 85・timeout 23。**失敗率 100% のタスクが 30 本**（`financial-unifier-daily`、`edinet-normalized-facts-refresh-daily`、`daily-screener-refresh-morning`、`tdnet-quality-check-daily`、`data-quality-gate-{am,pm}`、`health-dashboard-daily`、`scheduler-audit-daily` 等）。最多失敗は `edinet-landing-replay-daily` 309/516、`earnings-disclosure-diff-readiness-intraday` 231/231。ODR-0043 で退役したはずのタスクが Scheduler 登録解除待ちで失敗し続けている。
- **manifest 実数**: enabled 279 / disabled 94 / manual_only 43 / retired 15 = 431。disabled 94 のうち **約 55 本が 2026-08-11 の「検証済み保有スナップショット源なし」HOLD 連鎖**（exit monitor・PF risk・VaR・factor・correlation・sizing・allocation・feedback loop・decision runner・workflow orchestrator・daily screener run・story builder）。他: IR 証拠 6 本（7/20〜）、決算ラベル 8 本（ODR-0043 退役）、`core.sizing_results` 表が存在せず 2 本、METI IIP 取得不能 3 本（5/6〜）。
- **ツール**: `tools/` 318 `main.py`（16 カテゴリ）。**71 本は manifest 非掲載**（手動 CLI か孤児）。**24 ディレクトリはソース削除済みの `__pycache__` 残骸**（`semantic_search`、`research_agent`、`daily_review_agent`、`regime_integrator` 等）。`tools/AGENTS.md` が参照する `docs/current/generated-repository-snapshot.json` は存在しない。
- **Desktop**: ルーター `desktop/src/lib/app-router.tsx`（1,009 行）に 63 ルート = 実ページ 39 + 互換リダイレクト 21 + 旧解決 3。サイドバー 25 項目（TODAY/COLLECT/DECIDE/EXECUTE/REVIEW/SYSTEM）。未リンクの実ページは `/fundamentals` の 1 本のみ（記憶にある「未リンク 13 本」は解消済み）。ページ 161・コンポーネント 524・テスト 576。`/company/$code` は **ODR-0029 の 10 章連続ページと、約 62 詳細タブ + 37 業種 BM タブ + 7 ワークスペースタブが同居**（ODR-0029 は排他タブでの置換を禁じている＝矛盾）。
- **BFF**: 63 ルーター、522 パス、`endpoint_registry.py`（3,867 行、540 EndpointSpec）。2026-07-04 の棚卸しで **469 ルート中約 60 本が Desktop から未参照**、うち `kpi-trends`/`macro-exposure`/`iip-*` は供給 0 行。`us-pulse` 3 本は製品方針で 410。`README.md` は 2026-05-06 のまま（408 件と記載、実 522）。
- **「LLM が変な機能を作った」の具体証拠**: ① `shared/decision_models.py` の `StrategyCode` は **39 メンバーの架空戦略体系**（docstring は 20/35 と矛盾、正本は 22 戦略、名称も `E.1`=EARNINGS_SURPRISE 等で正本と食い違う、**importer ゼロ**）。② `desktop/src/lib/strategy-catalog.ts` の `primaryGates: G1..G5` が `/review` の StrategyScoreboard に描画されているが、OWNER_INTENT §4 は「G1〜G9 の名称・分類は未承認」。③ 上記 `/company` のタブ二重化。④ 台帳 `SCORE-02` の「21 戦略」表記。
- **データが表示されない具体例（9 月 worklog）**: EDINET 年次原本は正しく保存されたが企業ページの通期表から FY2026 が消える（配当予想修正・J-Quants メタと混在、`20260914-edinet-annual-serving.md`）／半期財務は保存済みだが「比較不能」で API が空を返す（`20260914-edinet-serving-basis.md`）／J-Quants 予想修正行の空文字 actual を実績と誤認して財務反映が全停止（`20260913-jquants-empty-actuals.md`）／BFF が NUMERIC を JSON 文字列で返し Desktop の `toFixed()` でデータ管理画面が全面クラッシュ（`20260909-data-status-number-display.md`）／`raw.supply_demand_daily.foreign_buying/selling` 546,608 行が 100% NULL で書き手なし（SFF-P2-01）／業種別 BM パネルの silent skip 事故 3 回再発（`tools/AGENTS.md`）。
- **投資ロジックの配線**: 22 戦略の実装正本は `tools/decision_support/daily_screener/framework_contract.py`（793 行）→ `screening_catalog.py` → `/screening`（14 サブビュー）まで**接続済み**。しかし判断→サイズ→配分→出口監視→振り返りの書き込み側は **HOLD で全停止**。Gate0 は manifest 非掲載、guardrail は 8/11 停止、レジーム配分 3 タスクは停止かつ purpose-firewall で Shadow 固定。DecisionCase は本番に 12 表適用済み・行数 0・shadow 未起動。
- **LLM 関連の到達点**: `earnings-evaluation` skill は人手/エージェント駆動で稼働（manifest 非掲載）。Qwen 27B sidecar は設計 11 本・ODR 7 本に対し、最新統合 worklog（9/10）が「最終 Ready・独立 review・統合・共有回収有効化・通常 worker 更新・実分析確認」を未実施のまま Verifying。`reg_llm_tagger` は live LLM HOLD。`disclosure_embedding_indexer` は日次で稼働し `knowledge.embeddings`（pgvector/HNSW）へ書き込むが読み手なし。`semantic_search` はソース削除済み。
- **台帳と負債**: `次アクション管理台帳` done 147 / todo 40 / **blocked 22** / in_progress 8。コード内 TODO/FIXME は計 13 件のみ（lint で抑止）＝負債はコードではなく文書側に蓄積。テストは 1,839 ファイル、最終全走行 10,598 passed / 322 skipped、実 xfail 3 件。
- **陳腐化した文書**: `docs/known_issues.md`（2026-05-14 で停止）、`docs/design/入力ツール全体像.md`（active 299/disabled 3 と記載、実 279/94）、`docs/status/qwen35-local-llm-current-status.md`（9B 時代の凍結スナップショット）ほか。

### 探索 C（データ層・LLM/RAG）で確定した追加事実

- **スキーマ実数**（baseline 由来、2026-07-18 時点の生成物）: core 154 表/33 view、analytics 134/12、ops 112/1、raw 85/0、public 84/11（legacy_compat なのに `daily_prices` 全履歴・EDINET XBRL・TDnet 原本など実体の多くを保持）、decision 76/1、main 70/1（runtime_compat、`main.daily_prices` は 42 営業日キャッシュ）、knowledge 24/1、reg 23、legacy_archive 13、jquants 8、mart 2 表/**222 view**（BFF の読み面）、search 0/4 view（互換）、**law / noncorp は空スキーマ**。拡張は amcheck / pg_stat_statements / pg_trgm / pgcrypto / vector。
- **Alembic**: コード head `20260906_02_common_share_semantics_forward`、本番 `20260904_01`（未適用 1 本）、**baseline 生成物は `20260718_03` で停止（約 18 revision・25〜30 表が baseline に無い）**。ファイル名の日付と依存順が非単調。`EARN-BASE-01`: baseline 生成器がコード head を記録するため、別 DB のダンプに対して誤った manifest を出し得る。
- **3 層の実態**: PostgreSQL 954GB（2026-07-11 実測、価格系のみ 3.6GB）／オブジェクトストア `data/object_store` **50GB・約 31.5 万ファイル**（raw/edinet 312,502、raw/tdnet 1,880、`lake/warehouse` は空）＋ `data/disclosure_raw` 20,027 ファイル／**DuckDB の研究用ファイル `data/investment.duckdb` は存在しない**（runbook と baseline README は存在すると記載＝陳腐）。
- **バックアップ: 稼働ゼロ**。`postgres-recovery-{wal-sync,base-backup,monthly-verify,offsite-backup}` は 2026-07-20 から manual_only、98,142 件の runlog に backup の記録 0 件、NAS 実パス未提示（`20260912-nas-backup-policy.md`）。`data/db_backups` は 9/7 の重複退避 CSV 5 本のみ。**再構築以前に最大の資産保全リスク**。
- **保持方針**: `shared/catalogs/db_retention_policy.yml` は全 18 ルール warn_only。文書・証拠は永久保持、価格 10 年、判断記録 5 年。統計は 2000 年からの取得を目標（`history_coverage_requirements.yaml`）。価格履歴の開始年は文書に記録なし（未確認）。
- **鮮度・品質の測り方**: `shared/raw_ingest_tracking.py`（1,015 行、ソース別 stale TTL、日次予算 100GB/100 万 obj/1,000 run）→ `shared/source_freshness.py` + `ops.ingest_source_registry`/`ops.data_freshness_sla`（約 100 ソース、T1 12/24h・T2 24/36h・T3 48/72h）→ `data-quality-gate-{am,pm}`（5 軸、fail-closed）→ `db-ingest-governance-audit-daily`（6 ソースを恒久免除）。7/15 監査は「PowerShell Start-Process の exit code バグで全タスクが success を報告していた」と記録し、修正着地の worklog は見つからない（未確認）。
- **LLM 呼び出し元 約 22 か所**: 稼働中 = Qwen 決算分析 worker（Scheduler 管理外、runtime_supervisor 駆動、`analysis_status: partial` 多数）、embedding indexer、theme_narrative、news_intelligence、nlp_sentiment ×2、issuer facts 抽出、supply chain 抽出、law_tracker enricher、theme_scanner、daily_review。停止 = reg_llm_tagger（810 run で出力 0）、earnings_quality（退役）、market_situation、securities_report_qualitative、IR semantic enrich。**プロンプトの中央管理なし**（`shared/agent/prompts/*.md`、各 tool の `prompt_template.md`/`prompts.py`、inline builder に分散）。README は Q3_K_XL@8K のまま（ODR-0041 と矛盾）。
- **RAG の到達 ≈15%**: `knowledge.embeddings`（vector(768) + HNSW）へ日次で書くが、**ANN 検索でプロンプトに渡す経路が存在しない**。全文検索は pg_trgm（tsvector は 0 列）。決算分析の文脈は `context_builder.py` が検証済み原本から決定論的に組む（設計上の選択）。再ランク・ハイブリッド検索なし。
- **エージェント基盤は 3 系統が部分的に存在**: (a) `shared/agent/` routine 枠組み（capability 登録 3 件 = noop / alert.ack / job.run、routine 1 本 = `config/agent/routines/morning.yaml`、**manifest 未登録で一度も定期実行されない**、HITL 承認 API `routers/agent_actions.py` と Desktop の timeline UI はある）、(b) `ops.local_llm_agent_tasks` 耐久キュー（lease/heartbeat/通知状態機械、`task_kind` は `earnings_analysis` 固定）、(c) DecisionCase 12 表（0 行、Ed25519 鍵未 pin、apply packet writer 未実装）。**tool use / function calling のループ・検索ステップ・MCP は皆無**。開発用 skill（`ops-morning-check`）と製品 routine（`morning.yaml`）が同じ問題を別 runtime で解いている。
- **陳腐化・矛盾**: DB レイヤー契約 §6 は vLLM 必須経路と書くが実体は llama.cpp（契約未改訂）／`docs/status/qwen35-local-llm-current-status.md` は 9B 時代の archived snapshot／`docs/status/運用状態スナップショット.md` は 2026-03-07 の本文で最新リンクが 2/20／ghost dir 3 本（`semantic_search`、`research_agent`、`daily_review_agent`）／`law`・`noncorp` 空スキーマ。

### 設計案（計画エージェント P1: Linux 目標構成と移行順序）の要点 — レポート第 7〜9・12・14 章の骨子

- **戦略比較**: A 全面書き直し→一斉切替（データ喪失リスク高、成果まで数か月、11 月決算期と衝突、ADR「big-bang 禁止」違反）／**B 並走・レーン別移行（推奨）**（レーンごとに shadow 比較→合格→切替、旧系は Phase 4 まで無傷、決算期と衝突しない、オーナーが「同じ数字が出る画面」で段階検証できる）／C そのまま移設→後で整理（bloat・`archive_mode=off` を持ち込む、失敗率 26% のまま）。**C は「Phase 1 で旧 DB を Linux 機へ PG16 コンテナとして読み取り専用復元する」ことにだけ採用**（初の restore 実測 + ETL 元 + rollback 証拠を一度に満たす）。
- **書き直し対象**: ハーネス（`scripts/dev+ci` 47.7k 行・`tests/scripts` 72k 行）、Windows 実行層（`run_tool.ps1`・`register_schedules.ps1`・.bat 408 本）、Tauri ランチャー（`lib.rs` + `run_desktop_phase_a_launcher.ps1`）、DB スキーマ。**移植対象**: J-Quants/EDINET/TDnet 取得器の fetch/parse 核、Alembic 運用、Desktop の部品群（tokens/primitives）、`投資フレームワーク/`、DecisionCase 周辺の契約。旧 tools 349 パッケージのうち新系へ持ち込むのは「閉ループに必要な取得・計算」だけで、HOLD 55 本・100% 失敗 30 本は移植対象から外す。「クリーンなコード」はゼロ始点からではなく、依存方向規則を最初のファイルから強制・許可リストで持ち込みを絞る・ハーネス最小固定、の 3 つから生まれる。
- **凍結との関係（正直な記述）**: 新機・別リポジトリでも「Linux 移行への着手」に当たるため **凍結解除 ODR（仮称 ODR-0044）が必要**。ODR-0038 は自らを「最後のハーネス ODR」と定義するがアーキテクチャ ODR の起票は禁じておらず、判定日 10/7 と同時に決めるのが自然。**解除前にできること**: バックアップ実効化（§4 の明示例外）、NAS/offsite 実転送、ハードウェア調達、`register_schedules.ps1` 内の起動時刻 206 件を manifest `schedule:` へ集約（Windows 側でも SSOT 欠落の是正）、本討議。
- **目標構成**: Ubuntu 24.04 LTS Server／**PostgreSQL 18 を systemd ネイティブ**（PGDG apt、pgvector・pg_partman・pg_stat_statements・pg_trgm・auto_explain、scram、checksums、`statement_timeout` 既定 30s）、Docker Engine はテスト用使い捨て PG のみ／**pgBackRest → NAS（週次 full + 日次差分 + WAL 連続）→ restic → Backblaze B2（月 $3 級）**、復元演習は四半期ごと／**ジョブ実行は PostgreSQL 台帳型 scheduler + worker**（`ops.job`/`ops.job_run`、`FOR UPDATE SKIP LOCKED`、lease/heartbeat/fencing/timeout/retry/dead-letter、manifest の `depends_on`/`fresh_success_dependencies`/`timeout`/`recovery_policy`/`dedupe_key` をそのまま活かす。systemd timer 生成や APScheduler は不採用理由付き。規模 1.5〜2.5k 行）／**BFF は FastAPI 継続**、`app/<領域>/{api,usecase,domain,adapter}` の 8 領域、ADR §8 の共通封筒（`schema_version/as_of/data_cutoff/…/payload`）、endpoint は利用実績で ≤80 目標、端末別認証／**LLM は llama.cpp CUDA Linux build で ODR-0041 の固定 profile を再固定**、vLLM は量子化が変わるため再評価時に／Agent 層は BFF と別プロセス `agent.service`（P2 と整合）／otel-collector・llm-gateway スタブ・polaris・caddy は廃止、可観測性は **構造化 JSON ログ→journald + PG 台帳 + Desktop `/ops` + 赤は Discord**／**Tailscale**（`tailscale serve https → 127.0.0.1:8010`、identity header、端末登録表 + read/internal/admin、public port forward なし）／**薄型クライアントはブラウザ web app（PWA）を主とし `src-tauri` 撤去を推奨**（残る価値は tray・OS 通知・Stronghold のみ、失うものは Discord で代替済み、Windows ビルド・署名・更新契約と「この PC への反映」が消える。ADR の「薄型 Tauri client」からの逸脱なのでオーナー判断）。
- **図の文章記述（SVG 化用）**: 左 = Windows PC（ブラウザ + Tailscale client、HTTPS 矢印 1 本）。右 = Linux 中核機を 5 段（入口 tailscale serve→BFF 4 層／実行 scheduler→`ops.job`←worker@1..N、agent.service→LLM gateway→llama-server(GPU)/ollama／保存 PG18 + Object store + 破線の `investment_legacy` PG16 読み取り専用複製／出口 Discord／保全 pgBackRest→NAS→restic→B2）。右端に外部ソース（outbound のみ）。GPU 箱に「Phase 3 後に Windows から移設」注記。
- **移行フェーズ（約 9 か月、1 名 + agent のパートタイム前提）**: Phase 0（9/15〜10/7: 旧系で checksums/WAL archive 有効化・NAS base backup・復元演習・B2 offsite、機材発注、起動時刻の manifest 集約、解除 ODR ドラフト）→ Phase 1（10/8〜11/6: OS/Tailscale/PG18/pgBackRest/llama.cpp（GPU 未着で CPU 疎通）、旧 DB を `investment_legacy` へ物理復元、新リポジトリ雛形、**J-Quants 日足レーンを取得→保存→BFF→画面まで通し「同じ銘柄・同じ日の終値が旧画面と一致」をオーナーが確認**、再起動後に job 再開）→ Phase 2（11/16〜2027/1/31: TDnet→EDINET→統計・需給→ニュースの順に取得レーン移行と shadow 比較、不可逆データの hash 検証付き ETL）→ Phase 3（2027/2/16〜3/20、Q3 決算期を避ける: 閉ループ画面を新 BFF で完成、ブラウザ client 常用化、旧 Scheduler 段階停止、RPO/RTO 実測。rollback は `CONTROL_PLANE_BASE_URL` を旧 BFF へ戻す）→ Phase 4（3/21〜5/15: **GPU 移設**（決算閑散期、1〜2 日停止）、profile 再固定、決算 sidecar・chat・定期分析・多段調査）→ Phase 5（2027/6: 旧 Scheduler 全解除、Docker Desktop 撤去、legacy の最終スナップショットを NAS/B2 保管後に削除）。Phase 1〜2 は旧系に触れないため決算期と重なっても判断業務を止めない。
- **Windows 依存の退役マップ**: `run_tool.ps1` → `runner/run_task.py`（意味は移植、コードは書き直し）／`register_schedules.ps1`・.bat 408 本・`wrapper_bat` → 廃止（時刻は manifest へ）／PowerShell 呼び出し Python（`Get-NetTCPConnection` → psutil、`Get-ScheduledTask` 5 か所 → `ops.job` 台帳照会）／Monex Scouter・IFIS のブラウザ MFA 認証 → ODR-0009 に従い代替後に廃止（残すなら Windows 側の手動 CSV レーン）／Docker Desktop・WSL2・VHDX → PG18 ネイティブ／compose の otel・llm-gateway スタブ・polaris・caddy → 廃止／Tauri `lib.rs`・launcher.ps1 → 不要／`qwen_runtime.rs` → `llama-server.service` + runtime_supervisor の Linux service 化（移植）／`proof_pack_queue_windows.py`・proof-pack 一式・`tests/scripts` 72k 行 → 移植しない／runlog JSON 98k 件 → `ops.job_run` + journald（tar 保管）。
- **費用・リスク（推定、未確認）**: Linux 機 = CPU 16 コア級、**RAM 128GB**（PG 24GB + 27B ロード用 page cache 30GB + 余裕、64GB は下限）、NVMe 2TB（OS + 新 PG）+ 4TB（legacy 複製 + object store + WAL）、GPU 移設前提の電源 1000W 以上・PCIe x16、2.5GbE、概算 **¥35〜55 万（GPU 除く）**。電力 月 ¥2,000〜2,500（GPU 移設後 +¥1,000〜2,000）。B2 月 $3〜6。データ再取得の限界: J-Quants Standard は過去 10 年（実 plan 未確認）、**TDnet 無料範囲は直近 31 日→31 日超の PDF は object store 50GB にしか無い**、EDINET は動的 10 年窓、e-Stat 231GB は再取得可なので持ち込まない、Scouter/IFIS/kabutan/ブログ/自前台帳は再取得不能→最優先 ETL。二重運用コスト = 電力 +¥2〜3k/月 + オーナー検証 1〜2 時間/週。新リポジトリでも「新機構を増やさない」規律を AGENTS.md に最初から書く（ハーネス再肥大が最大の失敗要因）。
- **オーナー決定 13 問**（推奨先頭）: 戦略 B／解除時期 = 10/7 同時／新コードは新リポジトリ／GPU は Phase 4 で移設／クライアントはブラウザ／PG18 systemd + pgBackRest／PG 台帳型 scheduler／可観測性はログ + 台帳 + Discord／offsite は B2 + restic／Scouter・IFIS は代替後廃止／機材 128GB・2TB+4TB／llama.cpp 同 profile 再固定／自データの read-only MCP 公開は後続。
- **未確認**: J-Quants 実契約 plan と最古取得日、旧 DB の表別サイズ現在値、RTX PRO 5000 の実 TBP・スロット寸法、NAS 容量・プロトコル・実転送実績、Tailscale identity header 仕様、Ubuntu での llama.cpp b10566 相当 build 再現性、実売価格。

### 設計案（計画エージェント P2: エージェント/RAG 層）の要点 — レポート第 10 章の骨子

- **配置**: エージェント本体は BFF の外の `agent-worker`（Linux systemd 常駐）。既存の Tauri 子プロセス `earnings_evaluation_assistant` の worker と `ops.local_llm_agent_tasks`（ODR-0023 の耐久キュー: lease / heartbeat / advisory lock / 入力 hash × profile hash 一意）を `agent.tasks` へ一般化し、`task_kind` = earnings_analysis / chat_turn / investigation / scheduled_analysis、`priority` = interactive < scheduled < backfill で 3 モードを 1 本のキューに載せる。新しい queue 基盤は作らない（ODR-0035 整合）。BFF は受付・読取・SSE 中継のみ（`routers/system.py` の bus_event SSE を再利用）。
- **書けない構造**: PostgreSQL ロール `agent_reader`（allowlist view の SELECT）/ `agent_writer`（`agent.*` 提案表への INSERT のみ）。`agent.proposals` は `decision_eligible=false` を CHECK で固定、`provenance` 必須、`evidence_refs` 非空。昇格は既存 `ops.agent_action_requests` の承認導線（`routers/agent_actions.py`）経由の人間承認のみ。
- **ツール層**: `shared/agent/runtime/capabilities.py` + `step_handlers.py` の autonomy tier を拡張した型付きレジストリ。tier = read（固定 SQL の allowlist view、`as_of` 必須）/ compute（決定論計算のみ、LLM に算術をさせない）/ propose / never（数値正本・保有・閾値・DDL・shell・任意 SQL は存在させない）。露出は json_schema strict の action envelope から開始し、native tool calling は golden set で比較後。MCP は製品経路には使わず、read 専用 stdio アダプタを開発エージェント向けに提供。
- **RAG**: 索引は TDnet 原本ページ（`public.tdnet_document_pages`、locator あり）→ 短信セクション（`knowledge.sections`）→ EDINET → 表チャンク → 自分の判断記録 → 投資フレームワーク本文の順。見出し親区切り + 300〜500 字・1 文重なりの parent-document retrieval。新表 `knowledge.chunks` / `knowledge.chunk_embeddings(model_name, dim, vector)` を Alembic で追加し、既存 `knowledge.embeddings`（768 次元）は削除しない。検索は構造フィルタ（code・期・`available_at <= as_of`）→ 単一銘柄は全走査 cosine、横断は HNSW → `pg_trgm` 字句 → RRF 融合 → 再ランク → 上位 8。埋め込みは **bge-m3（1024 次元）へ並走移行を推奨**（nomic-embed-text は日本語が弱い、本コーパスでは未確認）。各 claim に `evidence_refs{doc_id, page_no, quote, char_span, content_hash}` を付け、引用照合できた文だけ `source_quote`。
- **安全契約**: 非信頼文書はデータブロックとして隔離、worker の egress は systemd `IPAddressDeny` で llama.cpp と PostgreSQL 以外を遮断。validator = json_schema strict → Pydantic → 引用照合 → **新規数字混入検査**（既存 `agent_analysis.py` の `_DIGIT_PATTERN` を「回答中の数値 ⊆ tool 出力 ∪ 引用」へ拡張）→ 不合格は `blocked`（表示・通知しない）。評価ハーネス（検索 golden set 50〜100 件、過去決算の回答セット）を prompt/model 変更毎に回帰。過去分析は上書きせず別 profile 版。
- **GPU**: 72GB の予算は 27B Q8 29GB + mmproj 0.9GB + KV 3〜4GB（64K 満量は未確認）+ 小型ルータ 4B 級 ≈5GB + bge-m3 ≈1.2GB + 再ランク ≈1.2GB ≈ 45〜55GB、余裕 15〜25GB（要実測）。**11 月決算期までは llama.cpp 固定 profile を維持し、vLLM は Linux で shadow ベンチ、2027Q1 に判断**（GGUF 不可・量子化が変わると過去分析との比較条件が変わる）。GPU が Windows に残る移行期は、退役済み Mac worker 契約（ADR 2026-07-12 §6）と同じ **outbound-pull 型 `llm-worker` を Windows で走らせ**、`agent.llm_requests` を Tailscale 経由で取りに行く（llama-server の tailnet 公開は ADR 違反）。
- **画面**: 生トークンは流さず、進捗イベント + 検証済み最終回答を SSE で流す（未検証文が一瞬でも表示されると非交渉条件 4 と衝突）。
- **開発をローカル LLM に委ねる条件**: 過去 PR 30 件程度の再演評価、隔離 worktree + 隔離 DB + 外部 network なし、diff ≤300 行・許可 path 限定・DDL/Scheduler/config 禁止、人間 merge 常時必須、フロンティアの独立レビュー併用。今は ODR-0038 凍結中・評価証拠ゼロ・製品 validator が先、のため見送り。
- **段階**: 0（〜10/7、決定 + DDL）→ **1a（既存レーンで実 TDnet 決算 1 件を自動分析→Discord、ほぼ新規実装不要）** → 1b（10 月末、保有・監視銘柄の決算 Q&A に引用付き回答、read tool 10 本 + ハイブリッド RAG + validator + chat パネル）→ 2（11/11 まで、優先度キュー・stage 間 yield・Windows pull worker）→ 3（12 月、多段調査と提案→承認）→ 4（2027Q1、PIT 再演・スライド読取・vLLM 判断）。
- **オーナー決定 12 問**（推奨先頭）: worker 配置／画面へ流す内容／ツール露出方式／MCP の範囲／埋め込みモデル／字句検索エンジン／llama.cpp か vLLM か／GPU 未移設期の worker 方式／最初のスライス／提案昇格の方式／Phase 1 の索引範囲／開発エージェントの局所化時期。

### 設計案（計画エージェント P3: データ資産の棚卸しと新スキーマ）の要点 — レポート第 11 章の骨子

- **新たに分かった事実**: 8/13 調査が言及した 2026-05-03 の 68.8GB dump は `data/db_backups` に存在しない（所在未確認）→ **フルバックアップは現在ゼロ**。EDINET landing は `raw/edinet/landing/2016/09` から始まり、API の 10 年窓の縁にある（これより古い原本は再取得不能）。TDnet 原本は object store `raw/tdnet`（2026/01〜、814MB）と `data/disclosure_raw/tdnet`（2.0GB）に分散、`.sha256` sidecar は見当たらず hash は DB 列側（未確認）。J-Quants Standard は履歴 10 年・120 req/分・詳細 BS/PL/CF は Premium 限定・**訂正は上書き配信で旧版は返らない**（現行 backfill 開始 2013-01-01 → 2013〜2016 の保存行は再取得不能）。`core.investment_holdings` は EDINET 政策保有株の抽出でありオーナー保有ではない（保有は `decision.managed_instruments`、時点なし、ODR-0039 で snapshot 化予定）。
- **トリアージ**: **A 代替不能（移す・照合必須）** = オーナー判断記録（`decision.trade_decision_journals`・`journal_entries`・`managed_instruments`・`instrument_hypothesis_notes`・`thesis_*`・`earnings_season_decisions`・`decision_cases` 族 11 表）／保有・約定・トランシェ（`core.tranches`・`positions`・`fills`・`orders`・`trade_track_records`）／人手レビュー・承認（`ir_review_events`・`knowledge.memos`・`hypotheses` 等）／LLM 分析結果（`decision.earnings_agent_evaluations`・`ops.local_llm_agent_tasks`・`knowledge.extracted_facts`・IR ledger）／履歴 API のないスクレイプ（コンセンサス snapshot、Scouter 14 表、IR page snapshot、news、law/reg 23 表、fear_greed）／TDnet 原本（DB 表 + files 2.8GB）／EDINET 原本 landing（49GB + 4.6GB、**XBRL fact 表はコピーせず landing から再生**）／J-Quants 保存版（訂正前版・窓外期間）／PIT 系譜（`raw.ingest_runs` 等は移送行から参照される run_id の閉包だけ）／需給・JPX・日証金。**B 再取得可だが高コスト** = J-Quants 窓内（A と同じ表なので分けず移送後に期待 ID 突合で欠落だけ再取得）／EDINET 窓内 XBRL（`edinet_xbrl_facts` 118.7GB・`linkbase_arcs` 93.6GB は **コピーせず手元 landing から Linux 上で再パース**）／マクロ生データ（`raw.estat_values_raw` 231.7GB は API 再取得、改定履歴だけ Parquet 退避、正規化済み `core.*_metrics` 9.1GB は A 扱い）／EDINET 派生（`large_holdings` は J-Quants endpoint に置換）。**C 派生・再計算** = mart 222 view、feature store、analytics snapshot、screening runs、財務 resolved 系（新パイプラインで再解決）、main.* cache、`knowledge.embeddings`（再埋め込み）。**D 廃棄** = dead tuple・未使用 index 40GB、legacy_archive 13 表、main/public 非正本側、search 互換 view、空スキーマ、単表スキーマ、個別 run 台帳 28 本、`earnings_quality_labels`（Parquet 退避のみ）、filesystem 残渣（documentation residual 5.5GB・vlm_training 18GB 等はオーナー確認後）。
- **規模**: コピーしない分だけで ≈484GB。**移送する DB 論理サブセットは 80〜200GB + ファイル ≈57GB**（表別内訳は未確認。最初の作業は `data_platform_migration audit` 相当の読み取り専用サイズ棚卸し）。暦日 **4〜8 週**、parity 観測は 11 月 Q2 決算を 1 サイクル含めたい。
- **新スキーマ原則 20 条**（DB 診断 §5 の 7 原則 + 製品モデル §3）: キーに次元（財務 fact PK = instrument_id・fiscal_year・quarter・period_kind・consolidation・is_guidance・metric_key）／読取時 dedup 禁止／timestamptz 既定で `published_at/available_at/ingested_at` + `valid_from/valid_to/superseded_at`、naive 列 0 を CI 固定／金額は numeric（double 禁止）／汎用 run 台帳 `ops.runs`（`records_out=0` は `status='empty'`）／COMMENT 必須／enum は共有定義から生成／**銘柄同一性は SCD2**（`instrument_code_assignments`・`sector_history`・`market_history`、as-of 変換関数 1 本）／不変原本 `raw.source_objects`（sha256・object_uri は Linux パスへ正規化、旧 URI は alias）／**財務 fact は縦持ち canonical + 横持ち serving**／汎用 revision 表 `core.artifact_versions` を PIT の背骨に／SourceRights fail-closed／provenance 5 値と `decision_eligible`／raw landing は初日から pg_partman 月次パーティション／serving は事前計算表のみ／`agent.*` 分離／`knowledge.chunks` + `chunk_embeddings`／**スキーマは 7 つ**（raw / core / mart / decision / knowledge / agent / ops、退役: main・public・search・law・noncorp・analysis・archive・market・quality・topix・jquants・legacy_archive）／ID 規約（bigint identity / uuid、32bit 禁止）／役割分離（`bff_reader`・`ingest_writer`・`agent_writer`・`migrator`、BFF に `statement_timeout=30s`）。
- **移行手順**: (a) 旧 DB のフル物理復元を Linux 機に `investment_legacy`（PG16）として置き、新 DB（PG18 別クラスタ）から `postgres_fdw` で `stage.*` として読む（Windows 本番負荷ゼロ）→ (b) 族ごとの SQL 変換 + `ops.migration_reconciliation` に件数・行 hash 照合を記録、code 再利用の人手確認リスト → (c) 再取得が安い族は API 再取得 / EDINET は landing replay → (d) golden set 50 社（保有 + Watch + 33 業種各 1）で調整後株価 10 年・財務 8Q×15 指標・保有・マクロ 12 系列・スクリーニング 1 日・会社ページ BFF JSON を parity 比較、両 BFF 並走 → (e) 旧 DB は `default_transaction_read_only = on` で存続、shadow 全 green + rollback リハ 1 回 + 新 DB restore 実測 1 回が揃うまで削除しない。**PIT 条件**: `ingested_at/available_at/observed_at/run_id` は旧値を明示列で INSERT（`DEFAULT now()` を踏ませない）、naive 列は表ごとに JST/UTC を判定して台帳化、不明は `pit_quality='reconstructed'`。
- **バックアップ先行（すべてを gate）**: NAS UNC 確定 → `archive_mode=on` + canary + wal-sync + health → base backup（NAS 空き ≥1.1TB）→ **restore drill を Linux 機で実施（= `investment_legacy` の入手）** → Scheduler 登録（wal-sync 2 分・health 5 分・base 週次）→ 任意で restic offsite。これが終わるまで旧 DB への読み出し・凍結・DSN 変更に着手しない（新スキーマ DDL の作成は進めてよい）。
- **Alembic**: **新 DB は新 chain（`db/alembic_v2/`、`alembic_version_v2`、初版 `0001_baseline_2026` は人が書き、適用後に baseline を機械生成）**。非交渉条件 5 は同一 DB の履歴への禁止なので別クラスタ・別 version table の新 chain は整合。旧 chain（本番 `20260904_01`）は触らない。255 本を Linux で再実行しない理由 = 捨てるものを作ってから壊す作業になる・データ状態依存 revision の再実行が保証されない。CI の single-head ratchet と baseline check は v2 に付け替え、`squawk` と `lock_timeout` 機械強制を追加。
- **サービング層**: BFF は `mart.*` 事前計算表のみ読む（画面単位 read model: `company_financials_quarterly`・`company_price_adjusted`・`dashboard_calendar_daily`・`portfolio_positions_current`（鮮度窓 5 営業日で stale）等）。refresh は ingest 後の manifest job が `ops.serving_generations` を書き、既存 `read_cache.py` の generation probe で TTL 制御。D-02 再発防止 = 財務は `core.facts` → 書込時解決 `core.facts_resolved` → job → 横持ち mart、旧 `vw_financials_unified` は作らない。D-01 = `core.price_daily`（未調整）+ `core.corporate_actions`（型付き split_ratio）→ 累積係数で調整系列生成、ベンダー adjusted は照合列に降格、連続性ゲート日次。DuckDB は READ_ONLY ATTACH + `lake/` Parquet 直読みの研究経路、serving 依存にしない、`pg_duckdb` 不採用。
- **オーナー決定 12 問**（推奨先頭）: バックアップ先行を前提条件に／財務 fact は縦持ち + 横持ち serving／Alembic 新 chain／200GB 級 raw はコピーせず再取得・replay／LLM ログ本文は 90 日／退役ラベルは Parquet 退避のみ／銘柄同一性 SCD2 + code 再利用は人手確認／naive 時刻は表ごと JST 既定 + 例外台帳／旧 DB 読み取り専用は Q2 決算サイクル終了（2026-12）まで／offsite 採用／filesystem 残渣は中身確認後／完了定義は shadow green + rollback リハ + restore 実測 + Desktop 切替 + Scheduler 登録まで。
- **未確認**: 表別サイズと A〜D 内訳、TDnet 本文表・knowledge の実容量、EDINET landing の年別カバー率、2026-05-03 dump の所在、J-Quants 実 plan の capability 証跡、`raw.ingest_runs` 最古行、object store sidecar 有無。

### 3 案の統合で親が揃える点（執筆時）

- P1 の `agent.service` と P2 の `agent-worker` は同一物として 1 つの名前に統一する。
- 埋め込みは P1「nomic 維持」と P2「bge-m3 並走」を「**並走して golden set で選ぶ、旧 768 次元表は削除しない**」に統一する。
- ジョブ基盤は P1 の PG 台帳型 scheduler + worker と P2 の `agent.tasks`（既存 `ops.local_llm_agent_tasks` の一般化）を「**同じ `ops.job` 台帳の task kind 差**」として 1 本に揃える（P2 の「新しい queue 基盤は作らない」と整合）。
- P1 の移行フェーズ（9 か月・Phase 0〜5）と P2 の段階（0〜4）と P3 の 4〜8 週は、**P1 の暦を骨格**にし、P2 の 1a（実決算 1 件の自動配信）は Phase 0〜1 の間に現行 Windows 構成で先行、P3 の DB 移送は Phase 1〜2 に内包、と位置づける。
- クライアント（ブラウザ vs Tauri）と GPU 移設時期は既存 ADR からの逸脱を含むため、推奨は示しつつ「オーナー決定」に残す。
- 凍結との関係は P1 の記述（解除 ODR 必須、解除前にできる範囲）を第 2 章に置く。

## 成果物の仕様

- **場所**: `D:\Dev\Investment_設計資料\現状総点検とLinux再構築計画_2026-09-15.html`（単一ファイル。CSS/JS インライン、図は Mermaid を CDN から読み込むか、静的 SVG をインライン埋め込み。オフラインで開けるよう SVG インラインを優先し、Mermaid はフォールバック）。
- **読者**: オーナー（非技術者）。全文日本語・敬体。専門用語は初出で平易に説明。結論先出し。各章末に「オーナーが決めること」を番号付き選択肢（推奨を先頭）で置く。
- **議論を進められる形**: 章ごとに「事実（出典付き）／解釈／選択肢／推奨／未確認」を分離。不確実な箇所は「未確認」と明記。図は「この図の見方」を添える（`feedback_sector_page_visualization` の掟）。
- **図（最低限）**: ① 現行アーキテクチャ（Windows/WSL2/Docker/Scheduler/Tauri/BFF/PG/LLM）、② 機能マップ（データ取得→分析→判断→画面の縦の流れと、各レーンの稼働状態を色分け）、③ 目標アーキテクチャ（Linux 専用機 + 薄いクライアント + エージェント層 + RAG）、④ 移行フェーズのタイムライン（並行構築→切替→旧系退役）、⑤ データ資産の分類（引き継ぐ／再取得できる／捨てる）、⑥ 現行 DB スキーマの問題箇所（二重正本・分割調整）を示す簡略図。
- **サイズ目安**: 本文 15〜25 章立て相当。読み飛ばし用の目次と「5 分で読む要約」を先頭に置く。

## レポート構成（案）

1. 5 分で読む要約（結論・推奨・オーナーが決めること 6〜8 問）
2. このレポートの位置づけ（凍結リストとの関係、既存 ADR との衝突点、議論用資料であること）
3. 現状の全体像（構成図①、規模、開発史 2026-02〜09 の山谷）
4. 機能マップと設計思想（図②。データ取得／分析／判断・通知／Desktop の 4 領域を、`機能目的台帳_2026-08-11.md` と全体設計 §9 改善台帳を土台に、「目的・思想・稼働状態・判断への接続」で一覧化。オーナーが「変な機能ができた」と感じる箇所＝目的不明・未接続の機能を明示）
5. 動いているもの／止まっているもの／壊れているもの（HOLD 80、閉ループ、静かな失敗、表示されていないデータ、未リンク画面、価格調整、財務二重正本、バックアップ）
6. なぜこうなったか（構造要因: 機能単位の横展開、正本の複数化、ハーネスがハーネスを呼ぶループ、承認の非対称、Windows 土台の脆さ、設計先行・実装遅延）
7. 「1 から作り直す」か「並行構築で置き換える」か（big-bang vs strangler の比較、既存 ADR との関係、推奨）
8. 目標アーキテクチャ（図③: Linux 専用機の役割、薄いクライアント、BFF、ジョブ実行基盤、LLM/エージェント層、RAG/ベクトル、観測・バックアップ）
9. 技術スタック見直し（言語/フレームワーク、DB、ジョブスケジューラ（systemd timer / cron / 軽量 queue）、コンテナ（Compose on Linux、Docker Desktop 廃止）、Desktop（Tauri 維持 vs Web UI）、型チェック、テスト方針、観測性）
10. エージェント・RAG 設計（3 つの姿の実現方式、tool use / MCP、pgvector の活かし方、文書チャンク設計、検証なしに DB へ入れない契約の保ち方、GPU 配分、開発をローカル LLM に委ねる条件）
11. データ資産と新スキーマ方針（図⑤: 引き継ぐ資産の棚卸し、再取得可能性と履歴限界、新スキーマの原則＝DB 診断の 7 原則、必要データだけ移す手順）
12. 移行計画（図④: Phase 0 準備〜Phase N 旧系退役、各フェーズの完了条件、並行運用の期間、rollback、11 月 Q2 との関係）
13. 開発の進め方の見直し（ハーネス縮減、フロンティアモデル主体、Done の定義、WIP 制限、オーナーが理解できる 30 ページ説明書の習慣）
14. リスクと費用（ハードウェア、電気代、期間、データ再取得コスト、失うもの）
15. オーナーの意思決定リスト（統合）
16. 付録（出典一覧、数値の計測方法、未確認事項）

## 承認後の進め方

事実収集（探索 A〜C）と設計案（計画 P1〜P3）は plan mode 中に完了済み。承認後は次の 4 段階で、**すべて読み取り専用**（共有 DB・Scheduler・`.env`・secrets には触れない。DB の行数等は既存レポート・worklog の記載値を出典付きで使う）。Ultracode が有効なため、段階 1 と 3 は Workflow で並列実行する。

### 段階 1: 敵対的検証（Workflow、読み取り専用）

レポートに載せる「動いていない／壊れている／使われていない／矛盾している」型の主張は投資判断の道具に対する強い言葉なので、主要な主張（目安 20〜25 件）ごとに **反証役 3 名（視点: 実装を読む／文書・決定記録を読む／runlog・生成物を読む）** を並列に立て、過半が反証した主張はレポートから落とすか「未確認」へ降格する。対象の例:

- 「定期実行の 26% が失敗、30 タスクが 100% 失敗」（runlog 集計の再現、期間・分母の妥当性）
- 「バックアップ稼働ゼロ」（manual_only の確認、NAS 転送の未実施、runlog 0 件）
- 「RAG は索引のみで検索経路なし」（`<=>` / ANN を使うクエリの不在）
- 「39 戦略の架空 enum は importer ゼロ」「G1〜G5 が描画されている」「/company にタブと連続ページが同居」
- 「PowerShell exit code バグ修正の着地が確認できない」
- 「HOLD 55 本は 1 つの連鎖」「DecisionCase 12 表 0 行」
- 「vLLM は契約にだけ残る」「DuckDB 研究ファイルは存在しない」「baseline は 20260718_03 で停止」
- 「Linux 移行は凍結リストに載っている」「解除前にできる範囲」の解釈（OWNER_INTENT §4・reform-program Gate 6・ODR-0038 の原文照合）
- 「TDnet 無料範囲は 31 日」「J-Quants Standard は 10 年」（出典 worklog/research の再確認）

反証役は結果を schema（`{claim_id, refuted: bool, evidence, confidence, note}`）で返す。

### 段階 2: HTML 執筆（親）

`D:\Dev\Investment_設計資料\現状総点検とLinux再構築計画_2026-09-15.html` を単一ファイルで執筆する。図は SVG インライン（オフラインで開ける）。CSS/JS はインライン。章立ては下記「レポート構成」。各章末に「オーナーが決めること」を番号付き選択肢（推奨先頭）で置き、最終章で統合する。数値は出典（文書名+日付 or file path）付き、未確認は明示。設計案の推奨は P1〜P3 の要点を親が統合し、相互の矛盾（例: P1 の agent.service と P2 の agent-worker は同じもの／P1 の nomic 維持案と P2 の bge-m3 並走案は「並走して選ぶ」に統一）を解消して 1 つの推奨に揃える。

### 段階 3: 完全性批評と整合検査（Workflow、読み取り専用）

- **完全性批評 3 名**（視点: 非技術者オーナーの読みやすさ／設計者としての抜け（例: 認証・秘密情報・Alembic・テスト戦略・監視・費用）／非交渉条件 7 項との整合）。指摘は `{section, issue, severity, suggestion}` で返し、親が反映。
- scratchpad スクリプトで機械検査: 章内リンク切れ 0、出典なしの数値段落 0、「未確認」章に未検証項目が転記されていること、非交渉条件 7 項が最終章の表に並ぶこと。

### 段階 4: 実表示確認（親）

ブラウザペインで HTML を開き、目次ジャンプ・図の描画・日本語の表示・横スクロールの有無を確認する。問題があれば修正して再確認。完成後、レポートの所在と「オーナーが決めること」の要約を会話で報告する。commit・PR・DB・Scheduler・通知は行わない。

## 再利用する既存資料（新規に調べ直さない）

- `Investment_設計資料/現状調査レポート_2026-08-10.md`（構成・規模の説明）
- `Investment_設計資料/DB基盤・DB設計調査レポート_2026-08-13.md`／`DB設計診断レポート_スキーマ編_2026-08-13.md`（Docker/PG 適合性、D-01〜D-15、7 原則、Linux 移設 Phase 3 案）
- `Investment_設計資料/機能目的台帳_2026-08-11.md`（機能ごとの目的と明確度）
- `Investment_設計資料/現状アップデートレポート_2026-09-07.md`／`統合現状評価と改善計画_2026-09-07.md`／`改善計画の実行報告と判断記録_2026-09-07.md`（9 月時点の現在地・原因分析）
- `docs/design/裁量投資判断OS_全体設計.md`（判断の閉ループ・情報モデル・安全境界。**新設計でも引き継ぐ思想の正本**）
- `docs/decisions/20260712-single-server-analytical-modular-monolith.md`／`20260712-decision-support-and-private-network-boundaries.md`（Linux 中核・private BFF・Tailscale・RPO/RTO の既存決定）
- `docs/research/20260906-advanced-analysis-candidates.md` §8（LLM とツール併用・PC 増設の既存検討）
- `docs/runbooks/local-llm-rtx-pro-5000-operations.md`（現行 LLM 構成）

## 検証（レポート完成の確認方法）

1. HTML をブラウザペインで開き、目次リンク・図の表示・日本語表示を目視確認。
2. 各「事実」に出典（文書名+日付、または file path）が付いていること、「未確認」が明示されていることを機械的に走査（scratchpad スクリプト）。
3. オーナー非交渉条件 7 項（発注禁止・BFF 経由・LLM 補助限定・Alembic・旧経路保持・ETF 除外・secrets）と推奨案の整合を最終章で明示。
4. 完全性批評エージェントの指摘ゼロ、または残指摘を「未確認」章に転記。

## 承認範囲の確認

- リポジトリへの変更なし（レポートは `Investment_設計資料` に置く）。commit / PR / DB / Scheduler / 通知は行わない。
- 実 DB・実 Scheduler・`.env` へは接続・読取しない。数値は既存レポート・worklog の記載値を出典付きで使う。
