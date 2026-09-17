---
name: project-business-model-phase18
description: Business Model Phase 18 (2026-05-17) loader_smoke failed=31→0 完全解消 + regression gate 化 + alembic 2 head merge (Phase 17 申し送り #1/#2/#9 同時消化)
metadata:
  type: project
  originSessionId: phase18
---

# Business Model Phase 18 (2026-05-17)

Phase 17 で audit に組み込んだ loader_smoke が baseline `imported=157 / failed=31 / exit_code=1` を可視化していたが、gate 化されておらず regression を検知できなかった。Phase 18 は **31 件全件を pack YAML + alembic seed 同期で解消** し、`--with-loader-smoke` を `failed > 0 → exit 1` に gate 化した。Phase 17 申し送り #1 (gate) + #2 (sample 修正) + #9 (alembic 2 head) を同セッションで完走。

## 着地サマリ

| 指標 | Phase 17 完了 | Phase 18 完了 |
| ---- | ------------- | ------------- |
| loader_smoke.failed | 31 | **0** |
| loader_smoke.imported | 157 | **172** |
| audit `--with-loader-smoke` exit | 1 (gate なし) | **failed=0 → 0、>0 → 1** |
| alembic heads | 2 (申し送り #9) | **1** (b4688d6d7aee) |
| pack YAML 編集 | — | **18 pack / 70+ metric** |
| core.metric_catalog 新規 seed | — | **28 行** |
| audit pytest | 4 ケース | **5 ケース** (gate 2 追加 + Phase 17 baseline 1 更新) |

## Wave 構成

- **Wave 0**: audit 実走で 31 件全部が V1 violation (= pack に未定義の業界共通財務指標を使用) と判明。当初想定の「複合 dispatch 22 + 既存 9」シナリオは誤りで、実態は Phase 6-14 anchor sample が `operating_margin` / `segment_op_margin` / `overseas_revenue_ratio` 等の汎用指標を使っていた。
- **Wave A〜D (4 並列)**: 18 pack YAML に metric_key 追加 (Wave A=ec/platform/saas/gaming、B=auto/parts/conglomerate/electric_equip、C=trading/leasing/pharma、D=oil/glass/nonferrous/shipping/logistics/telecom/electric_power)。
- **Wave E (直列)**: 28 件 core.metric_catalog seed + 2 head merge + audit gate + test + ruff + 文書。

## 重要な発見

- **pack YAML 修正だけでは silent fail が残る**: pack validation を通過しても `core.metric_catalog` の seed が無ければ `ensure_catalog_ready` で弾かれる。Phase 16 Wave A、Phase 18 ともに **「pack + alembic seed + SAMPLE_MAPPINGS の 3 点セット」が同一 PR で揃わないと再発** することを 2 度確認。CLAUDE.md の MUST 規約に「seed migration 同梱」を明示追記する案を Phase 19 で検討。
- **`alembic_version` テーブルの 2 行残存問題**: Phase 17 closeout 時点で `20260518_18` と `20260517_05` の 2 行が DB current に残存していたが、実は前者が後者の祖先関係。前者を削除して single current に修復することで alembic upgrade head の overlap エラーが解消。同様の状態が再発したら DELETE で復旧可能。
- **`metric_group` CHECK 制約**: pack YAML で使われる `quality` は metric_catalog の CHECK 制約 (許可: balance_sheet / capital_policy / cash_flow / cashflow / efficiency / financial / guidance / monthly / orders / other / sector) に含まれない。Phase 18 seed では `quality` → `other` に振替。pack YAML 側は `quality` のままで OK (別レイヤー)。
- **regression gate の許容範囲**: `failed > 0` のみで exit 1。`exit_code=-1` (loader script not found) は許容 (deploy/env 問題で別レイヤーが拾うべき)。これにより既存テスト `test_with_loader_smoke_handles_missing_loader_gracefully` も互換維持。

## Phase 18 申し送り

1. **新規 pack 追加時の 3 点セット同期**: CLAUDE.md MUST 規約に「pack YAML / alembic seed / SAMPLE_MAPPINGS を同一 PR で揃える」を明示追記 (Phase 19 P0 候補)。
2. **`alembic_version` 週次 sanity**: 「DB current 行と alembic head の整合」検出 audit (`tools/quality/alembic_head_sanity/` 新設) を Phase 19 候補。
3. **Phase 17 申し送り #3〜#8 は未着手** (cosmetics 命名統合 / yoshinoya 重複 sample / IndustryFrameworkTabStrip 50+ 拡張 / J-REIT surface 取り込み / probe ハング本格対策 / 複合 dispatch 実機検証)。
4. **operating_margin 等の DB seed 競合**: linter による自動修正で seed migration に既存 metric が追加される事象あり。ON CONFLICT で無害だが、新規 28 件のみリスト化する運用が綺麗。

## 触ったファイル

- pack YAML: 18 ファイル (ec, platform_marketplace, saas_metrics, gaming_entertainment, auto, automotive_parts, industrial_conglomerate, electric_equipment, trading_house, leasing_consumer_finance, pharma, oil_gas_refining, glass_ceramics, nonferrous_metals, shipping, logistics, telecom, electric_power)
- alembic 新規: `20260518_20_phase18_cross_pack_metrics.py` (28 seed) / `20260517_b4688d6d7aee_phase18_merge_heads.py` (2 head merge)
- audit gate: `tools/quality/business_model_catalog_audit/main.py` line 167-180 + 204-211
- tests: `tests/tools/quality/business_model_catalog_audit/test_loader_smoke.py` (gate test 2 追加 + Phase 17 baseline 1 更新)
- ruff: `pyproject.toml` per-file-ignores に `db/alembic/versions/*` の E501 ignore 追加

## 関連 memory

- [[project-business-model-phase17]] — 前フェーズ着地サマリ
- [[project-business-model-aggregator-catalog-gap]] — 2026-05-14 時点で pack/aggregator 同期問題の元祖
- [[bugs-business-model-probe-hang]] — Phase 17 申し送り #7 (Phase 18 未着手)

## Worklog

`docs/worklogs/20260517-business-model-phase18-loader-smoke-gate.md`
