---
name: project-startup-progressive-redesign
description: Desktop 起動を即時表示+順次読込へ再設計 (2026-06-11)。loading_initial_data phase 廃止、warm-up は ready 後 3-stage、起動画面は Signal Horizon デザイン
metadata: 
  node_type: memory
  type: project
  originSessionId: b71979e6-2eb7-4359-9ffe-2ed4b4099bc4
---

# Desktop 起動 progressive 再設計 (2026-06-11 着地)

- **phase 機械**: `tokens_loaded + readReady → ready` 直行。`loading_initial_data` / `connecting_sse` は StartupPhase 型から削除済み。データプリロードは ready をブロックしない
- **warm-up**: `useReadBootstrap` は ready 後 300ms 遅延で `runPostReadyPreload` (dashboard_critical → post_ready_secondary → background の直列 3-stage)。失敗は info トーストのみ、phase 不変。`setStartupPhase` は `useStartupPhaseManager` のみが呼ぶ (一元化)
- **ヘルスプローブ**: `resolveHealthProbeInterval` — 初回成功前は 400ms バースト (max 10s) → 2s (60s) → 10s。リカバリ発火は `hadSuccessfulProbe` 条件で初回起動中は誤発火しない
- **起動画面 "Signal Horizon"**: index.html スプラッシュ (インライン CSS/SVG) と `startup/BrandMark` + `startup/StartupBackdrop` が同一ジオメトリでシームレス接続。StartupOverlay は Stage A (〜2.5s ミニマル) / Stage B (2.5s 超 or error/setup で詳細タイムライン) の 2 段。exit 600ms。reduced-motion は globals.css の CSS メディアクエリのみで対応 (JS matchMedia 不使用 = jsdom 安全)
- **フォント**: @fontsource/space-grotesk + jetbrains-mono を main.tsx で import (tailwind config の欠落フォント実体化)
- **残課題**: 実機 Tauri でのフル起動目視確認が未実施。`commands.test.ts` BM-OVERRIDE 40件期待 vs 実体 38件は既存の別 issue (J-REIT 除去起因)
- worklog: `docs/worklogs/20260611-startup-redesign-signal-horizon.md`

## フォローアップ (2026-06-12 着地)

- **BFF ログオン時自動起動**: `\InvestmentDesktop\DesktopBffServeOnLogon` (AtLogOn+120s, retry 3×5min)。starter は `scripts/start_desktop_bff.ps1` (healthy ならスキップ → launcher full 引数委譲)。allowlist 方式で scheduler 監査対象外。**重要知見: `run_hidden_bat.ps1` の `Start-Process -Wait` は PS5.1 で子孫ツリー全体を待つため、常駐プロセスを残すタスクの action に使ってはいけない** (インスタンスが終わらず ExecutionTimeLimit で強制停止される) — 直接 `powershell -WindowStyle Hidden -File` で起動する。契約テスト: `tests/scripts/test_desktop_bff_autostart_contract.py`
- StatusBar に WARMUP チップ (loading=pulse / error=warn+title)。commands.test.ts 40→38 修復で desktop フルスイート完全緑 (2306)
- 既存ドリフト (別 issue): manifest 定義済み・スケジューラ未登録 7 タスク + BusinessModelProbeWeekly の register 未対応 → `register_schedules.ps1` 実行が必要
- worklog: `docs/worklogs/20260612-startup-followups-bff-autostart.md`
