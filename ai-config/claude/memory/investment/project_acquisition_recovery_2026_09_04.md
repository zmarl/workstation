---
name: project-acquisition-recovery-2026-09-04
description: 2026-09-04 のデータ取得復旧セッション。PR #368 は gate green・未マージ。btree 破損 3 件、監査 global stop の真因、bulk master 上書き P0
metadata:
  type: project
---

# データ取得復旧 (2026-09-04) — PR #368 は gate green・未マージ

Codex の `codex/data-acquisition-recovery` を引き継ぎ、レビュー P0 修正まで完了。**マージだけが repo 全体の監査停止で保留**。

## 状態

- PR #368 head `8abed4bd7`（base `167b2412e`）で gate `overall_status=passed`、全 4 pack passed。
- worktree `D:/Dev/Investment-data-acquisition-recovery`、claim `c5061005b63d2e167ecd210045cac6fc`、branch は更に rebase 済み（PR と乖離。再開時は rebase → gate → publish-pr → finish-pr）。
- `.env` を worktree へコピー済み（EDINET/J-Quants の実行に必須）。

## レビューが見つけた P0（修正済み・実在の危険）

`_BULK_ENDPOINT_TO_TYPED_ENDPOINT` に `/equities/master` があると、**過去月の公式マスター bulk file が現行 `main.stocks` を上書きする**。`save_stocks` の upsert 競合キーは `code` のみで、**`repository.py` の 16 箇所の conflict key のうち日付・期間次元を持たない唯一の例**。2016 年からの pending bulk task が **231 件**実在し、日次 `--max-tasks 1200` の初回で拾われるところだった。対応表から外して解決（`_bulk_endpoints()` も生成を止め、既存は `unsupported` で queue から消える）。
**教訓: bulk/履歴ファイルを typed table へ流す経路を足すときは、保存先の conflict key に時間次元があるかを全件確認する。**

## btree 破損が 1 日に 3 件（systemic の疑い）

同一 DB で 3 件。単発事故として扱わないこと。

1. Codex 修復: EDINET catalog index
2. 本セッション修復: `mart.idx_mart_edinet_latest_cache_concept`（163 MB、`high key invariant violated`）。症状は正規化時の `psycopg.errors.InternalError_: posting list tuple with N items cannot be split at offset M`
3. **未修復**: `core.edinet_concept_catalog_pkey`（35 MB、破損）。症状は `UniqueViolation ... already exists` **on upsert**。壊れた一意 index が重複を素通しし、`ON CONFLICT` が既存行を見つけられず挿入してしまう。**214,950 行 / distinct 214,558 = 392 重複**。うち 219 行は本セッションの正規化 run が、173 行は同日別 run が作った。**catalog seed を通すたびに増える**。修復は「重複 392 行の削除 → REINDEX」の順で、削除は明示承認が要る破壊的操作のため未実施

**特定は `amcheck` の `bt_index_check('<schema>.<index>'::regclass)`**（拡張は導入済み）。index ごとに回して 1 件だけ特定できた。

### REINDEX CONCURRENTLY の実行方法（3 回失敗した）

- `shared.db.pool` の `conn.autocommit = True` は **adapter の属性にしか効かず**、生 connection は transaction のまま → `ActiveSqlTransaction`。`getattr` は True を返すので**嘘の確認になる**
- `psql -c "SET ...; REINDEX ..."` も **1 つの `-c` が単一 transaction** になり同じエラー
- 成功形: `docker exec -e PGOPTIONS="-c lock_timeout=15s -c statement_timeout=90min" investment-postgres psql -U investment -d investment -c "REINDEX INDEX CONCURRENTLY <idx>;"`

## マージ全体停止の真因（別セッター修復中・触らない）

`finish-pr` が `weekly audit state is unreadable (global stop)`。真因は **proof pack queue の v1/v2 レーン不整合**。`merge_attested_aggregates` は `_queue_root_for_lane` で**各レーン自身の root を基準に summary を読む**。full_audit `e7986ad2f85019c5613da1999eaa8d8a`（queue job `cac89e366...`）は request が **v2**、summary は **v1** にしかなく `FileNotFoundError`。

**`weekly_audit_guard.py:743` のとおり state が `unknown` のときは repair_audit の解除経路が無い**（repair は blocked な aggregate に束縛するので、読めない状態には束縛できない）。ODR-0019 の「停止を解除する修復自体を止めない構造」に対する穴。

**bypass しない判断の根拠**: 最新 full_audit が `failed` で、それ以降に passed が 0 件。つまり記帳の不整合だけでなく**実体としても未解決の失敗監査がある**。なお他セッションは同時刻帯に PR #372 #373 を着地させている（helper 以外の経路）。

## base race が 6 回（並行セッションが活発な時間帯）

gate は約 7 分。この日は 10 分間隔で PR が着地し、`base_unchanged=false` で 4 回無効化、1 回は db-focused が **300.085 秒**で per-command 上限 300 秒を 0.1 秒超過（他セッションの gate と CPU 競合）。**混雑時は gate 直後に publish/finish まで一気に通す**。

## 実データで進んだこと

- EDINET 正規化 2026-04-15〜05-07 を実復旧: **477,122 行**書き込み（提出日不一致 0）。`core.edinet_facts_normalized` は 2026-02-21 以降 30,596 行 → **507,718 行**
- XBRL 有りと公示されながら fact 0 件の 6 文書を再取得（計約 6,979 行）
- **対象文書だけの再取得手順**: `EDINETFullIngestService.run_ingest_day(target_date=..., documents=[絞り込んだ listing])` が使える。日次一覧 1 回 + 対象文書だけで、4 日分 23 秒
- 提出日不一致は backfill 範囲で **103 文書**（55 照会日）、**全履歴では 1,264 文書 / 470,444 fact 行**（fact 日 > 文書日が 1,229、逆が 34）

## EDINET raw 復旧の容量ブロッカー（オーナー判断）

対象 12 relation の実測合計 **367.4 GB**、契約の 1.2 倍で **440.8 GB 必要**。`runtime.py:270 _validate_storage_roots` が **backup root を C ドライブ、scratch root を D ドライブに固定**。C: 空き 273 GB で約 168 GB 不足、D: は 2.1 TB 空き。機械全体の容量不足ではなく**ドライブ割り当ての制約**。なお本番 DB は WSL の docker volume にある。
