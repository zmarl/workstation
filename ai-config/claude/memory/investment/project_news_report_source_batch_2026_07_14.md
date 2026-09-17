---
name: project-news-report-source-batch-2026-07-14
description: Bloomberg廃止+ニュース保存基準強化+PR TIMESフィルタ+レポートソース監査バッチ (2026-07-14) の実装内容と運用知見
metadata: 
  node_type: memory
  type: project
  originSessionId: 7bc73776-66f9-4622-be75-0aac9a5ff5e3
---

# ニュース/レポート取得改善バッチ (2026-07-14, feat/hidden-asset-screener, 未コミット)

## 実装内容
- **Bloomberg 廃止**: news_detector から bloomberg_rss ソース削除（有料化）。`_helpers.py` の bloomberg 分岐も削除。読み取り側（serving/_utilities・_decision・news_intelligence の優先度マップ、desktop News タブ）は既存行の表示互換のため**意図的に残す**。
- **保存基準強化**: T1全件保存を廃止 → `_FULL_SAVE_SOURCE_NAMES={jpx_news_rss, boj_rss}` のみ全件。他は `scorer.is_directly_investment_relevant()`（macro カテゴリ単独 OR 銘柄マッチ+score>=0.4 の2経路。マクロは+0.2しか付かないので単純ANDでは全滅する）。`NewsItem.matched_categories`（メモリ内専用）で score_item の全ヒットカテゴリを記録。
- **PR TIMES**: `_filter_prtimes_investment_relevant` = 銘柄マッチ → 投資必須語（~48語）→ 販促除外語（~30語、拒否権）の3段。**フィルタ通過分（matched_codes あり）は保存ゲートで無条件資格**（scorer 辞書に無い「新工場」等でスコア0.2止まりでも落とさないため）。実測: 200件中 178 unlisted + 20 no-keyword drop。
- **localization gate**: Reuters 専用化。監視1本になったため取引日の沈黙は warn を経ず即 fail。
- **レポート監査 (Part B)**: `--probe-disabled`（--dry-run 必須ガード）新設。DISABLED_IDS 19→14（復活5: 大和AM/三菱総研(browser UA)/世銀/NIRA/ピクテ(後3者URL修正+ID再計算)）。新規ソース追加は0件（日銀レビュー/ESRI は汎用抽出で dated link 0、マネクリは日次市況記事）。worklog: docs/worklogs/20260714-report-source-audit.md

## 運用知見（重要）
- **常駐 serve はコード変更後に再起動必要**: NewsDetectorServe は 07:55 起動の12h常駐。`schtasks /End` は成功表示でも uv.exe→python 子プロセスが生き残る。`taskkill` は最高権限タスクのため一般シェルから ACCESS DENIED。watchdog は uv_count=1 なら healthy 扱いで再起動しない → **max-runtime 到達（19:55）の自然ロールオーバーを待つのが最短**（または管理者で kill → watchdog 5分以内に新コード再起動）。
- **stocks.short_name はどのスキーマにも存在しない**: scorer は常に name-only フォールバックで稼働（警告ログ毎回）。銘柄略称マッチは実質無効。449件の初回スコアリングに23分かかる（serve 定常では dedup 後少数なので問題なし）。
- **Reuters (google news site:jp.reuters.com) がほぼ死んでいる**: 30日で11件、7/9以降0件。gate が取引日毎日 fail する見込み → 要観察・クエリ見直し候補。
- 明治安田AM が 6/14 以降 403 硬ブロック化（report collector で failure=1）。

## フォローアップバッチ（同日 第2弾, 実装済み）
- **Reuters 復旧**: 真因は「クエリ死」ではなく **2026-05 の Reuters URL形式変更**（`idJPKBN…` → `<26字slug>-YYYY-MM-DD/`）を `_REUTERS_ARTICLE_ID_RE` が全滅させていたこと（週625→14件の正体）。`_REUTERS_SLUG_RE` 追加+旧regex末尾アンカー化+`q=ロイター` 冗長フィード（`<source url>` でデコード前に他社除外）+JP二重フィルタ撤廃 → ライブ39件全件 jp.reuters.com 当日記事で復活
- **yahoo_finance_jp 廃止**（`__PRELOADED_STATE__` 消滅・全期間0件）。**minkabu bs4化で復活**（Tailwind移行で属性なし正規表現が死んでいた。id="news_list" は現存）
- **略称マッチ強化**: `_derive_short_aliases`（反復除去・曖昧語ブロックリスト・重工業→重工 変換）+ `_COMMON_ALIAS_CATALOG`（三菱UFJ/ユニクロ/東エレク等18社）+ `tests/shared/test_news_company_matching.py` 新規
- **MACRO_KEYWORDS 拡充**: インフレ/関税/利上げ/円安/日経平均等17語追加（Reuters実見出しの市場・政策記事が macro 資格を得られなかったため）
- **日銀レビュー/WP + ESRI 専用抽出**（作業E, boj-esri-parser agent）: `_extract_boj_paper_items`（js-tbl・掲載日が別td・テーブル毎3件キャップ）/ `_extract_esri_bunseki_items`（月精度day=1）。日銀3件が即日 persist。source_id: `www_boj_or_jp_a5d8aecb06` / `www_esri_cao_go_jp_9d685d41e6`

## Handover / 観察項目
- 19:55 の serve ロールオーバー後、bloomberg_rss の新規保存が止まることを確認
- 保存件数大幅減による news-detector-watchdog staleness 誤発報（warn30/critical60分）→ 頻発なら閾値緩和
- localization gate の Reuters 沈黙 fail 頻度 → Reuters クエリ修理 or gate window 拡大の判断
- 復活レポートソース（三菱総研・世銀）が次回発行時に収集されるか数日観察
