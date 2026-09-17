---
name: project-ui-ux-reform-202607
description: "裁量投資アプリ UI/UX 大改革 (2026-07-04 開始, feat/functional-uplift-p1)。Phase1-2 + 3C + 4-badges 完了、残 Phase3構造/Phase4残"
metadata: 
  node_type: memory
  type: project
  originSessionId: 689143f6-cbb6-41e4-baa9-0b00a74cda56
---

# 裁量投資アプリ UI/UX 大改革 (2026-07-04〜)

ブランチ `feat/functional-uplift-p1`。プラン: `C:\Users\kazum\.claude\plans\smooth-purring-wilkes.md`。
ユーザー確認済み方針: 使い勝手優先で全部 / 入口は積極統合 / 企業60+タブはプリセット既定化 / サイドバーは2文字コード併記(依存追加なし)。

## 完了 (全て vitest 2354 green + typecheck + design-guard で検証済、未コミット)
- **Phase 1**: 無効 Tailwind トークン無色バグの全面修正。詳細 [[bugs-desktop-undefined-tailwind-tokens]]。+ FailureInboxBadge の取得失敗時サイレント消失を「取得不可」赤バッジ化 + FailureInboxTab を StatusBadge 統一。tokens.ts に `FAILURE_SEVERITY_TO_SEVERITY`/`SEVERITY_LABEL_JA` 追加。
- **Phase 2**: Dashboard を「判断可否バナー→優先度キュー→地合い裏付け→ブリーフィング」に再構成。読み込みスケルトン+エラーバナー接続(briefingQuery の isLoading/isError を初めて処理)。raw palette 62箇所を semantic 化 → `pages/Dashboard.tsx` を CLEAN_PATHS 追加。Dashboard.test の waitFor をゲート後セクション待ちに更新。
- **Phase 3-C**: Sidebar の icon モード(48px)で曖昧な記号の代わりに `code` を表示(rail は既に code 表示済)。
- **Phase 4 Stage2 (badges)**: `components/ui/badges/*`(Confidence/Evidence/Freshness/Risk) を semantic 化 → CLEAN_PATHS 追加。company/FreshnessBadge.test の `.bg-red-400`/`.bg-amber-400` 検証を `.bg-danger`/`.bg-warn` に更新。

## 一括変換の手法 (Phase 4 で再利用)
色相→semantic の family sed (Dashboard/badges で実証):
`red|rose→danger, emerald|green|lime→ok, yellow|amber→warn, blue|sky|indigo→semantic-info, cyan|teal→accent-secondary, purple|violet|fuchsia|pink→semantic-info, orange→warn, slate|gray|zinc|stone|neutral→muted`。
`sed -E 's/\b(bg|text|border|ring)-(family)-[0-9]+/\1-token/g'`。ok=price-up=--c-up 緑、danger=price-down=--c-down 赤で同値。各領域 sed→残差0確認→CLEAN_PATHS追加→vitest→typecheck。

## 重要な注意 (Phase 4 残作業)
- **カテゴリ配色は family sed 不可**: `lib/news-utils.ts`(ニュース分類12色)や kb パレット、BusinessModel edge色 は「severity でなくカテゴリ識別」。単純統合すると分類の区別が消える。CATEGORY_PALETTE 設計 or 用途別名前付き定数が要る(判断点A)。
- **テストが raw クラスを直接検証している箇所あり**: sed 後に `.bg-red-400` 等の querySelector 検証が落ちる。sweep 毎に vitest 全体を回して該当テストを新トークンへ更新する。
- **design-guard は未定義トークンを検出しない**(生成されないだけ)。raw palette(red-500等)のみ検出。

## 追加完了 (2026-07-04、コミット済 4本: 7f4676ee/dcdfca00/740b9b8f/010802c3)
- **Phase 4 全域**: 残り約180ファイルの生パレットを family sed で semantic 化 → 残差0。design-guard CLEAN_PATHS を **components/pages/lib/styles/hooks/i18n** へ拡大＝Rule2 が実質リポジトリ全体で生パレット禁止。カテゴリ/グラデーション(FearGreed 5段/イベント種別/ニュース源)も semantic に畳んだ(ラベルが分類を担保、設計方針どおり)。
- **Phase 3-A screening統合**: industry-league をスクリーナーの `industryLeague` モードに取り込み(IndustryLeagueTable に `embedded` prop 追加でヘッダ抑制)。/industry-league → /screening?mode=industryLeague リダイレクト。registry から industry-league 削除+screening legacyRoute 追加。SCREENING_MODE_VALUES に capexSurge/industryLeague 追加。
- **Phase 3-A 受信箱統合**: Inbox サマリに FailureInboxBadge を追加し夜間失敗を同画面化(additive)。
- **Phase 3-B は実質既存**: CompanySnapshot は既に3階層(CompanyTaskPresetBar 5プリセット→SNAPSHOT_WORKSPACE_TABS→ワークスペース内 detail tab のみ表示、既定=overview=判断)。60タブ一括表示は既に回避済み。追加変更は再設計となり実画面検証要のため見送り。

## 品質・a11y 修正 (2026-07-04、コミット済 639c6979/8e7d88c8/1afc03ca)
- **Alerts.tsx rules-of-hooks 実バグ修正**: `if(!bffReachable) return` の後で useMemo/useInstrumentDetailsBatch を呼んでいた→接続切替でクラッシュ。フックを早期return前へ移動+派生配列 useMemo 化。repo 全体で rules-of-hooks 違反は Alerts のみだった。
- **silent query failure 修正**: PositionsPanel(取得失敗が「保有なし」に化ける)+ useInbox に isError 追加し Inbox でエラーバナー表示。※panels 配下は useQuery 58ファイル中 error 表示は約19のみ、残り~38 に同種 silent failure が残る(NarrativeTracker が手本、QueryErrorBanner 使用)。
- **a11y キーボード対応**: AdvancedResultTable/StockStageScreeningView/Backtest/Tasks/RankingTable/BreakoutTable/BreakoutSummaryCard の `<tr|li onClick>` に role=button/tabIndex/Enter・Space/focus-ring 付与。手本 EarningsSeason/CapitalPolicyView。
- **ScoringPrimitives accent(判断点B=C1 実施)**: Grade B/Level 2/ゲージ50-75%帯の accent→semantic-info。勾配 danger→warn→info→ok に。scoring-palette.ts + ScoringPrimitives.tsx。

## 品質第2バッチ 完了 (2026-07-04、コミット ce306f6e/67e50e84/fb99be6b/0bf23118/205c281d)
- **silent failure 21パネル**: components/panels の useQuery で isError 未処理を QueryErrorBanner+retry 化(部分データ系は全滅時のみ)。既存エラー表示を持つ7パネルは誤検出だったので不変(revert)。
- **lint 負債 完全解消 (50件→0, eslint exit 0)**: 機械的(未使用/余白/fast-refresh/exhaustive-deps)+ no-explicit-any 14件(→unknown/Record、OpsAgentaction 等に実フィールド補完)+ **@ts-nocheck 16ファイル全除去**。7ファイルは不要だった、9ファイル88エラーを適切な型付けで解消(as any/expect-error 不使用)。過程で API シグネチャの潜在バグ(similar-events の k 未送信、no-op 引数)も判明・修正。
- **tailwind.config @deprecated 除去**: bloomberg(未使用)+ amber(GoBar/NewsTicker の2箇所→text-warn)を除去。kb は knowledge-base 用に維持(Rule1 で封じ込め済)。
- サブエージェント知見: 「useQuery で isError 未処理」を機械検出→委譲したが、既にエラー表示を持つ7件を誤って標準化しテスト破壊→revert。**委譲前に「既存エラー表示の有無」を精査すべき**。@ts-nocheck 型修正は3エージェント分担で全て正しい型付け完了。

## 保守性改善 完了 (2026-07-05、コミット deee2f7f/3e156859)
- **EnvironmentTab silent failure 修正**: 市場環境の主データ(briefing/regime)失敗時に空表示→QueryErrorBanner。※silent failure の grep は誤検出多数(多くは `error instanceof Error` でエラー処理済)。真に silent なのは十数件でバッジ/図解(非表示許容)中心、判断影響ある画面(EnvironmentTab)のみ修正。
- **日付フォーマッタ集約**: 重複3つ(news-utils formatRelativeTime / Inbox formatInboxTimestamp / FailureInboxTab formatTimestamp)を `lib/date-format.ts` に統合(formatRelativeTime+dateFallbackAfterDays / formatAbsoluteDateTime / formatAbsoluteDate)。news-utils は再エクスポートで既存呼び出し非破壊、挙動保持。131ファイルの toLocaleDateString 直書き全migration は低価値のため見送り。
- **DataTable 重複は統合見送り**: 共有 DataTable(369行, 汎用 ColumnDef データグリッド)と knowledge-base/DataTable(75行, kb-* パレットの単純表)は API も見た目も別物。統合は kb 見た目刷新(M3, 実画面検証要)と一体で、安全な単独リファクタでない。

## 残 (判断/実画面検証が要る・低優先)
- **M2 任意値クラス ~996箇所**: `text-[Npx]`(text-xxs 等へ)/`min-h-[]` 等。視覚ほぼ不変・高churn・ESLint 未捕捉。**費用対効果低**。やるならページ単位で段階的+ESLintルール拡張。
- **M3 kb 統合**: knowledge-base の kb-* パレット(325箇所)+生hex29を semantic へ。低トラフィック画面だが全体の見た目が変わり**実画面検証要**。tailwind.config の kb トークン除去とセット。
- **Canvas/SVG hex → design-tokens 集約 (Phase4 Stage8)**: charts/BusinessModel*/Sparkline/startup の hex を design-tokens.ts 定数へ。現状も「正当」。design-guard に hex 検出 Rule3 新設とセット。
- **M4 その他**: 日付フォーマット共通化、共有 DataTable と knowledge-base/DataTable の重複整理。相対時刻の固定表示は再取得で更新されるため実害小(見送り)。
- **H2 残**: components/panels 以外(market/ tabs, pages)の useQuery で silent failure が残る可能性。

## 旧・残債務(第1バッチ調査時点、上で解消したもの含む)
- **H2 silent failure 残~38 panels**: PositionsPanel 以外の useQuery パネルで isError 未処理(ScreeningPanel/RegimeTrianglePanel/FlowSignalStrip/QuoteBoardPanel/IndexPanel/HeatmapPanel 等)。AsyncPanel/AsyncBoundary はデッドコード(採用 or 削除の方針決定が根治)。
- **M1 lint 負債**: `@ts-nocheck` ×14ファイル、no-explicit-any ×12(api-client/query-keys/types/company)、no-unused-vars、exhaustive-deps 警告数件。`--max-warnings 0` なので CI 未達。@ts-nocheck 除去は隠れ型エラーが出る可能性ありで要慎重。
- **M2 任意値クラス ~996箇所/200+ファイル**: `text-[Npx]`(~1000, Dashboard に text-[10px]×13)/`min-h-[]`(18)/`w-[]`/`h-[]`。ESLint no-restricted-syntax は余白系5件しか捕捉せず。密度トークン(text-xxs/terminal/label)へ寄せ+ルール拡張が回帰防止。BusinessModel 系は正当。
- **M3/M4**: knowledge-base の独自 kb- トークン+生hex29箇所(並行DS化)、共有 DataTable と kb/DataTable の重複、日付フォーマット不統一(共通フォーマッタ未整備)、Inbox 相対時刻が再計算されず固定表示(軽微)。
- **Canvas/SVG hex**: charts/、company/BusinessModel*、Sparkline、startup グラデの hex → `lib/design-tokens.ts`(COLOR/CHART_CHROME)集約。design-guard に hex 検出 Rule3 新設。※hex は Rule2 対象外なので CLEAN_PATHS 拡大は阻害しない。
- **kb 統合 + tailwind.config**: knowledge-base 内 kb-* を意味論へ畳む → config の @deprecated(amber/bloomberg/kb)除去。bloomberg は要 grep 0 確認。
- **ScoringPrimitives accent(判断点B)**: `scoring-palette.ts` 中間段 accent→semantic-info。視覚変化あり、単独コミット推奨。
- 関連: [[project_design_reform_phase3]] [[feedback_react_refresh_export_separation]] [[bugs-desktop-undefined-tailwind-tokens]]
