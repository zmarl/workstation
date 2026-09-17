---
name: project-book-knowledge-integration-2026-07-11
description: "Obsidian投資本のRAG基盤化+スクリーナー原典照合バッチ (2026-07-11, feat/book-knowledge-integration worktree)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 46e0558c-1a18-417e-8a2d-37fcf19f9af2
---

# 書籍知識活用バッチ (2026-07-11)

worktree `feat/book-knowledge-integration`（16ce1193起点）。ユーザー制約: **既存機能があれば必ず既存のアップデート**（新戦略0・新ツール0で全要望を実現）。

## 実装済み
- **書籍原典照合台帳** 新設: `投資フレームワーク/03_売買戦略/書籍原典照合台帳.md`。adopt/intentional_diff/deferred の3値、実データ校正済み値は書籍値より優先、OCR数値は2回以上出現で相互検証。F3/F7/ST/HA/F5/BK 系50行超
- **F.3 shin_netnet**（しん流6条件 SH-1〜6）: `scoring/fundamentals.py` gate + `repository.py` enrichment。6/6でカタリスト任意。BS入力は `mart.vw_edinet_facts_normalized_latest`（CurrentAssets/InvestmentsAndOtherAssets、直近500日、負債=総資産-純資産近似）。実データ: 6/6=0社・5/6=70社（全てSH-4欠け）= 原典の希少性と整合
- **canslim校正**: C因子に売上25%関門新設・A因子STRONG=各年25%厳格化、全定数に章出典
- **stock_stage 8/8化**: readiness/buyable 7/8→8/8（原典準拠）。buyable 327→278件、**断層日 2026-07-11**
- **hidden_asset 清原軸**: net_cash_ratio =（流動資産+投資有価証券×70%-負債）/時価総額（原典実査で確定。「現金+」ではない）。重み 0.40/0.30/0.15/0.15
- **presets**: graham-defensive / fisher-growth 追加。graham-netnet はNCAVフィールド不足で deferred。※「NCAV×2/3」は賢明なる投資家本文に直接表現なし（俗説）
- **RAG基盤**: `disclosure_embedding_indexer load-books`（56冊/2,252章、content_hash冪等、denylist=config/book_knowledge.yaml）→ 既存embeddings → `GET /api/v1/knowledge-base/book-search`（pgvector `<=>`+ef_search=200、Ollama不達はdegrade）→ WorkNotesPage意味検索UI。汚染ガード: theme_narrative_tracker と disclosure-search 既定に `source <> 'book'`
- **manifest**: book-knowledge-load-weekly（tier3）+ governance allow-sources + alembic 20260711_04

## 重要知見
- **.env の OBSIDIAN_VAULT_PATH が旧パス（D:\UserData\ドキュメント、消滅）のままで既存の作品メモ表示が沈黙故障していた** → `C:\Users\kazum\Documents\02_投資・知識\Obsidian Vault` に修正済み（メイン+worktree両方）
- EDINET正規化facts（vw_edinet_facts_normalized_latest）に BS詳細項目（流動資産・投資有価証券・負債・投資その他）が約3,000社分ある。financial_unifier拡張やDDLなしで PBR系派生指標を作れる
- book sections の published_at は frontmatter date_extracted 固定（mtime禁止: theme tracker の直近窓に混入する）
- 並行セッションのDDLチェーンは流動的（01〜03→01〜11へ再構成された）→ **ミラー方式は破綻。私の revision (_04/_05) は確定済みhead(20260709_04)にチェーンし、マージ時に down_revision を1行付け替えて適用**する方式に変更

## 第2弾（同日実施、実行規律・心理・moat）
- ①レジーム連動損切り（exit_monitor、td/rf・caution以下で-4.5%/-6%）②タートルATRユニットキャップ（sizing、min併記・Rust契約不変。ATRはmetric_series優先+OHLC直接計算fallback）③オニールFTD検出（canslim/market_timing.py→market_regime補助シグナル±0.15）④ジャーナル規律チェックリスト（**draft_payload JSONBマージでDDL不要**、hard_gate不変）⑤economic_moat framework（3点セット）⑥原則集30項目（config/investment_principles.yaml正本+shared/principles.py決定的日替わり）→briefing「本日の原則」+PhilosophyTab
- 無関係本6冊削除+**ローダーにpurge機構追加**（denylist入り本の残骸が永続する欠陥修正）。50冊/2,057セクション残存
- 凍結予算ちょうどのファイルへの挿入は「既存ブロックの等価圧縮で相殺」が有効パターン

## Handover
- [x] strategy-signal-collector「停止」は**誤診断**（毎日正常稼働、ATR_14 29万行）。真因: **metric_series.metric_key 列は collector 経路で NULL — 参照は必ず metric_catalog join**（列直参照だと0件に見える罠）。sizing は series優先+OHLC fallback に改良
- [ ] alembic 20260711_04/05 の適用: マージ時に down_revision を最終headへ付け替え → upgrade head（INSERT-onlyで低リスク）
- [ ] Windows タスク登録 BookKnowledgeLoadWeekly（$scheduler-registration）
- [x] tdnet 未embedding残はバックフィル実施（2026-07-11）
- [ ] FTD閾値+1.7%の実データ校正（引数化済み）/ SZ-104 ユニット上限統合 / マンガー25傾向の収載
- [ ] VCP検出（ST-107）・moat持続性因子（F5-102）・RS 80/90段階表示（ST-105）は deferred 起票済み
- [ ] 企業分析画面への関連書籍知識カード（未実装、設計メモのみ）

関連: [[project-hidden-asset-screener-2026-07-05]] [[bugs-refactor-tooling-footguns]]
