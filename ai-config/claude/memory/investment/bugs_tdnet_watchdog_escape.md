---
name: TDnet watchdog の read_epoch PowerShell エスケープ衝突
description: scripts/run_tdnet_breaking_watchdog_impl.bat の read_epoch サブルーチン内 PowerShell 正規表現が cmd の ^ エスケープと衝突していた
type: feedback
originSessionId: 8451be61-e9d9-4275-a77e-958c175252bd
---
2026-04-18 に watchdog が serve 死亡検知の直後に毎回 327B で途切れる症状を調査して発見。

**問題**: `run_tdnet_breaking_watchdog_impl.bat` の `:read_epoch` サブルーチン内で `for /f %%i in ('powershell ... if ($v -match ''^\d+$'') ...')` を使っていた。cmd の中の `^` は pipe エスケープ（`^|`）用だが、PowerShell 正規表現の先頭アンカー `^\d+$` と混在することで cmd のパーサが `^\d` を破壊し、PowerShell 側で `UnexpectedToken '^\d+$'` が発生。ただし `for /f` 自体は errorlevel を受けても本体処理を続行するため、batch の下流処理でサイレントに失敗し、最終ログが書かれないまま exit 255 で終了していた。

**Why**: `TdnetBreakingServe` が何らかの理由で死亡した際、watchdog が再起動できず、Discord 決算通知が 2026-04-15 以降ゼロになっていた根本原因。

**How to apply**:
- cmd の `for /f` 内で PowerShell を呼ぶときは正規表現の `^` を避けるか、PowerShell コマンド全体を独立したヒアドキュメント相当にする
- 可能ならまず **pure cmd 実装で書く**（`for /f "tokens=1 delims= " %%i in ("%~1")` と数値チェック用の per-char delimiter）
- watchdog / 診断系の batch が 327B など **異常に同一サイズのログで途切れる場合**、batch から呼び出す外部コマンドが silent parser error を起こしていないか疑う
- 修正後は `cmd //c "scripts\run_tdnet_breaking_watchdog_impl.bat --dry-run"` で手動実行し、ログが最終行（Dry-run mode 等）まで到達することを確認
