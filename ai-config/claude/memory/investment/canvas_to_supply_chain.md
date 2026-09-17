---
name: canvas_to_supply_chain tool
description: Canvas 9-block テキストから 4 桁コード付き取引先を regex 抽出して supply_chain_edges に llm_inferred / canvas_derived_v1 で投入するツール。2026-04-23 新設。
type: project
originSessionId: 65357bd0-8be7-4709-8ff3-f6490456ad0c
---
`tools/analytics/canvas_to_supply_chain/` は `analytics.canvas_llm_summaries` の `key_partnerships` / `customer_segments` / `key_resources` から「日本上場企業名 + 4 桁コード」ペアを正規表現で抽出し、`analytics.supply_chain_edges` に `tier_source='llm_inferred'` / `extraction_version='canvas_derived_v1'` / `confidence=0.55` で upsert するツール。

**Why:** 既存の `supply_chain_extractor` は 1 銘柄ずつの対話投入で、Tier1/Tier2 100 社のカバレッジ拡充に時間がかかる。Canvas テキストには Claude 対話で既に多数の日本上場企業名 + 4 桁コードが書き込まれているため、正規表現抽出で一気に数百 edges を投入できる。2026-04-23 実行で 101 Canvas 行 → 229 edges 生成、supply_chain_edges は 22 行 → 251 行・5 銘柄 → 74 銘柄に拡大。

**How to apply:**
- 実行: `uv run python -m tools.analytics.canvas_to_supply_chain.main extract [--code <sec>] [--dry-run] [--min-confidence 0.55]`
- `key_partnerships` → `supplier`、`customer_segments` → `customer` にマップ。文脈判定なし。**`key_resources` は誤分類率が高いため v2 で除外**（2026-04-23 調整、詳細は後述）。
- 4 桁コードは `core.instruments.is_active=TRUE` でフィルタ（海外企業 / 未上場は除外）。
- 名前フィールドに連続 2 空白以上が含まれる候補はテーブル / リスト layout の誤検出としてスキップ（例: ルネサス 6723 で "デモ指数 単独 連結指数 ETF 2018" 誤抽出を排除）。
- edge_key_hash は `supply_chain_extractor` と同じ SHA256 スキーマで冪等。再実行で重複は生じない。
- `extraction_model='canvas-regex-v1'`、`evidence_concept_qname='canvas:<block_name>'`、`doc_id='canvas://<issuer>/<as_of>'`。

**既知の限界:**
- Canvas に 4 桁コード表記が無い銘柄（例: 6861 キーエンス）は抽出不可で 0 件のまま。別途 Canvas 再生成か `supply_chain_extractor` 対話投入が必要。
- `key_partnerships` → supplier の単純マッピングで誤分類が発生する（例: 7974 任天堂の Gree 3632 が supplier として登録されるが実態はプラットフォーム提携）。v1 は精度より速度優先、Wave 2 で文脈判定を検討。
- 同一銘柄が `customer_segments` と `key_partnerships` の両方に現れるケースは customer / supplier 両方向の edge が生まれる（6920 レーザーテックの HOYA 7741）。これは仕様通り。

**v2 調整 (2026-04-23):**
- `key_resources` ブロックは除外。3/3 が誤分類だった（3382→8410 セブン銀行は子会社、6301→6305 日立建機は同業、6723→2018 は壊れ名前）。`key_partnerships` / `customer_segments` のみを走査。
- 名前抽出で連続 2 空白以上を含む候補を reject（テーブル layout 誤検出防止）。
- 日本語閉じ括弧類「」『』》〉】 を NAME_TRIM_CHARS に追加。
- 再実行で 229 → 226 edges、issuer 74 → 73 社になったが品質は向上（3382 の supplier が 山崎製パン/日本ハム/味の素 に正常化）。

**関連:**
- ADR: `docs/decisions/supply-chain-classifier-claude.md`（外部 API 不使用、対話セッション方式のみ）
- Pair tool: `tools.analytics.supply_chain_extractor`（1 銘柄対話投入、より高確度）
- 読み手: Desktop `PureSupplyChainDiagram.tsx`（Supply Chain サブタブ専用、peer/regulator は描画しない）

**テンプレート確度との対応 (Wave 1 完了 2026-04-29):**
- Canvas 由来 edge は DB 上では `source_kind='canvas'`、confidence=0.55 → 実装 `confidence_band='low'`（テンプレート確度では C 相当）。理由: Canvas 自体が Claude 対話で生成された二次情報で、相手側の正式開示や有報の関連当事者取引のような一次根拠を持たないため。
- UI 表現: Wave 1 で `BusinessModelGraphV2Panel.tsx` に `.band-low-edge` selector を追加（点線・opacity 0.55）。`CompanyMajorPartners.tsx` でも band=`low` のバッジ（黄）が表示される。
- 詳細: @./supply_chain_template_alignment.md
