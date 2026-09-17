# 移行前の Git 救出（名前付け → 凍結 → bundle / .git 退避 → USB へ複製・照合）

## Context
Linux 再構築計画（第 4 版 §3.1）の「救出」段。GitHub から clone し直すと、名前の無いコミット・ローカル限定コミット・未コミット変更・git 管理外の証拠が消える。これを旧 4TB を作り直す前に、ドライブ外の控えへ指紋付きで残す。
NAS は未接続のため、オーナーが挿した USB（E:、28.9GB 空き、**FAT32 = 1 ファイル 4GB 上限**）を置き場にする。

## 実測で分かったこと（計画の前提）
- detached HEAD の作業フォルダが **12 個**（報告書の「12 本」はこれ）。うち 6 個は他の ref からも辿れず、6 個は辿れるが、指示どおり 12 個すべてに tag を付ける。
- `.git` 5.1GB の大半は `.git/investment/proof_pack_queue`（4.8GB、ゲートの待ち行列の状態）。コミット本体は約 144MB。
- flash-next: 未コミット 92 件、証拠フォルダは **351,617 ファイル・約 16GB（JSON 14.3GB）**。`.env` 等の名前は含まれない。
- stale-harness-constraints: 未コミット 0、ローカル限定コミット 1 つ（3853f9f6e）。
- rtx5000: 未コミット 3 件 → オーナー回答「記録を文書として保存」＝ commit/tag はせず、差分と実ファイルを退避物に同梱。
- D:\Dev 直下の repo は Investment / codex-pet / tools（深さ 4 まで）。報告書の 36 個は実行時に深く再探索して確定する。

## 手順（作業フォルダ・ブランチ・main の作業ツリーは一切動かさない）
退避先の作業場所: `D:\MigrationRescue\git-20260916\`（repo 外）。スクリプトは scratchpad に置き `uv run --no-project python` で実行。

1. **名前付け**: detached HEAD 12 個に `git tag salvage/<作業フォルダ名から Investment- を除いた名前> <HEAD>`（軽量 tag、ローカルのみ・push しない）。実行時に一覧を再取得し、台帳に作業フォルダ・SHA・「他 ref から到達可否」を記録。
2. **flash-next の凍結**（作業フォルダの index/ブランチを触らない方法）:
   - 作業フォルダの index を一時ファイルへ複製 → `GIT_INDEX_FILE=<一時>` で 92 パスを明示指定して `git add` → `git write-tree` → `git commit-tree -p fa92df508`（メッセージ: 採用ではなく凍結の記録である旨＋Co-Authored-By）→ `git tag -a rescue/flash-next-initial-analysis-20260916`。
   - 事前に 92 ファイルへ秘密情報らしい文字列（鍵・トークン形式）の簡易検査。当たれば止めて報告。
   - 同コミットの `git format-patch` / `git diff fa92df508 <rescue>` を patch として退避物へ。
   - 証拠フォルダを `tar | zstd -T0` で圧縮し 3900MB ごとに `split`、ファイル一覧（パス・サイズ）と件数 351,617 を台帳へ。
3. **stale-harness-constraints**: `git tag -a rescue/stale-harness-constraints-20260916 3853f9f6e`。
4. **rtx5000 の文書保存**: `git diff` の patch と変更 3 ファイルの実体、HEAD SHA を記した README を退避物へ（tag なし）。
5. **bundle と .git 退避**（各 repo）: `git bundle create <repo>.bundle --all` → `git bundle verify`。`.git` を `tar | zstd` で固め 3900MB 分割（proof_pack_queue も含む。並行セッションの書き込みで tar が "file changed" を出したら記録して続行）。
6. **台帳**: 全成果物の `sha256sum` を `SHA256SUMS`、tag 一覧・証拠件数・repo 一覧を `LEDGER.md` に。
7. **USB へ複製と読み戻し照合**: E:\investment-git-rescue-20260916\ へコピー → E: 上で `sha256sum -c SHA256SUMS`（デバイスから読み戻す）。さらに E: の bundle を一時フォルダへ `git clone` し、salvage/rescue tag 14 本と flash-next の 92 ファイルが入っていることを確認。分割 tar は結合して `zstd -t`。
   - 容量見込み: bundle 数百 MB＋.git 圧縮 1〜2GB＋証拠圧縮 2〜4GB（JSON 主体）。28.9GB に収まる見込み。超える場合は止めて報告。

## やらないこと
- tag の GitHub push、ブランチ・作業フォルダの変更や削除、USB のフォーマット、WSL 内 repo（~/clawd、§3.2 の別項目）、docs/research への取り込み（移行後の別作業）。

## 検証（完了条件）
- `git tag -l 'salvage/*' 'rescue/*'` に新規 14 本、各 tag が台帳の SHA を指す。
- 作業フォルダの `git status` 件数と各ブランチ HEAD が作業前と同一（flash-next 92 / rtx5000 3）。
- E: 上で `sha256sum -c` 全件 OK、bundle から clone して tag と 92 ファイルを確認、分割アーカイブの整合性検査 OK。

## 報告時に伝える注意
USB メモリ 1 本は NAS より壊れやすく、DB ダンプ（60〜150GB）は入らない。今回は Git 救出の控えとして使い、NAS 照合は別途残る。
