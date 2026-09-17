---
name: project-design-reform-phase3
description: デザイン改革 Phase 3 着地 (2026-07-03)。research/sector-analysis 構造寄せ + screening 残 semantic 化 + CLEAN_PATHS ラチェット拡大
metadata: 
  node_type: memory
  type: project
  originSessionId: 9f7b3013-0350-4c83-96ab-dfd07bcd2c35
---

# デザイン改革 Phase 3 着地 (2026-07-03)

Phase 2 申し送りを消化。worklog: `docs/worklogs/20260703-design-reform-phase3.md`

- **screening 残**: CapexSurgeView(18)/ScreeningExplanation(4)/ShortSqueezeView(4)/CandidateView(1)/screening-utils を semantic 化。スコア強度は warn 2 段 + panel-header、5 軸カテゴリバーは warn/up/info/accent-secondary/down のトークン供給、資金源バッジは warn/danger/ok
- **research/ 構造寄せの核心**: `ResearchShared.SectionCard` を `layout/primitives` の Panel へ**内部委譲**(呼び出し側 93 箇所 API 不変)。これで research 全画面が Panel の標準クローム/density/a11y を継承。ValuationBandCard の hex 直書き chartColors → design-tokens COLOR 供給
- **sector-analysis**: 確信度ドット→ok/warn/danger、方向バー→semantic-up/down、空売り警戒→danger (テスト 2 ファイル追随)
- **design-guard CLEAN_PATHS**: components/research・components/sector-analysis・pages/screening (ディレクトリ全体) を追加 (11→12 エントリ、個別 screening 2 ファイルはディレクトリへ統合)
- 検証: design-guard 3/3、tsc 0、全体 vitest 2,322/2,323 (唯一の fail は Portfolio.test の既知並列フレーク、単体 11/11)
- **Phase 4 送り**: Dashboard/LatestEarnings/DisclosureSearch 等 raw 大量ページ (他バッチ未コミット交差)、ScoringPrimitives の accent 使用判断、repo-wide 生パレット lint 恒久化
