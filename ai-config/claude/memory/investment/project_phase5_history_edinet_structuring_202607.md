---
name: project-phase5-history-edinet-structuring-202607
description: Phase 5 (2026-07-04) 分析履歴永続化5本 + EDINET構造化（buyback 220/230・大量保有XBRL・訂正報告書130/150/170）の実装知見
metadata: 
  node_type: memory
  type: project
  originSessionId: 8eca7815-00b8-4f60-b28f-29474a402de1
---

Phase 5 実装完了 (2026-07-04, alembic `20260704_02_phase5_history_and_edinet_structuring`)。git commit はしていない。

## 4項目と成果
1. **分析履歴永続化**: `analytics.{market_breadth,sector_rotation_rrg,volatility_regime,options_flow,short_squeeze_warning}_daily_history` 5テーブル + 各 main.py に `--persist` フラグ（`persist.py` モジュール追加）。manifest disabled→tasks 復帰 + registry 5行（T3）。live BFF 経路は無改変。実行検証: volatility/options/short_squeeze は行書込成功、market_breadth/rrg は **`raw.prices_daily` が空**（価格は `public.daily_prices`/`mart.vw_price_daily_corporate_action_adjusted` に約1000万行）のため no-op。
2. **buyback 220/230**: `tools/market_data/buyback_execution_monitor/edinet_sbr_extractor.py`。CLI `extract-sbr`。500件中443パース(89%)、118件を active program にマッチ。`core.buyback_progress.source_kind` 列追加（edinet_sbr>tostnet>cf_estimate 優先）。
3. **大量保有XBRL精密化**: `tools/market_data/edinet/xbrl_holdings.py`。`public.large_holdings` に精密列追加。regex は docDescription に%が無く全滅、XBRL で保有割合/株数/共同保有者/基準日を正確取得。
4. **訂正報告書130/150/170**: `edinet_extractor._ALLOWED_DOC_TYPE_CODES` に追加 + `_DOC_TYPE_PRIORITY` で訂正>原本。

## 重要な技術的発見（非自明）
- **buyback 220/230 は数値 XBRL fact が無い**。全て HTML TextBlock（`AcquisitionsByResolutionOf{Board,Shareholders}MeetingTextBlock`）。表構造: `計`行=当月取得、`累計`行=cumulative、`取得期間 START～END`=resolution。parser はこのアンカーラベルの直後の数値セルを取る。value_raw は正しい UTF-8（端末の文字化けは Git Bash コンソール codepage 由来、DB は正常）。
- **大量保有 XBRL (jplvh_cor)**: 集計値(total)は最大 `HoldingRatioOfShareCertificatesEtc` の context（多くは bare `FilingDateInstant`）、個別保有者は `_jplvhNNNN` サフィックス context。**保有割合は fraction 格納（0.5574 = 55.74%）→ ×100 で percent**。共同保有者 = anchor 以外の distinct `Name`。
- **訂正報告書は文書 period_end が NULL**（全10,661件）だが `parent_doc_id` で原本に紐付く。ただし訂正の **XBRL facts は自身の context に restate 済み period を持つ**ため、fiscal_period はバケット処理で facts 側から導出され、原本と同じ (code, fiscal_period) に入り priority で勝つ。検証: 5388 の 2021Q4/2019Q4 が訂正(submit日一致 S100M0JK/S100IXXC)値で AmendedAnnualSecuritiesReport 化。
- **source_catalog.source_type CHECK**: `api/rss/scrape/manual/derived` のみ（'filing' 不可）。EDINET SBR は 'api'。

## 既知の残課題 / 申し送り
- buyback SBR の `unmatched_no_program` 322/500: program は TDnet 開示由来のみ生成、SBR は進捗充填のみ（設計通り）。
- ToSTNeT 側 `raw.tostnet_transactions.amount` が NULL、同一株数の日次重複行あり（別系統の data quality 課題、SBR とは独立）。
- market_breadth/rrg は raw.prices_daily 空のため persist 空振り。calculator の読取元切替は BFF 無改変制約により見送り（別途要検討）。
- buyback SBR の manifest 登録は未実施（task 上「報告のみ可」）。日次 edinet ingest 後の実行を推奨。
- 既存の無関係失敗3件: case_study_extractor/supply_chain_extractor の sec_code/date バリデーション（Phase 5 対象外）。

関連: [[bugs_manifest_argparse_order]] [[project_functional_uplift_202607]] [[project_edinet_extraction_corruption_fix_2026_06]]
