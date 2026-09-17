# 計画: 『全体設計書 — Linux ネイティブ・AI ネイティブ・ローカル LLM ネイティブな作り直し』（新しい HTML）

## Context（なぜ）

第 4 版（移行計画）は「どう移すか」。オーナーの新しい要望は「移した先で、どう作るか」を全体像の図と詳細で示すこと。
- 不満: 機能が中途半端で機能同士がつながらず判断材料にならない／見せ方（グラフ・表）が貧弱／決算分析が使える形で動いていない。**データ基盤は使えるレベル**。
- 方針（本セッションの回答で確定）: **完全に刷新したものを作る。旧アプリ（BFF・Desktop）は Linux では起動せず参照専用。表示を急がないので作っている間は画面が無くてよい。25 画面の機能は「写す」のではなく 1 から作り直して同じ機能を持たせる**。
- GPU 2 枚を活かす（5070 Ti は「別モデルを丸ごと」+ PyTorch/GPU 計算）。CUDA 以外の GPU 活用も。財務モデルは**純利益まで**。拡張性。決算分析はコア。モデル切替前提・タスク別モデル。音声は**コーディング指示とチャットの両用途**。個人利用（速度・性能・ユーザビリティ優先）。言語・技術が最善かの説明。BitLocker の答え。
- **同日にオーナーが決定した ODR-0044**（`docs/decisions/20260917-ai-stack-renewal-and-inference-engine.md`、Accepted）と AI スタック調査レポート改訂 2（`docs/research/20260917-ai-stack-survey-and-technology-proposal.md`、1,663 行）に**従う**: D1 同等なら維持・良くなるなら刷新／D2 推論は **vLLM 主（Qwen3.8-27B FP8、版固定、127.0.0.1、gpu-memory-utilization 明示、NVFP4 保留）・llama.cpp 予備**（切替は評価セットで Q8_0 と同等以上を確認してから）、SGLang 不採用／D3 **Ollama 廃止**、埋め込み・リランクは **TEI か vLLM pooling** で 5070 Ti（Ruri v3 310m、全件再索引）／D4 **外部有料 OCR 全面停止**、PaddleOCR-VL-1.6 か GLM-OCR を評価で 1 本／D5 PostgreSQL 推奨経路 + **PGroonga**／D6 **MCP クライアントを製品経路の標準装備**（許可一覧・読取自動/書込承認・MCP 由来の文はデータ・秘密と正本書込権限を渡さない・台帳記録）、TradingView 公式 MCP は既存契約の範囲、NeMo Agent Toolkit を評価／D7 Tauri を外しブラウザ配信、AG-UI 語彙、契約生成／D8 **Phoenix を最初から**／D9 **GPU 計算レーン（CUDA 13.4 + RAPIDS 26.08 + CUDA Python + cutile-rs（CUDA Rust））**で決定論の計算器を高速化（5070 Ti 側か夜間）／D10 **日経225 IV スキューマップを拡張の試金石**（`raw.jquants_derivative_bars_daily` 1,051 万行、型付き列 NULL → payload_json から埋め戻し）／D11 **Linux 移行の着手凍結は解除されていない、ODR-0038 のハーネス凍結（〜10/7）中は新しい台帳・queue・hook を作らない**。
- 「参照のところは 1 回作業した」= この並行作業と NAS/BitLocker 確認。設計書は改訂 2 と ODR-0044 に依拠し、技術選定を再調査しない。**ODR-0044 D7「既存 React をブラウザ配信」と本セッションの「完全刷新」の関係**は設計書で明示する: 技術（React・FastAPI・PostgreSQL）は維持、画面と機能の実装は新しい木で 1 から。旧画面は起動しない（移行直後の確認は BFF/API のスモークと新しい木の最初の画面で行う）。

成果物: **`D:\Dev\Investment_設計資料\全体設計書_LinuxネイティブAIネイティブ_2026-09-17.html`**（新規、第 4 版とは別文書、図 18 点前後）。設計書は決定ではなく提案（着手は別 ODR）。

## 調査で確定した事実（Phase 1、出典は設計書の付録へ転記）

### 並行セッションの成果（依拠する）
- 改訂 2 の層別第一候補: 基盤（Ubuntu 26.04.1・ドライバ 595 open・CUDA 13.4・Docker 29+CDI・pgBackRest・NUT・ext4）／データ（PG16 同一イメージ→16.15+pgvector 0.8.6→18.6 --link、DuckDB 1.4.5/1.5）／推論 vLLM 主・llama.cpp 予備／モデル（初日 Q8_0、切替後 FP8、対抗 Gemma 4 31B、小型 Nemotron-Nano-9B-Japanese）／埋め込み Ruri v3 + Reranker を TEI か vLLM で B に／エージェント（自作ループ + Pydantic AI 部品 + MCP クライアント、NeMo Agent Toolkit 評価）／ジョブ（systemd timer、DBOS は凍結明け）／知識（pgvector + PGroonga + RRF）／OCR ローカル／品質（決定論検証 + 評価セット + 管制盤 + 台帳 + Phoenix）／アプリ（FastAPI + React ブラウザ配信、fetch+ReadableStream、AG-UI、orval/openapi-typescript）／任意（音声 Qwen3-ASR、学習 Unsloth/TRL 別 venv・LoRA は vLLM で直接配信、GPU 計算レーン、IV スキューマップ）。
- 4.8 の実測引用（未統合 worktree）: vLLM 0.28.0 + 27B FP8 + MTP 3 で純デコード 56.7〜60.2 tok/s、GPU 最大 37.9GiB。80B NVFP4 MoE は 7 tok/s で不可。Flash-Next は CPU 併用で起動可だが品質未合格・商用制限。
- 6.10 MCP 設計（置き場所 = BFF 内エージェント層、許可一覧、自律度の目盛り、混入対策、秘密と正本、記録、通信）。TradingView MCP（OAuth 2.1、Essential 以上、100 要求/分、**オプションデータなし**→ IV は J-Quants が正本）。
- 11.3 計算レーンの型: 「入力の指紋 → 決定論の関数 → 出力と版」で登録し、実装が Python/RAPIDS/Rust でも呼び出し側は区別しない。CPU と GPU の同値テスト後に GPU を既定に。11.5 IV スキューマップの作り方 6 段（取込の列名修正と埋め戻し（DDL なし）→ 計算器（IV 面・マネーネス正規化・スキュー指標・期間構造・分位）→ 保存（新表は凍結明け、それまで BFF でその場計算 + キャッシュ）→ 画面（**Plotly.js 推奨**: ヒートマップ・曲面・スライダー）→ LLM は説明だけ → 断面は画像を見て決める）。性能: 全期間集計 1 本 40〜60 秒。
- 残る判断（14.3）: N2 ドライバ枝、N4 UPS、N10 主読解 A/B、N14 ガード、N17 音声、N18 第 4 版 Markdown 化、TradingView 契約プラン、OCR 1 本化、IV 主画面の断面、FP8 品質実測。
- **設計書が担う差分**: ①全体像の図解 ②完全刷新の作業量と進め方 ③財務モデル（純利益まで） ④拡張性のあるリポジトリ構成（「1 機能 = 1 フォルダ」+ 計算レーンの型 + MCP の受け皿） ⑤5070 Ti の使い方 ⑥決算分析コア ⑦音声（両用途） ⑧BitLocker ⑨学習パイプライン群 ⑩25 機能の刷新一覧 ⑪IV スキューマップを「拡張の型」の実例として通す。

### Web 調査（2026-09-17）
- スタック: FastAPI / React 19 + Vite / TanStack / Tailwind / PostgreSQL + pgvector は「現状維持が合理的」（FastAPI vs axum は DB 律速で誤差、React 19+Compiler は Svelte/Solid に 15〜20% 劣るが体感差なし、pgvector 0.8 の iterative scan）。Tauri の Linux WebKitGTK が唯一の実害リスク。Rust/Svelte/専用ベクトル DB/deck.gl/NIM は不要（Rust は GPU カーネル（cutile-rs）にだけ使う）。
- GPU 道具: PyTorch 2.14（sm_120、CUDA 13 wheel 既定）／RAPIDS=CUDA-X／Polars GPU engine（無改修、streaming）／XGBoost cuda／cuOpt／PaddleOCR-VL 1.6／ruri-v3／GLiNER・GLiClass・SetFit／Chronos-2・TimesFM 2.5（ライセンス未確認）。
- 可視化: サーバ（Polars/DuckDB/Arrow）で集計 → Arrow IPC → 数千〜数万行。TanStack Table + Virtual。
- モデル切替: vLLM Sleep L1、論理名ルーティング、評価セットで回帰検出。日本語モデル: Qwen3.5、Gemma 4、GPT-OSS 20B、Nemotron 3 Nano。
- 音声: Aqua Voice/Wispr/Superwhisper は Linux 非対応、Parakeet/Canary は日本語非対応。現実解 = whisper.cpp large-v3-turbo / Qwen3-ASR 1.7B + Handy or Speech Note + ローカル LLM で整形。

### リポジトリ調査（main 41aa2ae52 → 67dbf83e5）
- 製品側 ≒138.5 万行（tools 78.8 万・desktop 40.2 万・db 12.3 万・shared 7.3 万）、ハーネス ≒26.5 万行、tests 54 万行、manifest 431 本。新機能 1 つ = DB→BFF→画面で 20〜30 ファイル・6〜9 工程（Alembic・fingerprint・closeout registry・db_contracts・manifest→.bat→.ps1・gate 分類・3 層の型）。BFF 16.7 万行（router 63、EndpointSpec 518、公開パス 522、serving 8.7 万行）、静的配信なし。Desktop: React 19/Vite 7.3/TS 5.7/Tailwind/Tauri 2.11/TanStack/zustand/zod/recharts 3.8/lightweight-charts 5.1/cytoscape/mermaid、ルート 63、Tauri 依存 10 ファイル + Rust 4.7 千行、手書き `<table>` 108、同名型 68 重複。Desktop は Python 層とゼロ結合。LLM 基盤: provider 文字列分岐、論理名なし、モデル名固定 13 か所、`llm_runtime_policy.py` 単一 GPU 64GiB 要求、Rust 側二重化。埋め込み 768 次元 DDL 固定。`import torch` 0、cu126。
- 契約: DB レイヤー契約、OWNER_INTENT §2 非交渉・§4 凍結（Linux 移行、判断 WF に接続しない新画面、BFF 分割）。負債: 財務取込 07-11 停止、偽の成功、pool の `?`→`%s` 誤変換、195 箇所の同値、preload 死に書き、792 表・255 revision、再取得キュー形式不一致、バックアップ 0。ハーネスは「新しいシステムには移植しない」。

### 財務データ・PL モデル調査（DB 実測）
- `core.financial_facts_resolved_v2` 197 万行・4,520 銘柄・FY2015–2027（縦持ち）、セグメント 188 万行、PL 完全チェーン約 3,870〜3,910 銘柄（86%）、会社予想 55.8 万行、**unit 94% NULL（実値は円）**、コンセンサス 0 行、株価 1,022 万行、日中板 341 万行、日経225 オプション 1,051 万行（型付き列 NULL）。
- **PL 純計算器は既存** `shared/domain/financial_performance.py`（443 行、BFF/Desktop 未接続）。run-rate は純計算のみ。`analytics.financial_models` 0 行、`financial_modeler/` 空。`guidance_credibility_scores`、`kpi_driver_decomposer` ほか既存。画面 `CompanyPL.tsx` 1,673 行 + 9 パネル + 9 チャート、1 銘柄 × 最大 200 期。**PL 決定論計算は 17 万コンテキスト → CPU 数分（GPU 不要）**。品質 `unit_comparison_scope_unverified` 27,953 件、USGAAP セグメント欠落、feature-store と embedding indexer 失敗継続。

## 設計の答え（設計書の骨子）

### 1. 作り直しの方針 = 「完全刷新」（技術は維持、実装は 1 から）
- 3 段階: (a) 新リポジトリ + データ基盤だけ再利用 (b) 同じリポジトリに新しいアプリ層 `app/ web/ ml/` を並置 (c) 現状維持。**採用 (b)**: 結果は (a) と同じだが取込 177 種の切り出し 3〜7 日と履歴喪失を払わない。旧 BFF/Desktop は Linux で起動せず参照専用。全機能が揃った時点で旧側を 1 コミットで削除。ODR-0044 D1 の言い方では「データ・計算器・取込 = 同等なので維持、画面・機能・LLM 基盤 = 良くなるので刷新」。
- 残す: PostgreSQL・Alembic 270 本・baseline・原本、`shared/domain` 約 2 万行、`shared/db`、`shared/llm_gateway`（registry 化）、取込 177 種。捨てる: ハーネス 26.5 万行、manifest→.bat→.ps1、gate 分類、closeout registry、`db_contracts`、旧 BFF 16.7 万行、Desktop 39 万行、紐づく tests、到達不能 3 領域。移植（読んで書き直す）: serving の SQL 4 ファイル（3〜5 千行に圧縮）、企業ページ 9 パネルの表示仕様、決算評価アシスタント、`earnings_asof`、`disclosure_embedding_indexer`、`disclosure_search`、`knowledge_facts.py`。
- 作業量（推定）: M1 画面が戻る 9〜15 日／M2 決算分析 +10〜20 日（±10）／M3 PL モデル +5〜10 日。(c) は M2 だけで 20〜35 日。共通の先行作業: 財務取込停止と unit NULL（1〜3 日）。
- 「変わらないもの／作り直さないと変わらないもの（足すコスト）／設計で直すもの（つながらない）」を明示。25 画面の刷新一覧表（旧 → 新機能 + 直す不満）。

### 2. リポジトリ構成と拡張の流儀（`app/ web/ ml/ gpu/`）
- `app/core/{db.py, ids.py, contracts.py, arrow.py, registry.py, llm.py（論理名→vLLM/TEI/llama-server）, mcp.py（許可一覧つき MCP クライアント）, calc.py（計算レーンの型: 入力の指紋→決定論関数→出力と版、CPU/GPU 実装の同値テスト）, jobs.py（tasks.yaml→systemd unit）}`、`app/features/<name>/{schema.py, router.py, tool.py, tasks.yaml, tests/}`、`web/src/features/<name>/page.tsx`（自動収集）、`web/src/lib/api.d.ts`（生成のみ）、`web/src/lib/{table, chart}`（TanStack Table+Virtual、recharts、Plotly.js）、`ml/{registry/profiles/*.yaml, serve/, experiments/, promoted/}`、`gpu/`（cutile-rs の Rust カーネル crate、PyO3/maturin で Python から呼ぶ。cuda-oxide は追跡のみ）。
- **拡張の受け皿 3 種**: データ源（取込モジュール or MCP サーバー（許可一覧に 1 行））、計算器（Python/RAPIDS/Rust の同型登録）、画面（page.tsx 自動登録）。新機能 = 3〜5 ファイル・2 工程。ハーネスの代替 3 つ（systemd 生成 150 行、typegen pre-commit、`pytest --testmon` + `vitest --changed`）。
- venv: `.venv`（app、torch なし）、`.venv-infer`（torch 2.14 cu130・RAPIDS・xgboost・polars[gpu]・GLiNER・SetFit）、`.venv-train`（Unsloth）。vLLM/TEI/Phoenix はコンテナ（127.0.0.1 束縛、CDI）。ML の本番は 5070 Ti 側の常駐 HTTP（ml-serve）。
- 境界維持: web→BFF のみ、PostgreSQL write 唯一、Alembic、発注禁止、外部 LLM API なし、BFF 1 プロセス。**凍結**: 新表（`ops.model_assignments`・`lab.runs`・`ops.gpu_samples`・`analytics.earnings_analysis_feedback`・`evidence_links` 拡張・IV 分析表）は ODR-0038 明け or 次の ODR。それまで YAML/JSONL・既存表（`ops.ml_evaluation_runs`、`analytics.financial_models`、`knowledge.*`）で代替。

### 3. 言語・技術の選定と「今が最善か」（第 5 章の答え）
- 維持: Python 3.12 + FastAPI、React 19 + Vite、TanStack、Tailwind、PostgreSQL 18 + pgvector + PGroonga、DuckDB（研究）、Polars + Arrow/Parquet、systemd、uv。2026 年の根拠と採らない代替の理由（axum/Go・Svelte/Solid・Next.js・Tauri・専用ベクトル DB・deck.gl・NIM・LangGraph・Prefect/Temporal・SGLang・Ollama）。
- 変更（ODR-0044 に沿う）: **ブラウザ配信・React 継続 = そうすべき**。推論 vLLM 主・llama.cpp 予備。埋め込み TEI/vLLM。OCR ローカル。MCP 標準装備。Phoenix。GPU 計算レーン（RAPIDS・CUDA Python・cutile-rs）。charts = recharts（企業ページ）+ **Plotly.js（ヒートマップ・曲面・等高線: IV マップ・感度格子）**、uPlot は任意。手書き型・zod を廃し生成型のみ。Rust は GPU カーネルにだけ使う（アプリ層には使わない理由）。
- 個人利用ゆえに落とすもの: 認証・多テナント・監査ゲート・全域回帰 CI・Prometheus/Grafana。

### 4. 判断材料の連鎖
- 共通識別子 `ids.py`（code、FiscalPeriod、document/version、fragment_id、fact_id、model_run_id、agent_run_id）、共通部品 3 つ（EarningsContext・SourceRef・meta.versions）、`evidence_links` 拡張（凍結明け）。規則「どの画面の数値・文もクリックで別の段に着地。着地先が無いものは表示しない」。企業ページハブ `GET /company/{code}?period=`。

### 5. 財務モデル（PL シート、純利益まで）
- 行 = 売上・原価・粗利・販管費・営業利益・営業外収益/費用・経常・特別損益・税引前・法人税等（実効税率）・純利益 + 率 4 つ + EPS。列 = FY×Q（単独/累計/年度/TTM）。layer 3 系列（L0 実績 = `financial_performance.py` を純利益まで拡張、ブリッジは営業利益まで厳密／L1 会社予想 + 版 + 進捗率／L2 推定 = run-rate + 季節性 + セグメント積み上げ + 営業外・税率の仮定 + 感度格子）。シナリオ = パラメータ集合（率の上書きと金額固定の両方）。
- 新設 `shared/domain/pl_model_sheet.py`、`app/features/pl_model/`（input_adapter 共用、batch、repository → `analytics.financial_models` 実使用、jsonb 内の版）。通り道: resolved_v2 → 単位・連結範囲アテステーション（一括、conflict は除外）→ Polars 横持ち → 計算器（**計算レーンの型で登録。全銘柄再計算は cuDF/cutile-rs に載せられるが CPU で数分なので既定は CPU**）→ Parquet → BFF → 画面。API `/api/v2/company/{code}/pl-model`、`/api/v2/pl-model/compare`。
- 見せ方: `PLModelTable`（TanStack + Virtual、layer 帯色、単位切替、理由ツールチップ）+ recharts（ブリッジ・積み上げ・利益率・PL 推移、新規: シナリオ帯・進捗率バレット）+ Plotly（感度格子のヒートマップ）+ 出典 drawer。判断材料の表示規則。ピア比較（peer-group、順位なし）。

### 6. 決算分析コア
- 既存 pack→LLM→検証→保存→通知を核に、KPI 抽出 3 層（Tier 0 表セル決定論 310 万セル→`core.metric_observations`／Tier 1 GLiNER・GLiClass（GPU B）／Tier 2 LLM 候補のみ）→ 承認（`ir-evidence-review`）→ `core.metric_series`。PL シートへ観測行。配信（企業ページ・Discord・朝の当番）。管理（feedback、reevaluate、blocked 576 の集計）。LLM は `reader.deep`（vLLM、JSON Schema 強制）。

### 7. GPU・ML 基盤（ODR-0044 D2/D3/D9 に合わせて改訂）
- 配置台帳（GiB 推定）: **GPU A 72** = vLLM `reader.deep` 27B FP8 ≈26〜28 + fp8 KV 64K ≈2 + vision + CUDA graph（実測ピーク 37.9、MTP 3）常駐 ≈30〜38；余白 30 以上（対抗 Gemma 4 31B FP8 ≈32 は同居させず入れ替え = vLLM Sleep L1 or 別プロセス）；夜間枠 QLoRA 27B 22〜30（主を CPU RAM へ退避）；移行初日は llama-server Q8_0（≈32.4 実測）。**GPU B 16（実効 15.5）** = 画面 0.5〜1.5 + TEI（Ruri v3 0.6 + Reranker 0.6）+ vLLM OCR VLM（GLM-OCR ≈3 or PaddleOCR-VL ≈2）+ Qwen3-ASR 1.7B ≈3.9（or whisper.cpp turbo 1.7）+ ml-serve（GLiNER/SetFit/時系列）≈1 + 計算レーン枠 2〜3 + `reader.fast` 9B 級（vLLM、上限を明示）≈5.5 ≈ 15。GPT-OSS 20B は OCR/ASR を落とす別モード。B は複数プロセスなので `--gpu-memory-utilization` をプロセスごとに切る。
- 「主 LLM の余りを B に層分割」は採らない（27B は A に丸ごと収まる／PCIe 往復で遅い／B の常駐群が置けない／120B 級は KV 余地なし）→ **別モデルを丸ごと**。
- 論理名 `reader.deep / reader.fast / extract.ner / extract.llm / classify.<task> / embed / rerank / ocr / asr / code / dictate.format`。対応表 = `ml/registry/profiles/*.yaml`（エンジン vllm/tei/llama-server/ml-serve、重み sha256、量子化、GPU UUID、引数、VRAM 予算）+ 割当（凍結中は YAML `assignments.yaml` 追記、凍結明けに `ops.model_assignments`）。Gateway `resolve()`。回帰検出 = `lab/evalsets/<logical>.jsonl` → promptfoo/Inspect → `ops.ml_evaluation_runs`（既存）→ 閾値 → 割当追記。**vLLM 切替の完了条件 = ODR-0044 D2**（FP8 が Q8_0 と同等以上、127.0.0.1、profile と検証器の再発行）。
- 置き換える現行コード: `shared/llm_runtime_policy.py`（廃止→`llm_gateway/registry.py`）、`current_runtime.py`、`__init__.py` provider 分岐、`ollama.py`・`shared/ollama_client.py`（退役、削除は shadow/rollback 証拠後）、`config.py` 13 か所→4 項目、`runtime_profile.py`、`qwen_runtime.rs`（削除）、import 元 11 ファイル。
- GPU 活用の順: ①埋め込み一括（TEI、B）②OCR（vLLM、B）③ASR（B）④XGBoost cuda ⑤Polars GPU engine（数百万行以上）⑥計算レーン（cuDF/CUDA Python/cutile-rs: IV 面の全期間再計算 1,051 万行、全銘柄 × 全日次の特徴量 307 万行、EDINET facts 1.37 億行）⑦torch.compile ⑧Chronos-2/TimesFM（CPU 基準比較必須）⑨cuOpt（任意）。不要: cuVS、TensorRT。Nsight Compute で計測。
- 学習 4 本（`lab/`、Parquet、時点規律、venv 分離、`ops.ml_evaluation_runs`）: 埋め込み（Ruri v3 MNRL+Matryoshka 768 維持、TEI で配信、昇格時全件再索引）／KPI 抽出器（表セル弱教師 + GLiNER、出口は数値逐語検証）／小型分類器（SetFit）／時系列（基準 → Chronos-2 → XGBoost cuda）。**LoRA は vLLM multi-LoRA で GGUF 変換なしに配信**（D2 の利点）。
- 観測: pynvml 5 秒サンプル（凍結中は JSONL、明けに `ops.gpu_samples`）、vLLM `/metrics`、TEI、ml-serve キュー → 管制盤。**Phoenix 1 コンテナ**（OTel、外部送信なし）にエージェント実行痕跡。

### 8. エージェント・MCP・知識ベース（第 4 版第 9・10 章を新構成へ写像 + ODR-0044 D6）
- 自作ループ + Pydantic AI 部品（承認一時停止・構造化出力・OTel・MCP クライアント）、状態は既存 PostgreSQL 表。**MCP クライアントは BFF 内エージェント層に標準装備**: 許可一覧（サーバー・ツール単位、設定ファイル、無いものは列挙しない）、読取自動／書込・外部送信・構成変更は `requires_approval`、MCP 由来の文はデータ、秘密と正本書込権限を渡さない、MCP 経由の数値は T4、台帳記録（既存台帳の列、新台帳なし）、通信 HTTPS+OAuth 2.1 / stdio / 127.0.0.1。TradingView 公式 MCP（Essential 以上の契約確認が前提、書込系は承認、オプションなし）。開発用 read-only MCP（postgres-mcp restricted、Obsidian）も同じ一覧。NeMo Agent Toolkit は MCP 集約・プロファイラとして評価。
- 知識ベース（第 4 版第 10 章）: 文書→版→断片→主張、pgvector + PGroonga + RRF、`/api/v2/knowledge/ask`、引用検証。当番（朝・夕・書記・還流）。

### 9. 拡張の試金石: 日経225 IV スキューマップ（ODR-0044 D10 を「1 機能 = 1 フォルダ」で通す実例）
- `app/features/nk225_iv/`: tool.py（取込の列名対応を `Strike/CM/PCDiv/LTD/SQD` に直し、既存 1,051 万行を payload_json から UPDATE で埋め戻し。DDL なし。索引追加は凍結明け）→ calc（計算レーンの型: 日付ごとの IV 面・マネーネス正規化曲線・スキュー指標（OTM プット − OTM コール、90%/110% or 25Δ）・期間構造（第 1〜3 限月 ATM）・過去分位。Polars 実装 → cuDF/cutile-rs 実装の同値テスト。全期間 40〜60 秒/本 → GPU レーンで短縮）→ 保存（凍結中は BFF その場計算 + Parquet キャッシュ、明けに分析表）→ page.tsx（Plotly.js ヒートマップ・曲面・日付スライダー・スキュー時系列、「この図の見方」）→ LLM 説明（`reader.deep`、数値の算出なし）。断面はオーナーの画像を見て決める（未決）。TradingView MCP はこの機能には使えない（J-Quants が正本）。
- この 1 本で確認する拡張性: データ源の修正 → 計算器登録 → 画面自動登録 → LLM 説明が境界を崩さず通ること。

### 10. 音声入力（両用途）と開発環境
- 本線: Handy + whisper.cpp large-v3-turbo（B）→ 品質が要る場面は Qwen3-ASR 1.7B（ml-serve or vLLM）→ `dictate.format`（`reader.fast`）で整形、**モード 2 つ**（`code`: フィラー除去・識別子/パス保持・箇条書き／`chat`: 句読点・段落・敬体）をホットキー切替。品質目安（読み上げ CER 5〜8%、会話 14〜18%、整形後「意図通り」9/10 を 50 発話で測る）。補助: Claude web/ChatGPT web のマイク（Linux ブラウザで未確認）。予備: スマホ音声入力 → KDE Connect/LocalSend。開発: Claude Code / Codex（サブスク内）。

### 11. BitLocker の答え
- 実機の証拠は「暗号化されていない」側（Home で未確定）。暗号化されていても Linux は `cryptsetup open --type bitlk`（回復キー）で読める → **回復キーがあれば持っていける**。推奨は **Windows 退役前に「デバイスの暗号化」を OFF にして復号完了**（4TB は数時間）。理由: 当日の変数を減らし、qemu-nbd で VHDX を開く前に復号層を挟まない。

### 12. 実装の順序（依存順、暦なし。着手は別 ODR）
1. 移行（第 4 版第 3〜5 章 + 改訂 2 の再構築前ゲート: 救出→退避→組立→sm_120 スモーク（llama.cpp Q8 と vLLM FP8 の両方）→DB 復元→pgBackRest 訓練）。旧 BFF/Desktop は起動しない。初日の LLM は llama-server Q8_0 の profile。
2. `app/core` + `web/` 殻 + typegen + systemd 生成器。取込 177 種を `tasks.yaml` で載せ、財務取込停止と unit NULL を潰す。
3. `features/company` + `financials` → `prices`・`screening`・`today` → **M1**。
4. LLM registry（論理名・vLLM A・TEI/vLLM B・ml-serve）+ 評価セット 30 問 + vLLM 切替判定（D2）+ `features/knowledge`（断片・PGroonga・Ruri v3・問う）+ MCP クライアントと許可一覧 + Phoenix。
5. `features/nk225_iv`（拡張の試金石、計算レーン初出）。
6. `features/earnings`（pack→抽出 3 層→承認→配信→管理）→ **M2**。
7. `features/pl_model`（純利益までのシート・シナリオ・比較）→ **M3**。
8. `features/agents`（当番・書記係）、管制盤、残りの機能（業種/ピア・サプライチェーン/相関図・マクロ・ニュース・規制・イベント…を 1 から）。
9. 学習 4 本、音声、凍結明けの新表 6 つ（Alembic）、旧木の削除。

## 成果物の構成（HTML、18 章・図 18 点前後）

| 章 | 内容 | 図 |
|---|---|---|
| 0 要約 | 結論 8 行（完全刷新・技術は維持しブラウザ配信・vLLM 主・GPU は「別モデルを丸ごと」+ 計算レーン・PL は純利益まで・MCP 標準装備・BitLocker）、最初にやること、決めていただきたいこと | — |
| 1 前提と方針 | 要望の整理、ODR-0044 と改訂 2 への依拠（決定済み／残る判断の対応表）、個人利用ゆえに落とすもの、守る境界と凍結 | — |
| 2 全体像 | 1 枚の層図（基盤／データ／計算レーン／LLM・ML／エージェント・MCP／機能／画面／運用・観測）と流れ | 図 1 全体像、図 2 層と技術の対応 |
| 3 作り直しの方針 | 3 段階、残す/捨てる/移植の面積図、作業量、旧アプリは参照専用、25 機能の刷新一覧 | 図 3 面積図、表 刷新一覧 |
| 4 リポジトリ構成と拡張の流儀 | `app/ web/ ml/ gpu/`、自動登録、受け皿 3 種、計算レーンの型、ハーネス不採用、venv とコンテナ、凍結中の代替 | 図 4 構成と自動登録（旧 6〜9 工程との対比）、図 5 計算レーンの型 |
| 5 言語・技術の選定と理由 | 維持/変更の表と根拠、採らない代替、ブラウザ配信と React の是非、Rust の使いどころ | 図 6 技術スタック地図 |
| 6 データ基盤 | 正本表、Alembic、原本、品質課題、Parquet キャッシュ、DuckDB、PG18 経路 | 図 7 データ層 |
| 7 判断材料の連鎖 | 識別子・SourceRef・versions、企業ページハブ、着地規則 | 図 8 識別子の連鎖、図 9 企業ページ骨格 |
| 8 財務モデル | PL シート 3 層（純利益まで）、シナリオ、通り道、見せ方、ピア比較、最初の 1 本 | 図 10 PL シート、図 11 通り道 |
| 9 決算分析コア | KPI 抽出 3 層、接続、配信、管理 | 図 12 抽出 3 層 |
| 10 エージェント・MCP・知識ベース | 自作ループ + Pydantic AI、MCP 許可一覧と承認、TradingView、知識ベースと当番（第 4 版へ参照） | 図 13 MCP の受け皿と境界 |
| 11 GPU・ML 基盤 | 配置台帳 3 モード、層分割を採らない理由、論理名ルーティング、vLLM 切替条件、評価→昇格、GPU 活用一覧（CUDA 以外含む） | 図 14 配置台帳、図 15 ルーティングと昇格 |
| 12 拡張の試金石: IV スキューマップ | データ・6 段の作り方・計算レーン・Plotly・LLM の役割・確認できる拡張性 | 図 16 IV マップの通り道 |
| 13 学習パイプライン | 4 本（データ・正解・分割・最初の 1 本・GPU/時間・LoRA の配信） | 図 17 パイプライン |
| 14 音声入力と開発環境 | 3 段の対策、整形 2 モード、品質の測り方 | 図 18 音声の経路 |
| 15 運用・観測 | systemd、管制盤 + 台帳 + Phoenix、gpu_samples、バックアップ、モデル切替の運用 | （図 15 と共有） |
| 16 実装の順序 | 依存順 DAG、M1/M2/M3、移行との接続、BitLocker の手順 | 図 19 依存順 DAG |
| 17 リスク・未確認・決めていただきたいこと | 各章の問い集約（推奨つき）、改訂 2 の残る判断との対応 | — |
| 18 付録 | 出典（ODR-0044・改訂 2 の記号・Web URL・実測 SQL）、用語、図一覧、改訂履歴 | — |

## 実装手順（承認後）

1. 作業場所 `scratchpad\design1\`。`report4/` の build.py・head/tail・CSS を複製し、CHAPTERS を 19 章、`OUT_FINAL` を新パス、タイトル・バナーを設計書用に。図の描き方（inline SVG、`fx-*`、「図 N の見方」）と構造検査を流用。
2. Phase 2 の 3 案本文・Web 調査・改訂 2 の差分要点を `scratchpad/design1/src/*.md` に保存。
3. 章 c00〜c18 を執筆（平易な日本語、事実／解釈／推奨／未確認の箱、実測/推定を明記、ODR-0044 と改訂 2 は決定番号・章番号で参照、第 4 版は章番号で参照）。図 19 点を SVG で作成。
4. ビルド → 構造検査 0 → ローカル http.server でデスクトップ/375px の描画検査。
5. 批評 2 本（Workflow: 事実の突き合わせ（リポジトリ・ODR-0044・改訂 2 と照合、特に vLLM/Ollama/OCR/MCP/凍結の記述）／読み手目線）→ 反映 → 再ビルド。
6. `build.py --final` → SendUserFile → 記憶ファイル更新（設計書の所在・結論、ODR-0044 の要点）+ MEMORY.md 索引。
7. 返信: BitLocker の答え、完全刷新の要点、ODR-0044 との整合、決めていただきたいこと。

## 検証
- `build.py` の検査 0 問題。図 19 点の text が viewBox 内・重なりなし、375px で横スクロールなし。
- 批評の「高」指摘 0。数値・表名・ファイル名は Phase 1 実測と ODR-0044 に一致（vLLM 主／Ollama 廃止／外部 OCR 停止／MCP 標準装備／Phoenix／凍結継続）。
- オーナーの回答（完全刷新・全機能を 1 から・純利益まで・音声両用途）と ODR-0044 の 11 決定が本文に反映されていること。

## 守る境界
読み取り専用の調査と設計資料の作成だけ。リポジトリ・DB・Scheduler・`.env`・`secrets/` に触れない。外部 LLM API なし。commit・PR・通知・公開なし。設計書は提案（着手は別 ODR、凍結は解除しない）。

## 設計書の「決めていただきたいこと」に載せる問い
- NAS の空き容量と接続方法、BitLocker の確認結果（暗号化の有無）— 依然未受領。
- 旧木の削除時期（全機能が揃った時、推奨）／夜間学習中に `reader.deep` を止めてよいか／GPU B の小型 LLM は 9B 級常駐でよいか／ピア比較の軸／IV マップの主画面の断面（画像待ち）／TradingView の契約プラン／OCR の 1 本化と主読解 A/B は評価セットの後（改訂 2 の残る判断を転記）。
