---
name: project-ideal-architecture-review-2026-07-12
description: ゼロベース理想アーキテクチャ評価ドキュメント完成 (2026-07-12)。骨格は現状維持が正、Adopt 7件、レッドチームで2件Hold降格
metadata: 
  node_type: memory
  type: project
  originSessionId: 1788810b-ab42-4231-8c85-c6182a88cc54
---

# ゼロベース理想アーキテクチャ評価 (2026-07-12 完了)

成果物: `docs/architecture/ideal-architecture-2026/`（README + 痛点台帳45件 + Web調査ログR1-R6 + 不採用案）。コミット 0486565e（feat/hidden-asset-screener、ドキュメントのみ）。

## 中心結論
- **骨格は現状維持が正**: Postgres+DuckDB / FastAPI BFF 509ep / Tauri+React / Task Scheduler+manifest / ローカルLLM / ratchet 文化は、2026年の一次情報照合で「ゼロから作っても9割同型」。オーケストレータ移行(Dagster等)・WSL2移設・宣言的スキーマ(Atlas/sqldef)・DuckLake は全て却下（理由と再評価条件は appendix-rejected.md）
- 変えるのは3系統のみ: **観測性の反転 / 層の削減 / 腐敗防止の機械化**

## Adopt 7件（未着手、オーナー承認待ち）
1. 外形 dead-man's switch（SaaS、共通モード故障検知）2. 内容プローブ拡張（source_freshness の対象13ソース→全書込先へ、feature_store型凍結検知）3. 階層化バックアップ（**DB実測868GB**、コアのみオフサイト・市場データは再構築訓練）4. 安全DDL機械強制（squawk+env.py lock_timeout）5. Docker起動信頼性（自動起動確実化+ClickHouse残骸削除）6. **Python 3.12 移行（3.11 EOL=2026-10-31、numpy制約はwheel解消済み）**+uv exclude-newer 7. docs階層分離（AI正本/アーカイブ+鮮度CI）

## レッドチームで潰された提案（重要な再発防止知見）
- **Postgres の Windows ネイティブ化は不成立**: compose に otel-collector/llm-gateway が既定起動同居で Docker 依存は消えない。868GB restore は Linux glibc→Windows の照合順序差でサイレント索引破損リスク。pgvector の Windows 導入は AI 委任困難
- **タスクの SYSTEM 実行化は false-green の新種源**: uv がマシン PATH に無い（run_tool.ps1 は素の uv）/ BFF は Docker Desktop のユーザーセッション名前付きパイプ依存 / cwd=System32 で相対パスがサイレント別所書き込み / Obsidian 等ユーザー ACL パス不達 / Ollama・LM Studio はログオンセッション依存。現行の「年数回一括登録」が調査上もベスト
- dead-man's switch は「起動断型」しか検知できず、「完走successだがデータ凍結」型(P-07/10/13)は内容プローブという**別機構**の仕事 — 混同しないこと

**Why**: 今後のアーキテクチャ議論・提案はこのドキュメントが基準線。同種の「ネイティブ化」「SYSTEM化」「オーケストレータ導入」提案が再浮上したら第9章の反証を先に参照。
**How to apply**: Adopt 着手時は Phase 0（quick wins）から。関連 [[project-hidden-asset-screener-2026-07-05]]
