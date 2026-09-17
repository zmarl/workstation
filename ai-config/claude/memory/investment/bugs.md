---
name: bug-fixes-knowledge
description: PostgreSQL移行後のバグパターンと修正方法。DuckDB→PostgreSQL非互換、FK制約、ビュー再定義の知見。
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c6f4640f-3d7f-4bb0-8788-5eeb02128b35
---

## PostgreSQL DDL 非互換パターン

### `DOUBLE` 型
- **問題**: PostgreSQL に `DOUBLE` 型は存在しない
- **修正**: `DOUBLE PRECISION` に変更
- **発生**: global_equity_tracker/repository.py 他
- **注意**: earnings_ranking, pts_ranking, tradingview, signal_experiment_codex にも残存（既存テーブルあるため未発火）

### `INTERVAL 1 DAY` 構文
- **問題**: DuckDB構文。PostgreSQL では不正
- **修正**: `INTERVAL '1 day'` に変更
- **発生**: rates_tracker/repository.py

### `CREATE OR REPLACE VIEW` でカラム順序変更
- **問題**: PostgreSQL の `CREATE OR REPLACE VIEW` はカラム名/順序変更不可
- **修正**: `DROP VIEW IF EXISTS ... CASCADE` + `CREATE VIEW`
- **発生**: flow_tracker, commodity_tracker（他の mart.vw_* も潜在的リスクあり）

## Ingest Tracking の FK 制約問題

### `record_raw_ingest_error` FK violation
- **問題**: 一部ツール（boj_tracker, rates_tracker 等）が run_id 生成後 start_raw_ingest_run() 前にエラー発生 → ingest_errors INSERT で FK violation
- **原因**: ingest_runs にレコードが未登録の状態で ingest_errors に INSERT
- **修正**: record_raw_ingest_error 内で INSERT ... ON CONFLICT DO NOTHING でミニマル run レコードを事前作成
- **パターン**: execute_with_tracking() を使わないツールで発生しやすい

### consensus_collector の run_type=None
- **問題**: `run_type=None if run_type == "ingest" else run_type` で明示的に None を渡す
- **原因**: Python のデフォルト引数は明示的 None で上書きされる
- **修正**: `"incremental" if run_type == "ingest" else run_type`

## スケジューラ exit code 65

### SUCCESS_MISMATCH 検出
- **仕組み**: `run_tool.ps1` が Python exit 0 でもログに Traceback/status=failed を検出 → exit 65 に書き換え
- **主要原因**: `psycopg_pool.PoolTimeout` (30秒) — 同時実行タスクが PostgreSQL 接続上限に到達
- **対策候補**: タスク開始時刻のスタガリング、PostgreSQL max_connections 増加、PgBouncer 導入

## flow_tracker fetchone() 問題

- **問題**: INSERT ... SELECT の結果に `.fetchone()[0]` を使用 → PostgreSQL で "last operation didn't produce records"
- **原因**: INSERT は RETURNING 句なしでは結果行を返さない
- **修正**: `.rowcount` プロパティを使用

## FRED CSV エンドポイントの UA ブロック

- **問題**: `fredgraph.csv` が Chrome User-Agent (`Chrome/123.0.0.0`) のリクエストを無期限タイムアウトさせる
- **原因**: FRED がブラウザ模倣 UA を検知してブロック（IP ブロックではなかった）
- **修正**: FRED リクエスト専用の `FRED_HEADERS: dict[str, str] = {}` を定義し、デフォルト httpx UA を使用
- **発生**: rates_tracker, macro_tracker, commodity_tracker, global_equity_tracker, sentiment_tracker
- **注意**: 空辞書 `{}` は Python で falsy → `headers or DEFAULT_HEADERS` ではなく `DEFAULT_HEADERS if headers is None else headers` を使用

## BOJ API 日付フォーマット

- **問題**: `getDataCode` API の STARTDATE/ENDDATE が daily 頻度でも `YYYYMM` を要求
- **原因**: `date_to_boj_param()` が daily に `YYYYMMDD` を返していた → 400 エラー
- **修正**: daily フォーマットを `YYYYMM` に変更（`ingest_helpers.py`）

## tdnet strategy_metrics 重複キー

- **問題**: CTE クエリが `(code, period_end, metric_key)` の重複行を生成 → PK violation
- **修正**: `ON CONFLICT DO UPDATE` を追加

## improvement_backlog UUID 型不整合

- **問題**: DDL で `task_id UUID` だが、アプリコードが VARCHAR で INSERT → 型エラー
- **修正**: INSERT に `?::uuid` キャスト追加、sync 関数で条件付き uuid/text キャスト

## Business Model anchor: 9783 ベネッセ 上場廃止 (2026-05-17)

- **問題**: `scripts/load_disclosure_kpi_samples.py` SAMPLE_MAPPINGS の education_services anchor が 9783 ベネッセ HD だったが、同社は **2024-02-22 EQT/福武家 MBO 完了で東証上場廃止**。新規 disclosure ingest が事実上停止しており anchor 健全性が劣化
- **修正**: 9783 を SAMPLE_MAPPINGS から撤去し、education_services pack の代替 anchor として **4668 明光ネットワークジャパン** (`4668_meiko_network_2025q3.json`, 5 metrics) を採用。既存 9783 sample JSON は参考用に保持
- **教訓**: Business Model anchor は MBO/TOB/上場廃止イベントの影響を直接受ける → anchor 健全性チェックに上場区分監視を加えるべき (フォローアップ)


## .bat 生成時のバックスラッシュ  破損 (2026-07-04、2セッションで同一再発)
- **問題**: Python/heredoc 経由で Windows パス入り .bat を生成すると `\scriptsun_tool.ps1` の `` が CR に化け `.\scripts` + 改行 + `un_tool.ps1` になる。scheduler wrapper 8 本がこの状態でコミットされ、run_tool 委譲が最初から壊れていた（別セッションも同じバグで再現）
- **原因**: bash heredoc → Python の二重エスケープ層で backslash が 1 段崩れ、`` がエスケープ解釈される
- **解決**: バックスラッシュは `chr(92)` で合成し `write_bytes(content.encode('ascii'))` で書く + 書き込み直後に `run_tool.ps1 in text` を assert。テスト tests/scripts/test_scheduler_run_tool_wrapper_contract.py が恒久ゲート

## CREATE TABLE IF NOT EXISTS 方式 migration の「適用済みだが列なし」乖離 (2026-07-09)
- **問題**: raw.delist_disclosure_events に event_key 列が無く tdnet_delist_monitor が毎日 failed。migration `20260517_02` は event_key を定義済みで alembic 上も「適用済み」
- **原因**: 本番に旧形テーブルが先に存在し、`CREATE TABLE IF NOT EXISTS` が空振り。revision は適用済み記録になるため以後自動修復されない。`CREATE INDEX CONCURRENTLY` 中断→invalid index→pg_dump 非出力→baseline 欠落 (estat 3本) も同族
- **解決**: head の後ろに ALTER TABLE ADD COLUMN + バックフィル + index の新 revision (`20260709_01/02`)。新規テーブル migration でも IF NOT EXISTS に頼らず、既存環境との乖離は「列単位の ALTER」で塞ぐのが正道

## stuck_task_detector が timeout_minutes:0 の常駐 serve を 120 分で誤 force-fail (2026-07-09)
- **問題**: news-detector-serve (720分常駐、ingest_runs 行を1本保持) が毎回 elapsed 125m で force-fail
- **原因**: `_load_timeout_map` が timeout>0 のタスクだけ登録 → 無制限タスクはデフォルト 120 分に落ちる。source_name (news_detector) も manifest に未紐付けだった
- **解決**: timeout 0 は `UNLIMITED_TASK_TIMEOUT_MINUTES=1440` にマップ + manifest に `source_names: [news_detector]`。常駐 serve 系タスクを新設するときは source_names 紐付けを忘れない
