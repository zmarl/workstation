---
name: bugs-consensus-collector-starvation
description: コンセンサス収集が2026-06-09から4週間沈黙停止（success+no_data=200で監視素通り）。ETF混入×NULLS FIRST×420秒タイムアウトの複合飢餓。2026-07-05修理
metadata: 
  node_type: memory
  type: project
  originSessionId: a89ee46f-c16c-4af8-bf52-772b55e76059
---

# コンセンサス収集 飢餓障害（2026-07-05 修理済み）

- **問題**: `raw.consensus_snapshots` が 6/9 から新規0行なのに、`consensus-collector-daily` は毎日 success（note `no_data=200`）。consensus_revision / expectation_gap のコンセンサス脚が全部空振り
- **原因**（3複合）: (1) 銘柄選定が instrument_policy 未適用で ETF等702行が混入、(2) 優先順位 NULLS FIRST で「一度もデータがない銘柄」が毎日の枠200を恒久占有、(3) `--source-timeout-seconds 420` で毎日先頭の同じ約200ペアだけ試して打ち切り
- **解決**: `_filter_policy_eligible_codes`（フィルタ→上限の順序が重要）+ NULLS LAST + manifest で catchup 無制限/タイムアウト6h（全対象約3.8k銘柄を毎日一巡）。worklog: `docs/worklogs/20260705-consensus-collector-starvation.md`

## 診断の教訓
- 「バッチだけ全滅・単発は成功」→ 選定リストの中身を最初に見る（コード形式・ポリシー除外対象の混入）
- `no_data=N` の N が毎日同じ値 → タイムアウト/枠による打ち切りシグネチャ
- 「success + 出力0件が連続」は governance で warning 化すべき残課題

## 追補 (2026-07-09): 優先レーンの死亡カバレッジ占有を修正
- 7/5 の全銘柄一巡で約2,000銘柄回復（1,978行保存）したが、初回一巡は 480分タスクタイムアウト超過で stuck_task_detector に強制終了された（定常状態では約4.3hで収まる）
- 7/6-7/8 観測: 優先レーン（毎日更新枠）が「4月に一度取れて以後死んだ」銘柄に占有され no_data=200/日
- 修正: 優先レーンを「直近30日に取得成功実績がある銘柄」に限定（0/16→5/5成功）。死亡・未カバーは無制限 catchup 掃引の担当。全滅時は旧順序へフォールバック。コミット 1f018639
- 定常設計: 生存銘柄は優先レーン(毎日100)+catchup(3日周期)で更新、未知銘柄は catchup 掃引で発見（実測1-2件/日）

## 残課題
1. **consensus_eps は史上未取得**（raw 3.6万行全て null、IFIS パーサが EPS 非抽出）→ consensus_revision の EPS 追跡は依然空。EPS 抽出追加 or op_income ベース化の二択
2. カバレッジ死亡銘柄の attempt 履歴永続化（現在は無制限 catchup で無害化）

関連: [[project-analytics-accuracy-202607]] [[reference-product-policy-adr]]
