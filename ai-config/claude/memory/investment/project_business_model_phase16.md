---
name: project-business-model-phase16
description: Phase 16 Business Model 図解カバレッジ最大化拡張 (2026-05-17 着地)。framework 65→73、sample +40、panel +8、複合 dispatch 基盤完成
metadata: 
  node_type: memory
  type: project
  originSessionId: 617eb7a9-3c16-49a0-94cb-11f0e1550730
---

# Phase 16 着地サマリー (2026-05-17)

Phase 15 ([[project-business-model-phase15-final]]) で達成した available
68 + audit clean を起点に、**超大規模並列 (15+ 並列・複数 wave 連結・全方位
拡張)** で着地。worklog: `docs/worklogs/20260517-business-model-phase16-final.md`。

## 数値

| 指標                            | Phase 15 終了 | Phase 16 終了 |
| ------------------------------- | ------------- | ------------- |
| framework 数 (wired_and_seeded) | 63            | **71** (+8)   |
| sample 数 (official)            | 147           | **187+** (+40) |
| Desktop panel                   | 既存          | +8            |
| 複合 dispatch 実証銘柄          | 0             | **3**         |
| Phase 16 新規 framework available | -             | 0/8 (Phase 17 課題) |
| pytest (business_model)         | -             | 949 passed / 0 failed |
| ruff / Desktop typecheck        | -             | clean / pass |

## Wave 構成 (5 wave 連結)

- **Wave A** (8 並列 + 1 直列): 新規 8 framework (`apparel_brand` /
  `airport_operator` / `it_services_integrator` / `fitness_amusement` /
  `funeral_services` / `nursing_care_services` / `bridal_services` /
  `printing_services`)。builder + pack YAML + sample + alembic seed + aggregator
  配線。8 sibling head は `20260518_16a_merge_wave_a` で single head 復帰。
  contract test 40/40 pass。
- **Wave B** (10 並列): 既存 20 framework に 40 sample 新規作成。SAMPLE_MAPPINGS
  に 36 entry 追加 (4 件 code 重複で skip)。loader 34/36 success
  (2 件 9401/9409 は alembic 進行後解消)。
- **Wave C** (8 並列): Wave A 対応 Desktop panel 8 新規。共通
  `BusinessModelMetricsSection` 再利用、Fast Refresh 対応。typecheck pass /
  vitest 40/40 pass。
- **Wave D** (1 直列): SAMPLE_MAPPINGS schema を `dict[str, list[tuple]]` に
  拡張、3 銘柄 (3231 / 4680 / 6752) を複数 framework entry 化。
- **Wave E** (2 並列): audit / probe / pytest / ruff / Desktop typecheck +
  vitest。

## 重要な発見

- **aggregator は既に複数 framework dispatch 対応済み**。Phase 17 で aggregator
  改修は不要、SAMPLE_MAPPINGS schema 拡張のみで複合業種が動く。
- **printing_services agent が `desktop/src/lib/types/company.ts` を併走更新**
  していた。他 7 agent は panel 側のみ。Phase 17 では Wave A sub-2 に
  `company.ts` 更新を含める運用に。
- **SAMPLE_MAPPINGS schema 拡張** (`dict[str, list[tuple]]`) で後方互換は
  `_normalize_mapping_entries()` が list/tuple 自動判定して既存 entry を
  `[entry]` で wrap。
- **Phase 16 新規 8 framework は available 0/8** (全 partial)。`has_segment_groups
  =False` で available 判定未達 (`metrics_count ≥ 2 AND has_segment_groups`)。
  Phase 17 で `analytics.segment_financial_facts` 投入で available 化する。
- **9401 / 9409 loader fail は alembic 進行順依存**。merge 適用後の再走で解消。
  Phase 17 で「alembic upgrade head → loader 再走」を SAMPLE_MAPPINGS 編集後の
  標準手順に。

## Phase 17 申し送り

1. 新規 8 framework × 6 銘柄 (8227 / 9706 / 4680 / 6184 / 2418 / 7912 +
   2374 / 9613) に `segment_financial_facts` を投入し partial → available 化
   (`scripts/load_segment_facts_samples.py` パターン)。
2. 残り 8 銘柄複合 dispatch sample 本実装: 7974 任天堂 / 9433 KDDI / 9984 SBG /
   4755 楽天 / 8058 三菱商事 / 3382 セブン&アイ / 4661 OLC / 9020 JR 東日本。
3. Desktop CompanySnapshot で複数 available framework のタブ切替 / 同時表示 UI。
4. catalog audit に loader smoke step を組込 (Phase 15 申し送り 1)。
5. 8951 j_reit surface 取り込み方針決定 (Phase 15 申し送り 4)。
6. pack YAML + alembic seed の同 PR pre-commit hook (Phase 15 申し送り 5)。
7. `cosmetics_retail` framework と `cosmetics_toiletries` pack の命名揺れ統合。
8. 重複 sample `9861_yoshinoya` 2 ファイルの統合判断 (複数期展開か最新期のみか)。

## 関連

- [[project-business-model-phase15-final]] (Phase 15 申し送り元)
- [[bugs-business-model-probe-hang]] (probe 5分ハングは DB DDL ロックが真因)
- [[project-business-model-aggregator-catalog-gap]] (aggregator 配線不備の
  根本問題、Phase 8 で解消)
- worklog: `docs/worklogs/20260517-business-model-phase16-final.md`
- Phase 15 worklog: `docs/worklogs/20260517-phase15-final.md`
