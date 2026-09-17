# 技術的な選択と理由（2026-09-17）

オーナーの決定（置き場所・パスワードの分担・範囲・AI 設定の持ち出し）は計画で確定済みです。ここには、その範囲で AI が選んだ「どう入れるか」と理由を残します。調べた日は 2026-09-17 で、配布元の一次資料と ubuntu:26.04 コンテナでの確認に基づきます。

| 対象 | 選んだもの | 理由 / 代わりの案 |
| --- | --- | --- |
| NVIDIA ドライバ | Ubuntu の `nvidia-driver-610-open`（610.57） | Blackwell はオープン版が必須。Ubuntu 署名済みのためセキュアブートで追加の鍵登録が要らない。**CUDA 13.4 の新機能は R615 以上が必要**だが、26.04 にはまだ 615 のパッケージが無い。13.x で作られた既存のプログラムは 580 以上で動く。615 が必要になるのは計算レーン（投資アプリ側、凍結中）を始めるときなので、その時点で Ubuntu の 615 が出ていればそれに、無ければ NVIDIA の CUDA リポジトリの `nvidia-open` に上げる（セキュアブートの鍵登録はオーナー） |
| Claude アプリ | Anthropic の apt リポジトリ（公式手順どおり、鍵の指紋を照合） | apt の通常更新で届く。ベータのため音声入力・Computer Use は無い |
| ChatGPT アプリ | 公式 `.deb`（`persistent.oaistatic.com/.../chatgpt_amd64.deb`） | `.deb` が OpenAI の署名付きリポジトリを自分で登録する。リポジトリの鍵 URL は公開されていないので手で登録しない |
| Google Chrome | 公式 `.deb` | `.deb` が `google-chrome.sources` を自分で登録する（コンテナで確認）。手でリポジトリを足すと二重登録になり apt が止まることがある |
| Cursor / gh / Docker / NVIDIA Container Toolkit | 各社の公式 apt リポジトリ | 公式手順どおり。gh は Ubuntu 版（2.46）が古く、snap は公式が非推奨 |
| WezTerm | fury の apt リポジトリの `wezterm-nightly` | 安定版は 2024-02 のまま（Windows と同じ版）で、Ubuntu 24.04 以降向けの配布が無い。26.04 は Wayland のみなので、以後の修正を含む毎日更新の nightly にする。設定は Windows と共通のまま Linux 分岐だけ修正（fish のパス、WSL タブは Windows だけ） |
| CoolerControl | 公式 `setup.sh` と同じ内容のリポジトリ設定を台本に直接書く | 管理者権限でネットのスクリプトを流さない |
| Discord / Obsidian / OpenCode / Handy / LACT | 公式 `.deb`（GitHub のリリースから名前で探す） | Obsidian は最新リリースに Android 版だけのことがあるため、最近のリリースを順に探す。LACT は 26.04 専用ビルドを選ぶ |
| Thunderbird | `apt install thunderbird`（中身は snap） | 26.04 の標準。自動更新される |
| yazi / DuckDB | yazi は GitHub のリリース、DuckDB は公式インストーラで 1.5.5 を固定 | どちらも Ubuntu のパッケージに無い。DuckDB 1.4 は 9 月でサポート終了 |
| starship / lazygit / zoxide ほか CLI | Ubuntu のパッケージ | 版は Windows より少し古いが十分（lazygit 0.57 / Windows 0.58） |
| Node.js | fnm で LTS | 版の切り替えができ、sudo が要らない。`~/.local/share/fnm/aliases/default/bin` を PATH に入れて、どのシェルからも同じ版が見える |
| Codex CLI | 公式インストーラ（`~/.local/bin/codex`） | Windows は npm だったが、Node の版に左右されない置き場所の方が MCP の `codex` 呼び出しが安定する |
| Python | uv（3.12 と 3.13） | 投資アプリの標準。Anaconda は持ち込まない |
| 日本語入力 | 既定の ibus-mozc。fcitx5-mozc も入れておき、`setup/switch-ime.sh` で切替 | Chrome で文字が二重になる報告があるため、確認で出たらパスワード無しで切り替えられるようにする |
| 権限の変更 | `35-permissions.sh` に分け、項目ごとに了承 | docker グループは管理者と同等、input は キー入力の注入を許す。他の台本に混ぜない |
| SSH | 公開鍵のみ・パスワードと root のログイン禁止 | 今の PC に SSH 鍵は無いので、使う時点で鍵を作って登録する |
| AI 設定 | ルール・スキル・設定・メモリ・計画を持ち出し。ログイン情報・履歴・キャッシュは運ばない | Codex の config.toml は ChatGPT アプリが Windows で自動生成した項目（通知・Computer Use・ローカルの配布元）を外し、パスを Linux 用に置換 |
