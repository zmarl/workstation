---
name: Business Model Catalog dev page
description: 22 Business Model / Wave G コンポーネントを 3 状態でモック表示する dev catalog ページ。Wave L pixelmatch / Wave M LLM narrative の前提
type: project
originSessionId: f1d34748-6f3d-4f12-be48-82f78cdc8854
---
# Business Model Catalog dev page (2026-05-09 完成)

## 構成

- **Route**: `/_dev/business-model-catalog` (DEV ビルドのみ、production bundle 除外)
- **22 components × 3 states = 66 セル**: Universal 5 / Industry 12 / Strategic (Wave G) 5
- **Source files**:
  - `desktop/src/pages/_dev/BusinessModelCatalog.tsx` (page、~285 LOC)
  - `desktop/src/pages/_dev/business-model-catalog-mock.ts` (mock factory、~970 LOC)
  - `desktop/src/pages/_dev/BusinessModelCatalog.test.tsx` (9 tests)
  - `desktop/src/lib/app-router.tsx` (3 箇所追加: lazy import / createRoute / DEV 配列)

## QueryClient seeding

ページマウント時に専用 QueryClient (staleTime: Infinity, refetchOnMount: false) を作成し、**`useMemo` 内で `setQueryData` を同期実行して seed する**。query-driven 6 コンポーネント (BusinessModelDiagram / GraphV2Panel / CanvasView / PureSupplyChainDiagram / RelationshipGraphDiagram / PharmaPipelinePanel) が BFF を一切叩かずに動作する。

**重要**: 当初 `useEffect` で seed していたが、child の `useQuery` が初回 render で cache miss → queryFn 実行（API refused）→ failed state に固まる。`useEffect` で setQueryData しても failed state は更新されない（`refetchOnMount: false` のため）。`useMemo` 内で seed すれば cache が事前投入され、child の useQuery が初回 render から hit する。

Seeded query keys:
- `["company-business-model", code]`
- `["company-business-model-graph-v2", code, { peers_limit: 0, tier_depth: 1 }]`
- `["business-model-panel-health"]`
- `["company-business-model-frameworks", code, { peers_limit: 0 }]`
- `["company-pharma-pipeline", code]`

CATALOG_CODES: available=9001, partial=9002, unavailable=9003 (synthetic)

## 業界別 mock segment 名

`INDUSTRY_SEGMENTS` dict で各業界の典型 segment names を保持。classifier 関数を満たす実 segment 名を投入することで industry panels の available state が正しく描画される。

- trading_house: 金属事業 / エネルギー・化学事業 / 機械事業 / 食料事業 / 住生活事業 / 情報・金融事業
- semiconductor: ファウンドリ事業 / OSAT後工程事業 / 半導体製造装置事業 / マスク・材料事業
- ec_marketplace: EC モール事業 / 物流事業 / フィンテック事業 / 広告メディア事業
- electric_unbundling: 発電事業 / 送配電事業 / 小売電気事業
- logistics_hub: ラストワンマイル配送 / 倉庫・物流センター / 幹線輸送 / 拠点運営
- shipping_fleet: コンテナ船 / バルク船 / タンカー / LNG船
- telecom: ネットワーク / ホールセール / コンシューマ
- bank: 法人融資 / リテール預金 / 投資信託・運用 / 保険
- j_reit: オフィスビル / 商業施設 / 物流施設
- auto_oem: OEM完成車 / Tier1部品 / 販売金融

## 落とし穴 (実装中に踏んだもの)

- `data_state: "missing"` は `DataState` 型に存在しない → `"no_data"` を使用
- `INDUSTRY_SEGMENTS[opts.industry]` は string index で `undefined` 戻りのため `?? []` 補完が必要
- catalog ページは専用 QueryClient を持つため、Layout 配下の親 QueryClient とは独立。`/_dev/*` は Layout を経由するため Layout 内の `useQueryClient` 呼び出しは親クライアントのまま。catalog 内のコンポーネントだけが catalog の seeded client を見る (これは意図通り)
- 既存 dev page (`DesignSystem.tsx`) は PascalCase ファイル名。catalog も `BusinessModelCatalog.tsx` (PascalCase) で揃えた
- `desktop/src/lib/app-router.tsx:846-849` の DEV 配列は `[...baseRoutes, designSystemRoute, businessModelCatalogRoute]` で並べる。`import.meta.env.DEV` ガードで production bundle から完全除外される
- **StartupOverlay (App.tsx の root に常時マウント) が catalog ページに `fixed inset-0 z-50` で被さる**。BFF 不要の dev catalog では overlay が pointer event を intercept してブラウザ操作 / Playwright capture を阻害する → catalog 側で `<StartupOverlayBypass />` (CSS injection: `section[aria-label="投資コントロールタワー起動画面"] { display: none !important }`) を mount。overlay 自身を hide するので、startup phase の更新を待たず catalog が即時 render される
- **QueryClient の seed は `useEffect` ではなく `useMemo` 内で同期実行**: child の `useQuery` が初回 render で cache hit するため。`useEffect` は child の queryFn が走った後に setQueryData するので timing 競合する

## Wave L (visual baseline) 完了 (2026-05-09)

- Playwright (`@playwright/test`) + pixelmatch + pngjs を `desktop/devDependencies` に追加
- `desktop/playwright.config.ts` (1920×1080 / dark / chromium-desktop / single worker / fontHinting 無効)
- `desktop/tests/visual/business-model-catalog.spec.ts` で 66 cell + ページ全体 1 枚 = **67 baseline PNG** を生成 (`test:visual:update`)
- `desktop/tests/visual/__baselines__/*-chromium-desktop-win32.png` に commit
- `desktop/tests/visual/catalog-entries.fixture.ts` (entry id × state ハードコードミラー) と `desktop/src/pages/_dev/BusinessModelCatalog.fixture-drift.test.ts` (vitest drift detector) で source `CATALOG_ENTRIES` との同期を保証
- `FLAKY_CANVAS_CELLS` (cytoscape / recharts radar 系 3 cell) は `maxDiffPixelRatio: 0.04` に緩和、それ以外は `0.001` (0.1%)
- npm scripts: `test:visual` / `test:visual:update` / `test:visual:report`
- CI workflow: `.github/workflows/visual-regression.yml` (workflow_dispatch only, `update_snapshots` input で linux baseline 生成)
- 運用ガイド: `docs/guides/visual-regression.md`

## 次のセッションで進むべき作業

1. **Linux baseline 生成 + commit**: visual-regression workflow を `update_snapshots: true` で dispatch → artifact `linux-baseline-png` をダウンロードして `desktop/tests/visual/__baselines__/` に追加 commit。これが完了すれば Phase 2 の PR gate 化が可能
2. **PR gate 化 (Phase 2)**: visual-regression workflow を `pull_request` トリガーに切替、catalog 関連ファイル変更時のみ run
3. **Wave M qwen3.5:9b narrative**: BFF に business-model 向け narrative endpoint 新設 → catalog に live narrative セクション差し込み
4. **manifest entry 追加**: `business-model-segment-backfill-initial` を `scripts/run_manifest.yaml` に追加 (並行作業 348 行 diff コミット後)
5. **PeerComparisonOverlay (Wave G Phase 2)**: catalog に追加候補
6. **実 BFF 経由モード切替**: ユーザー指定 code を入力する toggle UI

## 関連 ADR / worklog

- `docs/worklogs/20260509-business-model-probe-hang-root-cause.md` (probe ハング修復、本タスクの前提条件)
- `docs/worklogs/20260509-business-model-catalog-and-initial-backfill.md` (catalog 新設の worklog、前セッション)
- `docs/worklogs/20260509-wave-l-visual-baseline.md` (Wave L 導入、本タスク)
- `docs/guides/visual-regression.md` (Wave L 運用ガイド)
- `docs/runbooks/visual-regression.md` (Wave L 運用 runbook、threshold ポリシー / リカバリ手順 / branch protection 設定、2026-05-14 新規)
- `docs/worklogs/20260508-wave-f-phase3-horizontal-expansion.md` (12 panel × live metrics 配線、catalog の表示対象)

## Wave L Phase 2 着地 (2026-05-14)

threshold 微調整 + runbook 新規作成で「always-failing でない gate」になる土台が整った。

| 値 | 旧 | 新 | 理由 |
|---|---|---|---|
| デフォルト `maxDiffPixelRatio` | 0.001 | **0.002** | DPI/フォント差で false positive を抑止 |
| full-page snapshot | 0.005 | **0.006** | 要素数累積差分のため少し緩め |
| canvas/グラフ系 (FLAKY) | 0.04 | **0.05** | recharts/cytoscape の非決定性 |

ファイル:
- `desktop/playwright.config.ts`
- `desktop/tests/visual/business-model-catalog.spec.ts`
- `docs/runbooks/visual-regression.md` (新規)

**残: branch protection rule で required check 化**は GitHub web UI 操作のため runbook §5 にユーザー手順を記載。Claude からは設定できない。

詳細実測ログ: `docs/worklogs/20260514-business-model-residuals-completion.md`
