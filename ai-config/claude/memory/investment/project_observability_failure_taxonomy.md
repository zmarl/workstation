---
name: project-observability-failure-taxonomy
description: 観測できない失敗の4類型（記録より手前で落ちる / 記録機構が壊れている / 記録経路が無い / 記録は正常でも外形が同一）。新しい経路を足すたび4つとも通す
metadata: 
  node_type: memory
  type: reference
  originSessionId: 4536797c-cfe8-41ab-8cb0-896ec79630fc
  modified: 2026-08-31T02:32:51.527Z
---

**観測できない失敗には 4 類型ある**（2026-08-30 に計 11 例を実測）。新しい経路を足すたび、
**4 つとも通す**こと。どれも「外から見ると何も起きていない」ように見えるが、原因も対処も違う。
**A→D の順に発見が難しくなる**。A〜C は記録の欠陥だが、**D は記録が完璧でも残る**。

**類型 A: 記録より手前で落ちる**（失敗の事実が消える）
- otel probe の 1 例外捕捉漏れ / `AttemptLogStore` の attempt 記録前 raise /
  `start_raw_ingest_run()` 前のブロックで 45 日不可視 / 新設 `RecoveryError` が同じ位置で raise
- **対処**: 痕跡を残してから落ちる（記録位置を後ろへ動かす、または raise 直前に `logger.error`）

**類型 B: 記録機構自体が壊れている**（成功しているのに記録だけが失われる）
- `anomaly_calendar` が `start_raw_ingest_run(run_note=...)` と誤った引数名で呼び、
  **DB に触れる前に `TypeError`**。`except Exception:` が例外を捨てるので原因が残らず、
  **ツール本体は毎日 success を報告し続けた**。外からは「このソースは存在しない」としか見えない
- **これが最も紛らわしい**。A（失敗が消える）でも C（記録経路が無い）でもなく、
  **「記録経路が壊れていることを記録できない」**
- **対処**: 握り潰すなら**何を握り潰したかを書く**（`logger.warning("...: {}", exc)`）。
  この 1 行があれば `TypeError: unexpected keyword argument 'run_note'` が毎日出ていた

**類型 C: そもそも記録経路を持たない**（成功も失敗も最初から存在しない）
- `attribution` は毎週 `UndefinedTable` で FAILED し、runlog に `RECOVERY_HINT` まで出しているのに
  誰も見ていない。`raw.ingest_runs` に記録経路が無いため、**ingest_runs 起点の調査には原理的に現れない**
- **大きく失敗していても、記録経路が無ければ視野の外**。静かさは関係ない
- **対処**: 調査の起点を記録テーブルでなく **run_manifest の active タスク**に置く
  （手順: [[project-data-gap-inventory-279-2026-08-30]]）

**類型 D: 記録は完全に正常で、それでも原因が分からない**（外形が同じ事態が複数ある）
- `status=success` / `error_count=0` / `records_out≈0` は、**まったく異なる 3 つの事態の共通の外形**だった:
  **① series id が 404**（`industry_leading_indicators` の DBDI20。対照 `DCOILWTICO`=200 で確定）/
  **② ソースが正式に退役済み**（`global_leading` の korea。`RETIRED_SOURCES` に登録済みで**データ損失ゼロ・修理不要**）/
  **③ 上流が更新を止めた**（e-Stat 鉱工業生産 `0004052181`。表も `cat01` も生きているが
  `updated: 2026-06-03` で time 軸が 202603 打ち止め）
- **A〜C は「記録を直せ」で済むが、D は記録が正常に機能していても分からない。外形での監視には原理的な限界がある**
- **「追いついた」と「進めない」も同じ外形**（`estat_investable` は 69 日間 61ms で success / 0 行。
  カタログが 12,453 行あるのに固定 top-120 スライスの末尾でカーソルが自己永続化していた）
- **対処**: 外形（status / 件数）で分類しようとせず、**上流に何が存在するかを対照付きで直接問う**
  （生きている別 id を同時に叩けば、API 障害と id の死を同時に切り分けられる）。
  **「成功の記録は、成功したことすら証明しない」**
- **付随**: 上流が止まっているとき、**SLA はどれだけ直しても満たせない**（IIP は完全修理後も
  age≈182 日 vs `max_staleness_days=60`）。**満たせない SLA は SLA 側か指標の出所側の問題**で、
  パイプラインの修理項目に混ぜない（ODR-0019 と同型）

**類型 D の裏面: 緑のテストは、テスト対象が現実であることを証明しない**（2026-08-31）
- e-Stat 週次 full crawl は 7 週間 failed だったが、**テストは通り続けていた**。
  `test_ingest_response_integrity.py` / `test_metadata_discovery_integrity.py` の擬似応答が
  **`getStatsList` に `RESULT_INF.TOTAL_NUMBER` を置いていた——実 API に存在しない形**。
  総件数は `DATALIST_INF.NUMBER` にあり、`getStatsData` にだけ `TOTAL_NUMBER` がある。
  **擬似応答が現実と違うので、この誤読はテストでは原理的に検出できない**
- **gate が落ちたときの分岐が要点**: 「テストを変更に合わせる」と「テストが誤りと判断する」の間で、
  **実 API を実測済みだったから後者を選べた**。実測が無ければ契約を緩める方向に倒れていた
- **対処**: 外部 API を読む経路の擬似応答は、**一度は実応答を取って形を突き合わせる**。
  テストが緑であることは、ここでは何の保証にもならない

**検出の道具**（2026-08-30 実測、いずれも AST 走査）:
- 類型 B: **ヘルパーの実シグネチャ外のキーワードを渡す呼び出し**を全数検査。
  `run_note=` の綴りは 33 ファイルに出るが、**呼び出し単位で見ると誤用は 1 箇所だけ**だった。
  grep のファイル単位一致では判定できない
- **テスト側の共犯**: 素の `MagicMock` は**任意のキーワードを受け付ける**ので、
  引数名の誤りを原理的に検出できない。`@patch(..., autospec=True)` にすると実シグネチャで束縛される
- 「`Exception` を捕まえ・ログを出し・例外変数を一度も参照せず・再 raise もしない」ハンドラの件数。
  **当初 241 件と報告したが、この数字は使わないこと**——`logger.exception(...)` と
  `logger.opt(exception=True).warning(...)` は**変数を名前で参照しなくても traceback を出す**ので
  握り潰しではない。判定を修正して測り直すと **素朴判定 373 / うち traceback あり 212（57%）/ 残り 161**。
  さらに `anomaly_calendar:228` のように**現在到達不能**な箇所も含まれるため、161 もなお上振れ。
  **「規約化が要るほど違反がある」の根拠には、形の数ではなく発火して実害が出る数が要る**が、
  それを機械的に測る方法は無い（この限界ごと報告すること）
- 既存 ruff では正確に強制できない: **`BLE001` 1,346 件**は多すぎ、
  **`TRY400` 67 件は `.warning` を捕まえない**（`anomaly_calendar` はまさに `.warning`）

**さらに悪い変奏（数値が生き残って意味だけ変わる）**: `decision_quality_scorer` は
4 コンポーネント中 1 本だけ失敗すると `None` になり、**composite が残り 3 本の平均として保存される**。
`detail.components` は 4 本を列挙したままなので、**分母が黙って変わる**。
失敗が消えるより、**失敗が「正しそうな数値」に化ける**方が発見が遅れる。

関連: [[project-weekly-audit-otel-silent-stop-2026-08-30]] / [[project-data-gap-inventory-279-2026-08-30]]
