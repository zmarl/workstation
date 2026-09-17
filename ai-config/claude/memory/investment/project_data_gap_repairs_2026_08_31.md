---
name: project-data-gap-repairs-2026-08-31
description: 2026-08-30/31 のデータ欠損修理 6 件の内容・実測効果・未反映分と、オーナー判断待ち 5 項目
metadata: 
  node_type: memory
  type: project
  originSessionId: 4536797c-cfe8-41ab-8cb0-896ec79630fc
  modified: 2026-08-31T02:33:24.025Z
---

2026-08-30〜31 のデータ欠損修理。**棚卸しの手順は [[project-data-gap-inventory-279-2026-08-30]]、
失敗の類型は [[project-observability-failure-taxonomy]]。ここには成果と残件を書く。**

## 着地済み（5 件）

| 修理 | PR | 実測効果 |
|---|---|---|
| EDINET activation の条件化 | #285 | 財務諸表・業績予想が **2026-07-16 → 08-30**（45 日停止の解消。reports +4,087 / guidance +3,371） |
| `anomaly_calendar` の ingest 記録 | #286 | `raw.ingest_runs` の該当ソースが**全期間 0 行 → 記録開始**。原因は `run_note=`/`records_written=` という**存在しない引数名**（`TypeError` を `except` が捨てていた） |
| `buyback` の集計期間 | #305 | 30 日指定で **0 件 → 1,654 件**。`INTERVAL '%s day'` はプレースホルダが**リテラル内**にあり、窓が引数でなく**序数**になっていた |
| `estat` 日次パックのカーソル | #304 | **62 日間 0 行 → 93 表・529 行**。末尾に到達したカーソルが自己永続化していた |
| `industry_leading` の status | #308 | **97 回すべて success/err=0 → 初めて failed で記録**。`return []` と固定 `"success"` の合わせ技 |
| `estat` 週次 discovery の読み取り位置 | #314 | 7/11 から 8 連敗していた `e-Stat filtered total is missing` を解消。**`getStatsList` は総件数を `DATALIST_INF.NUMBER` に返し、`RESULT_INF.TOTAL_NUMBER` は持たない**（`getStatsData` は持つ）。同じ `_filtered_total_number` が両方に使われ、片方でしか成立しない前提だった |

**未反映**: **PR #299**（cursor 経路の `?` 変換）。gate は全パック passed だが、
weekly audit の **domain 停止（db-fresh / desktop / desktop-release）** に当たって merge できない。

## `repair_audit` を投げるときの 4 条件（2 回空振りして判明）

`tested_head` は **PR の head** にする。**現在の origin/main ではない。**

1. **その exact head に claim 付き worktree が実在する**（`proof_pack_queue.py:676`
   `source claim does not resolve to one exact-head worktree`）。**ここを落とすと
   `runner-create-start` すら出ず 4 秒で失敗する**。ancestry を確認しても意味がない
2. `resolve_stop_state(tested_base=tested_head)` が **blocked=True**（`enqueue_repair_audit` の前提）
3. `request["head_sha"] == request["base_sha"] == tested_head`
   （merge guard が渡す `tested_head` は PR の head。`weekly_audit_guard.py:388`）
4. `request["selection_digest"]` が **gate 証跡の `selection.selection_map_sha256`** と一致

**罠**: gate 証跡には**トップレベルにも `selection_digest` があり、値が違う**。
guard が使うのは `sync_repo.py:690` が取り出す `selection.selection_map_sha256` の方。
**同じ名前で別の値が同じファイルに並存している。** 一度これを誤読して「不一致・失敗確定」と
判断しかけた（実測を取りに行っても、**何を測るかを間違えれば誤る**）。

## オーナー判断待ち（5 件、いずれも着手していない）

1. **e-Stat の週次 full crawl** — 7/11 から 8 回連続 `RuntimeError: e-Stat filtered total is missing`。
   **カタログ順序を更新する唯一の経路**なので、これが直らないと日次パックは古い top-120 を回るだけ。
   **7 月以降のデータが平常時の 0.4%**（月 11 万行 → 7 月 390 行 / 8 月 139 行）なのは主にこれ
2. **e-Stat 日次指標（`estat-ingest-daily`）** — 4 日連続 `exit=65 SUCCESS_MISMATCH`
3. **鉱工業生産指数の参照先** — 固定 ID `0004052181` は生きているが**上流が 202603 で更新停止**
   （`updated: 2026-06-03`）。**取り込めるのは 1 か月分だけで、SLA（`max_staleness_days=60`、
   期限 8/31）はどう直しても満たせない**（完全修理後も age≈182 日）。新表 ID への差し替えは
   **指標定義の変更**なのでオーナー領域
4. **e-Stat 日次パックの取得範囲** — `is_investable AND active_for_daily` は 12,453 行あるが
   日次は上位 120 件のみ。120 は `main.py:190` の CLI 既定を manifest が黙って継承したもので、
   **`estat_full_crawl_max_tables_per_run` を変えても効かない**（実測 0）
5. **`industry_leading` の指標 ID** — `DBDI20` は**存在しない FRED 系列**（対照 `DCOILWTICO`=200 で確定）。
   何を BDI の正本にするかは指標定義の変更

**別途、オーナーが「保留」と回答済み**: `attribution` 2 本への HOLD 適用
（80 本の 08-11 大規模 HOLD からの適用漏れ。毎週 `UndefinedTable` で FAILED 継続）。

## 緑のテストは、テスト対象が現実であることを証明しない

`#314` の gate で既存テスト 5 件が落ちた。原因は**擬似応答が実 API と違っていた**こと——
`test_ingest_response_integrity.py` / `test_metadata_discovery_integrity.py` は
`getStatsList` の応答に **`RESULT_INF.TOTAL_NUMBER` を置いていた**が、その形は実在しない。
**擬似応答が現実と違ったので、この誤読はテストでは原理的に検出できなかった**（7 週間気づかれなかった理由）。

**分岐点は「gate が落ちたときテストを変更に合わせるか、テストを現実に合わせるか」。**
実 API を実測済みだったのでテスト側が誤りと判断できたが、**実測が無ければ契約を緩める方向に倒れていた**。
契約 5 つ（total 変化 / cursor 停滞 / 件数不一致 / 上限超過 / 重複 id）はすべて残し、
**総件数の置き場所だけを実形に合わせた**。

**「規則を緩めず経路を変える」の逆向きの例**でもある（[[project-observability-failure-taxonomy]]）。
今日 3 回は規則の方が正しかったが、**ここでは規則が守っていたのが現実ではなかった**。
**規則が守っているものを探す**という手順は同じで、結論だけが逆になる。

## 並行セッションとの協調で効いた形

**今夜の主要な発見は、ほぼ全部「片方が構造を疑い、もう片方が実測でひっくり返す」形だった。
そして片方だけが正しかった回は 1 度も無い——交互に、対称に間違えている。**
だから「レビューする側/される側」ではなく、**同じ問題に 2 つの独立した観測を当てる**のが効いた。
**授権の読み替えだけは実測で捕まらない**（[[feedback-ask-dont-infer-authorization]]）。
