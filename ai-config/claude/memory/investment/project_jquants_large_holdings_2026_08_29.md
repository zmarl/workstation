---
name: jquants-large-holdings-2026-08-29
description: "実行順3完了 (PR #275)。大量保有をJ-Quants化しバックフィル完走。audit盲点5例・worktree実測の罠・並行セッション協調の教訓"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4536797c-cfe8-41ab-8cb0-896ec79630fc
  modified: 2026-08-29T22:30:48.579Z
---

2026-08-29〜30、総点検の実行順 3 番（大量保有 J-Quants 置換）。[[architecture-review-2026-08-28]] [[clickhouse-retirement-landing-2026-08-28]]

**着地済み**: PR #279（merge commit `a85a1bf9d`、2026-08-30）。worktree/branch 片付け済み。

## 成果（データは PR マージ前に本番反映済み）

- 取得元を `/v2/edinet/large-volume-shareholders`（Standard 対応、収録 2021-07-01〜）へ置換。壊れた docDescription regex パーサと XBRL enrichment を廃止。
- **実測: 総 67,674 行（旧 14,634 の 4.6 倍）・holding_pct 非 NULL 64,845 行（95.8%、旧 0%）・data_source=jquants 65,354・重要提案あり 1,796 件（2.7%）**。バックフィル processed_dates=1,753 / new_holdings=48,907。
- クライアントは `jquants-api-client` **2.6.0**（EDINET 系 3 API は **2.4.0** で追加。大株主状況・政策保有も同時に使えるので実行順 8 で流用可）。メソッドは `get_edinet_large_volume_shareholders(date_yyyymmdd=...)`。

## API の実データ知見（次に触る人向け）

- レスポンスは**短縮フィールド名**（`DocId/SubDate/TotalShsRatio/TotalShsRatioLast/TotalOutStks/Hldrs[].HldrName/ShsRatio/HldgPurp/ImpProp`）。**割合は 0-1 小数**（テーブルは % 保存なので ×100）。`DocId` は EDINET 書類 ID と同一体系で既存 `doc_id` と直接突合でき、upsert の UPDATE 経路で過去行を修復できる。
- **単独保有者の届出は文書レベル合計が欠落する**（8/27 実測で 29 件中 17 件）。`Hldrs[]` の合算フォールバックが無いと半数超が NULL のまま。
- **`ImpProp`（重要提案行為等）は否定表現が表記ゆれ**（「該当事項なし。」の句点付き、HTML 断片の混入）。単純なブロックリスト一致だと**偽陽性 7,741 件中 5,945 件**。「否定表現の正規化 + 『提案』包含」で 1,796 件（2.7%）に収束。
- バースト連投は**数分で 429**。約 120 日分で RetryError。日次ペーシング（2 秒）+ 429 時 300 秒冷却で 1,753 日を完走。
- 変更報告書も `DocTypeCode=350` で返る（種別は `LargeHldgTypeCode`）。change_type は前回割合との差分から導出する。

## 同時に直したバグ

- `edinet/repository.py`: 割合の書込みが truthiness 判定で、**0%（保有解消）の届出が NULL に落ちていた** → `is not None` 化。exit 検知（E.3・アクティビスト監視）に直結。
- `idx_holdings_holder` の **index 破損**（IndexCorrupted）。`REINDEX TABLE large_holdings` で修復し doc_id 重複 0 を確認。WSL 強制再起動が誘因の可能性。

## audit レーンの盲点（今回の全体停止の構造的原因・5 例で実証）

- **gate は audit マーカーのテストを走らせない**ため、audit だけが落ちる drift が素通りする。今夜だけで 5 例、うち 4 例が PR #248 由来。すべて「実装を変えたのにテスト期待値が未追随」型。
- 非対称の実例: gate の `decision_api_endpoint_contracts` は `--min-typed-scope 393` の**下限判定**なので新 route を足しても通るが、audit 側は**完全性と件数一致**を見る。
- `RUNNER_SAFETY_TEST_PATHS` は中身が集合 pin されるが、**`audit.critical_contract_patterns` との対応は誰も見ていない**。この非対称がオーナー提案（対応付けの整合検査）の核心。
- **`weekly_audit_summary.py:151-158` は failure_reason を最後の非 passed attempt からしか作らない** → 先行レーンの赤が後続の赤にマスクされる。aggregate の failure_reason だけ見ると原因を見誤る（実際 contracts の赤が safe-db の赤に隠れていた）。

## 実測の罠（自分が踏んだもの）

- **worktree での audit レーン実測には `npm ci` と `.env` の両方が要る**。node_modules が無いと desktop 契約テストが **105 件規模で偽陽性**になり、「自分の PR が壊した」と誤認しかける。runner は `sync_runner_dependencies` で npm ci するので runner では起きない。
- **detached runner は `.env` を用意しない**（`proof_pack_queue_dependencies.py` は uv sync + npm ci のみ）。DB マーカー除外が効く限り顕在化しないが、マーカー付与漏れのテストが増えた瞬間に監査を壊しうる**潜在欠陥**。
- **未マージ branch の commit を main の挙動と取り違えた**（`21c2d3cda` の修正が main に入っている前提で反証を組み立て、誤った結論を出した）。並行セッションが多い環境では `git merge-base --is-ancestor <sha> HEAD` と `git branch -r --contains <sha>` で**必ず ancestry を確認**する。
- 正常時の safe-fast は **36,367 passed / 出力 47KB / 約 740 秒**。16 MiB 上限に対し約 350 分の 1 の余裕。この基準値を知っていれば異常膨張の判定が速い。

## 並行セッション協調の実例（うまくいった型）

- 全 PR がマージ不能な 12 時間の全体停止を、2 セッションで**分担 + 相互反証**して解決。相手が真因（otel probe の例外漏れ）、当方が failure_reason マスキングと **db_fresh の赤**を発見（これが無ければ修理後の監査が 1 回落ちていた）。
- **queue の repair_audit は「最新の 1 本」しか受理されない**ため、相手が repair を駆動している間は**自分が enqueue しない**ことが決定的に重要。driver を 1 セッションに一本化する合意が有効だった。
- 自分の誤りは即座に撤回して記録する（反証 2 件を撤回）。相手も記述誤り 2 件を訂正。**相互反証で機構理解が 1 つに収束した**のが最大の成果。
