---
name: project-hidden-asset-screener
description: 含み益調整後PBRスクリーナー完成 (2026-07-05)。賃貸等不動産注記TextBlockパース・分割補正・整合ガードの知見
metadata: 
  node_type: memory
  type: project
  originSessionId: e28dbe8e-a3b8-4055-ba08-36a8f9d5e627
---

# 含み益調整後PBRスクリーナー (2026-07-05 完了 + 2026-07-09 表示詳細化, feat/uplift-p2-visibility)

有報の賃貸等不動産注記（簿価/時価）から含み益を抽出し、調整後純資産ベースの実質PBRでスクリーニング。

## 2026-07-09 詳細化アップデート
- `securities_note_extractor.py` 追加: 有価証券関係注記 → asset_class securities_afs（carrying=取得原価/fair=BS計上額/gain=差額, equity_reflected=TRUE）+ securities_htm。3,308社。直近成功率92%
- hidden_asset_facts に breakdown JSONB（カテゴリ別: 賃貸用施設等/遊休土地・株式/債券）+ property_use_tags JSONB（用途キーワード: オフィス/商業施設・店舗/住宅・マンション等）+ equity_reflected 追加（revision 20260707_01 に統合、_02 は廃止）
- 有価証券パーサーの罠: ①年度2表+売却実績表が同一セクションに積層（売却表にも合計行）→ 合計区切りセグメントを後ろから「差額=時価−簿価」自己検証で選別 ②「売却益の合計額」ヘッダの合計誤認 → _TOTAL_RE はアンカー付き ③列順2種（計上額先/取得原価先）→ ヘッダ判別+自己検証でスワップ補正
- テストフィクスチャの罠: `<p>A</p><table>` はタグ除去で先頭セルに連結 → fixture は改行区切り必須（実XBRLには改行がある）
- BFF company/hidden-assets に asset_classes[] 追加、Desktop は要約文+区分別テーブル（区分|簿価|時価|含み益|純資産への反映バッジ）
- CLI: `extract-hidden-asset-notes`（rental+securities）。manifest args 差し替えのみで Windows 再登録不要だった

## 構成
- 抽出: `tools/market_data/financial_unifier/rental_property_note_extractor.py` → `core.hidden_asset_facts`（(doc_id, asset_class) PK）。CLI `extract-rental-property-notes`
- 計算: `mart.vw_hidden_asset_adjusted_valuation`（税効果30%、gross/net両方）+ `mart.vw_policy_holdings_latest`（matview、週次refresh は抽出タスク内）
- ツール: `tools/decision_support/hidden_asset_screener/`（capex_surge テンプレ、--save で ops.screening_runs strategy=HIDDEN_ASSET）
- BFF: `GET /api/v1/screener/hidden-asset`（保存ラン優先、refresh=true でライブ ~10s）+ `GET /api/v1/company/{code}/hidden-assets`
- Desktop: screening「含み資産」モード + 銘柄詳細「含み資産」タブ（実質純資産ブリッジ）
- alembic: `20260707_01_hidden_asset_facts`。週次タスク2本（rental-notes 日曜10:30 / screener 10:45）

## 会計前提（重要）
- その他有価証券（政策保有含む）は純資産に時価反映済み → 加算すると二重計上。純資産未反映の含み益は主に賃貸等不動産
- 政策保有株式明細・土地簿価は可視化専用（調整に不使用）

## 抽出の知見
- 賃貸等不動産の時価に共通タクソノミ構造化 fact は無い → TextBlock パースが正面ルート（`NotesRealEstateForLeaseEtc(Consolidated)FinancialStatementsTextBlock`）
- レイアウト2種: vertical（ラベル行→数値、期末残高/期末時価、複数カテゴリは合算）+ transposed（ヘッダ横持ち、最終データ行=合計）。年度別セクション分割は「最後のクラスタ採用」で対処
- 罠: 損益ナラティブに「賃貸収益」が表より先に出る / ラベルに（注N）付き / 単位が独立セル "(百万円)" / 数値セルに単位直付き "1,234千円" / ―はゼロプレースホルダ / 該当なしは3表現（該当事項・記載を省略・記載すべき重要な）
- 実績: 14,265 docs → ok 7,946 (high 87.7%) / omitted 4,680 / no_item 1,286 / unparsed 353 (4.2%)。1,134社
- context_id は `x1:` prefix 付き（`x1:CurrentYearInstant_Row1Member`）→ LIKE '%CurrentYear%'

## valuation の罠（上流データ債務）
- `mart.vw_daily_valuation` の market_cap は株式数 as_of（期末）ベース → **分割未反映で1/N倍**。対策: 価格正本ビューの `raw_close/close`（shares_as_of_date 時点）= 分割倍率で補正（view 内 split_correction CTE）
- 整合ガード: (mc-based PBR / bps-based PBR) / split_factor が 0.67-1.5 外は除外（野村不HD型の混在stale を検出）
- **検出不能な残債務**: 京王電鉄9008型 = 分割が価格ビュー自体に欠落（raw_close==close のまま、-80%の偽クリフ）。9008 の adjusted PBR は過小。jquants.shares_outstanding_daily に 9008/3231 等が無い + vw_daily_valuation が 2026-05-01 で refresh 停滞も既知
- `vw_screening_custom_base` は点参照でも 70s 級 → 新ビューは vw_daily_valuation (matview) 直基盤に

## BFF エンドポイント追加の登録先（今回実測 8箇所）
routers/<domain>.py → app.py (import + include_router) → endpoint_registry.py EndpointSpec → response_models.py（company/* は WAVE10 tuple に専用契約名必須、broad契約はテスト禁止）→ scripts/decision_api_typed_response_scope.txt → tests の ratchet 3件（wave10 area counts / residual counts / typed_scope 510→512）→ desktop api/market.ts等 + types → openapi typegen

## CI ゲート（manifest 追加時に今回踏んだもの）
tool_tiers parity / scheduler integrity（register_schedules.ps1 マッピング必須、weekly は depends_on の時刻整合に注意→daily依存は外す）/ tool count drift（README×4+CLAUDE.md の数字）/ file size budget（凍結ファイル増加禁止→前例に従い --write-baseline 再生成）/ freshness SLA（financial_unifier 既存source下なら新規行不要）

## Handover
- Windows タスク登録2本（FinancialUnifierRentalPropertyNotesWeekly / HiddenAssetScreenerWeekly）が人間境界（$scheduler-registration）
- 上流修理待ち: vw_daily_valuation refresh 停滞（2026-05-01）・9008系の分割欠落・jquants shares 欠損銘柄
