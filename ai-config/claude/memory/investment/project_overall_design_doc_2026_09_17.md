---
name: project-overall-design-doc-2026-09-17
description: 『全体設計書 — Linux ネイティブ・AI ネイティブ・ローカル LLM ネイティブな作り直し』（2026-09-17、リポジトリ外 HTML）の所在・骨子・オーナー回答・未回答の問い
metadata:
  node_type: memory
  type: project
  originSessionId: 9e487860-ad88-47e9-9466-54d6f1282242
  modified: 2026-09-17T06:57:54.811Z
---

# 全体設計書（2026-09-17 初版）

**所在**: `D:\Dev\Investment_設計資料\全体設計書_LinuxネイティブAIネイティブ_2026-09-17.html`（19 章・図 19 点・約 400KB）。作業一式は scratchpad `design1/`（build.py + head.html + ch/c00〜c18 + figs/fig01〜fig19、`report4/` の作法を流用）。計画は `~/.claude/plans/d-linux-linux-ai-llm-1-pc-pc-pc-5070ti-calm-cocke.md`。第 4 版（移行計画）とは別文書で、「移した先でどう作るか」だけを扱う。

**依拠（再調査しない）**: ODR-0044（`docs/decisions/20260917-ai-stack-renewal-and-inference-engine.md`、D1〜D11: 同等なら維持・良くなるなら刷新／vLLM 主・llama.cpp 予備／Ollama 廃止／外部有料 OCR 停止／PG 推奨経路 + PGroonga／MCP 標準装備（許可一覧・承認・データ扱い・秘密不渡し・台帳）／Tauri 撤去・ブラウザ配信／Phoenix／GPU 計算レーン RAPIDS + CUDA Python + cutile-rs／IV スキューマップ試金石／**Linux 移行の着手凍結とハーネス凍結（〜10/7）は継続**）と AI スタック調査レポート改訂 2（`docs/research/20260917-ai-stack-survey-and-technology-proposal.md`、1,663 行。4.8 単一エンジン、6.10 MCP、11.3 計算レーン、11.5 IV マップ、14.3 決定状況）。

**オーナー回答（09-17）**: 完全に刷新したものを作る（旧 BFF・旧画面は Linux で起動しない、参照専用、表示は急がない）／25 画面の機能は「写す」のではなく 1 から作り直して同じ機能を持たせる／PL モデルは純利益までモデル化（営業外・税率の仮定も）／音声はコーディング指示とチャットの両用途／「参照のところは 1 回作業した」= NAS・BitLocker の確認 + 並行セッションの AI スタック調査。

**骨子**: ①土台（PostgreSQL 792 表・Alembic 270 本・原本 82GB・取込 177 種・`shared/domain` 計算器）は残し、上物（旧 BFF 16.7 万行・旧画面 39 万行・ハーネス 26.5 万行）は新しい側 `app/ web/ ml/ gpu/` で 1 から。同じリポジトリに並置、全機能が揃ったら旧側を 1 コミットで削除。作業量 M1 画面 9〜15 日／M2 決算 +10〜20（±10）／M3 PL +5〜10（推定）。②「1 機能 = 1 フォルダ」（schema/router/tool/tasks/page）で自動登録、新機能 3〜5 ファイル・2 工程。拡張の受け皿 3 種（データ源=取込 or MCP、計算器=計算レーンの型（指紋→決定論関数→出力と版、Python/RAPIDS/cutile-rs の同値テスト）、画面=page.tsx）。venv 3 つ（app は torch なし／infer torch 2.14 cu130／train Unsloth）。③技術は維持（Python/FastAPI、React 19 + Vite、TanStack、PostgreSQL 18 + pgvector + PGroonga、Polars/Arrow、systemd、recharts）+ 変更（ブラウザ配信、vLLM、TEI、ローカル OCR、MCP、Phoenix、GPU レーン、Plotly.js、生成型のみ）。④判断材料の連鎖: 識別子（code・FiscalPeriod・document/fragment・fact_id・model_run_id・analysis_id・agent_run_id）+ EarningsContext + SourceRef + meta.versions、「クリックで別の段に着地、着地先が無いものは表示しない」。⑤PL シート 3 層（実績＝`financial_performance.py` 443 行を純利益まで拡張／会社予想 + 版／推定＝run-rate + 季節性 + セグメント + 営業外・税率仮定 + 感度格子）、`analytics.financial_models` 実使用、GPU 不要（17 万コンテキスト、CPU 数分）。⑥決算コア: KPI 抽出 3 層（表セル決定論 310 万 → GLiNER（GPU B）→ LLM 候補）→ 承認 → `core.metric_series`。⑦GPU: A = vLLM 27B FP8 ≈30〜38（実測ピーク 37.9）+ 夜間 QLoRA；B = TEI 埋め込み/リランク + OCR VLM + Qwen3-ASR + ml-serve + 計算枠 + 9B 級 ≈15（上限側は計算枠を止める）。**主 LLM の余りを B に層分割しない**（別モデルを丸ごと）。論理名 11 種、`ml/registry/profiles/*.yaml` + 割当（凍結中 YAML → `ops.model_assignments`）。⑧学習 4 本（埋め込み Ruri v3 768 維持／KPI 抽出器／SetFit 分類器／時系列 基準→Chronos-2→XGBoost）。⑨音声 = Handy + whisper.cpp turbo（→ Qwen3-ASR）+ `dictate.format` の 2 モード（code/chat）。⑩BitLocker: 回復キーがあれば `cryptsetup --type bitlk` で読めるが、退役前に復号完了を推奨。

**未回答（第 17 章）**: NAS の空き・接続と D: 暗号化の有無／旧側の削除時期／「完全刷新」の読み方（技術は D7 どおり維持、画面は 1 から）／25 機能の順／夜間学習中に reader.deep を止めてよいか／B の小型 LLM は 9B 級か／ピア比較の軸／IV マップの断面（画像待ち）／TradingView の契約／音声は Handy+whisper から／ODR-0038 中の生成器・差分テストの解釈。

**Why**: 09-17 のオーナー方針（完全刷新）と ODR-0044 を 1 冊に統合した唯一の設計正本。次の会話は第 17 章の問いへの回答と、着手 ODR（Linux 移行の凍結解除）から始まる。
**How to apply**: 第 0 章 → 第 3 章（作り直し）→ 第 16 章（順序）の順に読む。技術選定の議論は ODR-0044 の D 番号と改訂 2 の章番号で参照する。関連: [[project-linux-rebuild-report-2026-09-15]]、[[project-ai-stack-survey-2026-09-17]]、[[feedback-no-extra-billing]]、[[feedback-ask-dont-infer-authorization]]。
