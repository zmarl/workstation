# 計画: AI スタック調査と技術提案レポート（新 Ubuntu/NVIDIA サーバー + AI ネイティブアプリ向け）

## Context（なぜ書くか）

- オーナーは数日以内に新 PC（現 PC の部品を移す同一機再構成: Core Ultra 7 265F・96GB・**RTX PRO 5000 72GB＝計算専用**・**RTX 5070 Ti 16GB＝表示と雑用**、Ubuntu 26.04）を組み、即 Linux へ移行する。移行計画自体は第 4 版レポート（2026-09-16、リポジトリ外 HTML）にある。
- 新方向は「私の代わりを務める AI ネイティブなアプリ」（アプリ全体が 1 つのエージェント）＋ 株式投資の個人知識ベース。ローカル LLM をエージェントとして動かす前提。
- 足りないのは「2026 年 9 月時点でどの技術が使えるか」の広い調査と、この環境・制約に合わせた提案。本計画はそのレポート 1 本を書き、リポジトリに着地させるためのもの。
- 守る制約（既存正本より。レポートは変更しない）: LLM は `Desktop → FastAPI → LLM Gateway → ローカル推論` のみ・外部 LLM API 不採用（ODR-0024 決定 6 = `docs/decisions/20260829-qwen38-27b-formal-adoption.md`）、サブスク外課金ゼロ、Desktop→BFF のみ、書き込みは PostgreSQL のみ、LLM 出力は検証なしに判断・DB へ入れない、発注・ETF 恒久除外、ODR-0038 ハーネス凍結（〜2026-10-07。新しい常設検査・台帳・hook を増やさない）、`docs/OWNER_INTENT.md` §4 凍結リストに「Linux 移行への着手」が含まれる → **レポートは調査・提案であり着手ではないと明記する**。

## オーナー回答（2026-09-17、拘束条件）

1. **案 A（既存資産を土台に AI 層を新設）と案 B（データ資産だけ引き継ぎ、アプリ層は白紙で選定）を同じ深さで比較する。**
2. **第 4 版で既に選ばれた技術（llama.cpp 常駐・Docker・ブラウザ画面・Ollama 埋め込み・nomic→ruri 再索引・決定論再ランク・MCP 不採用）は 2026-09 時点で再評価し、代替案も理由と移行コストつきで提案する。** 決定は変えず、提案と判断事項に留める。
3. 任意領域: **音声は日本語で実用レベルの候補がある場合だけ**（無ければ「現時点では見送り」と根拠つきで明記）、**学習・ファインチューニング基盤**、**GPU データ分析（CUDA 活用）**、**開発用 AI ツールの Linux 運用** は含める。

## 前提として置く解釈（確認済み事項から導く。変更が必要ならレポート内で判断事項に載せる）

- **案 B の定義**: PostgreSQL（`knowledge.*` 含む）と原本ファイルは引き継ぐ。アプリ層（API・画面・ジョブ実行・エージェント実行基盤・言語）は白紙で選ぶ。決定論の計算器・検証器はコードなので「同値テスト付きで移植」として費用計上する（案 B を安く見せない）。
- **モデル層は案 A/B の分岐軸ではない**（差は導入順だけ）。節約した分量はライセンスと日本語評価に使う。
- 机上調査 + 新 PC 到着後の受入試験計画。現 PC の稼働状態は変えない。読み物 HTML は作らない（2026-09-16 オーナー決定）。ODR は起票しない（次番号は「次番号の ODR」と書く）。
- 「AI ネイティブ」「PKB」は docs 内に無い語 → 作業語として初出で定義し、正本語彙にしない。

## 成果物と配置（確定）

- **本文**: `docs/research/20260917-ai-stack-survey-and-technology-proposal.md`（Research 区分「問題・調査・採否」。前例 `docs/research/20260906-advanced-analysis-candidates.md` と同型）。front matter なし（`research_evidence` プロファイル）。冒頭は 4 点見出し（目的／調査方法／調査時点／注意）。日本語、mermaid（`flowchart` のみ・≤25 ノード・raw HTML 不可）、GFM 表（≤8 列・セル内に `|`/改行なし）。
- **台帳**: `docs/research/registry.yaml` に 27 項目のエントリ `RES-AI-STACK-SURVEY-20260917`（`portability: repo`、`disposition: unreviewed`、`confidence: mixed`、`decision_links: []`、`freshness_due: "2026-12-17"`、`repo_evidence` は実在パスのみ、`sources` は URL）。**`content_hash` は本文確定後に最後に計算**（`check_docs_research_registry.py --json` の `computed_content_hashes` を転記）。台帳・本文とも Windows 絶対パス禁止。
- **導線**: `docs/README.md` §1 の Research 行の隣に 1 行（前例 L29 と同形。`## 2. 現行正本導線` 見出しは機械契約なので触らない）。`scripts/contract_scope.yaml` は変更不要。
- **worklog**: claim helper が決める `docs/worklogs/20260917-<slug>.md`（Lite。`Model / Effort`・`概算コスト`・影響する正本＝「docs/README.md 導線のみ、OWNER_INTENT/ODR 変更なし」・ODR-0038 D9 のコストカード＝触るファイル 3〜4／追加テスト 0／新機構なし）。
- **第 4 版（リポジトリ外 HTML）の扱い（確定: 最小案）**: `docs/research/registry.yaml` に `portability: external_local`、`artifact_paths: ["external://investment-design-docs/<ファイル名>"]`、`external_file_hash: sha256:<登録時に再計算>`、`content_hash: unavailable`、`expected_artifact_count: 1` のエントリを追加し、本文からは「第 4 版（リポジトリ外・台帳登録済み）」として引用する。**Markdown 化は別タスクとして第 14 章の判断事項に載せる。** 付録 A に「外部ファイル名は第 4 版を保持し、リポジトリ内の Markdown は第 2 版相当」と注記する。

## レポート構成（最終。目標 ≈2,050 行・上限 2,300 行、図 ≤7）

各章は「この章の結論（3〜5 行・平易語・推奨先頭）」で始める。

| # | 章 | 中身 | 目安行 |
|---|---|---|---|
| 見出し | 4 点見出し | 目的「2026-09 時点で使える AI スタックを層別に調査し、案 A/案 B を同じ深さで比較して提案する。決定はしない」／調査方法「読み取り専用の並列調査 5 本 + 反証検証 1 本、取得日 2026-09-17、main `<sha>`」／調査時点／注意「調査であり Linux 移行の着手ではない。版数・性能・ライセンスは取得日時点。推定・未確認は明記」 | 10 |
| 0 | 要旨と推奨一覧 | 位置づけ 6 行、案 A・案 B 各 1 段落 + 5 行構成表、**再構築前ゲート 5 項目**、第 4 版から変えた提案の要約表（維持／変更／新規 ≤12 行）、オーナーが決めること上位 5 問、図 1 層構成対比 | 90 |
| 1 | 再構築前ゲート — 基盤層と推論ランタイムの準備状況 | Ubuntu 26.04（GCC 15 等）、driver 615 系 + open kernel modules、CUDA 13.4、Container Toolkit、Docker の `127.0.0.1:` 束縛、systemd、ストレージ（新 2TB／旧 4TB+1TB／NAS 未確定）、**バックアップ先行（WAL 未稼働・919GB 控えゼロ）**、PG 復元経路（同一イメージ → 16.15 + pgvector 0.8.6 → 18.6 `--link`）、DuckDB 1.5.5/2.0、GPU 役割（PRO 5000 計算専用／5070 Ti 表示+小物、MIG 2×36GB の是非、ECC −6%、UUID 名指し）、**準備状況マトリクス**（llama.cpp／vLLM／SGLang／Ollama／TensorRT-LLM／NIM × sm_120・CUDA 13.4 ビルド・構造化出力・26.04 パッケージ・事前スモーク）、図 2 依存順 | 170 |
| 2 | 前提・制約・用語 | 凍結 2 種（OWNER_INTENT §4 L66–67、ODR-0038）、ODR 整合表（維持／改訂候補、パス併記。0030 重複に注意）、表記規約（事実／推定／仮説／提案／未決／未確認 + 確度）、作業語、第 2〜4 版の所在、評価基準 C1〜C10 の定義 | 100 |
| 3 | 現状の足場（事実のみ） | プロセス内 Gateway と 3 backend、llama-server b10566・:8081・ctx 65536・1 slot・実測 33,138MiB、JSON Schema + 決定論検証、ツールループ／RAG 経路／フレームワーク依存なし、`ops.local_llm_agent_tasks`、morning routine 1 本、Task Scheduler、Tauri 2.11.5 + SSE 1 本、Google Cloud Vision OCR（課金継続実装）、`knowledge.embeddings` 12.2 万行・HNSW 未使用、torch cu126 | 60 |
| 4 | 推論ランタイム層 | 地図: llama.cpp（Router 複数モデル、NVFP4/MXFP4、Qwen3.8 MTP ドラフト、DFlash2、grammar、`--device`）、vLLM（NVIDIA コンテナ RN 26.08、sm_120 NVFP4 KV、MoE カーネル未対応 issue、構造化出力、multi-LoRA）、SGLang（cu130、sm_120 不具合）、Ollama 0.18（構造化出力、有料クラウド姿勢）、TensorRT-LLM、NIM（要登録・条件）。図 3 Gateway→エンジン→GPU の A/B 配置、VRAM 配置表（72GB／16GB、推定明記）、投機的デコードの計測計画 | 200 |
| 5 | モデル層（縮約テンプレ） | 役割表: 主読解 Qwen3.8-27B（2026-08-14、27.78B 密・VLM・Apache-2.0・262k）／大型（gpt-oss-120b MXFP4、GPT-OSS-Swallow、GLM-5.3、DeepSeek V4、Gemma 4、Nemotron 3、Qwen3.8 Flash-Next の community license と 72GB 超過）／日本語特化（PLaMo 3.0 Prime 契約、Swallow、Sarashina、LLM-jp）／埋め込み（Ruri v3、Sarashina-Embedding、PLaMo-Embedding、Qwen3-Embedding。JMTEB（MTEB 上）・**JFinTEB** arXiv 2604.15882）／リランカー／ガード（Qwen3Guard、Granite Guardian、Llama Guard、NeMo Guardrails、LlamaFirewall）／文書画像（Qwen3.8 vision、PaddleOCR-VL 1.6、YomiToku、Docling、MinerU、DeepSeek-OCR は日本語非対応）。列: 版・日付／ライセンス条件／VRAM@量子化／日本語評価／A 導入順／B 導入順／確度 | 170 |
| 6 | エージェント実行層とプロトコル | 要件＝第 4 版の自律度（操作 6 種）と検証係 5 条件。候補: 自前ランナー（`ops.local_llm_agent_tasks` 一般化）、PydanticAI、LangGraph、OpenAI Agents SDK（OpenAI 互換 base_url）、Microsoft Agent Framework 1.0（2026-04-03 GA）、Google ADK、smolagents、Strands、Mastra/Vercel AI SDK（TS、案 B のみ）、Claude Agent SDK（外部 API → 実行系不可・開発用のみ）。MCP 2026-07-28（製品経路はプロセス内ツール、開発エージェント向け read-only MCP を「第 4 版に無い新規」）、AG-UI/A2A の立場、ツール権限モデル（shell/SQL/URL ツール無し）、指示文混入対策、事象台帳。図 4 境界図 | 190 |
| 7 | ジョブ実行・スケジューリング層 | systemd timer + PostgreSQL 台帳（第 4 版基線）vs DBOS Transact（Postgres 内蔵）vs Temporal vs Hatchet vs Procrastinate vs APScheduler 4。lease/heartbeat/再試行/冪等/鮮度待ち（exit 65/66/70）、タスク定義 431 件の移行、管制盤で見える台帳、凍結注記（新 queue/台帳＝凍結明けか ODR 後） | 130 |
| 8 | 知識・検索・文書取込層 | pgvector 0.8.6（HNSW VACUUM 修正）、日本語全文検索（pg_trgm／PGroonga／pg_bigm／pg_textsearch 1.0 BM25／ParadeDB）、VectorChord/pgvectorscale、400 字断片 + RRF + 決定論再ランク（維持）vs モデル再ランク（評価セットがある場合のみ）、埋め込み切替＝全件再索引 + モデル版列の Alembic、OCR の Google Vision 置換、Obsidian（Local REST API 内蔵 MCP、2026-07-28 版対応）、投資フレームワーク 329 本・Q1〜Q127、新表 4 つ（Alembic + 凍結フラグ）、ODR-0008/0040。図 5 パイプライン | 180 |
| 9 | 品質保証・検証・観測層 | (a) 決定論検証の継承 + 評価セット段階、(b) ガードモデルは追加信号でありゲート代替ではない（5070 Ti の VRAM 費用）、(c) 観測: アプリ内管制盤 + PostgreSQL 台帳（第 4 版）vs Prometheus/DCGM vs Langfuse（MIT）/Phoenix（ELv2）/MLflow 3（Apache）。BFF 専用規則により別ダッシュボードは開発者用。OTel GenAI semconv の状態 | 130 |
| 10 | アプリケーション層（A/B の差が最大） | 案 A: FastAPI BFF 429 ファイル + React 39 万行をブラウザ配信（Tauri 2 × WebKitGTK × NVIDIA × Wayland の既知問題）、SSE→トークン配信（未検証文を画面に出さない原則）、静的配信、Python 3.12/uv。案 B: 言語（Python FastAPI/Litestar vs TypeScript Hono/Next + Mastra）、UI（React SPA vs サーバー駆動 HTMX/Datastar vs NiceGUI/Reflex）、生成クライアント、**計算器・検証器の同値移植コスト**。図 6 | 180 |
| 11 | 任意領域 | 音声（判定は WER 等の数値つき: Whisper large-v3-turbo、kotoba-whisper、ReazonSpeech、Qwen3-ASR、faster-whisper/whisper.cpp の sm_120。Parakeet は日本語非対応。TTS: Style-Bert-VITS2、VOICEVOX 規約、Kokoro）／学習・FT（Unsloth、TRL/PEFT、LLaMA-Factory、sentence-transformers、27B LoRA/QLoRA の VRAM、「いつ知り得たか」の時点規律）／GPU 分析（RAPIDS 26.x + CUDA 13/sm_120、Polars GPU、torch 2.14 cu130、効く所・効かない所の表）／開発用 AI（Claude Code/Codex on Ubuntu＝既存サブスク、ローカルコーディングモデル + OSS クライアント） | 150 |
| 12 | 案 A/案 B 総合比較と段階導入 | 基準（最初に使える結果までの時間・リスク・保守面積・境界/ODR 整合・可逆性・VRAM/運用負荷）× 層の行列、各案の評点 + **混成 1 行のみ**、依存順の段階（暦なし。共通の背骨→分岐点）、各案の ODR-0038 D9 コストカード、両案で同じもの（データ層・検証・外部 API なし・発注なし）。図 7 | 130 |
| 13 | 受入・検証計画（提案） | 2026-07-12 ADR の 4 条件を再利用、sm_120 スモーク（ビルド/wheel、64K + 画像で実推論 1 件、UUID 配置、ECC 状態）、profile ID 規則と評価セットゲート、ロールバック、「凍結解除 ODR の後に実行する提案」 | 80 |
| 14 | オーナー判断事項 | 第 4 版 §14.2 の 13 問との対応表 + 本書の新規問い（案 A/B、Ollama 退役、開発用 read-only MCP、監視基盤、ガードモデル、第 4 版回収）。推奨先頭・番号付き・決める時期 | 80 |
| 15 | 付録 | A 出典（S-id、URL、取得日、種別）／B 主張の検証結果（C-id、支持/訂正/反証/未確認）／C 用語（作業語に印）／D 改訂履歴／E 調査分担 | 150 |

### 層テンプレ（同じ深さを保ち、分量を倍にしない）

```
X.0 この章の結論（3〜5 行）
X.1 選択肢の地図   表: 候補／何をするものか（1 文）／版・日付／ライセンス・条件／sm_120・日本語／出典 S-id／確度
X.2 評価           表: 候補 × 基準 3〜6 個（◎○△×）+ 総合 + 一行根拠   ← A/B 共通で 1 回だけ
X.3 案 A の推奨     表: 要素／採用／理由 + 最初の成果物 + 主なリスク（≤3）+ 移行コスト
X.4 案 B の推奨     X.3 と同じ列・±20% の行数
X.5 第 4 版との差分  表: 第 4 版の選択／本書の提案／区分（維持・変更・新規）／理由／移行コスト／必要な ODR 改訂（パス）
X.6 この層の判断事項 → 第 14 章へ集約
X.7 未確認・仮説
```
A/B が収束する章（1・5・9）は「共通の推奨 + 違い 2 行表」に畳む。X.5 の「新規」は第 0 章の要約表にも必ず載せる。

### 評価基準（第 2 章で 1 回定義、各層で 3〜6 個使う）

C1 日本語品質／C2 費用ゼロ（要登録・商用制限・契約・有料クラウド誘導のフラグ）／C3 単一機・2 GPU 適合（sm_120、64K 込み VRAM、役割分担）／C4 検証前置の適合（構造化出力、引用 ID 束縛）／C5 境界・ODR 整合（必要な改訂数）／C6 非技術オーナーの運用負荷／C7 成熟度・保守面積／C8 可逆性／C9 最初に使える結果までの時間／C10 凍結適合。

## 調査方法（実行時）

- 読み取り専用の調査エージェント **5 本を並列**（Explore/general-purpose。Workflow は使わない。過剰並列を避ける）+ **反証検証 1 本を後段**。一次情報（公式 docs／GitHub releases・issues／モデルカード／arXiv）を優先し、二次記事は `secondary`・確度 ≤中。版・日付・ライセンスは推測せず `不明` を返す。取得日 2026-09-17 を記録。**散文ではなく記録（1 技術 1 レコード、≤30 件/agent）**、末尾に「確認できなかった 5 点」。
  - R1 基盤・ハード（Ubuntu 26.04、driver 615、CUDA 13.4、Container Toolkit、Docker 束縛、systemd、PG 18.6 + pgvector 0.8.6 イメージ、`pg_upgrade --link`、DuckDB、RTX PRO 5000 72GB 公式仕様と MIG 対応 SKU、5070 Ti、Tailscale、pgBackRest/restic）
  - R2 推論ランタイムとモデル（llama.cpp／vLLM／SGLang／Ollama／TensorRT-LLM／NIM 規約、主要モデルの版・ライセンス・VRAM・日本語評価、埋め込み・リランカー・ガード）
  - R3 エージェント・プロトコル・ジョブ・観測（MCP 2026-07-28、各フレームワークの OpenAI 互換 endpoint 対応と承認プリミティブ、DBOS/Temporal/Hatchet/Procrastinate/APScheduler、Langfuse/Phoenix/MLflow/OTel semconv、AG-UI/A2A、LiteLLM の 2026-03 PyPI 事故）
  - R4 知識・検索・文書処理（pgvector、pg_textsearch、ParadeDB、PGroonga、pg_bigm、VectorChord/pgvectorscale の PG18 対応とライセンス、OCR モデルのライセンス（YomiToku の非商用条項を確認）と日本語縦書き・表の根拠）
  - R5 任意領域 + アプリ層（日本語 ASR/TTS の WER と規約、FT スタックの sm_120、RAPIDS/Polars GPU/torch cu130、Claude Code/Codex on Ubuntu、Tauri Linux 問題、FastAPI/Litestar/Hono/HTMX/NiceGUI の版と Python 対応）
  - R6 反証（優先順: ハード数値 → ライセンス/規約 → sm_120 対応 → モデル公開事実 → 版・日付 → リポジトリ引用の再読）。判定は 支持／訂正／反証／未確認 を付録 B へ。
- 共通レコード様式: name／layer／version／release_date／license／terms_flag／one_line_ja／sm_120_status／japanese／footprint／fit_case_a／fit_case_b／boundary_flags／risks／vs_4th_edition／sources（url, title, retrieved, type）／confidence／unverified。
- 統合規則: 同名を正規化して重複除去、official/release を secondary より優先、エージェント間で食い違えば平均せず未確認として R6 へ。本文の数値は必ず S-id か 推定/未確認 を伴う。

## 執筆規則（要点。詳細は本文の第 2 章に）

- 規則の複製禁止（OWNER_INTENT・documentation-standard・プロジェクト概要は最小引用 + 相対リンク）。ODR は番号 + ファイルパス。
- 事実／推定／仮説／提案／未決／未確認 のラベルを本文に、確度列を地図表に。訂正は訂正後の形で C-id を付す。
- 費用ゼロのフラグ: NIM/Developer Program（要登録・条件）、gated モデル、Ollama cloud、copyleft（Grafana AGPL、MinerU AGPL、VectorChord）、**既存の Google Cloud Vision 課金は事実として明記し両案で置換案を出す**。
- 検証前置: LLM 再ランク・LLM 判定をゲートとして提案しない。ガードモデルは追加信号。ストリーミングで未検証文を画面に出さない。
- 凍結: 新表・台帳・hook を要する提案は「凍結明けまたは ODR 後」と付す。本レポートの公開で検査・テストは増やさない。
- 表記: 絶対 Windows パスを本文・台帳に書かない（「ローカルのモデル置き場（旧 D ドライブ）」等）。72GB カードは第 4 版と同じ「RTX PRO 5000（72GB）」表記、世代は sm_120 と書く。
- Desktop 描画: 生 HTML 不可、`---` の前に空行、相対リンクは `../decisions/...`、脚注は使わず S-id。mermaid は `flowchart TB|LR`、引用符付きラベル、ASCII の id、`style`/`click`/`%%{init}` なし。

## 実行手順（承認後、依存順）

1. **worktree を claim**（`pr-ready-gate` §1: `scripts/dev/sync_repo.py create-worktree --task ... --branch ... --worklog ...`。docs-only、DDL なし）。worktree 内の Bash guard は heredoc・`$(...)`・powershell を拒否するので、補助スクリプトは scratchpad に書いて `uv run python <path>` で実行。
2. **worklog** を `worklog-starter`（Lite）で起こし、承認内容（本計画のオーナー回答 3 点）・利用者が確認する結果（レポート 1 本 + 台帳 + 導線）・欠損/未確認の見せ方（付録 B・X.7）・今回確認する範囲（docs 検査 + Ready gate docs-only）を記録。
3. **HEAD SHA を控え**、第 2・3 章と見出しをリポジトリ事実から先に書く（Web 不要）。
4. **R1〜R5 を並列起動**。待ち時間に X.0/X.1 の骨格と図 1〜7 を下書き。
5. **層ごとに統合**（X.1〜X.5）、S-id 付与、第 1・4〜11 章を執筆。
6. **R6 反証**を優先クラスに実行、訂正反映、X.7 と付録 B を埋める。
7. 第 12・13・14 章、最後に第 0 章（結論は本文に合わせて最後に書く）。
8. 第 4 版の台帳登録（最小案の場合。`external_file_hash` は登録時に再計算）または回収 PR の先行（回収案の場合）。
9. 台帳エントリ・README 導線・worklog 更新 → 検査（下記）→ `content_hash` を最後に転記 → 明示パスで `git add` → commit。
10. **Ready gate**（clean exact head、`--scope` 追加なし。docs-only は `harness-docs` pack のみ・同期レーンなので `pending_async` は出ない見込み）→ `publish-pr`（`git diff --check origin/main..HEAD` を事前に自分で回す）→ `finish-pr` は ExitWorktree 後に main checkout から実行。`CLEANUP_DEFERRED` なら夜間 sweep に任せる。
11. main 同期後、Desktop の Markdown 画面（BFF 起動可能な場合）で表・リンク・図の描画を目視し、worklog に「内容確認済み」を検査合格とは別に記録。

## 検証（公開前チェックリスト）

1. 静的自己点検（grep）: `[A-Za-z]:\\` パス無し／mermaid 外に `<details>|<br>|<sup>` 無し／ODR 番号の同一行にパス有り／作業語の初出に注記／4 点見出し／先頭が `# `。
2. mermaid 各ブロックの描画確認（ブラウザで mermaid.live、または scratchpad で `npx -y @mermaid-js/mermaid-cli`）。
3. `uv run python scripts/check_md_links.py --scope docs --json` → 破損 0。
4. `uv run python scripts/check_docs_research_registry.py --json` → `computed_content_hashes` を転記して `ok: true`（本文を触ったら再実行）。
5. `uv run python scripts/check_docs_metadata.py --json` → ok。
6. `uv run pytest tests/scripts/test_docs_research_registry.py tests/scripts/test_docs_metadata.py -q`。
7. `git diff --check`、UTF-8 BOM なし（`write_text(encoding='utf-8')`、CRLF 混入注意）。
8. Ready gate `overall_status=passed`、strategy `docs_only`、pack `harness-docs` のみ。

## 触るファイル

- 新規: `docs/research/20260917-ai-stack-survey-and-technology-proposal.md`、`docs/worklogs/20260917-<slug>.md`
- 更新: `docs/research/registry.yaml`（エントリ追加。第 4 版を最小案で扱う場合は external エントリも）、`docs/README.md`（導線 1 行）
- 参照のみ: `docs/OWNER_INTENT.md`、`docs/audits/20260915-full-review-and-linux-rebuild-plan.md`（第 2 版相当）、`docs/runbooks/local-llm-rtx-pro-5000-operations.md`、`docs/decisions/20260909-rtx-pro-5000-llm-standard.md`、`docs/decisions/20260829-qwen38-27b-formal-adoption.md`、`docs/decisions/20260827-qwen38-earnings-agent-durable-queue.md`、`docs/design/DBレイヤー契約.md`、`shared/llm_gateway/__init__.py`、`shared/llm_runtime_policy.py`、`tools/converters/pdf_to_markdown/ocr_processor.py`、`scripts/check_docs_research_registry.py`、`desktop/src/components/shared/MarkdownBody.tsx`／`MermaidDiagram.tsx`

## 確認済みの判断（2026-09-17）

- 案 A/案 B を同じ深さで比較する。第 4 版の既選択は再評価し代替案も出す。任意領域 4 つを含める（音声は実用レベルの根拠がある場合のみ）。
- 第 4 版 HTML は台帳に sha256 付きで登録して出典にする（Markdown 化は別タスクとして判断事項へ）。

## 完了の定義

- レポート本文・台帳エントリ 2 件（本レポート + 第 4 版外部登録）・README 導線 1 行・worklog が 1 つの PR で main に着地し、docs 検査と Ready gate（docs-only）を通過している。
- 本文の全外部数値に S-id か 推定/未確認 が付き、付録 B に反証結果がある。
- レポートは決定・着手・ODR 改訂を含まず、オーナー判断事項が第 14 章に番号付きで揃っている。
