---
name: project_debt_triage_2026_09_13
description: "技術的負債レポート(09-08)の照合と改善計画(09-13)。オーナー決定7件、Lane A-1 着地(PR #445)、残レーン、罠4件"
metadata: 
  node_type: memory
  type: project
  originSessionId: 8287cc05-bf8f-4121-8fad-f3f1b5c196d0
  modified: 2026-09-14T07:13:23.372Z
---

# 技術的負債レポート照合と改善計画（2026-09-13）

計画正本: `C:\Users\kazum\.claude\plans\d-devtemp-kazum-claude-d-dev-investment-cryptic-clock.md`（Lane A〜E）。

## オーナー決定（2026-09-13、壁打ちで確定）
- 優先軸: 止血 → 気づける化 → 構造。
- **ODR-0039（保有スナップショット）6 問すべて推奨案**: 鮮度窓 5 営業日／時価は J-Quants 終値から導出／口座 `main` 1 つ／`core.position_state_daily` は導出 view に寄せて退役／CSV は触らず手入力+宣言／最初の束は「出口監視・PF リスク・VaR」。**ODR ファイルの Accepted 化（C-0）は未着手**。
- バックアップ: NAS 側のフォルダコピーで取得中（稼働中 DB フォルダのコピー→復元テストが必要、B-4）。
- 到達しない 3 領域（blog/converters/benchmarks）・TradingView・Rust 橋: 今回は触れない／凍結。
- 見送り銘柄追跡: 定義どおり daily-pack（通知あり）に戻す（A-3）。
- DecisionCase: 9/14 期限の読み取り確認と承認パック作成を含める（C-5、未着手）。
- 片付け: PR #410 マージ、古い PR 3 本の処遇提案、worktree 棚卸し、worklog Verifying 183 件の一括整理（一回限りの docs PR）。

## 着地済み
- **PR #451（ODR-0042、merge `f1f18f754`、2026-09-14）**: DecisionCase shadow の有効化を「検証時 head + migration ハッシュ」に拘束し、実行中 HEAD 一致を外した（オーナーが承認パック §3-A の推奨案を選択、凍結中だが製品 ODR として実施）。独立 review で P1 2 件（旧契約テスト残存／判定ごとのログ）を修正。罠: **非同期パック実行中に origin/main が進むと `base_unchanged=false` で全 pack passed でも failed** → rebase して取り直し。
- この PC への反映手順（確認済み）: `desktop/build-tauri.ps1 -release -NoBundle -StageOnly` でステージ → `desktop/launch-with-autobuild.ps1`（引数なし）が起動中アプリへ終了依頼→入替→新版起動まで自動。`-SkipRebuild` だと入替もスキップされる。通常起動先は `desktop/src-tauri/target/release/investment-desktop.exe`（AppData の installed 版は 08-02 で古い）。オーナーは画面操作権限（computer-use）を拒否 → 実画面確認はオーナーに依頼する。
- **PR #452（ODR-0043 段階 1、merge `8aec1a563`、2026-09-14）**: 決算ラベル（Gate 3）レーンを運用から外した。2 タスクを disabled、HOLD 6 タスクを `retired_earnings_label_lane`、台帳 13 件を取りやめ（`blocked`+注記。scanner の許容状態は done/in_progress/todo/blocked のみ）、企業ページの「決算ラベル」タブと品質ボードの「決算品質」カードを削除、`ScoringEarningsQuality.tsx` 削除、ODR-0004 を Superseded。**段階 2（未着手・要確認）**: 最新決算画面（`LatestEarnings.tsx` 1700 行超）とダッシュボード直近決算欄はラベル行に Qwen 分析・承認操作が乗るため、ラベル判定の表示だけ外す設計を提示してから実装。TDNET-KPI 台帳行は PR #411 待ち。Windows Scheduler の 2 タスク登録解除は登録ウィンドウ待ち（`disabled_present_in_scheduler_count=2`）。罠: 停止した task は `scripts/manifest/meta.yaml` の scheduler_audit 期待一覧と `scripts/scheduler_expected_task_ids.txt` からも外す。disable_reason に `: ` を含む文字列は YAML で引用符が要る。
- **PR #446（Lane C-0、merge `5f740c928`）**: ODR-0039 を Accepted に（6 問の回答を一次記録へ逐語）。OWNER_INTENT §6/§7 更新。
- **C-5 承認パック提出済み**: `D:/Dev/Investment/data/runtime/plans/20260913-decision-case-approval-pack.md`（ignored）。本番 DB は `alembic_version=20260904_01`、DecisionCase 12 表は**適用済み・行数 0** → 適用ウィンドウ不要。残りは shadow 有効化: オーナー Ed25519 鍵 pin（現在 `approval_blocked`）／rehearsal packet（未実施）／**operational-apply packet の writer が未実装**／署名付き activation JSON／flag + BFF 再起動。**構造問題: activation は repository HEAD に拘束され main が進むたびに inactive**（`shared/decision_case_shadow_activation.py:301-306`）→ オーナー判断待ち（凍結明けに製品 ODR）。Gate 3 縮小版は並走 1 サイクル後に判断。
- **PR #445（Lane A-1、merge `b80f4398f`）**: thesis_monitor の `detail` 列→実列、thesis 設定名 `thesis_*`（実効しきい値 50%→30%）、pool.py `%` 走査式、screener else 分岐、日米 10Y（`raw.rates_metrics_raw` series_key / `main.rates_daily.jgb_10y_yield`）、JPX 月別 xlsx 発見、`_query_clickhouse` 死経路→503、control_plane_audit DEBUG→WARNING。翌営業日の runlog 確認は未実施。

## レポートの訂正（照合で判明）
- NightlyRegressionPytest は登録済みで毎晩 02:30 に起動、3 時間上限で強制終了（要約未達）。skip-tracker は毎日起動（bat が手書きで `track` だけ、runlog なし）。再取得ワーカーは 20 本がスケジュール実行。Desktop `& unknown` は 0 件。
- earnings-schedule 停止の真因 = JPX が `kessanMM_MMDD.xlsx` の月別ファイル名に変更（08-12 から 404）。

## 罠
- **runlog JSON は UTF-8 BOM 付き** → `encoding='utf-8-sig'` で読む。
- **`tests/tools/market_data/test_long_job_resume_pilots.py` は `.env` 無しの runner で赤になっていた**（09-10 の `_wait_for_database_ready` 追加後、当該テストだけ未パッチ。PR #445 で修正）。queue runner worktree には `.env` が無い。
- **Ready gate を同じ head で再実行すると新しい async job を積む**（証拠の再照合ではない）。`passed` 証拠は async worker が source worktree の `data/runtime/evidence/local_pr_gate/v4/<head>/<run>/result.json`（`runner_kind=async_worker`）へ保管するので、それを `--evidence-path` に使う。
- **finish-pr の worktree 削除が `.venv` 内の uv ハードリンク（`ruff.exe`, `yt-dlp` 等 7 件、nlink 38）で「hardlinked entry」拒否**。`rm -rf` は機械 deny。片付けは deferred のまま（`D:/Dev/Investment-claude-debt-stopgap-a1-66e2eb921e` が残存、登録は解除済み）。凍結明けに `repo_lifecycle_cleanup.py:90` の `allow_regular_file_hardlinks` を worktree cleanup で許す検討。
- worktree セッションから main checkout の ignored path（`data/runtime/plans`）への Write も拒否される → scratchpad に書いて後で渡す。
- claim の worklog 名は `docs/worklogs/<date>-claude-<task>-<sessionhash>.md` 固定（lock reason に記載）。別名で作ると publish-pr で不一致になるので最初からその名前で作る。

## 未着手の次レーン
A-2 Desktop 兆表示、A-3 skip-tracker ラッパー、A-4 reingest note、A-5 PR #410 着地（claim は別 Claude セッション `29e04dd359`）、B-1 夜間回帰の並列化、B-2 scheduler-audit の Discord 要約、B-4 復元テスト、C-1 DDL（`ddl-position-snapshot`）→ C-2 → C-3 → C-4、D-1〜D-3、E（10/7 以降）。
- finish-pr の worktree 削除は 2 回目（PR #446、docs-only）は成功。A-1 で失敗したのは `.venv` に uv hardlink が残ったケース（pytest 実行後）。
