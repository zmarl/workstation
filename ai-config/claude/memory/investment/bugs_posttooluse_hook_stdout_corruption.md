---
name: bugs_posttooluse_hook_stdout_corruption
description: PostToolUse Bash フックが全 Bash stdout を上書きする — ファイルリダイレクト+Read で回避
metadata: 
  node_type: memory
  type: reference
  originSessionId: 7f9a7805-4c22-4abb-902a-78f9f25b1e23
---

`.claude/settings.json` の PostToolUse(Bash) フック `.claude/hooks/post_bash_worktree_check.ps1` は、git クリーン時に `working tree 0 bytes...`、dirty 時に `working tree dirty: N changed files...` を stdout に出力する。この出力が **Bash ツールの本来の stdout を画面上で置き換える**ため、`echo`/`grep`/`cat`/`uv run ...` の結果が一切見えなくなる（コマンド自体は正常実行されている）。

**回避策（実証済み）**: コマンド出力をリポジトリ内ファイルへリダイレクトし、Read ツールで読む。
例: `uv run pytest ... > .probe.txt 2>&1; echo "EXIT=$?" >> .probe.txt` の後に Read `D:\Dev\Investment\.probe.txt`。Git Bash の `/tmp` は Read ツールから見えない（Windows パス前提）ので必ずリポジトリ内に出す。終わったら一時ファイルを削除。

**Why:** このフックは不具合ではなくユーザー意図の正常動作。無効化（settings.json hooks を空に）してもセッション起動時ロードのため当セッションでは反映されない。勝手に消さず、検証は回避策で完遂し、settings.json は元に戻すのが正しい。

**How to apply:** Bash 出力が `working tree ...` で乱れたら即この回避策に切り替える。デバッグに時間を使わない。関連: [[reference_utf16_sql_files_unreadable]]
