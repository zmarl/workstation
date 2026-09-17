---
name: core.instruments 旧表記行は同期不全ではなく正当な上場廃止 (resolved)
description: 旧表記+is_active=False 728 件は全件 JPX 公式 list 不在 = 正当な上場廃止と確定 (Phase 1, 2026-05-10)
type: bugs
originSessionId: 8fae7726-72d7-451d-bf0a-4a02c919e15a
---
# core.instruments 旧表記+is_active=False 行 (resolved 2026-05-10)

## 当初の仮説 (Wave D Phase 6 followups)

`core.instruments` で `market` が旧表記 (`東証一部` `東証二部` `マザーズ` `JASDAQ スタンダード` `グロース`) かつ `is_active=False` の行が 713 件残存しており、2022-04-04 の東証市場再編 (一部/二部/マザーズ/JASDAQ → プライム/スタンダード/グロース) を master 同期がキャッチアップできていない疑い。継続上場銘柄が誤って sleeping 化していると想定し、5191 住友理工が代表例とされていた。

## Phase 1 (2026-05-10) 検証結果

JPX 公式 list (data_j.xls、4,449 銘柄) と突合した結果、想定が覆った:

- 旧表記+is_active=False の母集団は **728 件** (内訳: 東証一部 362 / 東証二部 121 / JASDAQ スタンダード 171 / マザーズ 49 / グロース 25)
- そのうち **JPX list に現存する銘柄 = 0 件**。全 728 件が「正当な上場廃止」確定
- **5191 住友理工も JPX list に存在しない** (実際には 2024-2025 に住友電工 TOB で上場廃止済)
- 健全性チェック: core.instruments の active 行 4,455 件 → JPX list hit 4,438 件 (99.6%) で突合ロジック自体は正常稼働

つまり「市場再編 master 同期不全」ではなく、**旧表記が残っているのは「再編より前または再編直後に上場廃止された銘柄」が is_active=False で停止しているだけ**。is_active=False の処理は正しく、修正対象は 0 件。

## 影響範囲 (今後の判断)

- BFF surface 除外 (`outside_current_listed_company_surface`) は **正しい挙動**。修正不要
- Wave D Phase 6 followups Track B で「5191 別 issue」とした寄与は **+0 available** で確定
- 旧表記文字列を `prime/standard/growth` 系に正規化する re-sync ETL は不要

## 残存タスク (別 issue)

- 旧表記文字列が cosmetic に残ること自体は害がないが、可視化 / レポート上の混乱回避目的で「is_active=False 行は market 列を NULL or 'archived:旧表記' に正規化」する案は検討余地あり (低優先)
- `delisted_date` カラムは 2026-04-19 に DROP 済 (`20260419_02_drop_instrument_delisting_date.py`) のため、廃止確定日を core.instruments で記録できない。必要なら別 schema 拡張 (低優先)

## 関連

- @./project_core_instruments_master_resync_phase1.md — Phase 1 finding 詳細・成果物 (JPX ETL scaffold + audit script)
- @./project_business_model_wave_d_phase6_followups.md — 当初の問題提起元
