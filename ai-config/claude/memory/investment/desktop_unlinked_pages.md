---
name: Desktop 未リンク Pages 整理
description: 一見 Sidebar から到達できない 13 本の page は、実態として親 page (Portfolio/Fundamentals/Operations) の view= タブとして統合済み。Sidebar 直接追加は不要
type: project
originSessionId: 06a37e34-9804-430a-aa3a-f36ce72a0a61
---
調査日: 2026-04-28 (再確認)。当初 plan で「未リンク 13本」と把握したが、実装を確認したところ全て親 page の view= タブで到達可能だった。

## 統合済みの実態

| Page ファイル | 実際の到達経路 | 実装場所 |
|---|---|---|
| `Backtest.tsx` (`BacktestPage`) | `/portfolio?view=backtest` | `Portfolio.tsx:57,233` で lazy import |
| `HiddenEdge.tsx` (`HiddenEdgePage`) | `/fundamentals?view=hidden-edge` | `Fundamentals.tsx:9` で import |
| `IpoPipeline.tsx` (`IpoPipelinePage`) | `/operations?view=ipo` | Operations.tsx で動的に表示 |
| `WatchlistMonitor.tsx` | `/portfolio?view=watchlist` | `app-router.tsx:613-624` で `/watchlist-monitor` → リダイレクト |
| `DisclosureSearch.tsx` | `/fundamentals?view=disclosure` | `app-router.tsx:600-611` でリダイレクト |
| `Jobs.tsx` | `/operations?view=jobs` | Operations.tsx で import |
| `Actions.tsx` | `/operations?view=actions` | Operations.tsx で import |
| `Tasks.tsx` | `/operations?view=tasks` | Operations.tsx で import |
| `Alerts.tsx` | `/portfolio?view=alerts` | Portfolio.tsx で import |
| `Universe.tsx` | `/portfolio?view=universe` | Portfolio.tsx で import |
| `Compare.tsx` / `EarningsSurprise.tsx` / `Ideas.tsx` | `/fundamentals?view=...` | Fundamentals.tsx で import |
| `News.tsx` | `/news-regulation?view=news` | NewsRegulation.tsx で import |
| `InvestmentDashboard.tsx` | `/` (dashboard) | Dashboard.tsx で import |

## 設計思想

- Sidebar は 6 グループ × 1〜N item の固定構成 (`workspace-registry.ts`)
- 個別ツール (Backtest / HiddenEdge / IpoPipeline 等) は親ワークスペースの **view= タブ** に統合
- `legacyRoutes` に旧パスを記録 → 旧 URL でも互換性維持 (`CompatRedirect` で誘導)

## 結論

- **Sidebar 直接追加は不要**。実装的には全 page 到達可能
- もし「子タブを Sidebar から直接ジャンプしたい」要望が出たら、`workspace-registry.ts` の `search` 属性付きエントリで実現できる (`path: "/portfolio", search: { view: "backtest" }`)
- ただし Sidebar が長くなりすぎる懸念があるので、現設計を維持するのが妥当

## 2026-04-28 削除した完全 orphan ファイル (7 件)

下記は誰からも import されておらず、対応する legacy URL も `app-router.tsx` の Redirect Route で別 page に飛ばされるだけ。tsc で検出可能だが残存していたため整理。

| 削除ファイル | 理由 |
|---|---|
| `Monitor.tsx` + test | Monitor.test 以外から import なし。`/monitor` は MonitorRedirectRoute が CompatRoute で動的リダイレクト |
| `Market.tsx` + test + error-boundary test | Monitor.tsx からのみ import → Monitor 削除で連鎖 orphan に |
| `Discover.tsx` + test | Discover.test 以外から import なし。`/discover` は DiscoverRedirectRoute |

`Market.tsx` から import されていた個別 panel (e.g. `MarketDriversPanel`, `RiskEventsPanel`) は `EnvironmentTab.tsx` 等の現行 layer で再利用済み。Market.tsx 自体は古いタブ構成のラッパーだったため削除して問題なし。

## 利用シーン

- 「この機能どこから入るの？」と聞かれたら、親 page + view= の組み合わせで案内
- BacktestPage / HiddenEdgePage / IpoPipelinePage 等の単体ファイル削除を検討する際、view= 経由で参照されているため削除不可
- workspace-registry.ts の `legacyRoutes` 一覧から旧 URL の互換性を確認
