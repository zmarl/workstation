---
name: project-functional-completeness-audit-2026-07-15
description: 機能不完全性の批判的監査完了 (2026-07-15)。確定所見96件・P0 6テーマ。正本は docs/audits/20260715-functional-completeness-audit.md
metadata: 
  node_type: memory
  type: project
  originSessionId: 504daa89-c939-480b-a50b-8bfb6e3d0dba
---

# 機能不完全性 批判的監査 (2026-07-15 完了・調査のみ)

**正本**: `docs/audits/20260715-functional-completeness-audit.md`（1,131行）。10領域×調査エージェント＋全所見の反証検証（79体）。CONFIRMED 96 / PLAUSIBLE 2 / REFUTED 2。7/12 バックログ50項目の照合表を第13章に収録（消化1・main側2・部分13・未着手32・悪化2）。

## P0（監査時点で進行中の実損）
1. **PostgreSQL インデックス物理破損**で financial_unifier が 7/11 から5日連続 failed（posting list tuple / mergejoin order エラー）。財務統合正本が 7/10 凍結、下流（xbrl_dimension/segment/coverage）連鎖停止。**コード修正では直らず REINDEX 必須**。
2. **バックアップ空白**: 800GB DB の最新 dump は73日前の手動1本（同一Dドライブ上）。
3. **統治分裂**: 実運用ツリー（feat/hidden-asset-screener）が origin/main から208コミット遅れ（3日で倍増）+ 未コミット969ファイルが本番稼働中 + **alembic チェーンが二又フォーク済み**（20260713_01 から本ツリー系と main 系に分岐）。main 着地済みの修理が本番で走っていない。
4. HV二重年率換算（#5）未修正のまま 377〜451% の不可能値を毎日保存・配信（market/company 両経路）。
5. consensus EPS 史上未取得（全4ソース43,127行 NULL）→ 改定パイプライン69,309行が全件偽中立 'flat'。F.6 は史上候補0件。
6. EDINET 正規化凍結が5ヶ月目（2/22〜）。

## 新発見の重要バグ（メモリ未記録だったもの）
- **run_tool.ps1 の Start-Process ExitCode null 罠**: ツールの実 exit code が一度も伝搬したことがない（7日5,761 runlog の非ゼロは wrapper 付与 65/66/124/1 のみ）。失敗検出は SUCCESS_MISMATCH regex 頼み。修正は Handle キャッシュ or `&`+`$LASTEXITCODE`。
- **run_tool.ps1 が safe_args/live_args を無視**（args キーのみ読む）: sub_sector_classifier / company_theme_classifier が毎週引数ゼロ起動→argparse 即死（0.9秒）→DONE 偽装。サブセクター再計算1ヶ月停止の真因。
- 7/14 実装群（decision-list-refresh 等）は DDL 未適用（20260714_01/04）・スケジューラ未登録・未コミットの三重不通電。exit-monitor エスカレーションも verified_exit_signals 不在で死亡。
- thesis_health_snapshots: detail 列不在で3ヶ月凍結（4/17 のスキーマ移設時に detail 無し DDL で確定）。
- decision_runner UniqueViolation 全滅・sizing は insufficient_history VaR で FREEZE 固定・guardrail は producer 不在 no_data hold（かつ hold を誰も読まない fail-open）→ 判断段史上ゼロの真因はバグ連鎖。
- mm_signal_reviews リターン充填ジョブは存在するが日本語 SQL リテラルの UnicodeDecodeError で8週沈黙（#20 の実態訂正）。
- ops.alert_events スキーマ不一致で全行フォールバック書込（priority/channel/dedup 全損）。
- qwen3.5:9b が 7/6〜7/15 の9日半 404、監視タスクは検知しつつ緑終了（fail-open）。7/15 22:23 に別セッションが復旧。

## 検証パスの教訓
- 前回同様 stale/誇張の訂正が多発（P0→P1 降格4件、REFUTED 2件）。反証検証パスは必須。
- 「監査当夜に別セッションの修理が並行」があり得る。実測時刻を所見に残すこと。

## Handover
- Task Registry 登録候補18件（監査ドキュメント第14章）。登録は未実施。
- 監査ドキュメント自体が未コミット（untracked）。
