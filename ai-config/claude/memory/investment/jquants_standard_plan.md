---
name: J-Quants Standard Plan Capabilities
description: J-Quantsスタンダードプランで利用可能/不可なエンドポイントと指数コード一覧（2026-08-22 新アカウントで再検証）
type: reference
originSessionId: f1534521-5214-4012-91a0-33c8262a3097
modified: 2026-08-22T00:33:53.120Z
---
## 契約履歴（重要）

- **2026-07-30ごろ旧アカウントの契約が失効**し全エンドポイント 403（"No active subscription found"）。
  jquants/topix/jpx の日次が21日間停止 → 2026-08-22 に**ユーザーが新アカウントで再契約**、
  新キーを .env へ反映して復旧。欠落 7/30〜8/22 は backfill-all-standard で埋め戻し済み
- 2026-08-22 の probe-capabilities（extended）: **17 supported / 4 premium-blocked**（下記の 2026-04 検証と同一集合）。
  `get_mkt_margin_interest_range` は**現在は実データが返る**（raw.jquants_margin_interest_weekly 980万行）
- 日次 daily-budgeted-pack の standard_latest_sync は margin_alert / margin_interest / short_ratio /
  short_sale_report / opt_225 / idx_bars_daily を**元からカバー**しており、キー復旧だけで新データも自動収集になる
- backfill の運用: `prepare-backfill-all-standard` は**window 内の task state を全消しして success も失う**ので
  再取得の全走になる。未取得分だけ再実行するには `jquants.endpoint_backfill_state` の
  status IN ('skipped','unsupported','suspended') を 'pending' へ UPDATE してから
  `resume-backfill-all-standard --max-tasks 30000 --allow-existing-state` が正解（2026-08-22 に 25,645 タスクで実施）
- **Standard の取得可能範囲は直近約10年のローリング窓**。窓より古い日付は 400 Bad Request →
  ツールが unsupported へ自動確定する（2013〜2016-03 分 5,030 タスクは手動で unsupported 化して短絡済み）
- **2026-08-22 完了時の typed カバレッジ**: 指数 2016-04〜(6.9万行) / 信用残週次 2020-01〜(982万行) /
  空売り比率 2017-07〜(22万行) / 信用規制 2016-04〜(222万行) / 日経225オプション 2017-11〜(840万行) /
  投資部門別 2016-04〜(21万行) / 空売り残高報告 2026-01〜(40万行、データ提供自体が新しい)。
  verify: pending 0 / failed 0

## スタンダードプランで利用可能（16エンドポイント）
- get_eq_master, get_eq_earnings_cal, get_17_sectors, get_33_sectors, get_market_segments
- get_eq_bars_daily_range, get_fin_summary_range, get_eq_investor_types
- get_idx_bars_daily_topix, get_idx_bars_daily（コード指定必須）
- get_mkt_calendar, get_mkt_margin_alert_range
- get_mkt_margin_interest_range（200応答だが常時0行）
- get_mkt_short_ratio_range, get_drv_bars_daily_opt_225_range
- get_mkt_short_sale_report_range, get_bulk_list

## Premium限定（403 Forbidden）
- get_fin_details_range, get_mkt_breakdown_range
- get_drv_bars_daily_fut_range, get_drv_bars_daily_opt_range

## 利用可能な指数コード（26個）
0000=TOPIX, 0028=Growth250, 0029=Growth250 Core, 0040=JPX Prime 150,
0041-0060=TOPIX派生指数群, 0070=Mothers(Legacy), 0075=REIT
※ 日経225(0010), JPX400(0020)はデータなし

## TSEMrgnRegCls（規制区分）
1=通常, 2=増担保規制, 3=さらに厳しい規制, 4=厳格規制, 5=最厳格, 101=特別区分

## JPX直接スクレイピングとの関係
JPXスクレイパーは**個別銘柄レベル**のデータ、J-Quantsは**セクター/集計レベル**が多い。
空売り比率・信用残高・投資部門別はそれぞれ粒度や対象市場が異なるため両方必要。

## 2026-09-04 追記（V2・実API probe で再検証）

- **新たに Standard で使える endpoint（未取り込み、第2弾で対応）**: `/fins/earnings-date`（2026-08-03、全プラン）、`/edinet/major-shareholders`・`/edinet/cross-shareholdings`（2026-07-06、Standard+）、`/edinet/large-volume-shareholders`（取り込み済み）。client 2.6.0 は `get_fin_earnings_date` / `get_edinet_major_shareholders` / `get_edinet_cross_shareholdings` を持つ。
- **403 確認済み（Premium）**: `/fins/dividend`, `/equities/bars/daily/am`, `/fins/details`, `/markets/breakdown`, 先物・オプション。`/markets/margin-interest-daily` は存在しない path（09-28 から `/markets/margin-interest` 自体が日次化）。
- 指数コード一覧の正本は https://jpx-jquants.com/ja/spec/idx-bars-daily/indexcodes 。Standard 可で未登録だった 0504/6000/6095/6096/B507 は第1弾で追加。
- 詳細: [[jquants-standard-acquisition-2026-09-04]]
