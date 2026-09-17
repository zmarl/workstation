# 当日の 1 枚 — 新しい Ubuntu PC を AI に整えてもらう手順

この紙（またはスマホ）だけ見れば進められるように書いています。あなたが行うのは「組み立て・Ubuntu の導入・パスワード・ログイン・再起動・了承」だけで、それ以外は AI（Claude Code）が進めます。

## 分解する前に（今の Windows で）

- [ ] 各サービスの 2 段階認証の手段が手元にあるか確認する（スマホの認証アプリ、回復コード）。対象: GitHub・Google・Anthropic（Claude）・OpenAI（ChatGPT）・Discord・Cursor・Obsidian・Thunderbird のメール
- [ ] Windows の Chrome で同期がオンになっているか確認する（設定 → 同期）。ブックマーク・パスワード・拡張機能が新しい PC に戻ります
- [ ] Discord のパスワードが分かるか確認する
- [ ] 移行計画 第 4 版 第 3 章の「救出・退避」が終わっている（DB・`.env`・Obsidian の保管庫・codex-pet などはこのキットでは運びません）
- [ ] Ubuntu 26.04 の起動 USB を用意する（第 4 版 §4.1）

## 当日 — あなたの担当（約 1 時間）

1. **組み立てと BIOS**（第 4 版 §4.4 の 1〜2）。BIOS では**仮想化（Intel VT-x / VT-d）を有効**にしてください。Claude アプリの Cowork が使います。
2. **Ubuntu 26.04 を新しい 2TB へ入れる。** 旧ドライブは外したままです。
   - 言語は「日本語」、キーボードは日本語
   - 「グラフィックスと Wi-Fi 機器のためのサードパーティ製ソフトウェアをインストールする」に**チェックを入れる**
   - ユーザー名は短い英小文字（例: `kazum`）
3. **端末を開いて、次の 3 行を順に打つ。** 端末は画面左下のアプリ一覧から「端末」を開きます。1 行目でパスワードを聞かれます。

   ```bash
   sudo apt update && sudo apt install -y curl git
   curl -fsSL https://claude.ai/install.sh | bash
   mkdir -p ~/dev && cd ~/dev && ~/.local/bin/claude
   ```

   Claude Code が起動したら、表示に従ってブラウザで Anthropic のアカウントにログインします。
4. **Claude に次の文を貼る（または打つ）。** ここから AI が進めます。

   ```text
   新しい Ubuntu PC の作業環境づくりを始めます。手順は GitHub の非公開リポジトリ zmarl/workstation にあります。
   1. GitHub CLI（gh）を公式リリースの linux_amd64.tar.gz から ~/.local/bin に入れてください（sudo は使わないでください）。
   2. GitHub へのログインは私がやります。新しい端末ウィンドウを開いて gh auth login --hostname github.com --git-protocol https --web を実行してください。
   3. ログインできたら gh repo clone zmarl/workstation ~/dev/workstation で取得し、~/dev/workstation の AGENTS.md に従って続きを進めてください。
   ```

## 当日 — AI が進める間のあなたの出番（約 2〜3 時間）

- **パスワード（5〜6 回）**: AI が「何が変わるか」を説明してから新しいウィンドウを開きます。内容に納得したらパスワードを打ってください。やめたいときはウィンドウを閉じれば止まります。
- **再起動（1 回）**: ドライバを入れた後です。再起動したら端末で `cd ~/dev/workstation && ~/.local/bin/claude` を起動し、「続きから」と伝えてください。
- **了承（項目ごと）**: 権限に関わる変更は 1 つずつ聞かれます。
  - Cowork 用の仮想化（kvm）
  - sudo なしで Docker を使う（docker。管理者と同等の強さになります）
  - 音声入力が文字を打ち込めるようにする（input）
  - 別の端末から SSH で入れるようにする（ssh）
- **ログインし直し**: 権限の変更を反映するため、1 回ログアウトしてもらいます。
- **各アプリのログイン**: Chrome（同期）・Claude アプリ・ChatGPT・Discord・Cursor・Obsidian・Thunderbird・OpenCode（LM Studio はログイン不要）。
- **目視確認**: 最後に AI が確認表を出します。日本語入力、音声入力（Handy）、スピーカー（MOTU）とマイク（HyperX QuadCast S）、Discord の画面共有を実際に試してください。

## 終わったと言える状態

- AI の確認表で自動確認の失敗が 0 件
- 目視確認がすべて問題なし（問題があれば AI が `NOTES.md` に記録して対応を相談します）
- この後は移行計画 第 4 版 §4.4 の 6 番（旧ドライブの読み取り専用接続）以降に進みます
