---
name: Supply Chain サブタブは PureSupplyChainDiagram を使う
description: Business Model 画面の Supply Chain サブタブは PureSupplyChainDiagram (self/customer/supplier のみ) を使い、BusinessModelDiagram は Overview タブ用の総合図として残す。peer/regulator/market_operator を誤って Supply Chain に混ぜないこと。
type: feedback
originSessionId: 65357bd0-8be7-4709-8ff3-f6490456ad0c
---
`desktop/src/components/company/BusinessModelSupplyChainPanel.tsx` は **`PureSupplyChainDiagram`** を呼ぶ。`BusinessModelDiagram` は `CompanyOverviewTab.tsx` 専用の総合図として残す。2 つを混同しないこと。

**Why:** BFF `get_company_business_model()` は `supply_chain`（取引関係）と `peers` / `regulator` / `market_operator` / `investor` / `ownership`（stakeholder 系）を同一レスポンスに詰めて返す設計。`BusinessModelDiagram` は 12 種類の `node_kind` をすべて同じ図に描画するため、Supply Chain サブタブで呼ぶと競合他社・規制当局・上場市場まで描画されてしまい、「仕入先 → 発行体 → 販売先」の意図を破壊する（2026-04-23 にディスコ 6146 で発覚）。

**How to apply:**
- Supply Chain 関連の新コンポーネントでは `BusinessModelDiagram` を直接呼ばない。`PureSupplyChainDiagram` を使うか、`buildDiagramModel()` の結果をフィルタしてから `BusinessModelSvg` に渡す。
- Pure 図で描画する `node_kind` は `self` / `customer` / `supplier` のみ。`edge_kind` は `sell` / `buy` のみ。`parent` / `subsidiary` / `affiliate`（資本関係）も Pure 図では除外（取引の流れではないため）。
- 取引先データが空のときは「取引先データ未取得」を明示。stakeholder にフォールバックして peer を出すのは禁止。
- `BusinessModelDiagram` 側の legend やラベルを変えない。Overview タブで peer/市場/規制は依然として有用な情報。

**関連:**
- Phase 1-5 実装: `C:\Users\kazum\.claude\plans\imperative-munching-honey.md`
- Canvas 由来の edges 補完: @./canvas_to_supply_chain.md
- 相関図の拡張ビジョン: `docs/design/company-relationship-graph-vision.md`（2026-04-23 承認）
- 資本系含む相関図タブは `CompanyRelationshipGraphDiagram` / `CompanyRelationshipGraphPanel`（Business Model タブ内に新設、2026-04-23）。こちらは self/customer/supplier/parent/subsidiary/affiliate の 6 種のみ描画し peer/regulator/market_operator/investor/segment は排除

**エッジスタイルと確度 Band の現状 (Wave 1 完了 2026-04-29):**
- `BusinessModelGraphV2Panel.tsx` に band 別 Cytoscape selector を実装済: `.band-medium-edge`(dashed) / `.band-low-edge`(dotted, opacity 0.55) / `.band-very_low-edge`(dotted, opacity 0.32, 細線) / `.band-unknown-edge`(dotted, 灰)。`high` band は default の solid を踏襲。
- band 値は BFF `compute_confidence_band` で 0.80 / 0.65 / 0.50 の閾値で算出（`tools/api/decision_api/serving/company/common.py`）。
- EdgeDetailPanel に `transaction_amount_million_jpy` / `transaction_fiscal_year` を表示するように拡張済。
- Pure Supply Chain サブタブは引き続き `min_confidence=0.65` BFF default で `very_low` 以下を非表示。
- 詳細: @./supply_chain_template_alignment.md
