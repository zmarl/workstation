---
name: project-ubuntu-workstation-kit-2026-09-17
description: 新 Ubuntu 26.04 PC の作業環境（道具・日常アプリ・AI 設定）を AI に整えさせるキット D:\Dev\workstation（非公開リポジトリ zmarl/workstation 予定）の所在・方針・当日の手順・Linux 版アプリの事実と罠
metadata: 
  node_type: memory
  type: project
  originSessionId: 134e8358-8c45-49de-811f-993811220bfc
  modified: 2026-09-17T13:51:31.668Z
---

# Ubuntu 作業環境キット（2026-09-17 作成）

**所在**: `D:\Dev\workstation`（独立 git リポジトリ。GitHub 非公開 `zmarl/workstation` への作成・push はオーナー確認待ちだった）。計画: `~/.claude/plans/ubuntu-git-ai-google-chrome-chatgpt-cla-unified-wall.md`。入口は `AGENTS.md`（AI の順番と規則）、`docs/day1-owner-sheet.md`（オーナーの 1 枚と最初に貼る指示文）、`NOTES.md`（判断待ち・当日の記録）、`docs/decisions.md`（技術選択の理由）。

**オーナー回答（09-17）**: 置き場所は新しい非公開リポジトリ／管理者パスワードは都度オーナーが入力（AI は `setup/run-as-admin.sh` で端末ウィンドウを開くだけ）／範囲は「ゲーム以外で Linux 対応のものすべて」／AI 設定はメモリも含め全部持ち出す（秘密情報除く）。

**順番の変更点**: 第 4 版 §4.4 では Claude Code の再開が 12 番目だったが、Ubuntu 導入直後に Claude Code を入れ（オーナー）、以後を AI が進める。範囲は OS・道具・日常アプリ・AI 設定まで。DB 復元・旧ドライブ・`.env`・CUDA/vLLM は Linux 移行凍結の対象として範囲外。権限変更（kvm / docker / input / ssh）は `35-permissions.sh` に分離し項目ごとに了承。

**Linux 版の事実（09-17 一次資料 + ubuntu:26.04 コンテナで確認）**: Claude アプリは公式ベータ（Anthropic apt、Code タブあり、音声入力・Computer Use なし、鍵指紋 31DDDE24…1A7ECACE）／ChatGPT アプリは公式プレビュー（26.04 明記、Codex 内蔵、`.deb` が OpenAI リポジトリを自己登録）／Chrome の `.deb` は `google-chrome.sources` を自己登録（手で足すと二重）／WezTerm 安定版は 2024-02 で止まり fury の `wezterm-nightly` が毎日更新／Obsidian の最新リリースが Android の apk だけのことがある／OpenCode の `.deb` のパッケージ名は `opencode`／yazi・DuckDB・wezterm は 26.04 の apt に無い／ydotool パッケージが udev 規則と user service を同梱（input グループ参加だけ要る）／Aqua Voice・Notion・LINE・BeeStation・GitHub Desktop は Linux 版なし／**CUDA 13.4 の新機能は R615 が必要だが 26.04 には 610-open まで**（既定は Ubuntu 署名の 610-open、計算レーン着手時に上げる）。

**罠（再発防止）**:
- root の台本が `~/.local/state/...` を `install -d` で作ると親の `~/.local` が root 所有になり、後のユーザー導入が全滅する → `runuser -u <user> -- install -d` で作る（予行演習 2 回目で発見）。
- `cmd | grep -q` は pipefail 下で SIGPIPE の偽陰性になる（fc-list など出力が多いもの）→ 出力を変数に取ってから照合（`output_matches`）。
- `while read` ループ内の `claude` は標準入力を食う → `</dev/null`。
- `if func` / `( ... ) || ...` の中では set -e が効かない → `set +e; (set -e; func); rc=$?; set -e`。
- ワークツリー外でも Bash の `python` は hook が拒否しコマンド全体が実行されない（ファイルも書かれない）→ Write ツールか `uv run`。
- Ubuntu 25.10 以降は既定の端末が Ptyxis（gnome-terminal が無いことがある）、coreutils は uutils、sudo は sudo-rs。

**Why**: 次の会話は「非公開リポジトリの作成と push の了承」か、移行当日の実行から始まる。
**How to apply**: 当日は新 PC で `~/dev/workstation/AGENTS.md` に従う。キットを直したら `bash tests/rehearse.sh <出力先>`（shellcheck + ubuntu:26.04 通し）で確かめる。関連: [[project-linux-rebuild-report-2026-09-15]]、[[project-overall-design-doc-2026-09-17]]、[[project-ai-stack-survey-2026-09-17]]、[[feedback-ask-dont-infer-authorization]]。
