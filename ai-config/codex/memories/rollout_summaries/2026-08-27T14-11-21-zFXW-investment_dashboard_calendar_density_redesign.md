thread_id: 01a0438f-a005-7a90-81a4-881da0cd1970
updated_at: 2026-08-28T07:25:14+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\08\27\rollout-2026-08-27T23-11-21-01a0438f-a005-7a90-81a4-881da0cd1970.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# ダッシュボードとカレンダーを投資判断向けに再設計し、実アプリまで反映した

Rollout context: `D:\Dev\Investment`、PowerShell、Tauri 2 + React 19 + Vite 7 の Desktop Control Tower。ユーザーは、意味の分からない朝会・実行・相場環境表示をダッシュボードから外し、Fear & Greed を見やすくし、当月カレンダーを追加すること、またカレンダーでは銘柄決算を集約し、マクロ指標・FOMC・BOJ・SQなどのリスクイベントを表示することを依頼した。

## Task 1: ダッシュボードの情報整理とレイアウト変更

Outcome: success

Preference signals:

- ユーザーは「意味のわからん項目」「このダッシュボードには不要」「こんなとこ見て株を売買しません」と明確に述べたため、各表示の目的が日々の銘柄選定・相場判断に直結するかを先に確認し、不要な説明やチャートを削る。
- ユーザーは Fear & Greed 自体は参考にするが「表示がちっちゃすぎる」「無駄なことがいっぱい」と述べたため、残す指標は視認性を優先し、補足メタデータを圧縮する。
- ユーザーは重要データ不足を「もっと小さく」、相場環境の変化は「ダッシュボードからには書かないで」と指定したため、欠損警告は主役にせず、不要な相場環境セクションはダッシュボードから外す。
- 実装後は、ユーザーの利用環境を想定して通常幅だけでなく3440px超の横長画面でも確認する方針が記録された。

Key steps:

- `TodayWorkspace`、`Dashboard`、朝会・実行モード、Fear & Greed、需給、既存のカレンダー実装を調査。
- 既存UIプリミティブとトークン、BFF-only境界、過去のDashboard撤回方針を確認。
- ダッシュボードを「主情報を左、補助情報を右」の bounded-density レイアウトへ変更し、カレンダーを主領域、Fear & Greed等を補助領域に配置。
- 3440px画面でサイドバー直後から始まり、右側だけに余白があり、横スクロールがないことを実画面で確認。
- 狭い画面では縦積みになることを維持。

Failures and how to do differently:

- 中央寄せ・全幅展開は横長画面で情報が間延びするため避ける。内容に合う最大幅を設定し、余白を埋めるためだけにカードや表を拡張しない。
- 長いPowerShell引用や複雑なコマンドは実行ハーネスに拒否された。今後はコマンドを短く分割し、必要なら既存helperを対話Python等から起動する。

Reusable knowledge:

- `desktop/src/pages/today/TodayWorkspace.tsx` は `dashboard` / `morning` / `execution` の3モードで、URLは `/`、`/?mode=morning`、`/?mode=execution`。
- DesktopはFastAPI BFF `127.0.0.1:8010`のみを利用し、DB・外部APIへ直接接続しない。
- 関連する既存部品は `desktop/src/pages/today/Dashboard.tsx`、`desktop/src/pages/EventCalendar.tsx`、`desktop/src/components/panels/FearGreedPanel.tsx`、`desktop/src/components/dashboard/MorningContextSection.tsx`。
- UI変更後はコードだけでなく実アプリ、モバイル/デスクトップ幅、横スクロール、アクセシビリティ、主要状態を確認する。

## Task 2: イベントカレンダーの決算集約とリスクイベント確認

Outcome: success

Preference signals:

- ユーザーは銘柄決算が多すぎてマクロ予定を押し出す問題を指摘し、「決算予定は一つにまとめて」「他3件を表示」のような集約を求めた。日別セルでは決算を最大3件表示し、残りを件数ボタンから詳細へ誘導する。
- ユーザーは補足情報や「データ元」「Yahoo! Finance」「SBI参考値」を不要と述べたため、カレンダー表示では銘柄名・日付・重要度・必要最小限の内容を優先し、冗長な出典・メタ情報は圧縮または詳細側へ退避する。
- ユーザーは統計、FOMC、金融政策、SQなど「いろんなリスクイベント」をカレンダーへ含めるよう依頼したため、決算だけでなくマクロ・政策・市場構造イベントを同一カレンダーで扱う。

Key steps:

- `EventCalendar.tsx` とテストを調査。既存実装は約183日先まで取得し、日別セルでイベントを最大3件表示し、超過分を詳細表で表示する構造だった。
- BFFの `tools/api/decision_api/serving/_event_calendar.py` が、公式決算・推定決算・米国主要決算・`mart.vw_market_risk_events` のリスクイベントを統合することを確認。
- `risk_event_tracker` の対象としてCPI、雇用統計、GDP、PCE、FOMC、BOJ、主要PMI、Major SQ、US Triple Witching、MSCI Rebalancing等が定義済みであることを確認。
- DB読み取り専用確認で、FOMC、BOJ、Japan Major SQ、US Triple Witching、PMI、GDP等の予定が実際に登録されていることを確認。
- 日次同期は `risk-event-tracker-sync-daily`、通知カレンダーは `event-calendar-next-business-day` / `event-calendar-next-week` としてmanifestに登録済み。

Reusable knowledge:

- Risk event の保存先は `raw.risk_events_raw`、`core.risk_events`、`ops.risk_event_overrides`、`mart.vw_market_risk_events`。
- リスクイベントの優先順位は manual override → official result → public calendar → anomaly bridge → schedule seed。
- 代表的な確認コマンドは `uv run python -m tools.market_data.risk_event_tracker.main list --lookback-days 0 --lookahead-days 183 --limit 500`。
- フォールバック日付生成は週次・四半期・scheduledイベントに対応し、Major SQは3/6/9/12月の第2金曜、US Triple Witchingは同月の第3金曜として定義されている。

## Task 3: main統合・ローカルアプリ反映・最終確認

Outcome: success

Key steps:

- Ready gate、独立レビュー、PR統合を完了。
- 最新mainをローカルreleaseアプリへ反映して再起動し、タスクバーから開く実アプリで変更を確認。
- `git status` は clean、mainとorigin/mainは同一SHA `b2eece59792ae7d628f37fa3a540061d825865bc`。
- BFF health check `http://127.0.0.1:8010/health` はHTTP `200`。
- 共有DB、Scheduler、正式インストーラー配布には変更を加えていない。
- 待機automation `dashboard-calendar-merge-wait` は存在せず、削除操作は `not_found` だった。

References:

- `desktop/src/pages/today/TodayWorkspace.tsx`
- `desktop/src/pages/today/Dashboard.tsx`
- `desktop/src/pages/EventCalendar.tsx`
- `desktop/src/pages/EventCalendar.test.tsx`
- `tools/api/decision_api/serving/_event_calendar.py`
- `tools/market_data/risk_event_tracker/README.md`
- `tools/market_data/risk_event_tracker/definitions/_fallback.py`
- `tools/notifications/event_calendar_sync/risk_event_source.py`
- `scripts/manifest/market_data.yaml`
- `scripts/manifest/notification.yaml`
- Validation: `git status --short --branch`, `git rev-parse HEAD`, `git rev-parse origin/main`, `curl.exe -s -o NUL -w "%{http_code}" http://127.0.0.1:8010/health`
