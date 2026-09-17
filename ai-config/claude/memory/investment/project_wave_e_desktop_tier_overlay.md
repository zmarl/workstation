---
name: Wave E Desktop tier overlay 着地 + Wave L 移植断念 (2026-05-10)
description: PureSupplyChainDiagram に Wave E tier 1-4 overlay を追加 (10 test pass)。Wave L 移植は 22 component が main 未着地で撤退、累積 PR 化が必要
type: project
originSessionId: 6192aae2-c325-49fa-b360-68bc84f12fc7
---
# Wave E Desktop tier overlay 着地 + Wave L 移植断念 (2026-05-10)

ユーザー指示「Wave L visual + Wave E tier UI 仕上げ (中規模)」のうち Stream B (Wave E) を着地、Stream A (Wave L) は範囲膨張で撤退。

**Why:** Wave E tier_inferer (11 業界 / 41+ anchor / Tier 1-4) は BFF 経由で配信されているが Desktop に未配線だった。`PureSupplyChainDiagram` の既存 chain_tier ロジック (1-3 段) を 4 段に拡張し、BFF primary 由来の chain_tier を優先しつつ Wave E inferer から不足分を補完する設計で配線。Wave L は当初「playwright config + 134 PNG copy」で済むと想定したが、catalog page + 22 component が main 未着地で大規模統合 PR が必要なため撤退。

**How to apply:**
- Wave E 配線: `desktop/src/lib/api-client.ts` の `companyBusinessModelSupplyChainTiers(code, params?)` で BFF を呼ぶ。既存 arrow 関数 + `readRequest<SupplyChainTiersResponse>` パターン
- TierLegend は `tiers` 引数で 4 段切替 (`tiers.tiers["4"]` 存在チェック)。Wave E response の anchor / industry を `data-testid="chain-tier-meta"` に表示
- annotation は BFF primary 由来の chain_tier を優先、Wave E lookup は未設定 edges のみ補完 (`applyTierAnnotations` 関数)
- error / 空応答時は overlay skip (`tiersQuery.isError ? null : tiersQuery.data`)、既存表示を破壊しない
- queryKey は `queryKeys.company.supplyChainTiers(code, depth?, industry?)` 形式

## 既存ファイル変更
- 修正: `desktop/src/lib/types/company.ts` (line 442 周辺、`SupplyChainTiersResponse` interface 追加)
- 修正: `desktop/src/lib/query-keys.ts:142-148` (`supplyChainTiers` 登録)
- 修正: `desktop/src/lib/api-client.ts:33, 2882-2891` (import + new method)
- 修正: `desktop/src/components/company/PureSupplyChainDiagram.tsx` (新 useQuery / TierLegend 拡張 / annotation 関数 / 4 段表示)
- 修正: `desktop/src/components/company/PureSupplyChainDiagram.test.tsx` (mock 拡張 + 3 新規 case)

## Verification
- `cd desktop && npx tsc --noEmit` exit 0 (pipeline-store.ts は untracked で本セッション範囲外、除外)
- `cd desktop && npm run test` 1768 passed (前回 1763 + 新規 5)
- `cd desktop && npm run build` exit 0 (8.11s)
- `uv run ruff check .` clean
- Python 側変更なし (BFF endpoint は前回 commit `48e136e0` で着地済)

## Wave L 撤退の落とし穴
- main (`origin/main` = `27d9d666`) は Phase 5 着地以前の checkpoint で、business-model 関連は何も入っていない
- Wave L visual の 22 component (AdSupportedFunnelPanel / AutoOemPyramidPanel / ... / ValueChainMap) すべてが main 未着地
- catalog source `desktop/src/pages/_dev/BusinessModelCatalog.tsx` も main 未着地
- → Wave L 単独移植は不可能。必ず Phase 1〜7 + Wave A〜K + 改革 #4/#5/#6/#11/#12 の累積 PR が必要
- 撤退判断のタイミング: worktree 作成 + ファイル copy + `npm install` 完了後、22 component missing 確認時点
- 後始末: `git worktree remove --force` でメタ削除、`git branch -D feat/wave-l-visual-regression-port` 完了、push なし、PR 作成なし、外部影響ゼロ
- `.worktrees/wave-l-port/` directory は Windows file lock で残骸あり、手動掃除推奨

## main 同期の方向性 (次セッション議論)
- A. main 全面同期 PR (超大規模、ADR レベル方針議論必要)
- B. wip 中心運用を継続、main 同期は当面見送り
- C. 段階的 main 同期 (#4/#5/#6 → #11/#12 → Wave A〜K → Wave L の 4-5 PR 分割)

## Tip
- Wave E inferer の output は `{anchor, industry, tiers: {"1": [...], "2": [...], ...}, generated_at}`。BFF response_model は `SupplyChainTiersResponse` (`tools/api/decision_api/response_models.py:1131-1146`)
- BFF endpoint: `GET /api/v1/company/{code}/business-model/supply-chain-tiers?depth=4`
- BFF unit test 既存 3 ケース (`tests/tools/api/test_decision_api.py:4125-4180`、known/unknown/depth clamp)
- Desktop の DiagramEdge 型に `chainTier?: ChainTier | null` 既存 (`business-model-types.ts:97`)、ChainTier = 1 | 2 | 3 | 4
- worklog: `docs/worklogs/20260510-wave-e-desktop-tier-overlay.md`
