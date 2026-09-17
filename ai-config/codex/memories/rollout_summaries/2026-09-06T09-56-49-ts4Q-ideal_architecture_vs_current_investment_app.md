thread_id: 01a07626-301e-7e40-b50f-549e9ef386f4
updated_at: 2026-09-06T10:06:32+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\09\06\rollout-2026-09-06T18-56-49-01a07626-301e-7e40-b50f-549e9ef386f4.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# ゼロベース理想構成と現状アプリの照合

Rollout context: D:\Dev\Investment。ユーザーは、現状を制約にしない理想アーキテクチャ案を、実際のリポジトリ実装と比較するよう依頼した。調査は読み取りのみで、コード変更・DB操作・画面の実動作確認は行っていない。

## Task 1: 理想アーキテクチャとの現状比較

Outcome: partial

Preference signals:

- ユーザーは理想論だけでなく「現状のアプリを照らし合わせて、比較してみて」と依頼した。今後は技術選定を提案する際、現行実装との差分、既存資産、未接続部分、置換コストを必ず分けて示す。
- 調査開始時に「今回は調査だけ行い、変更は加えません」と整理され、実際に読み取り調査のみを実施した。類似の相談では、設計・評価と実装を混同せず、変更前に比較結果を提示する。

Key steps:

- `OWNER_INTENT.md`、`docs/README.md`、製品全体設計、単一中核ホストADR、現行コード・依存関係・Desktop/API構成を確認。
- main は `9c6809e3f3cac9e73f534937e06d5898bc554380`。読み取りのみで、実行・DB・画面の正常性は未検証。
- 理想案と現状を、UI/API/DB/分析/検索/ジョブ/LLM/監視/データ lineage の観点で比較。

Failures and how to do differently:

- 「Temporalが必要」「現在は復旧機構がない」と単純化してはいけない。現状には決算AI用PostgreSQLキュー、lease、heartbeat、`FOR UPDATE SKIP LOCKED`、再試行、GPU待機、通知再試行がある。ただし、処理全体で統一された実行管理ではない。
- コードの存在を運用完成とみなしてはいけない。DecisionCase shadow は設定既定値が `False` で、実環境での有効化・一連の画面操作・性能・復旧は未検証。
- 理想案のECharts、Temporal、vLLM、専用Linuxホストへの置換が現行より優れるとは未証明。全面刷新より、共通計算・証拠 lineage・依存更新・実運用閉ループの完成を先に評価する。

Reusable knowledge:

- 現状は理想案の主要技術とかなり一致する。React/TypeScript/Vite、TanStack Query/Table/Virtual、Tauri、FastAPI/Pydantic/OpenAPI型生成、PostgreSQL/Alembic、DuckDB read-only、pgvector、OpenTelemetryがコード上確認できる。
- DesktopはFastAPI BFF経由でデータへアクセスし、Tauriはトークン・OS連携・ランタイム制御を担当する。`desktop/src-tauri/src/lib.rs` はDBや外部APIへ直接接続する構造ではない。
- 企業ページには集約読み取り、並列セクション取得、TTLキャッシュ、single-flight、ingest世代によるキャッシュ無効化がある。`tools/api/decision_api/read_aggregates.py` と `read_cache.py` が主要箇所。
- 決算AIは、決定論的な財務比較をvalue/unit/period/locator/binding_id付き観測値としてLLMへ渡し、入力hash・runtime profile hash・証拠・分析JSONをPostgreSQLへ保存し、APIとDesktop表示まで接続している。
- 最大の未完成点は、AI・画面・シナリオ計算が同じ統一財務snapshot/compilerを参照すること。`docs/design/financial-performance-compiler-spec.md` は `Target/Planned` で、`FinancialPerformanceCompiler.compile(event_id, analysis_cutoff)` は未実装。`OperatingProfitScenarioCompiler` は存在するが、今回の調査ではアプリ接続を確認できなかった。
- 全依存の差分更新も未完成。入力hashによる重複抑止はあるが、訂正資料から影響する計算・AI・表示を共通DAGで追跡する仕組みまでは確認できない。
- 根拠・時点・版管理の部品は存在するが、訂正後に過去の財務、仮説、保有情報、判断、振り返りを一式同じ状態で再現できることは未検証。
- 現在の処理基盤は Scheduler、独自ワークフロー、同一プロセスEventBus、決算AI専用キューに分散している。Temporal相当の機能は部分的にあるが、全体統一ではない。
- `pyproject.toml` 上、Polarsは限定的で、pandas・SQL中心の処理も多い。DuckDBはPostgreSQLをread-onlyで読む経路があり、理想案の版付きParquet中心の履歴分析構成とは異なる。

References:

- `docs/OWNER_INTENT.md` — 製品境界・正本・凍結方針
- `docs/README.md` — 文書正本の探索入口
- `docs/design/裁量投資判断OS_全体設計.md` — 判断閉ループと共通情報モデル
- `docs/decisions/20260712-single-server-analytical-modular-monolith.md` — 現行の単一中核ホスト・モジュラーモノリス方針
- `docs/design/financial-performance-compiler-spec.md:3-5,16,23` — 財務compilerはTarget/Planned、未実装
- `tools/decision_support/earnings_evaluation_assistant/agent_queue.py:82+` — lease回復・retry・GPU待機・SKIP LOCKED
- `tools/api/decision_api/read_cache.py` — TTL、single-flight、ingest世代によるキャッシュ無効化
- `tools/api/decision_api/read_aggregates.py:1620+` — company snapshot集約と並列読み取り
- `shared/decision_case_shadow_activation.py` / `shared/config.py:161` — DecisionCase shadowのfail-closed有効化、既定値False
- `desktop/package.json`、`desktop/src/components/shared/DataTable.tsx` — React/TanStack/Vite系の現行構成
- `infra/docker-compose.data-platform.yml` — PostgreSQL、OpenTelemetry Collector、LLM gateway等の現行構成

結論: 現在のアプリは「理想案から大きく遅れている」のではなく、技術スタックと重要な部品は既にかなり揃っている。差の中心は、新技術の不足ではなく、共通財務計算、証拠・版の一貫したlineage、訂正時の影響範囲更新、判断から振り返りまでの実運用接続、処理管理の統一である。
