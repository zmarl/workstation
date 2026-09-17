---
name: project-business-model-phase17
description: Business Model 図解 Phase 17 (2026-05-17) で 新規 8 framework の available 条件緩和 + 複合 dispatch 8 銘柄 sample 投入 (18 sample) + Desktop multi-framework tab UI + audit loader smoke 組込
metadata:
  type: project
  originSessionId: phase17
---

# Business Model 図解 Phase 17 (2026-05-17)

Phase 16 で 8 新規 framework (apparel_brand / airport_operator / it_services_integrator / fitness_amusement / funeral_services / nursing_care_services / bridal_services / printing_services) を builder + sample + alembic + aggregator まで一気に着地させたが、Phase 16 申し送り 8 件が残っていた。Phase 17 は Wave 17-A〜F の 6 段構成で「available 条件緩和」「複合 dispatch 横展開」「Desktop UI」「audit 自己防衛」を同セッション内で完走。

## 着地サマリ

| 指標 | Phase 17 開始 | Phase 17 完了 |
| ---- | ------------ | ------------- |
| framework 総数 | 71 | 71 (条件緩和) |
| sample 総数 | 187 | 205+ (+18) |
| 複合 dispatch 銘柄 | 3 | 11 (+8) |
| audit needs_action | 0 | 0 (維持) |
| audit loader_smoke | 未実装 | 実装 (baseline imported=157 / failed=31) |
| Desktop multi-framework tab UI | 未実装 | 11 framework 対応 (IndustryFrameworkTabStrip 新規) |
| pytest business_model | 953 | 953 pass |
| Desktop typecheck | 0 errors | 0 errors |

## Wave 構成

- 17-A: 新規 8 framework builder に `metrics_count >= 3` (segment_groups 不要) で available 分岐 (8 並列)
- 17-B: 複合 dispatch 8 銘柄 × 18 sample 投入 (7974/9433/9984/4755/8058/3382/4661/9020、8 並列)
- 17-C: SAMPLE_MAPPINGS 18 entry 追加 + Wave B 4 sample period_type typo 修正 (1 直列)
- 17-D: Desktop IndustryFrameworkTabStrip + BusinessModelCanvasView 統合 (1 直列)
- 17-E: catalog audit に `--with-loader-smoke` flag + 4 新規 test (1 直列)
- 17-F: 統合検証 (alembic / audit / probe / pytest / ruff / typecheck / vitest、2 並列)

## 重要な発見

- **segment_groups 条件緩和**: 6 anchor (8227/9706/4680/6184/2418/7912) が available 化見込だが、metrics_count >= 3 を満たすには alembic metrics_value の anchor seed 投入が追加で必要。条件緩和コードは実装済、anchor 自体は partial 残存。
- **複合 dispatch 18 sample**: 1 銘柄複数 framework 同居が SAMPLE_MAPPINGS `code -> [pack, pack, ...]` schema で動作確認。loader dry-run で 18/18 認識。
- **IndustryFrameworkTabStrip 新規**: BusinessModelCanvasView の dispatch hub に tab UI を統合し、複合 dispatch 銘柄の multi-framework パネル切替の基盤完成。
- **audit loader_smoke で silent fail 構造解消**: Phase 15/16 申し送り 1 (SAMPLE_MAPPINGS 未追記の silent fail) が audit json で可視化。imported=157 / failed=31 が Phase 17 baseline。

## Phase 18 申し送り

1. loader_smoke の regression detection (baseline=31 を超えた失敗時に audit exit 1)
2. 既存 sample の schema violation 修正 (9433 telecom / 8058 trading_house 等、dry-run で 31〜163 件 rc=2)
3. cosmetics_retail と cosmetics_toiletries の命名揺れ統合
4. 重複 sample (9861 yoshinoya 系) の統合判断
5. IndustryFrameworkTabStrip の対応 framework を 11 → 50+ に拡張
6. J-REIT surface 取り込み方針決定 (Phase 15 申し送り 4 持ち越し)
7. probe ハング対策の本格実装 (Phase 17 では batch=5 + `--codes` で運用回避)
8. 複合 dispatch 実機検証 (Desktop multi-tab UX 目視確認)
9. alembic single_head 復帰 (20260517_05 + 20260518_18 の 2 head 残存、merge revision 必要)
