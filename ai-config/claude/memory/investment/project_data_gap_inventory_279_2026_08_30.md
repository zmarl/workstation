---
name: project-data-gap-inventory-279-2026-08-30
description: 欠損調査の起点は raw.ingest_runs (114 source) ではなく run_manifest の active タスク (279) に置く。2026-08-30 の全数棚卸し手順と結果
metadata: 
  node_type: memory
  type: project
  originSessionId: 4536797c-cfe8-41ab-8cb0-896ec79630fc
  modified: 2026-08-30T10:22:23.444Z
---

2026-08-30 に実施した**データ欠損の全数棚卸し**。**起点をどこに置くかで視野が 4 割に縮む**ことが実測で判明した。

**視野の問題（investment-22 の実測）**: run_manifest の active タスク **279** に対し、
`raw.ingest_runs` に現れる distinct source_name は **114**。**ingest run を記録しないツールは、
欠損調査の網に最初からかからない**。実際 `telemetry_alert_runner` の欠陥は狙って見つけたのではなく、
別軸（cursor+`?` の機械捜索）で偶然踏んだ。

**採るべき手順**（この順で二分する）:

1. **run_manifest の 279 active タスク**を起点にする（`scripts/run_manifest.yaml`、
   各 task に `module` / `source_type` がある）
2. 各パッケージが**コード上 ingest run 経路を持つか**で二分 —
   `raw_ingest_tracking` / `start_raw_ingest_run` の参照有無。**2026-08-30 実測: あり 168 / なし 111**
3. **経路あり**: `start_raw_ingest_run` 呼び出しを **AST で**拾い、宣言 source 名を
   `raw.ingest_runs` の全期間 distinct source（**139**）と厳密照合。
   grep のファイル単位一致では判定できない（`run_note=` は 33 ファイルに出るが、
   誤用は 1 箇所だけだった）
4. **経路なし**: **書き込み先テーブルの鮮度**で生存確認する。
   さらに「外部到達するか」（`httpx|requests|urllib|selenium|yfinance|jquantsapi` 等の参照）で
   二分すると、**記録すべきなのにしていない 20 / 派生計算だけなので記録不要 91** に分かれた
5. **鮮度が古い／0 行のものは、まず manifest の `disabled_tasks` と `disable_reason` を引く**。
   意図的な HOLD がかなり混ざる（例: `dqi-daily-scoring` は `disabled_since: '2026-08-11'` で、
   `analytics.dqi_daily` の最終 `scored_date` と完全一致。**これは白**）。
   これを先に引かないと偽陽性を量産する。
   同様に、**発注しない方針の下では「保有前提の分析が 0 行」は正常**（`core.orders` 0 行など）

**2026-08-30 の結果**:

- 経路あり 168 → 確定欠陥 **1 件のみ**（`anomaly_calendar`。PR #286 で修理）
- 動的 source 名で静的判定できない 73 → **新たな欠陥なし**。
  逆照合（DB の実 source 名からタスクへ）で 13 件が「該当なし」と出たが、
  **11 件は監査・ダッシュボード系で記録不要が正しく、`rating_scraper` は
  `source_name="ratings"` で 118 件記録済み**（トークン照合が `rating`≠`ratings` で偽陽性を出した）
- 経路なし 111 のうち外部到達 20 → **書き込み先が 0 行のもの 2 系統**:
  - **`attribution` 2 タスクが毎週 `UndefinedTable: relation "core.sizing_results" does not exist`
    で FAILED していた**（2026-08-30 12:30 の実ログで確認）。`disabled_tasks` には無く
    `scheduler_binding: optional` で実際に走っている。参照先の `core.sizing_results` と
    `core.execution_quality` が存在しない（`core.tranches` は 145 行ある）。
    **runlog に FAILED / RECOVERY_HINT / RERUN_COMMAND まで出ているのに誰も見ていない**——
    「大きく失敗していても、記録経路が無ければ視野の外」の実例。
    修理は実約定・執行品質のテーブル新設（Alembic）を伴い、発注を扱わない方針との距離が近いので
    **オーナー判断事項**（使うのか退役させるのか）として止めた
  - `reg.company_reg_exposures` / `reg.regulation_provisions` が 0 行
    （law_tracker の他テーブルは 8/24〜8/29 と新しく、ツール自体は動いている）

**照合スクリプトは使い捨てで良い**が、上記 4 段の**二分の仕方**が再利用価値のある部分。
関連: [[project-observability-failure-taxonomy]] / [[project-weekly-audit-otel-silent-stop-2026-08-30]]
