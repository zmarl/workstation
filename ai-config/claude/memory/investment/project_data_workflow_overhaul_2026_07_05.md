---
name: project-data-workflow-overhaul-2026-07-05
description: データ取得→表示→分析ワークフロー総点検（2026-07-05）- 価格正本ビュー一斉移行・XBRLテキストブロック抽出・未表示データ表示拡充・決算WS統合の実装記録と重要知見
metadata: 
  node_type: memory
  type: project
  originSessionId: 5a8dca57-9bf7-426a-8e8c-7d533a5254fa
---

# データワークフロー総点検・改善（2026-07-05, feat/functional-uplift-p1）

計画: `C:\Users\kazum\.claude\plans\xbrl-rippling-whisper.md` / worklog: `docs/worklogs/20260705-data-workflow-overhaul.md`

## 実施内容（4 Track）

- **Track 1 数値正確性**: shared/prices.py を価格読み取り正本化（`ADJUSTED_PRICE_RELATION` 定数 + スポット系ヘルパー）。var_calculator（42日→231営業日、insufficient_history フラグ）、幽霊 market.daily_prices 参照2箇所、空 raw.prices_daily 参照（PER 帯復活: 7203=11.06 等）、長窓違反7ツール一斉移行、decision_support 3本に data_quality 採用、consensus_earnings_comparison に comparison_basis（fq=4のみサプライズ/中間は進捗率）
- **Track 2 XBRL 抽出**: alembic 20260706_01 で core.edinet_textblock_sections（事業リスク/MD&A/研究開発/設備投資/配当方針/サステナ等9種、DB→DB 正規化・再DL不要）+ core.extraordinary_report_events（臨報 180/190 分類MVP）+ mart.vw_edinet_concept_labels（linkbase 日本語ラベル17万件 matview）。financial_unifier に normalize-qualitative-textblocks サブコマンド + manifest タスク financial-unifier-textblocks-daily
- **Track 3 表示拡充**: JSF逆日歩（Flow + MarginShortPanel 内）、analytics.*_daily_history×5 の推移チャート、edinetdb テキスト/プロフィール並立パネル、大量保有 XBRL 精密カラム（COALESCE(reporting_ratio_precise, holding_pct)）、buyback source_kinds バッジ、訂正報告書フラグ+フィルタ
- **Track 4 UX**: 決算3ページ（/latest-earnings, /earnings-season, /earnings-cycle-classification）を /earnings ワークスペースに CompatRedirect 統合（サイドバー2枠→1枠）。NextActionStrip（判断記録/仮説ノート/アイデア/アラート、code 引継ぎ）を CompanySnapshot ヘッダ常設

## 重要知見（再利用価値大）

- **BFF 新規 GET エンドポイントの登録先は実質7箇所**: ①router 実装 ②endpoint_registry.py ENDPOINT_SPECS ③app.py READ_TOKEN_PROTECTED_ROUTES frozenset（**両方必要**、片方欠けで import 時 RuntimeError）④desktop api-client.ts+types+query-keys ⑤scripts/decision_api_typed_response_scope.txt 列挙 ⑥tests/scripts/test_decision_api_endpoint_contracts.py の件数ラチェット（==500 等の exact 値を +N）⑦ルートに runtime response_model（pydantic）必須（read_object_contract_count==0 制約）。先例: ops_failure_inbox（aa452124）
- **file-size budget は「bulk は新モジュール抽出、数行残差のみ --write-baseline 再固定」**（先例 bd79f83f）。新規エンドポイントは frozen された既存 router に足さず**専用 router ファイル**を作るのが正道
- **desktop api-client に未使用メソッドを足すと scripts/check_desktop_api_client_usage.py が fail**（BFF 先行・UI 後追いの分割コミット不可）
- **価格の履歴 PER 計算は raw_close を使う**（調整済み close だと分割前 EPS と株数基準がずれる）。執行品質比較も生値が正。vwap はビューに無いので public.daily_prices の turnover/NULLIF(volume,0)
- ページ内 useQuery パネルを含むページのテストは、新パネル追加時に page テストへ vi.mock 追記が必要（QueryClient エラーで即死）
- scripts/generate_db_baseline.py の docstring「CREATE SCHEMA」が runtime schema governance の DDL パターンに誤ヒット→文言変更で解消（コメントでも引っかかる）

## Handover（未消化）

- **Windows Task Scheduler 登録**（financial-unifier-textblocks-daily 等）: skill $scheduler-registration、人間境界
- テキストブロック本格バックフィル（現状1銘柄スモーク157行のみ。全銘柄 --since 実行が必要）
- bare daily_prices の COALESCE インライン再実装 17ツール群の ADJUSTED_PRICE_RELATION 寄せ（調整値は等価、優先度低）
- backtester close_t0 look-ahead / survivorship 検証
- EDINET CSV パリティ監査（四半期1回）
- data_quality 次バッチ: sizing_engine, feedback_loop, var_calculator persist
- VaR 保存値の世代断絶（2026-07-05 以降=正本ビュー由来）、daily_screener スコア断絶（close_125d_ago 実値化）
