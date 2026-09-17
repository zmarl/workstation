# Ubuntu 移行時の作業環境セットアップを AI に任せる計画

## Context（なぜ・何を目指すか）

- 新 PC は今の PC の部品を移して組むため、旧環境を動かしたまま新環境を先に作れない（移行計画 第 4 版 §4.1）。**AI が当日に使う手順書・スクリプト・AI 設定は、分解の前に Windows 側で作り終えておく**必要がある。
- 第 4 版 §4.4 では Claude Code / Codex の再開が 12 番目（最後）。AI に任せるなら **Ubuntu 導入の直後に Claude Code を動かし、ドライバ確認以降を AI が進める順に入れ替える**。
- 目指す状態: 人がやるのは「組み立て・OS 導入・パスワード入力・各サービスへのログイン」だけ。それ以外は Claude Code がキットに沿って 1 段ずつ進め、各段の完了を検証表で確認できる。途中で再起動しても続きから再開できる。
- 対象: 開発ツール一式 + 今使っているアプリのうち**ゲーム以外で Linux で使えるものすべて**（オーナー回答）。Linux 版が無いものは代替か Web 利用に振り分ける。「クローン」はリポジトリの取り直し（Investment / Multi-Agent-Orchestration / codex-pet）として扱う。
- 範囲外: DB の復元・旧ドライブのマウント・`.env` 配置・CUDA/vLLM など投資アプリ側（第 4 版 §4.4 の 6〜11 番と ODR-0044）。これらは「Linux 移行への着手」凍結（OWNER_INTENT §7、ODR-0044 でも継続）の対象なので、このキットは OS・道具・日常アプリで止める。

## オーナー回答（2026-09-17）

| 問い | 回答 |
| --- | --- |
| 置き場所 | GitHub に新しい**非公開リポジトリ**（投資アプリのリポジトリとは分ける） |
| 管理者パスワード | **都度オーナーが入力**。AI は内容を説明してから端末ウィンドウを開き、オーナーが打つ |
| 範囲 | ゲーム以外で Linux に対応しているものすべて |
| AI 設定 | **メモリも含めて全部**持ち出す（ログイン情報・秘密情報は除く） |

## 調査で確定した Linux 対応状況（2026-09-17 時点、一次資料で確認）

| 今のアプリ | Ubuntu 26.04 での扱い | 入れ方 / 更新 |
| --- | --- | --- |
| Claude アプリ | **公式ベータあり**（Chat・Cowork・Code タブ）。音声入力と Computer Use は Linux 版に無い | Anthropic の apt リポジトリ `claude-desktop`、apt で更新。Cowork は BIOS の仮想化 + `kvm` グループが必要 |
| Claude Code CLI | 公式 | `curl -fsSL https://claude.ai/install.sh \| bash`（sudo 不要・自動更新）。CLI の `/voice` は日本語可（音声はクラウド送信） |
| ChatGPT アプリ（Windows の実体は OpenAI.Codex） | **公式プレビューあり、26.04 明記、Codex 内蔵**。Computer Use なし、Wayland ネイティブは実験的 | 公式 `.deb` を入れると OpenAI の apt リポジトリが登録され apt で更新 |
| Codex CLI | 公式 | 公式インストーラか `npm i -g @openai/codex` |
| Google Chrome | 公式 | `.deb` → Google の apt リポジトリで更新。ログインで同期 |
| Discord | 公式 `.deb` | 2026-05 以降は Linux でも自己更新（`.deb` で効くかは当日確認） |
| Cursor | 公式 apt リポジトリ | apt で更新 |
| Obsidian / Thunderbird | 公式（`.deb` / snap） | Thunderbird は apt 経由でも snap になり自動更新 |
| WezTerm・starship・zoxide・fzf・fd・ripgrep・lazygit・yazi・Neovim・jq・DuckDB CLI・FFmpeg・ImageMagick・Poppler・7-Zip・git-lfs | すべて Linux 版あり | apt で足りるものは apt、古いものは公式配布 |
| Git・GitHub CLI | 公式 | gh は公式 apt リポジトリ（snap は非推奨と公式明記） |
| uv・Rust・Node LTS・Bun・pnpm・Playwright・yt-dlp | 公式 | ユーザー領域に導入（sudo 不要） |
| Docker Desktop | → **Docker Engine**（26.04 公式対応）+ NVIDIA Container Toolkit（26.04 対応） | 第 4 版 §4.4 の 5 番を前倒しでキットに含める |
| Aqua Voice | Linux 版なし → **Handy**（公式 `.deb`、Whisper で日本語） | Wayland で文字を打ち込むには `ydotool` が必要 |
| Logi G HUB / Options+ | なし → Solaar（apt） | |
| FanControl / MSI Afterburner | なし → CoolerControl / LACT（+ `nvidia-smi`） | |
| CrystalDiskInfo / CPU-Z | なし → GSmartControl・smartctl・nvme-cli / CPU-X | |
| MOTU M シリーズ | ドライバ不要（PipeWire） | 当日に入出力を確認 |
| HyperX NGENUITY | なし → 必要なら HeadsetControl / OpenRGB | 使い道を当日確認 |
| Notion・Teams・Outlook・Copilot | Web 利用（Chrome のアプリ化） | Notion は投資アプリ側では廃止済み |
| LINE | 公式 Chrome 拡張 | |
| Synology BeeStation | Linux クライアントなし → Web ポータル / ローカル共有 | 資格情報の入力はオーナー |
| 持ち込まない | Anaconda（uv に一本化）、Visual Studio Build Tools（build-essential で代替）、WSL、PowerShell 系、Windows 用ドライバ・拡張、CrystalMark、Clipchamp、Power Automate、LG Calibration Studio、ゲーム一式（VALORANT / LoL は不正対策の都合で Linux 不可） | |
| 要確認（実装時に調べて棚卸し表で判断を仰ぐ） | Bionic、FreeToken Desktop、OpenCode Desktop、GitHub Desktop（公式 Linux 版なし）、DLsiteNest、Unsloth（投資アプリ側の学習環境で扱う） | |

26.04 固有の注意: GNOME は **Wayland のみ**（X11 セッションなし）／日本語入力は既定の ibus-mozc で Chrome に文字が二重に入る報告あり → 検証で出たら fcitx5-mozc に切り替える台本を用意／Blackwell の GPU は**オープン版ドライバ必須**（26.04 には 595-open・610-open がある。ODR-0044 の CUDA 13.4 が要求する版を実装時に確認して選ぶ）／APT 3 で `apt-key` 廃止（鍵は `signed-by` 方式）。

## 全体の流れ

### 段階 0: 今の Windows で準備（AI、実装の本体）

1. GitHub に非公開リポジトリ `zmarl/workstation` を作成（**作成と初回 push の直前に一度確認**）し、`D:\Dev\workstation` に置く。
2. 棚卸し表 `inventory/windows-apps-2026-09.md` を作る（上表 + winget の全件、「入れる / 代替 / Web / 持ち込まない / 要判断」）。
3. AI 設定の持ち出し `ai-config/`:
   - Claude Code: `~/.claude/rules/*.md`（`.bak` 除く）、`skills/` 10 個、`settings.json`（Windows 専用の許可ルールを Linux 版へ置換）、`projects/D--Dev-Investment/memory/`（約 1.7MB・230 本）、plan ファイル群、プラグインは**一覧だけ**（キャッシュ 26MB は運ばず当日再導入）。
   - Codex: `AGENTS.md`、`config.toml`（Windows のパス・trust 設定を Linux パスへ書き換えた版）、`agents/*.toml` 4 本。
   - MCP: `.mcp.json` は**トークンを除いた雛形**（codex / notion。notion は廃止方針なので既定で無効）。
   - 除外: `.credentials.json`・`auth.json`・`.sandbox-secrets`・履歴・セッション・キャッシュ、Codex 履歴 29GB（必要なら旧ドライブから後で）。
4. dotfiles `dotfiles/`: WezTerm 設定（Linux 分岐は fish 起動・フォント Moralerspace Neon なので fish とフォントも導入対象）、`starship.toml`、`.gitconfig` の Linux 版（`core.autocrlf=input`、user.name/email と git-lfs は維持）、fish の最小設定（starship・zoxide の初期化）。
5. セットアップ台本 `setup/`（bash、何度実行しても同じ結果、各手順の前に「導入済みなら飛ばす」、ログと進捗を `~/.local/state/workstation/` に記録）:
   - `lib.sh` 共通（ログ・進捗・判定）
   - `00-bootstrap.md` 人が読む 1 枚（下の段階 1）と、Claude に最初に貼る指示文
   - `10-base.sh`（管理者）: apt 更新、build-essential・curl・git・zstd・rsync・ntfs-3g・qemu-utils、日本語フォント（Noto CJK・Moralerspace）、日本語入力、fish、openssh-server
   - `20-gpu.sh`（管理者）: NVIDIA オープン版ドライバの確認/導入、persistence mode → **再起動が必要**
   - `30-apps.sh`（管理者）: 外部 apt リポジトリ登録（gh・Chrome・Claude アプリ・ChatGPT・Cursor・WezTerm・Docker・NVIDIA Container Toolkit・CoolerControl）とアプリ導入（上記 + Discord・Obsidian・Handy・Solaar・LACT・GSmartControl・CPU-X・Thunderbird・ydotool・QEMU/OVMF）
   - `40-user-tools.sh`（sudo 不要）: uv と Python、Rust、Node LTS、Bun、pnpm、Codex CLI、Playwright、yt-dlp、apt に無い/古い CLI
   - `50-ai-config.sh`（sudo 不要）: `~/.claude`・`~/.codex` の復元。メモリのフォルダ名は**実際の clone 先パス**（既定 `~/dev/Investment`）から Claude Code の命名規則で算出して置く
   - `60-dotfiles-repos.sh`（sudo 不要）: dotfiles 配置、リポジトリの clone（Investment・Multi-Agent-Orchestration。codex-pet は remote が無いので旧ドライブから）
   - `90-verify.sh`: 検証表の出力（下の「検証」）
   - `run-as-admin.sh`: AI が管理者用台本を開く窓口。内容の要約を表示 → 新しい端末ウィンドウで `sudo` を実行 → オーナーがパスワード入力 → ログを保存 → AI がログと検証結果を読む（今の Windows でのタスク登録と同じ分担）
6. 当日の AI 向け規則 `CLAUDE.md`: 最初に進捗を読んで続きから／管理者操作の前に「何が変わるか」を日本語で説明／パスワードは打たない・sudo 設定は触らない／1 段ずつ実行して検証／**旧ドライブ（4TB・1TB）には触らない**（第 4 版の担当）／想定外は `NOTES.md` に書いて止まる／権限に関わる変更（`kvm`・`docker`・`input` グループ、SSH の設定）は個別にオーナーの了承を取ってから台本に含める。
7. 事前検証（Windows 上）: Docker の `ubuntu:26.04` コンテナで、GUI とドライバ以外の台本（10・30 のリポジトリ登録とパッケージ解決・40・90）を実際に流し、**鍵・リポジトリ URL・パッケージ名が 26.04 で解決できる**ことを確認。台本は shellcheck（コンテナ）にかける。秘密情報の混入検査（トークン形の文字列走査 + 持ち出し差分の目視）を通してから push。
8. 人が読む 1 枚（段階 1 の手順と最初の指示文）をスマホでも読めるよう送る。あわせて**各サービスの 2 段階認証の手段（スマホ・回復コード）を手元に揃えておく**よう案内する。

### 段階 1: 当日・人の担当（約 1 時間）

1. 組み立て・BIOS（第 4 版 §4.4 の 1〜2。**仮想化は有効**に — Cowork が使う）。
2. 新 2TB へ Ubuntu 26.04 を導入（旧ドライブは外したまま）。言語は日本語、「グラフィックスのサードパーティ製ドライバ」を入れる。
3. 端末を開き、Claude Code を入れてログイン（`curl` が無ければ先に `sudo apt install curl`）。
4. 1 枚紙の指示文を Claude に貼る → ここから AI が進める。

### 段階 2: 当日・AI が進める（約 2〜3 時間、パスワード入力 5〜6 回、ログイン 8〜10 回）

| 順 | AI がやること | オーナーの出番 |
| --- | --- | --- |
| 1 | git・gh を導入（管理者） | パスワード |
| 2 | `gh auth login`（ブラウザ） → キットを clone | GitHub ログイン |
| 3 | `10-base.sh` | パスワード |
| 4 | `20-gpu.sh` → 再起動 → `nvidia-smi` で 2 枚と UUID を記録 | パスワード、再起動後に Claude を開き「続きから」 |
| 5 | `30-apps.sh` | パスワード、権限グループ追加の了承 |
| 6 | `40`・`50`・`60`（sudo 不要） | なし |
| 7 | 各アプリのログイン案内（Claude アプリ・ChatGPT・Chrome 同期・Discord・Cursor・Thunderbird ほか） | 各ログイン |
| 8 | `90-verify.sh` と目視確認の案内 → 日本語入力が二重になれば fcitx5 へ切替 | 目視確認 |
| 9 | 結果を `NOTES.md` と検証表に残し、キットへ commit/push（当日の差分・実際に選んだドライバ版など） | なし |

この後は第 4 版 §4.4 の 6 番（旧ドライブの読み取り専用接続）以降へ。Claude Code の再開（12 番）はここで完了扱いになる。

## オーナーにしかできないこと（AI は代行しない）

組み立て・BIOS・OS の導入先ディスク選択／すべてのパスワード・2 段階認証・ログイン／再起動の実施／`.env` と秘密情報の配置／権限に関わる変更の了承（`docker` グループは管理者と同等の強さ、`input`（ydotool）はキー入力の注入を許す、`kvm`、SSH）／BeeStation など資格情報が要る接続。

## 検証（完了の判定）

- Windows 上の事前検証: `ubuntu:26.04` コンテナで台本が最後まで通り、全リポジトリの `apt update` が署名エラーなしで成功、全パッケージ名が解決する。shellcheck 警告 0、秘密情報の走査 0 件。
- 当日の `90-verify.sh`（自動）: `nvidia-smi` で 5070 Ti と PRO 5000 が見える／`docker run --gpus all` の中から GPU が見える／`git`・`gh auth status`・`uv`・`node`・`codex`・`claude` の版が出る／各アプリのパッケージが導入済み／`~/.claude` のメモリが新パスで読める（Claude Code に過去のメモリを尋ねて確認）／Codex が AGENTS.md を読む／Investment リポジトリの clone が main と一致。
- 当日の目視（オーナー）: Chrome と Claude アプリで日本語入力が正しい／Handy で日本語の音声入力がエディタに入る／MOTU から音が出てマイクが入る／Discord の画面共有／Chrome の同期完了。
- 完了と言える条件: 自動検証がすべて合格し、目視項目にオーナーの確認が付き、判断待ち（要確認アプリ等）が `NOTES.md` に列挙されている。技術的に入っただけで「使える」とは判定しない。

## 残るリスク

- Claude アプリ（ベータ）と ChatGPT アプリ（プレビュー）は Wayland で一部機能が欠ける。使えない場合は CLI と Web で代替する。
- Discord の `.deb` 自己更新、BeeStation の Linux 接続、MOTU の 26.04 での挙動は一次資料で未確認 → 当日の検証項目にする。
- ドライバの版は CUDA 13.4 の要件と `ubuntu-drivers` の推奨の両方を実装時に確認してから固定する。
