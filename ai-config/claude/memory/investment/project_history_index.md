---
name: project-history-index
description: 完了済みプロジェクトフェーズ記録への索引（JPX 銘柄マスター Phase 2-6、政策インテリジェンス Phase 1-6、2026-05 改革バッチ群）
metadata: 
  node_type: memory
  type: project
  originSessionId: db4670bd-5918-4c2b-abfa-f006083adc6c
---

# 完了済みプロジェクト履歴索引

## JPX 銘柄マスター同期（Phase 6 まで完了、月次 manifest 稼働中）
- [[project_jpx_listed_companies_phase2]] — 月次取り込み + drift_check（sanity 99.6%）
- [[project_jpx_listed_companies_phase3]] / [[project_jpx_listed_companies_phase3_followup]] — 自動同期 ETL + 保護コード機構 (config/jpx_protected_codes.yaml)
- [[project_jpx_listed_companies_phase4]] — scheduler 月次配線 + OpsHub 3 サブタブ
- [[project_jpx_listed_companies_phase5]] — 死蔵 InstrumentMasterTab 有効化
- [[project_jpx_listed_companies_phase6]] — 隣接拡張 6 ストリーム（cross-audit / SLA visibility 等）

## 政策インテリジェンス（Phase 6 まで完了）
- [[project_policy_intelligence_phase1]] — DB拡張 + 「政策」タブ化 + kanpo/egov ツール
- [[project_policy_intelligence_phase2]] — pubcom/diet scraper + TimelineMatrix 主軸化
- [[project_policy_intelligence_phase3]] — LLM 業界タガー + 仮説レビュー queue
- [[project_policy_intelligence_phase4]] — 審議会クローラ + mart.vw_reg_timeline
- [[project_policy_intelligence_phase5]] — 残宿題 8 件 + runbook 化
- [[project_policy_intelligence_phase6]] — e-Gov v2 暫定 + KPI mart。**main 追従が残**（worktree D:/Dev/Investment-phase6）

## 2026-05 改革バッチ群（全完了）
- [[project_reform_followups_phaseB_2026_05_11]] — Desktop統合 Follow-ups（司令塔 critical 浮上）
- [[project_reform_db_capacity_secrets_audit_phase1]] — DB容量 + 秘密情報監査
- [[project_reform_a_b_d_parallel_2026_05_10]] / [[project_reform_a_b_c_2026_05_11]] / [[project_reform_a2_a5_c1_d1_2026_05_11]] — S 粒度並列バッチ（scheduler 登録 / edge confidence / バイアス UI / PBR 履歴）
- [[project_wave_e_desktop_tier_overlay]] — tier overlay（Wave L main 移植は撤退）
- [[project_emergency_bug_fixes_2026_05_10]] — silent exception 9 箇所修正
- [[project_core_instruments_master_resync_phase1]] — 728 件正当廃止確定、JPX ETL scaffold 残置
- [[dev_execution_plan_progress]] — 開発実行計画 Phase 1-4 完了

## 2026-06〜07 完了バッチ群(MEMORY.md から 2026-07-18 移設)
- [[project_db_ops_safety_batch_2026_07_13]] — DB運用安全化 (07-13)。pool/alembic 二層ガードレール + DDL 20260713_02..04 + 実バグ5系統。残: legacy_archive DROP
- [[project_ideal_architecture_review_2026_07_12]] — ゼロベース理想アーキ評価。骨格現状維持・Adopt 7件(**Py3.12 EOL 2026-10-31**)。PGネイティブ化は Hold
- [[project_repo_audit_2026_07_12]] — 全域監査3弾。着手正本 docs/audits/20260712-unified-improvement-backlog.md(50項目)
- [[project_db_lane_rot_fix_2026_07_13]] — db レーン修理 (PR #51)。**「PG Tx abort+suppress=静かな全滅」**・fetch_all_dicts_isolated
- [[project_test_suite_slim_2026_07_12]] — テスト減量 (PR #48)。84→52s・ratchet・testing.md 正本
- [[project_test_speed_2026_07_11]] — テスト高速化 (PR #41-46)。隠れDB依存40件 hermetic 化。**Actions 枯渇=ローカル証跡を PR コメントでマージ**
- [[project_db_ops_optimization_2026_07_11]] — ClickHouse退役/VACUUM 186GB/品質ゲート3種/read_cache 15関数
- [[project_db_ops_volume_check_persist_2026_07_12]] — volume_check_mode 実装。pool cold-start は env POSTGRES_POOL_RETRY_INTERVAL_SEC=20
- [[project_book_knowledge_integration_2026_07_11]] — 書籍RAG・レジーム損切り・タートルATR。handover: alembic 20260711_04・Windows登録
- [[project_reform_program_202607]] — Track A 全完了 (PR #36/38/39/40)
- [[project_framework_review_2026_07_09]] — 投資フレームワーク総点検 101ファイル。handover: 暫定閾値校正
- [[project_functional_improvement_batch_2026_07_09]] — 評価13+表示5+品質5件 (PR #36)
- [[project_frontend_ux_roadmap_2026_07_09]] — フロントUX 5フェーズ。実画面検証は __APP_STORE__ トークン注入
- [[project_error_sweep_2026_07_09]] — failed 8+degraded 4修理。handover: jp.cpi e-Stat 乗り換え
- [[project_hidden_asset_screener_2026_07_05]] — 含み益調整後PBR。BFF追加は実測8箇所
- [[project_structural_cleanup_202607]] — 構造リファクタ P1+P2 (PR #22/#23)。**BFF endpoint=decorator+EndpointSpec 2箇所**・認証バイパスは _require_* patch
- [[project_data_workflow_overhaul_2026_07_05]] — 価格読取正本ビュー移行+テキストブロック9種。handover: 全銘柄バックフィル
- [[project_analytics_accuracy_202607]] — **価格正本=mart.vw_price_daily_corporate_action_adjusted / financials OI は四半期累計**
- [[project_data_acquisition_overhaul_2026_07_04]] — サイレント取得死7系統+監視3層+新規4ソース
- [[project_unfinished_completion_batch_2026_07_04]] — failure inbox 再構築+不整合6件
- [[project_functional_uplift_202607]] — 23バッチ。6重大故障修理+optimizer/predictor本実装
- [[project_repo_update_roadmap_202606]] — 10テーマロードマップ (06-12)
- [[project_debt_repayment_202607]] — T20 grandfather 1,202件返済。capsys 教訓
- [[project_structure_guardrails_roadmap]] — guardrails ブランチ破棄済 (07-03)
- [[project_decision_journal_round1]] / [[project_decision_journal_round2]] — 判断ジャーナル+DQI。Round 3=死蔵分析接続
- [[project_earnings_evaluation_batch_2026_06]] — 決算評価改善バッチ (2026-06)
- [[project_phase5_history_edinet_structuring_202607]] — buyback TextBlock構造化・XBRL保有割合 fraction(×100)・訂正facts自己period継承
- [[project_phase6_new_sources_202607]] — IIP e-Stat+JSF逆日歩+text-blocks配線。Windows登録5未実施
- [[project_ops_resilience_2026_06_12]] — Postgres 長期ダウン対策 (watchdog、manifest 未登録残)
- [[project_ci_hermetic_db_restore]] — CI-HERMETIC-01 (PR #17)。`stamp head --purge`・pgvector image 必須
- [[project_ops_cleanup_2026_07_03]] — 契約監査 132/132・NOTIF-STD-02 file-dedup
- [[project_docs_housekeeping_2026_06_12]] — worklog アーカイブ + tool-count CI ゲート
