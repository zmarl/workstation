---
name: project-frontend-ux-roadmap-2026-07-09
description: フロントエンドUX改革 全5フェーズ完了 (2026-07-09)。総合タブ/マクロセクタービュー/タブ履歴/パレット統一/AsyncPanel。ブラウザdev実画面検証手法込み
metadata: 
  node_type: memory
  type: project
  originSessionId: a76b407f-45f6-4e7f-86e1-3de33f591fa3
---

# フロントエンドUX改革 5フェーズ完了 (2026-07-09, feat/hidden-asset-screener 上に5コミット)

計画: `C:\Users\kazum\.claude\plans\quirky-hopping-otter.md`。worklogs: `docs/worklogs/20260709-frontend-ux-roadmap-phase{1..5}.md`

## 何が変わったか
1. **企業「総合」タブ** (`CompanySynthesisTab`): 8分野の結論カード（バリュエーション/健全度/市場期待/含み資産/需給信用/イベントPEAD/マクロ感応度/決算評価）を初期表示化。**detail パネルのアドホック query key をリテラル一致で再利用**（`["company-valuation-snapshot",code]` 等。`queryKeys.company.peadHistory` は別リテラルなので使わない — 正は `["pead-history",code]`）。概要は `?tab=overview`。
2. **マクロ「セクター」ビュー**: セクター意思決定マトリクスを /fundamentals から `/macro?view=sector` へ移設。行組み立ては `sector-analysis/industry-rows.ts` + `SectorDecisionMatrixSection`（自己完結・同一key）。逆引き露出パネル `MacroExposureReversePanel`（sectorMacroImpact×保有/監視のクライアント結合）。レガシー `?view=rrg` 等は view=sector へ。EnvironmentTab が focus-store.setRegime を配線、FocusBar はレジーム単独でも表示。
3. **タブ履歴** `company-tab-history-store.ts`: 銘柄別最終タブ復元（?tab= 優先、復元は replaceState で URL 反映）+ 最近のタブチップ。CompanyPageLink クリックで focus-store 更新（27箇所を1点で）。比較は `/fundamentals?view=compare&codes=X&mode=template` ディープリンク（FocusBar/QuickActions/パレットの3経路）。
4. **パレット統一**: WorkspacePalette 削除。ターミナルレイアウトは CommandPalette の kind:"layout" コマンド。Ctrl+P = 同パレットの layoutsOnly モード。
5. **AsyncPanel** (`layout/primitives/AsyncPanel.tsx`): Panel + derivePanelStatus。errorText は ReactNode（QueryErrorBanner可）。idle 時は children 非表示で emptyText。採用: 総合カード/逆引き露出/JSF(フィルタは footer へ)/CyclePhase/CrossMarketSignals。**パネルレジストリは恒久見送り**。

## 実画面検証手法（ブラウザ dev + Playwright）
- vite dev (port 1420) + 実BFF (127.0.0.1:8010, `uv run python -m tools.api.decision_api.main`)。
- ブラウザは Stronghold 不可でトークン空 → **DEV限定の `window.__APP_STORE__` に .env の DECISION_API_READ/RUN_TOKEN を注入**し `setBffReachable(true)+setReadinessState({dbConnectable,readReady:true})+setStartupPhase("ready")` で起動ゲート突破。page.goto 毎に再注入必要（store はリロードで消える）。
- playwright は `createRequire("D:/Dev/Investment/desktop/package.json")` 経由で require（scratchpad から直接 import 不可）。

## 罠・知見
- CompanySnapshot のデフォルトタブ変更は既存テスト6件（概要内容検証）に波及 → `?tab=overview` 明示が正。zustand ストアはテスト間共有 → beforeEach で `useCompanyTabHistoryStore.setState` リセット必須。
- Macro の `?view=sector` を LEGACY_MACRO_TARGETS に残すと自己ループリダイレクト。
- Panel の error に node を渡すと Panel ラッパー + QueryErrorBanner の **二重 role=alert**（テストは findAllByRole）。
- FocusBar は code/sector 無しだと自動非表示 → regime 単独表示は表示条件の拡張が必要だった。

関連: [[project-hidden-asset-screener-2026-07-05]] [[bugs-module-split-monkeypatch-binding]]
