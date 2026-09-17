---
name: business_model_coverage_snapshots persistence
description: business_model_graph_coverage の audit/matrix 出力を analytics.business_model_coverage_snapshots に毎日記録する仕組み。Wave 1 で 2026-04-27 に追加。
type: project
originSessionId: ece903a5-210f-4246-8ae7-c08cb3f31618
---
ビジネスモデル図解カバレッジの時系列監視のため、`tools/analytics/business_model_graph_coverage/main.py` の `audit` / `matrix` サブコマンドに `--persist` フラグを追加し、`analytics.business_model_coverage_snapshots` に 1 行 / 実行で永続化する。

**Why:** 「Tier1+2 で primary edges 0 件の銘柄が何社残っているか」を毎日記録できないと、Wave 2 以降の閾値見直しや UI 透明化の効果測定ができない。既存 audit ツールは出力を JSON で吐くだけで履歴が無かった。

**How to apply:**
- 永続化したいときは `audit --persist` または `matrix --persist` を渡す。flag 無しでは従来通り read-only。
- manifest `business-model-graph-coverage-audit-daily` (line ~2474) には既に `--persist` を組み込み済み。日次 audit が走るたびに 1 行追加される。
- snapshot テーブルは `breakdown_json` に scope/tier/priority_band の集計を JSONB で持つ。比較 SQL を書くときはこのカラムを掘る。
- `repository.fetch_latest_edinet_text_submit_date()` + `evaluate_edinet_text_freshness()` で `analytics.edinet_text_partners` の鮮度判定が共通化されている。日次ヘルスチェックや UI の "stale" バッジで再利用可能。

**関連:**
- DDL: `db/greenfield_postgres/76_data_enrichment.sql` 末尾 + `db/alembic_revisions/20260427_001_business_model_coverage_snapshots.sql`
- 計画: `C:/Users/kazum/.claude/plans/quizzical-sauteeing-goose.md`
- 既存 ADR: `docs/decisions/supply-chain-classifier-claude.md`（外部 LLM API 禁止）
- canvas_to_supply_chain は Wave 1 で manifest に dry-run 投入済み（`canvas-to-supply-chain-extract-daily`）。1 週間観測後 Wave 2 で `--apply --confirm-apply` 化を検討。

**Wave 2 拡張 (2026-04-27 同日):**
- BFF `_BUSINESS_MODEL_DEFAULT_MIN_CONFIDENCE` を 0.50 → 0.40 に引き下げ。`_TIER_MIN_CONFIDENCE = {primary:0.70, llm_inferred:0.40, text_inferred:0.50}` を導入（現状は閾値設計値の参照用、SQL 経路への分岐は Wave 3 以降）。
- BFF `meta.coverage_breakdown` を新設。`analytics.supply_chain_edges` を `tier_source` で集約し `{edges_count, last_ingested_at, extraction_versions}` を返す（除外発行体は空配列）。
- UI `business-model-builder.ts` に `buildCoverageBreakdown()` を追加し `DiagramModel.coverageBreakdown` を必須プロパティ化。empty 時は `EMPTY_COVERAGE_BREAKDOWN` を export して fixture から再利用可能。
- 空状態メッセージ刷新: `BusinessModelDiagram` / `PureSupplyChainDiagram` / `BusinessModelSupplyChainPanel` で「primary X 件 / Canvas 推定 Y 件 / EDINET本文 Z 件 / 最終取込 N 日前」表示。
- `CompanyBusinessModelCoverageChips` の Supply Chain チップで primary 0 + 推定 N のとき "0 (推定 N)" 表示と tone=accent 化。
- `wikidata-company-relationships-weekly` を manifest に週次 dry-run で投入（rate-limit 1 req/sec、`--from-coverage` で Tier1+2 100 社対象）。tool_tiers tier2 に登録済み。
- 検証: pytest 86 件通過 / vitest 927 件通過 / desktop build 成功 / manifest checker 4 本通過。

**Wave 3 拡張 (2026-04-27 同日):**
- BFF `meta.backlog_status` を新設。`analytics.business_model_coverage_backlog` から自銘柄行を pluck し、`priority_band` (tier1/2/3/other), `next_action` (supply_chain_extractor / canvas_summarizer / review_in_progress / skip_financial / complete), canvas/supply 進捗、最終更新日を返す。除外発行体は null。
- UI 型 `CompanyBusinessModelBacklogStatus` / `CompanyBusinessModelBacklogPriorityBand` / `CompanyBusinessModelBacklogNextAction` を `desktop/src/lib/types/company.ts` に追加。
- `CompanyBusinessModelCoverageChips` に Backlog チップを追加（`Tier1 / 取引先抽出 待ち` のような表示、tone は next_action ごとに切替）。
- `BusinessModelGraphV2Panel` に confidence threshold slider を追加（`ConfidenceThresholdSlider` 内部 useState + 250ms debounce で再フィルタ）。閾値 0 のときは無効化、閾値 > 0 でリセットボタン表示。`GraphFilterState.minConfidence` 経由で `filterVisibleGraph` で edge をふるい落とす。
- `BusinessModelSupplyChainPanel` の空状態に `ExtractionCommandsCTA` を追加。canvas_to_supply_chain / supply_chain_extractor / wikidata_company_relationships の 3 コマンドをコピーボタンで提供。Desktop からの実行はせず、ターミナル手動実行を促す。
- 検証: pytest 88 件通過 / vitest 929 件通過 / desktop build 成功 / manifest checker 4 本通過。

**Wave 3 後半: 未実装データ源の本実装 (2026-04-27 同日):**
- `tools/market_data/ir_pdf_scraper/` 新設。EDINET 有報 (doc_type_code='120') PDF を `extract_text_from_edinet_pdf` で読み、`edinet_section_splitter` で section 分割、「主要な販売先 / 主要な仕入先 / 事業の系統図」アンカー語の直後 600 文字を窓として `tools/analytics/canvas_to_supply_chain/extractor.py:extract_pairs` で `<会社名 + 4桁コード>` を抽出。`tier_source='llm_inferred'` / `extraction_version='ir_pdf_v1'` / `confidence=0.55` で投入。relation 優先度は customer/supplier > affiliate（同 counterparty が複数 anchor で出たら高優先のみ採用）。manifest `ir-pdf-scraper-extract-daily` に dry-run で投入、tool_tiers tier2 登録。
- `tools/market_data/tdnet_partnership_extractor/` 新設。`tdnet_disclosure_feed` の表題から「業務提携 / 資本業務提携 / 合弁会社設立 / 株式譲渡 / 子会社化 / 株式取得 / TOB / 公開買付 / 合併 / 事業譲渡」等のトリガー語を検出し、表題内の 4 桁証券コードを対向企業として抽出。`tier_source='llm_inferred'` / `extraction_version='tdnet_partnership_v1'` / `relation_type='affiliate'` 固定（v1 安全側） / `confidence=0.50`。年号 (1990-2049) と self-reference は除外。manifest `tdnet-partnership-extract-daily` に dry-run で投入、tool_tiers tier2 登録。
- `tier_priority` 整数化（spec 1.5 → impl 2）はコード再確認の結果、ORDER BY 順位付けが正しく動作する整数値（primary=1, llm_inferred=2, text_inferred(supply_chain_edges)=3, text_inferred(edinet_text_partners)=4）で実装済み。コード変更不要と判断。
- 検証: pytest 117 件通過 (新規 26 件) / desktop build 成功 / ruff クリーン / manifest checker 4 本通過。vitest は私の対象範囲で全パス、既存 Dashboard / Flow / SupplyDemand 系の状態汚染による flaky failure は Wave 3 と無関係（単独実行で通過）。

**Wave 4 (2026-04-29) Desktop 反映完了:**
- PartnerRow (`partner-display.tsx`) に tier_source バッジ (P=primary 緑 / L=llm_inferred amber / T=text_inferred yellow) と extraction_version tooltip 追加。`tierBadgeMeta()` を export。
- BusinessModelDiagram に `TemplateBadge` 追加。default 以外で「テンプレ: Auto OEM」「テンプレ: J-REIT」「テンプレ: 電力 unbundling」を panel header に表示（業種別テンプレ手動切替 UI は今回見送り、自動判定+バッジのみ）。
- `CompanyBusinessModelCoverageChipsLite` を新設し、BusinessModelDiagram の panel header 直下に配置。Overview タブからも Supply Chain / Related / Backlog チップが見える状態。Frameworks タブ用上位レスポンスを Overview で再 fetch しないため business_model 単独 props で動作。
- BusinessModelCanvasView の CanvasHeader に `DataSourceChips` (Seg/SC/Fact/Narr/Text の 5 chip) + `prompt_hash` 短縮 12 文字フッター追加。`ConfidenceBadge` を 3 段階閾値に再構成 (< 0.5 amber WARN / 0.5-0.7 NOTICE / >= 0.7 OK)。
- TIER ラベル統一: `formatTierCounts` を `厳格/LLM/regex` → `P/L/T` に変更（BusinessModelSupplyChainPanel + CompanyRelationshipGraphPanel）。TierBadgeLegend / BusinessModelLegend / TIER_BADGE_TITLE の文言を全て「primary: 構造化開示 / llm_inferred: 推定 / text_inferred: 本文抽出」に統一。
- 検証: typecheck / lint / vitest 1000 通過 / ruff / pytest 54 通過。
- 残: 実機動作確認 (7203 / 9501 / J-REIT / 中小銘柄) と、データ不足銘柄に対する dry-run → apply はユーザー手元で実施予定。
- worklog: `docs/worklogs/20260429-business-model-desktop-reflection.md`

**Wave 5 候補:**
- ir_pdf_scraper の精度測定（dogfood 銘柄 5 社で抽出件数と precision/recall）
- tdnet_partnership_extractor の relation_type 細分化（株式取得 / 子会社化 → subsidiary、合弁会社設立 → JV など）
- BFF: `_TIER_MIN_CONFIDENCE` の値を SQL 経路へ実際に注入（現状は閾値設計値の参照用のみ）
- カバレッジ実数値が出揃ったら、IR PDF / TDnet 両ツールを `--apply --confirm-apply` 化
- 業種別テンプレ手動切替 UI（Auto OEM / J-REIT / 電力 unbundling / default を BusinessModelDiagram ヘッダーから選択）
