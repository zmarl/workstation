# 判断待ちの事項と当日の記録

## オーナーの判断待ち（キットでは入れていないもの）

| 事項 | 状況 | 提案 |
| --- | --- | --- |
| GitHub Desktop | 公式の Linux 版なし（有志版は 2025-02 で止まっている） | 入れない。gh と lazygit で代わりにする |
| DLsiteNest | Linux 版なし | ブラウザで利用 |
| Synology BeeStation | Linux のクライアントなし | Web ポータルか、ローカルの共有フォルダとしてつなぐ（資格情報はオーナーが入力） |
| HyperX NGENUITY | Linux 版なし。使っている機器は USB マイク HyperX QuadCast S（09-17 オーナー回答・Windows の機器一覧で確認） | 入れない。マイク自体は標準の USB オーディオとして使える見込みで、ミュートと音量つまみは本体側で効く。光り方の設定だけができなくなる。当日にマイクの入力を確認する |
| Notion・Teams・Outlook・Copilot | デスクトップ版なし | Chrome で開き、必要なら「アプリとしてインストール」。Notion の MCP はトークン抜きの雛形だけ持ち出し（投資アプリ側では廃止済み） |
| LINE | Linux 版なし | 公式の Chrome 拡張（Chrome の同期で戻る） |
| Codex の履歴（約 29GB） | 持ち出していない | 必要なら旧ドライブから写す（第 4 版の判断事項） |
| Tailscale | 今の PC では使っていないので入れていない | 外出先から SSH したくなったら追加を検討 |
| CUDA 13.4 用のドライバ（R615） | 26.04 にパッケージが無い | 計算レーン着手時に上げる（docs/decisions.md） |

## 当日に確かめること（一次資料で確認できなかった点）

- MOTU M シリーズの入出力（26.04 での報告が見つからない）
- HyperX QuadCast S のマイク入力（設定 → サウンドで入力に選べて、音が入るか）

## 不要と決まったもの

- `Multi-Agent-Orchestration`（tools）と `codex-pet`（09-20 オーナー回答「多分ないのでいらない。codex-pet も適当に作ったものなのでいらない」）。どちらも GitHub 上に無く、`60-dotfiles-repos.sh` の取得対象から外しました

- FreeToken Desktop（09-17 オーナー回答: 使っていない）
- Bionic（LM Studio 社の AI エージェントアプリ）。09-17 オーナー回答「LM Studio を使うのに要るなら入れる」→ LM Studio は別アプリで Bionic は不要（配布元の案内と、パッケージの依存関係で確認）なので入れない。LM Studio 本体は 30-apps で入れる
- Windows の `~/.lmstudio`（約 2.9GB）は Bionic の実行部品と CLI で、モデルは 0 件のため運ばない

## LM Studio を使うときの注意

- 72GB のカード（RTX PRO 5000）は投資アプリの vLLM 用（ODR-0044）。LM Studio で大きなモデルを同じカードに載せると取り合いになるので、LM Studio の設定で使う GPU を 5070 Ti に絞るか、vLLM を止めているときに使う
- Claude アプリ（ベータ）と ChatGPT アプリ（プレビュー）の Wayland での不具合（通知・ショートカット・浮動ウィンドウ）
- 日本語入力が Chrome で二重にならないか

## 旧 PC での予行演習（2026-09-17、ubuntu:26.04.1 コンテナ）

- shellcheck: 警告 0。
- 3 回目の通し実行で全台本が終了コード 0（`90-verify` を除く）。`50`・`60` は 2 回流しても 0（何度流しても同じ結果）。ホームフォルダ内に tester 以外の所有物なし。
- 管理者の台本（simulate）: 全リポジトリの登録と `apt-get update` が署名エラーなしで成功し、全パッケージ（ドライバ 610-open、Chrome・Claude・ChatGPT・Cursor・WezTerm nightly・Discord・Obsidian 1.13.7・OpenCode・Handy 0.9.6・LACT・CoolerControl・Docker・NVIDIA Container Toolkit ほか）の導入が解決できた。
- ユーザーの台本（実導入）: uv 0.12.15 / Python 3.12.14 / Node 24.21 / pnpm / Playwright / Bun 1.4.2 / Rust 1.98.1 + rust-analyzer / Codex CLI 0.154.0 / DuckDB 1.5.5 / yt-dlp / yazi / Moralerspace Neon がすべて確認で合格。AI 設定（ルール・メモリの新パス・Codex の設定とメモリ）も合格。
- `90-verify` の失敗 33 件は、simulate で実際には入れていないパッケージの分だけ（想定どおり）。
- 別途、Chrome と ChatGPT の `.deb` を実際に入れ、それぞれ `google-chrome.sources` / `chatgpt.sources` を自分で登録し `apt-get update` が通ることを確認。
- 予行演習で見つけて直した不具合: OpenCode のパッケージ名（`opencode`）、ダウンロード用一時フォルダの権限、**root の台本が `~/.local` を root 所有にしてユーザー導入が全滅する問題**、`| grep -q` の偽陰性。
- コンテナでは確かめられないこと: GPU とドライバ、デスクトップ（端末ウィンドウの起動・日本語入力・音声入力）、snap（Thunderbird）、ログイン、グループ変更、systemd のサービス。

## 当日の記録

（AI が段ごとに、日時・結果・選んだ版・起きたことを追記する）

### 2026-09-20（セットアップ当日）

- 18:5x 前後: 準備（gh を `~/.local/bin` へ仮置き、GitHub ログイン、本リポジトリを `~/dev/workstation` へ取得）まで完了。
- 最初の `10-base` は 17:48 にウィンドウを開いたが、ログが 1 件も作られないまま終了コード 1 で記録されていた（パスワード入力前にウィンドウが閉じられたと判断）。導入は行われていなかったため、やり直した。
- 19:00–19:01 **段階 1 `10-base`: 全項目 ok**。system-upgrade（13 個の更新）・apt-base・apt-cli・apt-japanese。rg / fzf / nvim / starship / lazygit / fish / jq / btop / nvtop / git-lfs / ffmpeg / fdfind の実体と、ibus-mozc・fcitx5-mozc・fonts-noto-cjk の導入を確認。多くが導入済みだったため短時間で完了。
- 19:01–19:02 **段階 2 `20-gpu`: 全項目 ok**。Ubuntu 導入時に入っていた `nvidia-driver-595-open` は要件（610 以上）未満だったため、`nvidia-driver-610-open` へ入れ替え。`reboot-required` を作成。**再起動待ち**で中断。
- 19:22 再起動。ドライバ 610.57.04 が RTX PRO 5000 72GB と RTX 5070 Ti の両方で動いていることを確認。
- 19:29 **段階 2 `20-gpu` 再実行: 全項目 ok**。動作中の 610 系は要件を満たすため入れ替えなし。`nvidia-persistenced` は 26.04 では静的ユニット（`systemctl enable` の対象外）で、`--now` により稼働中。`reboot-required` を削除。
- 19:31 段階 3 の 1 回目は、引数なしのときに空の項目名が 1 つ渡り `unknown-` で失敗（`run-as-admin.sh` の `printf ' %q' "$@"` が引数ゼロでも `''` を出す不具合）。導入は行われていない。台本を直して再実行。
- 19:31–19:35 **段階 3 `30-apps`: 全項目 ok**。Chrome 153 / Claude 2.2553.1 / ChatGPT 26.915 / Cursor 3.21.16 / WezTerm nightly 20260917 / Discord 1.0.158 / Obsidian 1.13.7 / OpenCode 1.18.31 / LM Studio 0.4.25 / Handy 0.9.7 / Solaar 1.1.19 / CoolerControl 5.0.1 / LACT 0.10.1 / GSmartControl / CPU-X / Thunderbird（snap 156.0）/ Docker 29.8.1 + compose / NVIDIA Container Toolkit 1.20.1。Docker は稼働中で `nvidia` ランタイムが登録済み。
- `nvidia_container_toolkit` は 1 回目に `nvidia.github.io` へ繋がらず失敗（curl 7）。一時的な不調で、確認すると到達できたためその項目だけ再実行して成功。
- gh は Ubuntu の ESM 側（優先度 510）が公式リポジトリ（500）より強く、古い 2.46.0 が入った。`/etc/apt/preferences.d/github-cli.pref` で公式を優先する pin を台本に追加し、導入済みでも候補と違えば入れ替えるようにして再実行 → **公式 2.101.0**。仮置きの `~/.local/bin/gh` を削除し、GitHub のログイン（zmarl）が残っていることを確認。
- 19:45–20:10 **版と Linux 対応の総点検**（オーナーの依頼）。入れた版はほぼすべて上流の最新でした: Chrome 153.0.8010.52・Discord 1.0.158・Obsidian 1.13.7（1.13.8 は Android 専用の配布なのでデスクトップは 1.13.7 が最新）・OpenCode 1.18.31・Handy 0.9.7・LACT 0.10.1・LM Studio 0.4.25・NVIDIA Container Toolkit 1.20.1・gh 2.101.0。Claude・ChatGPT・Cursor・WezTerm・Docker・CoolerControl・Thunderbird は各リポジトリの最新（`apt list --upgradable` は空）。ドライバ 610 は 26.04 で選べる最新（595 と 610 のみ）。`40-user-tools` が固定する DuckDB 1.5.5 も最新のまま。
- Solaar だけ Ubuntu 提供の 1.1.19 で上流は 1.1.20。差が小さいので Ubuntu の更新に任せます（変更しない）。
- 動作の確認: 両 GPU の認識、docker / containerd / coolercontrold / lactd の稼働、LACT が両カードを認識、Docker への `nvidia` ランタイム登録、`/dev/uinput` が input グループ、ydotool 1.0.4 導入済み。
- **解決**: Discord は自前の自動更新を持つようになったため、`.deb` でも放置で更新されます（「当日に確かめること」から削除）。
- **見つかった不足 1**: GNOME + Wayland ではアプリ自身のグローバルキーが他のウィンドウに届かないため、Handy を呼び出せませんでした（登録は空でした）。`setup/70-handy-wayland.sh` を追加し、GNOME のカスタムショートカット（**無変換キー**・オーナーの選択）から `handy --toggle-transcription` を呼び、ログイン時に `--start-hidden` で常駐させます。2 回流しても登録が 1 つのままになることを確認済み。
- **見つかった不足 2**: 26.04 + Wayland では ibus のままだと Chrome や Electron 製アプリで二重入力が起きやすいため、オーナーの判断で**先に fcitx5 へ切り替える**ことにしました。`switch-ime.sh` に、fcitx5 のとき Chrome の起動設定（`--ozone-platform-hint=auto --enable-wayland-ime`）をユーザー側に置く処理を追加（ibus に戻すと消えます）。
- 段の表を更新: 段階 4 のあとに IME の切り替えを置き、**ログインし直しを 1 回にまとめる**。Handy の設定は段階 8 に新設（以降の段は 1 つずつ繰り下がり、全 11 段）。
- 小さな直し: `20-gpu.sh` は 26.04 の `nvidia-persistenced` が静的ユニットであることを踏まえ、起動のみ行うようにしました（長い警告が出なくなります）。
- 20:31 **段階 4 `35-permissions`: input・docker・kvm・ssh の 4 項目すべて ok**（オーナーが 4 項目それぞれを了承）。SSH は openssh-server 1:10.2p1 を導入し、公開鍵のみ・パスワードと root のログインは禁止。`~/.ssh/authorized_keys` は空なので、鍵を置くまで誰も入れません。`relogin-required` を作成。
  - 1 回目はログインが作られないまま終了コード 1（パスワード入力前にウィンドウが閉じたと判断）。グループも SSH も変わっていないことを確認してからやり直しました。
- 20:31 `switch-ime.sh fcitx5`。Chrome の起動設定の上書き（`--ozone-platform-hint=auto --enable-wayland-ime`）を `~/.local/share/applications` に配置。
- 20:32 **段階 5 `40-user-tools`: 全項目 ok**。uv 0.12.17 / Python 3.12.14 / Node 24.21 / pnpm 12.5.1 / Bun 1.4.2 / Rust 1.98.1 + rust-analyzer / Codex CLI 0.155.1 / DuckDB 1.5.5 / yt-dlp 2026.08.19 / yazi / Moralerspace（20 件）を実際に動かして確認。
- 20:32 **段階 6 `50-ai-config`: 全項目 ok**。設定・メモリを配置（既存は `~/.local/state/workstation/backups/20260920-203249/` へ退避）。marketplace 4 件とプラグイン 4 件（rust-analyzer-lsp / frontend-design / planning-with-files / claude-mem）を導入。
- 20:33 **段階 7 `60-dotfiles-repos`: 全項目 ok**。端末と Git の設定、Investment（256MB）を `~/dev/Investment` へ取得、ydotool の常駐を有効化。
- 20:33 **段階 8 `70-handy-wayland`: 全項目 ok**（無変換キーの登録は確認のみ）。
- 次の再開点: **オーナーがログアウト→ログインし直す**。戻ったら `60-dotfiles-repos` と `70-handy-wayland` を流し直し、段階 9（アプリのログイン）→ 段階 10（`90-verify`）→ 段階 11（記録と push）。
