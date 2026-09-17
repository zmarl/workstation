---
name: bugs_cross_audit_convention_false_positives
description: financial_facts_cross_audit の year_offset 誤検知2パターンと降格ルール実装 (6619/7202)
metadata: 
  node_type: memory
  type: project
  originSessionId: ae24642f-3458-49e6-bcbf-c3d78398485f
---

# cross-audit の年度オフバイワン誤検知2件と修正 (2026-07-11)

`tools/quality/financial_facts_cross_audit` 初回実行の critical 6件は全て EDINET DB(外部ソース)側の規約差による **誤検知**で、自前データは無破損だった。診断は生XBRL(`public.edinet_xbrl_facts`)・`raw.financial_reports`(全ソース)・`raw.edinetdb_financials_raw` の突合で確定。

## 2つの誤検知パターン
- **6619(W-SCOPE) source_year_label_shift**: 自前は period_end 年で採番(jquants/monex/edinet_xbrl の3ソース一致)、EDINET DB は同一実数値を全指標+1年ラベル。原因は W-SCOPE の決算期変更(12月末→1月末、移行6ヶ月期あり)で EDINET DB の年度導出が +1 ずれる。全5指標が offset -1 で厳密一致。
- **7202(いすゞ) concept_basis_mismatch**: 同一年 total_assets は一致(≤1%)、equity のみ相違。自前 fy2024=1,659,029百万=JGAAP純資産合計(NetAssets, fy2022も同概念で一貫)、EDINET DB=1,381,942百万=FY2025 IFRS有報の前年比較 `EquityAttributableToOwnersOfParentIFRS`(Prior1Year)。IFRS移行時の基準差。audit が year_offset 化したのは自前fy2025 IFRS親会社持分1,372,863が近接した偶然。

## 実装した降格ルール (comparator.py `_reclassify_conventions`, classify_pair 後段パス)
- 新 match_class 2つ(共に非critical): `concept_basis_mismatch`(info) / `source_year_label_shift`(warn)。`CRITICAL_CLASSES` は不変。
- Rule B(先)= equity の year_offset で同一年 total_assets が ≤REL_TOLERANCE 一致 → concept_basis_mismatch。アンカーは `CONCEPT_BASIS_ANCHOR_METRIC=total_assets`。
- Rule A(後)= 会社の year_offset が全て同一 ±1 offset かつ ≥2 metrics(`SOURCE_LABEL_SHIFT_MIN_METRICS`) かつ neighbour年が period_end 裏付け → source_year_label_shift。B を先に走らせ単独equityがA(多metric要件)に混ざらないようにする。
- period_end 裏付けは repository `fetch_ours_label_backed()` が `raw.financial_reports`(全ソース fq=4, `EXTRACT(YEAR FROM period_end)=fiscal_year`)から `set[(code,fy)]` を構築、`compare_datasets(..., ours_label_backed=)` へ注入。comparator は純関数維持。
- 真の our側フル企業オフバイワン破損は、そもそも neighbour が theirs と一致せず year_offset に到達しない(ours[fy]==ours[fy-1]になるため)。period_end 裏付けは追加ガード。

## 知見
- 6619 の edinet_xbrl fy2020/2021 正規化ファクトは `raw.edinet_xbrl_facts_raw`(lineage doc_id)由来で `raw.financial_reports` に edinet 行なし。だが同一(code,fy)の jquants 行が period_end 付きで存在するため会社レベル period_end 裏付けは全ソース union で取れる。
- EDINET DB(`raw.edinetdb_financials_raw`)は period_end が全NULL、12月/1月決算等 非3月企業で fiscal_year を +1 ずらす癖あり。IFRS移行企業では JGAAP純資産 と IFRS親会社持分 を年により混在させる不整合もある。
- 自前 equity 系列自体に JGAAP純資産合計→IFRS親会社持分 の定義段差(移行企業横断)。抽出器の equity 概念選択ポリシー変更は全銘柄影響で別タスク。
- 検証: ruff + `pytest tests/tools/quality/`(1311 passed) + 実DB再実行 critical=0(source_year_label_shift=5 / concept_basis_mismatch=1, value_mismatch は425不変) + file_size_budget緑(comparator 466行<800)。
