---
name: 開発実行計画 Phase 1-4 完了・次期計画移行
description: development-execution-plan + feature-upgrade-plan 全完了。Phase 4 残件のうち 4E-D4 は 2026-05-10 に Phase 1 着地。次期正本は improvement-roadmap。
type: project
originSessionId: dcf34b1c-90e6-4493-b988-e5a03ce161b3
---
## 開発実行計画の実装進捗（2026-05-10 更新）

Sprint 0 + Phase 1〜4 + feature-upgrade-plan 全11件を実装完了。Phase 4 残件のうち 4E-D4 は半自動解消エンジン (Phase 1) として 2026-05-10 に着地。9087テスト合格、lint 全パス。

**Why:** P2.5 Truth Model Lock 解除後、プロダクトビジョン P0 機能の実現に向けた段階的構築。全フェーズ closeout。
**How to apply:** 次期開発サイクルの正本は `docs/調査/improvement-roadmap-2026-04.md` + `docs/計画管理/バックログ/next-actions-2026-04.md`。Sprint 1: AI対話基盤（S-1 ポートフォリオ解説、S-2 インライン質問）、Sprint 2: リサーチ深化（S-3 Deep Research、A-1 テンプレート、B-5 プレモルテム）、Sprint 3: 可視化（A-2, A-4, A-7, B-2）、Sprint 4: インテリジェンス強化（A-6, A-3, B-7）。

### 完了済み

| フェーズ | 内容 | テスト数 |
|---------|------|---------|
| Sprint 0 | P2.5凍結解除（マイグレーション、CI gate、ADR-011） | — |
| 1A | pgvector + embeddings.py + hybrid_search.py + embedding_indexer | 50 |
| 1B | data_quality_gate_evaluator に consistency_checker 追加 | 47 |
| 1C | shared/llm_prompts/ テンプレートレジストリ | 18 |
| 2A | shared/rag_pipeline.py + semantic_search ツール + BFF API | 22 |
| 2B | earnings_briefing ツール（5ツール統合 + Discord + スケジューラ） | 29 |
| 2C-C1 | twitcasting_transcriber に earnings サブコマンド | 9 |
| 2D | cognitive_bias ツール + BFF API | 28 |
| 3A | financial_modeler（DCF + 感応度 + シナリオ） + BFF API | 31 |
| 3B | supply_chain_graph（再帰CTE + D3.js互換API） | 19 |
| 3C | regime_integrator（4トラッカー統合） + BFF API | 39 |
| 3D | sector_rotation（TOPIX-17 モメンタム） + BFF API | 23 |
| 3E | research_agent（8段階固定パイプライン） + BFF API | 27 |
| **4A** | **Dagster オーケストレーション基盤**（ADR-006昇格、orchestration/ パッケージ、TDNET/Financial/Consensus パイプライン） | **17** |
| **4B** | **MLflow モデル管理**（shared/ml_tracking/ 統合レイヤー、guardrail 連携） | **10** |
| **4C** | **7データソース拡充**（JPX空売り、IR BANK、Buffett Code、JPXガバナンス、TSE Prime改善、JSDA社債、J-PlatPat特許） | **46** |
| **4D-P5** | **LLM Gateway CI gate 修正**（llm-gateway-mandatory-path-ci パス） | — |
| **4E-D5** | **フィードバック閉ループ精緻化**（overfitting guard、auto_adjustment_config） | **23** |
| **4E-B4** | **バックテスト SLO**（slo_config、slo_evaluator） | **25** |
| **4E-D4 Phase 1** | **異時間軸戦略干渉の半自動解消エンジン**（`tools/quality/strategy_conflict_resolver/`、3 ルール: high opposing escalate / medium horizon prefer longer / low size skip smaller、Discord 通知バッチ、rollback 14 日 reentry guard、API 拡張 2 関数、greenfield DDL に `resolution_rule` カラム追加） | **40** |

### 未着手（方針決定待ち）

| 項目 | 内容 | ブロッカー |
|------|------|----------|
| 4D-P4 | ClickHouse dual_shadow 検証 | ClickHouse サーバー稼働が必要 |
| 4D-P3 | Iceberg canonical 運用化 | Polaris カタログ未導入 |
| 4E-D3 | ポートフォリオ全体最適化 | ファクター制約の定義が必要 |
| 4E-D4 Phase 2+ | 解消ルール拡張（規模別の段階的強化、accept_risk への自動移行など） | Phase 1 を 1〜2 週間運用してから判断 |

### 主要な技術的変更（Phase 4 で追加）

- Dagster 1.13 + dagster-webserver + dagster-postgres を依存に追加
- MLflow 3.11 を依存に追加（SQLite バックエンド）
- `orchestration/` トップレベルパッケージ新設（Dagster Definitions、tool_runner ブリッジ）
- `shared/ml_tracking/` パッケージ新設（MLflow ↔ ml_guardrails 統合）
- Dagster の `@asset` デコレータでは context パラメータの型アノテーションを省略する必要あり（1.13 互換性）
- ADR-006 を Design-Locked に昇格済み
