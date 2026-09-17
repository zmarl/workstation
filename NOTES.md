# 判断待ちの事項と当日の記録

## オーナーの判断待ち（キットでは入れていないもの）

| 事項 | 状況 | 提案 |
| --- | --- | --- |
| Bionic（LM Studio 社） | 2026-09-08 の 1.1.2 で Linux 版が出たと公式の変更履歴にあるが、配布形式と URL を確認できていない | 使っているなら当日に公式サイトから入れる。使っていなければ入れない |
| FreeToken Desktop | Linux 版があると README にあるが、配布形式が未確認 | 同上 |
| GitHub Desktop | 公式の Linux 版なし（有志版は 2025-02 で止まっている） | 入れない。gh と lazygit で代わりにする |
| DLsiteNest | Linux 版なし | ブラウザで利用 |
| Synology BeeStation | Linux のクライアントなし | Web ポータルか、ローカルの共有フォルダとしてつなぐ（資格情報はオーナーが入力） |
| HyperX NGENUITY | Linux 版なし | 何に使っているか（ヘッドセット・マイク・キーボード）を聞いてから、HeadsetControl / OpenRGB を検討 |
| Notion・Teams・Outlook・Copilot | デスクトップ版なし | Chrome で開き、必要なら「アプリとしてインストール」。Notion の MCP はトークン抜きの雛形だけ持ち出し（投資アプリ側では廃止済み） |
| LINE | Linux 版なし | 公式の Chrome 拡張（Chrome の同期で戻る） |
| codex-pet | GitHub にリモートが無い | 旧ドライブを読み取り専用でつないだ後に写す |
| Codex の履歴（約 29GB） | 持ち出していない | 必要なら旧ドライブから写す（第 4 版の判断事項） |
| Tailscale | 今の PC では使っていないので入れていない | 外出先から SSH したくなったら追加を検討 |
| CUDA 13.4 用のドライバ（R615） | 26.04 にパッケージが無い | 計算レーン着手時に上げる（docs/decisions.md） |

## 当日に確かめること（一次資料で確認できなかった点）

- Discord の `.deb` 版が自分で更新されるか（最初の更新が来たとき）
- MOTU M シリーズの入出力（26.04 での報告が見つからない）
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
