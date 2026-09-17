---
name: project-hv-double-annualisation-fix-2026-07-18
description: "HV二重年率換算バグ修正 (07-18)。コード修正・本番DB修復・PR #60 マージまで完了。jsonb ?演算子/hermetic skip/絶対日付fixture の知見あり"
metadata: 
  node_type: memory
  type: project
  originSessionId: b0d667c3-9aea-4ab1-9a2a-0d1823d2545b
---

# HV二重年率換算修正 (2026-07-18 完了 — PR #60 は 07-18 21時にマージ済み)

監査所見 4-1（P0）の解決。[[project-functional-completeness-audit-2026-07-15]] の残P0から着手。
経緯: 07-18 昼のセッションでコード修正+本番DB修復、PR #60 は OPEN のまま数時間放置 → 夕方に並行セッションが hv-landing worktree で着地、07-18 21:00 頃マージ完了（[[project-repo-state-repair-backlog-2026-07-18]] セッションが確認）。注意: PR #60 は worklog md 追加に対し docs/research/registry.yaml の expected_managed_markdown_count を更新せずマージされ、main の docs_research_registry check を一時赤にした（PR #75 で修復）。

- **単位契約**: `fs_price_features.volatility_20d/60d` は**年率化済み小数**（daily std×√252、0.238=23.8%）。volatility_regime 側の閾値・atm_iv・vix は**整数%表記** → 変換は ×100 のみ。√252 再適用が377〜451%の不可能値の原因だった。
- 本番 `analytics.volatility_regime_daily_history` 9行を算術逆変換で修復済み（`WHERE hv>100` ガードで冪等、payload_json に修復印 `hv_unit_repair_20260718`）。修復後 23.8〜28.6%。
- 正本記録: docs/worklogs/20260718-hv-double-annualisation-fix.md

## 再利用可能な知見

- **`shared.db.pool` の `?`→`%s` 変換は jsonb の `?` 演算子も壊す** → jsonb キー存在チェックは `jsonb_exists(col, 'key')` を使う。
- **db+requires_db マークのテストは通常環境では skip され hermetic gate でのみ実行される**。「単独実行で pass」に見えても skip の誤読があり得る。切り分けは `run_local_pytest.py --profile focused --test-path ...`（hermetic 同条件の単一ファイル実行）が有効。
- **テスト fixture の絶対日付＋staleness窓は日付ロットで将来必ず割れる**（ops_hub の 2026-03-20+120日がちょうど 07-18 に期限切れ）。相対日付（now−N日）で書く。

## Handover（解決済み）

- ~~screening serving テスト5件が素の main でも hermetic gate で red~~ → **07-18 PR #75（app refresh）で修正済み**。main で 0 fail を確認。
