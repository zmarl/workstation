# Windows のアプリ棚卸しと Ubuntu での扱い（2026-09-17）

元データ: `winget-list-2026-09-17.txt`（winget list の全 184 件）。オーナーの方針は「ゲーム以外で Linux に対応しているものはすべて入れる」。Linux 版が無いものは代わりの道具か Web 利用に振り分けました。

扱いの記号: **入れる**（同じアプリの Linux 版）／**代替**（別の道具で同じ役割）／**Web**（ブラウザで使う）／**不要**（Linux では要らない・役割が無い）／**除外**（ゲーム）／**判断待ち**（NOTES.md）

## 開発・AI

| Windows | 扱い | Ubuntu で | 台本 |
| --- | --- | --- | --- |
| Claude | 入れる | Claude アプリ（公式ベータ、Code タブあり） | 30-apps |
| ChatGPT（実体は OpenAI.Codex） | 入れる | ChatGPT アプリ（公式プレビュー、Codex 内蔵） | 30-apps |
| Codex CLI（npm） | 入れる | 公式インストーラ | 40-user-tools |
| Claude Code | 入れる | 公式インストーラ（段階 1 でオーナー） | day1 |
| Cursor | 入れる | 公式 apt | 30-apps |
| OpenCode | 入れる | 公式 .deb | 30-apps |
| Git / GitHub CLI | 入れる | Ubuntu の git / 公式 apt の gh | 10-base / 30-apps |
| GitHub Desktop | 判断待ち | 公式の Linux 版なし | — |
| lazygit / Neovim / ripgrep / fd / fzf / jq / zoxide / starship | 入れる | Ubuntu のパッケージ | 10-base |
| yazi | 入れる | GitHub のリリース | 40-user-tools |
| WezTerm | 入れる | fury apt の nightly | 30-apps |
| PowerShell 7 / Preview、Windows ターミナル | 不要 | fish と bash（WezTerm の Linux 分岐は fish） | 10-base |
| uv / Python 3.13 / Python Launcher | 入れる | uv で 3.12 と 3.13 | 40-user-tools |
| Anaconda3 | 不要 | uv に一本化 | — |
| Node.js LTS / pnpm / Playwright / ngrok | 入れる | fnm + npm | 40-user-tools |
| Bun | 入れる | 公式インストーラ | 40-user-tools |
| Rustup | 入れる | rustup + rust-analyzer | 40-user-tools |
| DuckDB CLI | 入れる | 公式インストーラで 1.5.5 | 40-user-tools |
| Docker Desktop | 代替 | Docker Engine + NVIDIA Container Toolkit | 30-apps |
| WSL | 不要 | Ubuntu そのもの | — |
| Visual Studio Build Tools / Windows SDK / VC++ 再頒布 / .NET / WindowsAppRuntime | 不要 | build-essential | 10-base |
| FFmpeg / ImageMagick / Poppler / 7-Zip | 入れる | Ubuntu のパッケージ | 10-base |
| yt-dlp（uv tool） | 入れる | uv tool | 40-user-tools |
| Unsloth | 不要（ここでは） | 投資アプリ側の学習環境で扱う（ODR-0044） | — |
| LM Studio（Windows では未導入。オーナーが今後使う） | 入れる | 公式 .deb（パッケージ名 lm-studio） | 30-apps |
| Bionic（LM Studio 社の AI エージェント） | 不要 | LM Studio を使うのに必要ない別アプリ（09-17 オーナー回答を受けて判断） | — |
| FreeToken Desktop | 不要 | 使っていない（09-17 オーナー回答） | — |
| Dev Home | 不要 | — | — |

## 日常・連絡・メモ

| Windows | 扱い | Ubuntu で | 台本 |
| --- | --- | --- | --- |
| Google Chrome | 入れる | 公式 .deb（更新リポジトリを自分で登録） | 30-apps |
| Microsoft Edge | 不要 | Chrome に一本化 | — |
| Discord | 入れる | 公式 .deb | 30-apps |
| Obsidian | 入れる | 公式 .deb | 30-apps |
| Mozilla Thunderbird | 入れる | Ubuntu の snap | 30-apps |
| Notion | Web | 公式の Linux 版なし | — |
| LINE | Web | 公式の Chrome 拡張 | — |
| Microsoft Teams / Outlook / Copilot / 365 Copilot | Web | — | — |
| Aqua Voice | 代替 | Handy（Whisper で日本語）+ ydotool | 30-apps / 35-permissions |
| Synology BeeStation | Web | Linux クライアントなし | — |
| DLsiteNest | Web | Linux 版なし | — |
| Clipchamp / Power Automate / Bing / MSN 天気 / 付箋 / フォト / ペイント / メモ帳 / 電卓 / カメラ / クロック / サウンド レコーダー / Snipping Tool / メディア プレーヤー / スマートフォン連携 / クイック アシスト / 問い合わせ / フィードバック Hub | 不要 | GNOME の標準アプリ（スクリーンショット・電卓・テキストエディタ等）で足りる | — |
| 動画・画像の拡張機能（AV1 / HEVC / HEIF / WebP / VP9 / MPEG-2 / Raw / Web メディア） | 不要 | Ubuntu の標準コーデック + ffmpeg | — |
| 日本語ローカル エクスペリエンス パック | 代替 | language-pack-ja・日本語入力 | 10-base |

## 周辺機器・監視

| Windows | 扱い | Ubuntu で | 台本 |
| --- | --- | --- | --- |
| Logi Options+ / Logi Plugin Service / Logicool G HUB | 代替 | Solaar | 30-apps |
| FanControl / PawnIO | 代替 | CoolerControl | 30-apps |
| MSI Afterburner / RivaTuner Statistics Server | 代替 | LACT、nvidia-smi、nvtop | 30-apps / 10-base |
| CrystalDiskInfo | 代替 | GSmartControl、smartctl、nvme-cli | 30-apps / 10-base |
| CPU-Z | 代替 | CPU-X | 30-apps |
| CrystalMark 3D25 | 不要 | — | — |
| HyperX NGENUITY | 不要 | 機器は USB マイク QuadCast S。マイクは標準の USB オーディオとして使い、光り方の設定だけ諦める。当日に入力を確認 | — |
| MOTU M Series | 代替 | ドライバ不要（PipeWire）。当日に入出力を確認 | — |
| LG Calibration Studio | 不要 | Linux 版なし | — |
| NVIDIA App / コントロールパネル / FrameView / PhysX / HD オーディオ / グラフィックス ドライバー | 代替 | nvidia-driver-610-open | 20-gpu |
| Intel / Realtek / Asmedia / Texas Instruments のドライバ、Dual Controller | 不要 | Linux カーネルに含まれる | — |
| Microsoft GameInput / DirectX / Game Bar / Xbox 系 / ゲーム サービス | 除外 | — | — |

## ゲーム（オーナーの方針で除外）

Steam、EA app、Riot Client / Riot Vanguard / VALORANT / League of Legends、Minecraft（Windows 版・Launcher・Java Edition）。VALORANT と League of Legends は不正対策ソフトの都合で Linux では遊べません。

## 自作・その他

| Windows | 扱い | 備考 |
| --- | --- | --- |
| Investment Control Tower | 不要 | 投資アプリは Linux で作り直す（全体設計書） |
| Windows アプリケーションの互換性関連、Widgets、Start エクスペリエンス、Windows セキュリティ、App Installer、Microsoft Store、Windows SDK AddOn | 不要 | — |
