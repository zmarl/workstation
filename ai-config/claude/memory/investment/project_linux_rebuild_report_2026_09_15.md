---
name: project-linux-rebuild-report-2026-09-15
description: Linux 再構築計画レポート（第 4 版 2026-09-16 が正本）の所在、即時移行の前提・救出順、AI ネイティブ化と個人知識ベースの構想、未回答のオーナー判断
metadata: 
  node_type: memory
  type: project
  originSessionId: aba6e8fc-2d62-4903-b9cd-f403a2b33648
  modified: 2026-09-17T02:02:54.731Z
---

# 現状総点検と Linux 再構築計画（第 4 版 09-16 が正本）

成果物: `D:\Dev\Investment_設計資料\現状総点検とLinux再構築計画_2026-09-15.html`（**第 4 版**、16 章・図 12 点 + 動く見本・約 310KB）。旧版は同フォルダに `..._初版.html`／`..._第2版.html`／`..._第3版.html`。作業一式は 2 つ目のセッションの scratchpad `report4/`（head.html + ch/c00〜c15 + figs/ + build.py）、材料は `scratchpad/wf2/`（調査 6 本 R1〜R4・W1〜W2、設計 3 案 + judges.json + synthesis.md + critique.md）。第 3 版の材料は最初のセッションの `scratchpad/wf/` と `report2/notes_verify.md`。
なお別セッション（文書集約 09-16）が 9/15 の HTML を `docs/audits/20260915-full-review-and-linux-rebuild-plan.md` に Markdown 化しており、**その Markdown は第 2 版相当で古い**（09-16 10:28 の 442KB HTML から変換。vLLM 常駐・Prometheus・暦ベースの段階を含み、第 4 版とは未同期）。第 4 版 HTML は 09-17 に `docs/research/registry.yaml` へ sha256 付きで外部登録した（[[project-ai-stack-survey-2026-09-17]]）。

## 前提（オーナー指示・回答 09-16）
- **数日以内に新 PC を組んで即 Ubuntu 26.04 へ移行**。第 2 版の暦（M0〜M5・「2 月まで作らない一覧」・30 日レビュー・解錠期限）は私が勝手に作った制約なので撤回済み。順序は依存関係だけ。
- 部品: HAVN BF360 FLOW / Corsair HX1500i (2025) / **SanDisk Extreme 2TB M.2 = Linux の本番ドライブ**／旧 4TB・1TB は持ち込み／この PC で Windows は使わない。**RTX 5070 Ti は手元にあり**（画面と雑用は 5070 Ti、72GB は計算専用）。RAM 96GB のまま様子見。
- **モデルは VRAM に置く**。モデル庫 458GB は持ち越し必須ではない（4TB に載ったまま運び、新 2TB には Qwen3.8-27B だけ）。CUDA 開発を活かす。
- **flash-next の作業フォルダ（未コミット 92 ファイル）は「記録として残す」**（採用は別）。手順: 記録用 commit + `rescue/*` tag + bundle + 証拠フォルダ 35 万ファイルの別途退避。
- **NAS は 2TB、`D:\Dev\Investment\data` だけ控え済み**。空き容量・接続方法は未回答。
- ポートフォリオ管理は意図的に保留。決算の閉ループ（DecisionCase）は重視しない。学習はこのアプリのデータで。
- **新方向: 「裁量投資の補佐」ではなく「私の代わりを務める AI ネイティブなアプリ」**（アプリ全体が 1 つのエージェント）＋**株式投資の包括的な個人知識ベース（PKB）**を細かく作り込みたい。
- 「移送」を「位相」と読まれたので、以後は「データを新 PC へ移す」と書く。

## 第 4 版の骨子
- 運搬: **旧 PC（ASRock B860 TW）は M.2 が 2 本だけで両方使用中**→新 2TB を先に挿す案は不可。DB の仮想ディスク `D:\DockerDesktop\wsl\disk\docker_data.vhdx`（1,394.6GiB）が載っている**旧 4TB を運搬手段**にし、Ubuntu で NTFS 読取 + qemu-nbd で中の ext4 を読み取り専用マウント。新 2TB には Ubuntu を先に入れる。
- PostgreSQL: 現行 16.13（pgvector pg16 bookworm、vector 0.8.2、libc en_US.utf8、glibc 2.36、checksums off）。**推奨順: 当日は同イメージ PG16 → 16.15 + vector 0.8.6（HNSW VACUUM 破損修正）→ 落ち着いてから 18.6 へ `pg_upgrade --link`（bookworm の `0.8.6-pg18`、統計保持）**。PG19 は Beta 3 で対象外。DuckDB 2.0 は未リリース（GA 予定 10-21）、lock 1.4.3 は 9 月 EOL → 1.5.5 へ。
- 自律度: 「1 か 3 か」ではなく**操作の種類ごとの目盛り**（読む・計算する・取り消せる書き込み＝自動／正本・外部発信・構成＝人）。自動承認は既定で全部閉じている（予算 0・allowlist 空・AGENT_AUTOMATION_ENABLED=false）が L2 として運用された実績なし。**平日 9:20 の daily-review-agent が LLM 自由文を検証なしに Discord へ送る唯一の経路**。
- 見せ方: 「どこに出すか」（①ページ／②上部の帯／③別窓）と「どんな姿か」（A 管制盤／B ドット絵／D 軌道盤…）を分離。推奨は ①に A を先に、②を足し、B を載せる。
- AI ネイティブ化（第 9 章）: 3 案の審査で「日課が先」42 点・「知識が先」41 点・「判断記録が先」29 点。骨格は日課代行（朝の当番 08:58/09:00、夕の当番、書記係、還流係）+ 発言は引用検証を通った文だけ。**ODR-0030（売買・順位・数量を出さない）は変えない推奨**。着手には次番の ODR（0044 以降、0041〜0043 は採番済み）と OWNER_INTENT §4 の例外、ODR-0038 ハーネス凍結の扱いが要る。全体の 1 本目は PKB の「根拠つきで問う」。
- PKB（第 10 章）: 知識の実体は `投資フレームワーク/` 329 本・214 万字（正本、90 日で 233 本更新）、本人発言 Q1〜Q127、Obsidian Vault 8,091 ノート・3,550 万字（**手書き 0、90 日更新 0、02_投資 は Vault の外**）、`knowledge.embeddings` 12.2 万行。単位は文書→版→断片(400 字)→主張。**`knowledge.embeddings` は 1 断片 1 行の一意制約 + vector(768) 固定 → モデル切替は全再索引**。`document_versions` に git_sha/有効期間の列なし。Obsidian 橋渡しモジュールはソース消失。
- 本番 OCR が外部有料サービスに流れている記述あり（要確認、サブスク外課金禁止と衝突の可能性）。

**Why:** 第 4 版がオーナーの最新の方向（即時移行 + AI ネイティブ化 + PKB）を反映した唯一の正本。次の会話は第 14 章の未回答 13 問（NAS の空き・接続、自律度の目盛り、見せ方、PG18/DuckDB の時期、tag push、C: の運び方、「私の代わり」の到達点、ODR と凍結の扱い、一次資料の解除、入口、本文反映の方法、ウォッチ対象の実体、問いの候補づくり）の回答から始まる。
**How to apply:** レポートの第 0 章と第 14 章を先に読む。実作業は「救出（第 3 章）→ 退避 → 分解 → 復元（第 4 章）→ 依存順の立ち上げ（第 5 章）」で、AI ネイティブ化は画面が戻った後。関連: [[feedback-ask-dont-infer-authorization]]、[[feedback-no-extra-billing]]、[[feedback-review-placement-markdown-canonical]]、[[project-docs-consolidation-2026-09-16]]。
