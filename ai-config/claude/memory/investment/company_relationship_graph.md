---
name: Company Relationship Graph ビジョンと Phase 1 実装
description: 正確で広範囲な企業相関図 (取引 + 資本 + 協業 + 出資 + ステークホルダー) の段階的拡張計画。Phase 1 で取引 + 資本の統合 UI 新設（2026-04-23）
type: project
originSessionId: 65357bd0-8be7-4709-8ff3-f6490456ad0c
---
企業分析の質を上げるために、個別銘柄ページで「この企業は誰とどう関わっているか」を多面的に可視化する長期プロジェクト。

**Why:** Supply Chain サブタブ（`PureSupplyChainDiagram`）は取引関係のみしか描画できない。資本系列・協業・出資・ステークホルダーを含む「相関図」はまだ UI 化されていない。ユーザーの目標は「正確で広範囲な企業相関図」。

**2026-04-23 決定事項:**
- Q1 外部 LLM API: **禁止維持**（既存 ADR `supply-chain-classifier-claude.md` のまま）
- Q2 有料 DB（Teikoku / Bloomberg 等）: **無料範囲のみ**
- Q3 Phase 順序: **データ → UI**（Phase 1 資本系列 → 2 IR PDF/Wiki → 3 協業系 → 4 本格 UI）
- Tier B 公開データ（IR PDF、Wikipedia/Wikidata、JPX、官報、特許庁）は利用可
- Tier C 対話 LLM セッション（Claude Code / Codex CLI）も引き続き利用可

**Phase 1 実装済み (2026-04-23):**
- `desktop/src/components/company/CompanyRelationshipGraphDiagram.tsx`: 取引 + 資本を 1 枚にした相関図。既存 `buildDiagramModel` の結果を self/customer/supplier/parent/subsidiary/affiliate + sell/buy/own_from/own_to にフィルタして `BusinessModelSvg` に渡す。
- `desktop/src/components/company/CompanyRelationshipGraphPanel.tsx`: RelationshipSummary + Diagram + MajorPartners + RelatedParties をまとめた Panel。
- `BusinessModelCanvasView.tsx` に "Relationship Graph" サブタブ追加。Supply Chain の隣。availability は (取引 > 0 && 資本 > 0) → available、どちらかのみ → partial。
- vitest 4 テスト、company 配下 258 テスト全通過、build も OK。

**How to apply:**
- 新しい関係タイプ（例: JV / 協業 / ライセンス）を追加する場合は、BFF の business_model レスポンスに新フィールドを足してから `CompanyRelationshipGraphDiagram` の filter を拡張する。
- 新データソース（IR PDF / Wikipedia 等）の取り込みは Phase 2 として別ツールを新設する。

**Phase 2+ の予定:**
- Phase 2: `tools/market_data/ir_pdf_scraper/` と `tools/market_data/wikidata_company_relationships/` を新設。PDF から「主要取引先」「事業系統図」節、Wikidata から親子・関連情報を抽出。
- Phase 3: Canvas `key_partnerships` を JV_partner / platform_partner / licensing に細分化、TDnet M&A・業務提携発表を regex + 対話で抽出。
- Phase 4: 本格 UI。d3 / cytoscape.js で force-directed / hierarchical レイアウト、フィルタ・drilldown。
- Phase 5: クロスソース検証、矛盾検出、対話セッションでの最終確認パイプライン。

**Phase 2a 実装済み (2026-04-23):**
- `tools/market_data/wikidata_company_relationships/` 新設。Wikidata SPARQL (https://query.wikidata.org/sparql) から P749/P355/P127/P1830 を取得し `analytics.supply_chain_edges` に `tier_source='llm_inferred'`, `extraction_version='wikidata_v1'` で投入。
- P6928 (Tokyo Stock Exchange code) は Wikidata で大半の日本株に未登録なので、**SPARQL UNION で `rdfs:label "name"@ja` 検索も並行**。linked entity にも P6928 が無いため、Python 側で `core.instruments.name` 正規化マッチ（`normalize_name`: 株式会社/(株)/（株）/空白を除去、lowercase）で code を解決。
- Tier1/Tier2 100 社実行結果: 69 銘柄で entity 発見、22 銘柄で 上場対向企業 edges 生成、合計 44 edges。トヨタ 7203 は 8 子会社（デンソー・アイシン・豊田自動織機・豊田合成・愛三工業・東海理化・セーレン・豊田通商）、新日鉄 5401 は 9 子会社（大阪製鐵・新日本電工・日亜鋼業・トピー工業・日鉄ソリューションズ 等）。
- confidence は P355/P749 直接関係で 0.70、P127/P1830 間接関係で 0.60。
- Crawl policy: User-Agent 明示、httpx+tenacity で 3 回 retry、1 req/sec rate limit。
- テスト 16 通過（client 4 / repository 12）、ruff クリーン。

**2026-04-23 BFF バグ修正:**
`tools/api/decision_api/serving/_company.py:get_company_related_parties` が `analytics.supply_chain_edges` からの行を無条件で `'primary' AS tier` で返していた（llm_inferred/canvas_derived/wikidata_v1 エッジも全て "primary" 表示になっていた）。`get_company_supply_chain` と同じ 3-tier UNION パターンに修正。テスト `test_get_company_related_parties_propagates_text_inferred_tier` のパラメータ数を 4 → 6 に合わせて更新。**BFF 再起動が必要**（auto-reload 無し）。

**関連:**
- `docs/design/company-relationship-graph-vision.md` (ビジョン文書、Approved)
- @./pure_supply_chain_diagram.md
- @./canvas_to_supply_chain.md
