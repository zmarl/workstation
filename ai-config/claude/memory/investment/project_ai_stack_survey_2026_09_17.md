---
name: project-ai-stack-survey-2026-09-17
description: "2026-09-17 の AI スタック調査レポート（PR #454、改訂 2 = PR #455）と ODR-0044（vLLM 主・Ollama 廃止・外部 OCR 停止・MCP 標準装備）の所在・決定・残る判断・IV データの欠陥と、執筆時に踏んだ罠"
metadata: 
  node_type: memory
  type: project
  originSessionId: 6ef95231-1e05-413f-9a54-045279c28522
  modified: 2026-09-17T06:07:06.929Z
---

# AI スタック調査と技術提案レポート（2026-09-17、PR #454 マージ済み）

**所在**: `docs/research/20260917-ai-stack-survey-and-technology-proposal.md`（15 章・約 1,520 行）+ 出典一覧 `docs/research/20260917-ai-stack-survey-sources.md`（機械生成 975 件、本文の記号 B/E/M/A/K/O+番号に対応）。台帳 `docs/research/registry.yaml` に `RES-AI-STACK-SURVEY-20260917`（artifact 2 件）と、リポジトリ外の第 4 版 HTML を `RES-LINUX-REBUILD-PLAN-V4-20260916`（`external://investment-design-docs/...`、sha256 `ceddc905…`）で登録。merge commit は `git log` で確認（head `a0dcea806`、base `41aa2ae52`）。

**オーナー回答（拘束）**: 案 A（既存資産を土台に AI 層新設）と案 B（データだけ引き継ぎ白紙選定）を同深度で比較／第 4 版の既選択（llama.cpp・Docker・ブラウザ画面・Ollama 埋め込み等）は再評価して代替も提案／任意領域は音声（実用レベルの候補がある場合のみ）・学習基盤・GPU 分析・開発用 AI ツールを含める／第 4 版 HTML は台帳登録のみ（Markdown 化は別タスク = 判断事項 N18）。

**結論の骨子**: 推奨は「案 A の骨格に案 B の部品を取り込む混成」。両案で同じ: 基盤・データ・モデル層・決定論検証・外部 LLM API なし。第 4 版から変える提案 = pg_trgm → **PGroonga**、Ollama 撤去（llama-server Router か TEI）、**MTP 投機デコード**を評価セットで A/B、**Gemma 4 31B**（Apache-2.0 化）を主読解の対抗馬に、外部有料 OCR（Google Cloud Vision、`tools/converters/pdf_to_markdown/ocr_processor.py`）の停止、pgvector の HNSW VACUUM 修正は **0.8.3/0.8.4**（第 4 版の「0.8.6」は不正確）、自作ループ + **Pydantic AI 部品**、開発用 read-only MCP（凍結明け）、管制盤 + 台帳の観測、pgBackRest と復元訓練、UPS + NUT、ext4。埋め込みは Ruri v3 310m（768 次元互換、JFinTEB 2 位）。vLLM/SGLang の「Blackwell 対応」は主に SM100 で sm_120 は条件付き。llama.cpp は公式 cuda-13.3 バイナリ + 120a-real 既定で摩擦最小。

**重要な事実（反証検証済み）**: RTX PRO 5000 72GB の MIG は NVIDIA 一次資料で未確認（公式一覧は 48GB 行のみ。「2×36GB」は二次記事の推測）／CUDA コア 14,080 は NVIDIA データシート PDF（48GB 版）に記載、HTML 製品ページには無い／DuckDB 1.4 LTS のコミュニティ支援は 2026-09-16 で終了／Unsloth 2026.9.5 の上限は torch<2.13（Python は <3.15）／NIM 無償枠は非本番限定／LiteLLM 2026-03-24 事故の `.pth` は 1.82.8 のみ。

**レポート公開後に判明した補足（09-17）**: 他セッションの locked worktree に、レポートの推奨と重なる評価が進行中 — `codex/rtx5000-fp8-thinking-evaluation`（09-11、RTX PRO 5000 で FP8 + thinking の評価。レポートは FP8 を案 B の経路として扱った）と `codex/flash-next-initial-analysis`（09-12、Qwen3.8-Flash-Next。レポートは 72GB に入らないとして見送り）。**N5（推論サーバー）・N10（主読解の A/B）を決める前に、これらの worktree の実測を確認する**（中身は未読・未マージ）。`labs/` は `__pycache__` だけの残骸で fine-tuning の実装は現存しない。`.venv-wsl` に unsloth/transformers が入っているが駆動コードは無い。

**未決（第 14 章 N1〜N19）**: N1 混成の採否、N5/N6 llama.cpp 継続と Ollama 撤去（ODR-0041 改訂候補）、N7/N8 PGroonga と Ruri v3 への切替（全件再索引）、N9 外部 OCR 停止、N3 `pg_upgrade --link` の前提 = 復元訓練合格、N18 第 4 版の Markdown 化 ほか。

**Why**: 次の会話は「案 A 混成で進めるか」と ODR-0041 の改訂、再構築前ゲート（第 1 章）の実行判断から始まる。第 4 版（外部 HTML）と `docs/audits/20260915-...md`（第 2 版相当）は不一致のまま。
**How to apply**: 技術選定の議論はこのレポートの章番号と記号（例: E3 = 投機デコード、K6 = PGroonga）で参照する。数値は取得日 2026-09-17 時点。着手は次番号の ODR（OWNER_INTENT §4 の「Linux 移行への着手」凍結）が先。関連: [[project-linux-rebuild-report-2026-09-15]]、[[feedback-review-placement-markdown-canonical]]、[[feedback-no-extra-billing]]。

## 同日午後: ODR-0044 起票とレポート改訂 2（PR #455 マージ、merge commit `ef338ed20`）

**オーナー決定（2026-09-17）**: 選定原則「同等なら維持、運用上・機能上良くなるなら刷新」／**Ollama 廃止**／**外部有料 OCR（Google Cloud Vision）全面停止 → ローカル OCR**（PaddleOCR-VL-1.6 vs GLM-OCR を評価セットで 1 本。YomiToku は非商用のため不採用）／PostgreSQL は推奨経路 + PGroonga／推論は私の提案どおり **vLLM 主・llama.cpp 予備・SGLang 不採用**（切替完了条件 = 評価セットで FP8 が Q8_0 と同等以上、127.0.0.1、profile 再発行。満たすまで通常アプリは llama-server のまま）／**MCP を製品経路に標準装備**（許可一覧・読み取り自動／書き込み承認・MCP 由来文章はデータ扱い・秘密を渡さない・台帳記録）／Phoenix 最初から／GPU 計算レーン（CUDA 13.4 + RAPIDS 26.08 + cutile-rs。cuda-oxide はアルファで追跡のみ）／日経225 IV スキューマップを拡張の試金石に。正本: `docs/decisions/20260917-ai-stack-renewal-and-inference-engine.md`（D1〜D11、Accepted/Planned、ODR-0041 を amend）。**「Linux 移行への着手」凍結は解除していない**（別 ODR）。OWNER_INTENT §3・§7 に反映済み。registry の disposition は `partially_adopted`。

**訂正した事実**: TradingView には**公式 MCP サーバー**（`https://mcp.tradingview.com/mcp`、ベータ、OAuth 2.1、Essential 以上のプラン、任意クライアント可、約 100 req/分、**オプションデータなし**）がある（私は最初「非公式のみ」と答えて誤った。オーナーの指摘で判明）。Qwen3.8-Flash-Next は llama.cpp で PLE 埋め込みだけ CPU に置けば GPU 61.9 GiB + RAM 27.5 GiB で起動できる（別セッション実測。品質未合格・商用制限で候補には戻さない）。

**別セッションの未統合実測（`codex/rtx5000-fp8-thinking-evaluation`）**: vLLM 0.28.0（Docker/WSL）+ Qwen3.8-27B FP8 + MTP3 で純デコード 56.7〜60.2 tok/s（CUDA Graph 有効。eager だと 12 tok/s）、GPU ピーク 37.9 GiB。80B NVFP4 MoE は起動 47.3 GiB だが 7 tok/s で時間超過（sm_120 の MoE/NVFP4 経路は未熟）。品質合格・通常アプリ採用は未達と明記。→ 密モデルの FP8 は使える、MoE NVFP4 はまだ。

**IV スキューマップ用データの事実**: `raw.jquants_derivative_bars_daily`（product_group `nk225_option`）に 2016-09-01〜2026-09-15 の 10,518,770 行、全行 IV あり、最新日 9,836 契約・27 限月・339 行使価格。**型付き列 strike/contract_month/put_call/expiry_date は全行 NULL** — `save_derivative_bars` の rename_map が旧 API 名（StrikePrice/ContractMonth/PutCallDivision/DeliveryDay）で、現行 v2 の `Strike/CM/PCDiv/LTD/SQD` を写していない。値は `payload_json` にある（Fear & Greed は payload から読んでいる）。全期間集計は 1 本 40〜60 秒。修正は rename_map 追加 + payload からの UPDATE 埋め戻し（DDL 不要）、索引追加は Alembic。画面は Plotly.js を推奨（recharts はヒートマップ不向き）。

**残る判断**: FP8 vs Q8_0 の品質差、OCR の 1 本化、TradingView の契約プラン確認、Linux 着手の凍結解除時期、スキューマップの断面（オーナーが画像を共有予定）。

## 執筆時の罠（再発防止）

- **Ready gate の `--expected-head` は 40 桁の完全 SHA 必須**（短縮 SHA は `expected_head_invalid` で preflight 失敗）。
- **worktree に `.venv` が無いと `uv run --no-sync` は空 venv を作って `yaml` 不在で落ちる** → 最初の 1 回は `uv run python`（sync あり）で実行する。
- worktree セッションでは `git -C D:/Dev/Investment ...` も hook が拒否する（origin/main の確認は worktree 内で `git fetch origin main`）。

- **worktree セッションの子エージェントは Bash が全面拒否される**（hook の cwd 判定。`cd` しても不可）。調査エージェントには Write/WebFetch/WebSearch だけで完結する指示を書き、YAML の機械パースは親が `uv run --no-sync python -c` で行う。
- **Windows コンソール出力は cp932** → Python の digest スクリプトは `sys.stdout.reconfigure(encoding="utf-8")` を先頭に。長い出力は persisted file になるので Read で読む。
- **pytest は `D:\DevTemp\kazum\pytest-of-kazum\pytest-current` で PermissionError** になることがある → `--basetemp=<scratchpad>/pytest-tmp -p no:cacheprovider` で回避。
- **出典が多い調査は本文と出典一覧を分ける**（registry の `artifact_paths` 2 件、`content_hash` は両ファイルの結合。本文を 1 文字でも直したら再計算）。`registry.yaml` の `sources` は代表 URL 60 件程度に留める。
- Python の stdout リダイレクトは CRLF になる → 生成ファイルは LF に正規化（repo は `text=auto eol=lf`）。
- `sync_repo.py status --json` に claim ID は出ない。`git worktree list --porcelain` の `locked` 行（`agent-session-v2:claude:<task>:<claim_id>:{...}`）から取る。
- docs-only の Ready gate は同期レーンだけ（`harness-docs`）で `pending_async` にならず、数十秒で `passed`。`finish-pr` は ODR-0038 中 `WEEKLY_AUDIT_ADVISORY` を出して統合へ進み、今回は worktree と branch の削除まで完了した（uv hardlink の `CLEANUP_DEFERRED` は出なかった）。
