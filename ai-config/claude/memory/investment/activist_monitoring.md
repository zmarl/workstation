---
name: アクティビスト監視機能
description: 2026-04-21 実装完了。アクティビスト 9 社のポートフォリオと保有変動を可視化、TDnet 株主提案も蓄積
type: project
originSessionId: ed968e93-2435-4bb5-a467-83f657c8b012
---
# アクティビスト監視機能（2026-04-21 実装完了）

## 目的
アクティビスト（Elliott・Oasis・Effissimo・Murakami・Strategic Capital・Dalton・ValueAct・Icahn・Third Point）のポートフォリオ（どの銘柄を何%保有しているか）を追跡する。

## データソース（根本診断の結論）
- **EDINET 生 XBRL は揃っている**: `raw.edinet_documents_raw` に 大量保有 350/360 が 66,614 件、`raw.edinet_xbrl_facts_raw` に 130M 件の facts あり。アクティビスト filer は Effissimo 732、Murakami系 360、Strategic Capital 256、Dalton 107、Elliott 8 件。
- **既存 `ownership_collector` が落とす理由**: `raw.edinet_documents_raw.sec_code` は「filer の証券コード」で、アクティビストは非上場のため NULL。既存 extract SQL は `sec_code ~ '^[0-9]{4,5}$'` でフィルタするため 1,463 件のアクティビスト filing が全部スキップされる。
- **正しい target code 抽出源**: XBRL fact `SecurityCodeOfIssuer`（および `HoldingRatioOfShareCertificatesEtc`、`TotalNumberOfStocksEtcHeld`、`TotalNumberOfOutstandingStocksEtc`）
- **shareholding_ratio のスケール**: EDINET XBRL は **0-1 の小数**（0.5315 = 53.15%）。DB も 0-1 で保存。VIEW / API で ×100 して % に変換して UI に返す

## 実装済み
- DB: `analytics.activist_timeline` テーブル + `analytics.vw_activist_holdings_delta` VIEW（alembic `20260421_07`）
- BFF: `/api/v1/stakeholders/{slug}/holdings-delta`、`/activist-events`、`/activist-monitor` の 3 エンドポイント
- TDnet detector: 4 語厳密一致、TDnet 既存開示 6 件を `unresolved` として蓄積済み
- **EDINET activist XBRL 抽出**: `scripts/backfill_activist_positions.py` で `SecurityCodeOfIssuer` から target code を復元しつつ `raw.edinet_ownership_positions` に upsert（2,230 件取込済み）
- Desktop: `ActivistHoldingsDeltaCard` / `ActivistEventsTimeline` / `ActivistMonitorGrid`、タブは `monitor/feed/registry/jpx`

## 現在の保有ポートフォリオ（取込済みサンプル）
- **Effissimo**: 17 銘柄（SOFT99 53%、商船三井 38%、不動テトラ 27%、リコー 24% 等）
- **Strategic Capital**: 11 銘柄（山洋電気 15.9%、テイン 15.4%、宝塚不動産 14.7% 等）
- **Dalton**: 5 銘柄（東京きらぼしFG 14.8%、ツルハHD 12.7% 等）
- **Murakami ファンド**: 6 銘柄（ヨドコウ等）+ 119 件の exit 履歴（頻繁に回転）
- Oasis / ValueAct / Icahn / Third Point は EDINET 直接提出なし（0 件）

## バックフィル手順（運用）
```bash
# 1. EDINET の過去 XBRL からアクティビスト保有を抽出
uv run python scripts/backfill_activist_positions.py

# 2. TDnet 既存開示から株主提案を検出
uv run python scripts/backfill_activist_timeline_from_tdnet.py
```

## Phase 2 アップデート（2026-04-22 完了）
- **重複排除**: `analytics.vw_activist_holdings_delta` を DISTINCT ON で再定義。同一 (instrument_id, holder_name 正規化後, disclosure_date) が 1 行に。alembic `20260421_10` + `20260421_11`（whitespace regex 強化）。view rows 10,219 → 5,535 → Effissimo 5 年分で重複ゼロ
- **holder_name 正規化**: `shared/text_normalize.normalize_holder_name`（NFKC + 連続空白圧縮 + strip）を ingest / extract / backfill 全パスに適用。全角スペースや NBSP が統一
- **ownership_collector 本体修復済**: `extract_ownership_positions_from_xbrl` の SQL を `SecurityCodeOfIssuer` XBRL fact 経由で target code を復元するよう書き換え。sec_code NULL の 90% の filing も取込対象に。2026-04-01〜 で 1,263 件新規取込、Oasis・Silchester・Farallon が初めて補捉された
- **SSE 速報 UI**: `useSSE.ts` が `activist.holdings_update` bus_event を受けて `useAppStore.recentActivistUpdate` を更新。`NewsTicker.tsx` が先頭バナーで「🔔 アクティビスト速報 {日付} {件数}」表示、クリックで監視グリッドへ。TTL 1 時間
- **window_days 拡張**: `holdings-delta` 上限 730 → 1825 日、デフォルト 90 → 365 日。`activist-monitor` は 60 日デフォルト

## Phase 3 アップデート（2026-04-22 完了）
- **PDF 本文による提案者解決**: `activist_detector` を拡張、`tdnet_document_texts` から pymupdf 抽出済の本文を読み、`提案株主 / 株主名 / 株主である...` のパターンで提案者を抽出。6 件中 3 件（6516→strategic-capital、8746→akatsuki-capital、9982→lim-advisors）が自動解決。proposer_name は payload_json に保存し UI から参照可能
- **新規アクティビスト登録**: LIM Advisors（LIM JAPAN EVENT MASTER FUND）、暁キャピタルワークス（Akatsuki Capital Works）、光通信グループ（重田康光・光時／光通信株式会社・株式会社光通信・ヒカリ・ツウシン・インベストメンツ）を `shared/famous_holders.py` に追加
- **光通信バックフィル**: `scripts/backfill_activist_positions.py` に 光通信パターンを追加し再実行。2,230 → 7,085 positions。光通信だけで 365 日内に 新規 45 / 増加 170 / 減少 73 / 撤退 10 の活発な動き。フクビ化学・日本プラテック・アルプス技研等の小型株に 7% 級の保有
- **unresolved 重複解消**: 同じ filing で後から real slug が解決した際に古い unresolved 行が残らないよう、upsert 前に `_PRUNE_UNRESOLVED_SQL` で削除

## 未解決の残課題
- **残 3 件の unresolved**: 6298 / 6142 / 8011 は `tdnet_document_texts` に本文抽出なし。PDF 再抽出ジョブが必要（別途）
- **Oasis / ValueAct / Icahn / Third Point の TDnet 補捉**: ValueAct/Icahn は TDnet 本文にもほぼ出現せず、日本市場での書簡提出が稀。現時点では EDINET（Oasis のみ）経由のみ
- **既存 raw データの物理正規化**: VIEW で吸収しているが、raw 行自体は不整合のまま
