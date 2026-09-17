---
name: desktop-launcher-shortcut
description: Desktopアプリ起動ショートカットの仕組み・CI契約・単一ショートカット化(2026-07-09)
metadata: 
  node_type: memory
  type: reference
  originSessionId: 90db5c8c-46c4-41fe-aa8d-ed7314171e90
---

# Desktop アプリ起動ショートカットの仕組みと単一化 (2026-07-09)

デスクトップの「Investment Control Tower」起動ショートカットの正体・CI契約・単一化変更。

## 起動チェーン
- `.lnk` → `wscript.exe "desktop\launch-with-autobuild-hidden.vbs"`（隠しVBS）→ `scripts\run_desktop_phase_a_launcher.ps1 -FastIfHealthy -ApplySchema -BuildIfMissing`（統合ランチャー: Docker→BFF ensure→ソース変更あればrebuild→Desktop起動）。WorkDir=repo root、Icon=`desktop/src-tauri/icons/icon.ico,0`
- ランチャーは起動毎に `create_desktop_phase_a_shortcut.ps1 -Location Desktop -EnsureLatest -AsJson` を呼びショートカットを自己同期する（`$SkipShortcutRefresh=$false` 既定）

## 正本スクリプト `scripts/create_desktop_phase_a_shortcut.ps1`
- **2026-07-09 変更前**: primary=`Investment Control Tower (Phase A).lnk` を作成し、`Sync-DesktopShortcutAliases` が `- Latest.lnk`/無印も **-AllowCreate 付きで作成**（＝常に3つ維持）。起動毎の自己同期で削除しても復活する設計だった
- **2026-07-09 変更後（feat/hidden-asset-screener, commit e21deede）**: 単一ショートカット方針。default `$ShortcutName="Investment Control Tower.lnk"`。`Sync-DesktopShortcutAliases` は作成でなく **legacy managed alias(.lnk) を Remove-Item で削除**。`desktop_shortcut_count=1`。これで自己同期しても1つのまま
- タスクバーのピン留めは Sync のみ（既存pinのtarget再ポイント、作成/削除しない）→ ユーザーの pin は保持。今回 pin は `- Latest.lnk` 名のまま残存（機能は正常。リネームは Windows pin キャッシュ破壊リスクで非推奨）

## CI 契約（重要）
- `scripts/check_desktop_local_launcher_contract.py` + `tests/scripts/test_desktop_local_launcher_contract.py`（GitHub workflow `framework-docs-quality.yml`、gate_id=`desktop-local-launcher-contract`）
- `_REQUIRED_SOURCE_MARKERS["scripts/create_desktop_phase_a_shortcut.ps1"]` が**3つの名前リテラル**（`(Phase A).lnk`/`- Latest.lnk`/`Investment Control Tower.lnk`）＋関数名（`Sync-DesktopShortcutAliases`/`Get-ManagedShortcutNames`/`Get-PinnedShortcutNames`）＋出力フィールド名（`desktop_shortcut_names`/`desktop_alias`/`taskbar_pinned`/`up_to_date`/`changed_fields` 等）を**部分文字列必須**化。→ 単一化しても3名前をmanaged names（削除対象リスト）として残せば契約を壊さない。目標名 `Investment Control Tower.lnk` は元から必須マーカーに含まれる
- **個数は問わない**: `_validate_shortcut_contract_records` は存在する各 `.lnk` の target=`wscript.exe`/workdir=repo root/args に vbs を含む/禁止マーカー(`powershell.exe`,`-WindowStyle Hidden`,`launch-with-autobuild.ps1`)非含有 を検証するのみ。win32 かつ cwd==repo_root のときのみ実デスクトップを検査（CI Linux では skip）
- 契約テスト19件 green・live checker ok=True で確認済み

## 注意
- `.lnk` は UTF-16 バイナリ。`strings` では読めない → `WScript.Shell` の `CreateShortcut($path)` で TargetPath/Arguments を読む
