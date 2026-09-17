---
name: Business Model Phase 5 closeout 完了 (2026-05-10)
description: Phase 5 残 3 ストリーム (Wave L Linux baseline / Wave E BFF 配線 / Wave D Phase 3 残 6 銘柄) を 1 セッション並列着地。3/6 銘柄が available 化、Phase 6 / Desktop 組み込みへ移行可能
type: project
originSessionId: 7fa74f8d-e369-45c4-bad7-1fc23613c263
---
# Business Model Phase 5 closeout final (2026-05-10)

Phase 5 着地後の繰り越し 3 件を、Stream W/X/Y 並列 (1 orchestrator + 7 sub-agent) で同セッション内クローズ。

**Why:** Phase 6 業種拡張 / Wave M (narrative) / Desktop Tier 可視化に進める前提を固めるため、Phase 5 を完全クローズ状態にする必要があった。

**How to apply:** 次セッションは Phase 6 業種拡張 (Phase 5 と同じ 4 トラック並列パターン)、Wave D 残 partial の metric 拡張、Wave E Desktop 組み込み、または Wave L main 向けインフラフル移植のいずれかに進む。

## 完了サマリ

| Stream | 結果 | commit |
|---|---|---|
| **W** Wave L Linux baseline 67 PNG | ✅ CI run 25614853405 (wip ref) success → 67 PNG を `desktop/tests/visual/__baselines__/` に追加 | `dc09f55d` |
| **X** Wave E `tier_inferer` BFF 配線 | ✅ 新 endpoint `GET /api/v1/company/{code}/business-model/supply-chain-tiers?depth=N` (depth クランプ 1..4、unknown anchor は 200 / `tiers={}`)、3 contract test pass | `48e136e0` |
| **Y** Wave D Phase 3 残 6 銘柄 | ✅ 5 JSON 作成 + loader 取り込み、6920 Lasertec のみ skip | 最新 commit |

## Wave D 6 銘柄 probe 結果

| code | framework | status | confidence | metrics |
|---|---|---|---|---|
| 9432 NTT | telecom | ✅ available | 0.85 | 4 (subscribers / arpu / churn_rate / capex_intensity) |
| 9101 NYK | shipping_fleet | ✅ available | 0.70 | 2 (spot_rate / fleet_dwt) |
| 9501 TEPCO | electric_unbundling | ✅ available | 0.70 | 2 (power_generation_kwh / transmission_kwh) |
| 4751 CyberAgent | ad_supported | ⚠️ partial | 0.55 | 1 (ad_revenue) |
| 9064 Yamato | logistics_hub | ⚠️ partial | 0.55 | 1 (cargo_volume_tons) |
| 6920 Lasertec | semiconductor | ❌ skip | — | 0 (装置メーカー特性で IR 非開示) |

着地: 3/6 が available、2/6 は metric 不足 (DAU/MAU、load_factor 非開示) で partial、1/6 は IR 非開示で skip。

## 重要な発見 / 教訓

1. **Wave L workflow は main ref で動かない**: PR #10 は workflow yaml だけ移植しており、`desktop/package.json` の `test:visual:*` scripts や playwright config / tests / 67 Win32 baseline はすべて wip 側のみ。main で実行可能にするにはフル移植 PR (5 種類のディレクトリ追加) が別途必要
2. **Wave E auth coverage 検証の副作用**: Stream X agent が `tools/api/decision_api/app.py` の `READ_TOKEN_PROTECTED_ROUTES` に新 endpoint を追加した際、test collection が失敗するため `capital-policy/history` と `screener/capital-policy` の 2 件 (WIP の他作業で導入済) も同時登録した。1 endpoint 追加のつもりが 3 endpoint 修正になる注意点
3. **IR 開示の限界**: Wave D 残 6 銘柄のうち、装置メーカー (Lasertec) は構造的に skip、消費者向けサービス (CyberAgent DAU/MAU、Yamato load_factor) は KPI 自体が IR 非公開。framework available 化を全銘柄で達成するには、pack の metric_keys 側を拡張するアプローチが必要
4. **probe の confidence は per-metric**: framework `available` 判定は metric の質 (confidence ≥ 0.85) と量 (≥2 metric が必要そう) の両方を見る。1 metric だけでは partial 止まり

## 次セッション候補

1. **Phase 6 業種拡張**: 4 トラック並列で 4 業種追加 (textile_apparel / rubber_tires / glass_ceramics / oil_gas_refining 等)
2. **Wave D 残 partial の available 化**: 4751 / 9064 の framework metric_keys を IR 開示 KPI に合わせて拡張
3. **6920 Lasertec の semiconductor pack 拡張**: equipment_sales / service_revenue / contract_liabilities / operating_margin など装置メーカー向け metric を追加
4. **Wave E Desktop 組み込み**: `PureSupplyChainDiagram.tsx` に新 endpoint を呼ぶ Tier 1-4 表示追加
5. **Wave L PR gate 化**: main への visual-regression infra フル移植 PR

---

## 2026-05-14 訂正 (実測 probe 再走による)

本ファイルの「Wave D 6 銘柄 probe 結果」表は 2026-05-10 時点のスナップショット。
2026-05-14 に同 codes で再 probe した結果、**memory が示唆していた「8/14 達成」は事実誤認**であることが判明:

- 実態: confidence ≥ 0.85 達成は **0/14**
- 4568 pharma_rd は available だが confidence 0.7 (≥0.85 未達)
- 4751 / 2433 / 9449 ad_supported は **partial 0.55** (sample に ad_revenue 1 metric しか入っておらず、pack 必須セット未充足)
- **6501 industrial_conglomerate は framework_key_missing** (aggregator catalog 未登録) — sample 投入と framework 登録の 2 ステップが分離しており、後者が未着手
- 6920 semiconductor partial 0.45 (sample に metric が 1 件もない)

[[project_business_model_aggregator_catalog_gap]] に Phase 5/7 共通の根本原因 (framework_key 未登録問題) を別途記録。
詳細実測ログ: `docs/worklogs/20260514-business-model-residuals-completion.md`
