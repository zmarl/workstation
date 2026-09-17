---
name: Business Model coverage backlog and scale category source
description: Tier1/2/3 のカバレッジ優先度は main.stocks.scale_category (TOPIX Core30/Large70/Mid400) が正本。topix_tracking は除外リスク watchlist で大型株は含まれない
type: project
originSessionId: 5561de06-22ab-4e2c-b31b-118e9adfe7a4
---
Business Model Canvas + Supply Chain の manual interactive pipeline で「どの銘柄を Tier1 として優先投入するか」は `main.stocks.scale_category` が正本ソース。

**Why:** `main.topix_tracking` は TOPIX 除外しきい値に近い watchlist（浮動株 120 億円前後の中小型株 watchlist）であり、7203 トヨタや 9432 NTT のような大型株は**含まれない**。2026-04-22 に topix_tracking ベースで seed したところ Tier1 に主要 6 銘柄が 1 社も入らず、scale_category ベースに切り替えて是正した。

**How to apply:** `tools.analytics.coverage_backlog.main seed --source scale` (デフォルト) を使う。`--source topix_tracking` は互換性のため残しているが使わない。scale_category ベースだと：
- Tier1 = TOPIX Core30（31 社、7203/9432/4568/8306/9984 含む）
- Tier2 = TOPIX Large70（69 社）
- Tier3 = TOPIX Mid400（396 社）

既存投入済みだが Tier1 に含まれないものとして 2269 明治ホールディングスは Mid400 = Tier3。

**関連:** `analytics.business_model_coverage_backlog.note` フィールドには sector_name をそのまま入れるが、Windows stdout では cp932 で文字化けする（DB 内は utf-8 正常）。ログ出力だけ崩れる仕様。
