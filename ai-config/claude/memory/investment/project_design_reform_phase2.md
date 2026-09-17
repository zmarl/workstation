---
name: project-design-reform-phase2
description: デザイン改革 Phase 2 着地 (2026-06-19)。kb-* パレット完全駆逐 + 主要画面 semantic 化 + design-guard ゲート恒久化。Phase 3-4 申し送りあり
metadata: 
  node_type: memory
  type: project
  originSessionId: 9771f53a-dd48-440f-895c-e03733e333e4
---

# デザイン改革 Phase 2 (2026-06-19 着地)

10 コミット (a06d43cf 起点) で高トラフィック画面を semantic トークンへ。worklog: `docs/worklogs/20260619-design-reform-phase2.md`。前提は [[project-design-reform-phase1]]。

## 確立したもの

- **kb-\* パレットは knowledge-base 内のみ**に限定（漏出 11 ファイル 56 箇所を全駆逐、design-guard allowlist 空）。kb-blue #58a6ff = `--c-info` 同色で無損失置換
- **design-guard ゲート** `desktop/src/test/design-guard.test.ts`: Rule 1 = kb-\* を knowledge-base 外で使うと fail（allowlist shrink-only + stale 検知）、Rule 2 = 生 Tailwind パレットを CLEAN_PATHS（grow-only）で fail。CLEAN_PATHS = components/{layout/primitives, charts, shared} + BuybackTracker + screening/{FrameworkView,ScreeningPage} + portfolio/{Allocation,Holdings,Counterfactual,Learning}Tab + portfolio-utils-core
- **tokens.ts SEVERITY_PALETTE = medium レシピ（/20）**、info=accent→**semantic-info**（accent=操作専用の規律本丸）。`src/styles/tokens.ts` は settings.json deny を `Read(**/*token*.json|yaml|...)` へ縮小して Read 可能化
- **GRADE_COLORS は `components/shared/scoring-palette.ts` に分離**（ScoringPrimitives と GradeBadge が共有、Fast Refresh 維持）

## 技術知見

- **死にクラス**: `text-warning`/`text-success`/`bg-panel-alt`/`bg-success`/`bg-warning` は tailwind.config に存在せず無色描画（正は warn/ok/panel-header）。AllocationTab・portfolio-utils-core にあった
- **共有コンポーネントの色トークン化は props 注入式で**: Section.tsx を headerClassName/badgeClassName 受け取りにし、KB ラッパーが kb クラスを注入 → KB ピクセル不変かつ kb-\* 文字列を knowledge-base 配下に閉じ込め
- **サーフェス置換規約**: 非 hover の `bg-white/5`→`bg-panel-header/50`、`bg-white/10` チップ→`bg-panel-header`、`bg-black/20`→`bg-panel-header/60`。**`hover:bg-white/5` は overlay-hover 同値で残す**（sed で placeholder 退避してから一括置換）
- Phase 2 の色クラス置換は business-model-catalog の視覚対象コンポーネントに当たらず **win32 visual baseline 0 差分**。Phase 1（共通 CSS/チャート）と波及範囲が違う
- React Fast Refresh: コンポーネントファイルから定数 export すると警告 → `*-palette.ts` 等へ分離（[[feedback_react_refresh_export_separation]]）

## Phase 3+ 申し送り

1. **linux baseline**: Phase 1 由来で dc09f55d 止まり（パネル質感/チャート/design-system 3 シナリオ未反映）→ Phase 2 S10 で CI workflow_dispatch update_snapshots=true 再生成
2. **CandidateView.tsx**（screening、未コミット差分=ジャーナル起票ボタン）+ screening 残（CapexSurgeView/ScreeningExplanation/ShortSqueezeView/screening-utils）
3. **不可触だった他ワークストリーム変更**: App/StartupOverlay/StatusBar/EarningsEvaluation/ActionQueueTab/ExitActionTrackingTab/Dashboard → 片付き次第
4. **research/ (3,460行・ResearchShared 36箇所) + sector-analysis/** = Phase 3 本丸（構造寄せ・Panel 化）
5. **ScoringPrimitives Lv2/B + GradeBadge B の accent 使用**は規律未整合 → Phase 4 判断
6. 生パレット残りは design-guard Rule 2 のラチェット拡大で順次駆逐 = Phase 4 で全 lint 化
