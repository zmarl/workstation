---
name: TDNet disclosure_feed 空問題（2026-04-18 発見）
description: tdnet_disclosure_feed テーブルが 0 件で下流のみデータがある異常状態。上流 ingest が止まっている可能性があり、TDNET KPI gate 3件の停止解除の根本ブロッカー
type: project
originSessionId: 1c5a8336-52b6-4f3a-bc98-466fa9c828b1
---
2026-04-18 の停止機能棚卸し調査で発見された上流パイプライン問題。

**現状**:
- `raw.tdnet_disclosure_feed` テーブルが **0 件**（空）
- 一方 `tdnet_earning_report_feed` は 1421 件、`tdnet_earning_section_feed` は 2179 件ある
- `tools.quality.tdnet_data_quality.main` の診断が watch item として `disclosure_feed_empty_with_downstream_rows` を報告
- KPI-01 asset_capture_rate は直近 5 営業日で **0%**（target 99.5%）。母集団は 88〜175 件ある
- ただし pending assets backlog は解消済み（pending_total: 0, pending_stale: 0）

**影響**:
- TDNET KPI strict gate は 5 営業日連続達成が必要だが、feed 空のため観測値が積めず、無期限で再開不可
- `tdnet-kpi-dashboard-daily` / `tdnet-kpi01-gate-daily` / `tdnet-resolve-pending-assets-daily` の 3 件は run_manifest の disabled_tasks に残したまま

**Why**: 停止中機能の棚卸しで判明した外部要因。事業継続性や意思決定支援の一部（開示カバレッジ）にも影響が及ぶ可能性がある。

**How to apply**:
- TDNET 関連の再開判定を求められたら、まず disclosure_feed の件数を確認する
- 復旧の最初のステップは `tools.notifications.tdnet.main --dry-run` を実行し、feed 取得ロジックが動くかを見ること（診断ツールの推奨アクション）
- 本問題は棚卸しスコープ外として別タスク扱い。優先度判断はユーザー指示を待つ

**Update 2026-04-18**: `uv run python -m tools.notifications.tdnet.main --dry-run` を単発実行した結果、Yanoshin API から 2703 件を正常取得し `tdnet_disclosure_feed` に正しく保存（4/1-4/17）。つまり feed 取得ロジックは正常で、空だった原因は scheduled BreakingServe が 2026-04-15 に死亡した後、watchdog 側の bug（read_epoch PowerShell エスケープ衝突、`bugs_tdnet_watchdog_escape.md` 参照）で再起動できていなかっただけ。復旧は「手動 dry-run で feed 初期化」→「watchdog fix 済みの状態で月曜 scheduler 起動を待つ」で足りる。KPI gate 3 件の再開は 5 営業日連続の観測データが貯まってから判断。
