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
| codex-pet | GitHub にリモートが無い | 旧ドライブを読み取り専用でつないだ後に写す |
| Codex の履歴（約 29GB） | 持ち出していない | 必要なら旧ドライブから写す（第 4 版の判断事項） |
| Tailscale | 今の PC では使っていないので入れていない | 外出先から SSH したくなったら追加を検討 |
| CUDA 13.4 用のドライバ（R615） | 26.04 にパッケージが無い | 計算レーン着手時に上げる（docs/decisions.md） |

## 当日に確かめること（一次資料で確認できなかった点）

- Discord の `.deb` 版が自分で更新されるか（最初の更新が来たとき）
- MOTU M シリーズの入出力（26.04 での報告が見つからない）
- HyperX QuadCast S のマイク入力（設定 → サウンドで入力に選べて、音が入るか）

## 不要と決まったもの

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
- 次の再開点: 段階 4（権限の変更を 1 項目ずつ了承 → `35-permissions`）。
