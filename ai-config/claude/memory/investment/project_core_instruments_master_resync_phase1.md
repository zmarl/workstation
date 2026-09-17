---
name: core.instruments 市場再編 master 同期不全 清算 Phase 1 (finding 報告型)
description: 旧表記+is_active=False 728 件は全件正当な上場廃止と確定。JPX ETL scaffold + audit script は次世代用に残置
type: project
originSessionId: 8fae7726-72d7-451d-bf0a-4a02c919e15a
---
# core.instruments 市場再編 master 同期不全 清算 Phase 1 (2026-05-10)

## サマリー

Wave D Phase 6 followups で「市場再編 master 同期不全」と認識していた **728 件 (旧表記+is_active=False)** を JPX 公式 list (4,449 銘柄) と突合した結果、**全件が JPX list 不在 = 正当な上場廃止**と確定。**修正対象は 0 件**。当初仮説 (継続上場 500-650 件混在) は完全に否定された。

5191 住友理工も例外でなく、2024-2025 に住友電工 TOB で上場廃止済。Wave D Phase 6 followups の anchor 復活見込みは **+0** で確定。

Phase 2 / Track C (alembic revision) / Track D (endpoint dry-run test) は **不要** と判断し中止。

## 突合ロジックの健全性

母集団:
| old_market           | 件数 |
|----------------------|------|
| 東証一部             | 362  |
| 東証二部             | 121  |
| JASDAQ スタンダード  | 171  |
| マザーズ             |  49  |
| グロース             |  25  |
| **合計**             | **728** |

健全性: `core.instruments` の active 行 4,455 件を JPX list と突合した結果 hit 4,438 件 (99.6%) → 突合ロジック (4桁 code zero-pad + LEFT JOIN) は正しく動作。data 主導の判定で揺らぎなし。

## 成果物 (次世代に再利用可能)

### Track A: JPX 公式 list 取得 ETL scaffold

`tools/market_data/jpx_listed_companies/` パッケージ新設:
- `client.py` — `JpxListedCompaniesClient` (`fetch_xls()` で data_j.xls 取得、httpx + tenacity retry + UA 詐称)
- `parser.py` — `parse_xls(content, min_row_count=3000)` で DataFrame 化 (列: code, name, market_segment, sector_code_33/sector_name_33/sector_code_17/sector_name_17/scale_code/scale_name)
- `repository.py` — `to_csv(df, path)` で UTF-8 BOM 出力。DB write 関数は未実装 (Phase 1 範囲外)
- `main.py` — CLI `ingest --dry-run --output PATH` のみ
- `constants.py` — `JPX_LISTED_COMPANIES_XLS_URL` / `PRODUCTION_MIN_ROW_COUNT` / `SOURCE_NAME`
- `tests/tools/market_data/jpx_listed_companies/test_parser.py` — parser 4 unit test (列名検証 / zfill / 列欠損 / 件数下限) all green

実 JPX 取得確認: 4,449 行 (Prime 1,574 / Standard 1,577 / Growth 596 / ETF 454 / PRO Market 178 / REIT 63 ほか)。

### Track B: 突合 audit script

`scripts/audit_core_instruments_market_resync.py` — JPX list × core.instruments 突合の汎用 audit。`--xls PATH` でローカル xls 利用、`--json` で stdout JSON サマリ。CSV/JSON 出力先は `tmp/` 配下。
`scripts/sql/core_instruments_market_resync_audit.sql` — 参考 SQL (人間用)。

## 確定した事実 (今後の判断材料)

- **Why:** 旧表記が残っているのは再編前/直後に上場廃止された銘柄が is_active=False で停止しているだけ。market 列の旧表記文字列は cosmetic noise で機能影響なし
- **How to apply:** 以後「core.instruments の旧表記行 = 同期不全」と推測しない。is_active=False 旧表記は正当廃止と扱う。新規 anchor を追加する際も、5191 のような既廃止銘柄を「sleeping pending revival」と誤認しない

## 残存タスク (低優先・別 issue)

1. cosmetic noise: 旧表記文字列を `archived:<旧表記>` などに正規化 (機能影響なし、可視化向上のみ)
2. delisted_date の schema 拡張 (2026-04-19 に DROP 済、廃止確定日が記録不能)
3. JPX 公式 list 月次取り込み (現状 jquants.stocks 依存、将来の再編検知に備え)
   - 配置先: `tools/market_data/jpx_listed_companies/main.py ingest --persist` (Phase 2)
   - run_manifest.yaml: `jpx-listed-companies-monthly` (毎月第1営業日 06:00)

## 関連

- @./bugs_core_instruments_market_reform_stale.md — resolved 化済、finding 反映
- @./project_business_model_wave_d_phase6_followups.md — 当初の問題提起元
- worklog: `docs/worklogs/20260510-core-instruments-market-resync-phase1.md`
