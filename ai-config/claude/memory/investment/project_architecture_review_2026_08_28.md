---
name: architecture-review-2026-08-28
description: 2026-08-28 設計・構造総点検セッション（調査のみ・編集なし）の実測事実・承認済み方針・オーナー判断待ち 3 件
metadata: 
  node_type: memory
  type: project
  originSessionId: cee7513f-74ae-4293-9650-eb9e82ec8684
  modified: 2026-08-29T19:42:17.977Z
---

8 本のサブエージェント調査（リポジトリ実測 + Web 調査）による総点検。編集は行っていない。

## 実測で確定した事実（2026-08-28 時点）

- **VmmemWSL 19.65GB（物理 96GB の約 20%）の主因は 835GB PostgreSQL のページキャッシュ（約 20GB）**。プロセス本体は 0.65GB。`C:\Users\kazum\.wslconfig` は不在＝既定の物理 50%（46.9GiB）上限。shared_buffers 4GB は compose 既定値で `.env` 上書きなし。
- **バックアップは一切未稼働**: archive_mode=off、WAL spool 空、復旧 5 タスクは manual_only でスケジューラ未登録。仕組み（pgBackRest 相当の自作群 + 復元 drill 検証）は実装済み。
- **DB 835GB の内訳**: raw.estat_values_raw 247GB、EDINET XBRL 系（raw+public+core で重複保持）300GB 超。raw スキーマ計 407GB。object_store は 8GB しかなく「filesystem が durable SoR」の 3 層契約と実態が逆転。
- **Docker ゴミ約 500GB**: 孤児 volume `investment-edinet-rehearsal-...-a002-pgdata` 312.9GB、未使用 OCR/vLLM イメージ約 77GB、build cache 129GB、停止コンテナ残骸。vhdx は 1.38TB。
- **ClickHouse は退役済みなのに稼働中**（833MiB / disk 14.65GB）。`bootstrap_data_platform.ps1` の CoreServices に残存し毎回起動。llm-gateway コンテナは `python -m http.server` のダミー。
- **financial_unifier 49 日停止**、8/17 以降は runlog JSON すら生成されず START 行のみ（監視から消失）。EDINET landing 8 日停止、EDINET 正規化正本は 2/20 で 6 ヶ月凍結。
- **consensus_eps は史上未取得**（IFIS ページに EPS 行が存在せず抽出分岐が一度も発火せず。4 ソース全て非 NULL 0 件）。
- **大量保有 holding_pct はほぼ全 NULL**（regex パーサ 14,554 行が保有者名のみ、XBRL 完全行 21 件）。
- boj_tracker は success 連発だが実データ 7/08 以降 0 行（偽グリーン）。estat_tracker 103 日 partial 常態。「success かつ 0 件」が直近 14 日で 15 ソース。
- logs/runlogs に 87,221 ファイル蓄積、FS 側 GC なし（ls が 120 秒タイムアウト）。
- pandas/numpy が pyproject 未宣言のまま 79 ファイルで直接 import（transitive 頼み）。easyocr/torch/anthropic は import 0 のデッドウェイト。
- compose に DB 資格情報平文直書き。Docker Desktop は設定 AutoStart:false なのに Run キーで自動起動。
- tdnet_disclosure_facts.published_at に 2099-02-08 の将来日付汚染あり（未対処）。

## オーナー承認済みの方針（2026-08-28 の会話）

1. **Docker + PostgreSQL は継続**。その前提で: `.wslconfig` でメモリ上限設定（16〜24GB 目安）／ClickHouse 退役完了（compose + CoreServices から除去）／Docker ゴミ掃除約 500GB（削除実施時は一覧提示→承認）。
2. **J-Quants Standard の新 API へ置き換え**: 大量保有報告書 API（2026/7/13）・大株主/政策保有（7/6）・空売り残高/日々公表信用残（2025 年追加）・決算発表予定日（8/3）。クライアントは ClientV2 使用済みで V2 移行は完了している。
3. **マクロ統計の復旧**: e-Stat 修理 + boj_tracker を日銀公式 API（2026/2/18 新設、stat-search.boj.or.jp の JSON/CSV API）へ切替。マクロは参考表示用（ODR-0012、スコア接続禁止）。
4. **バックアップは保存先確保まで保留**（オーナー明言）。確保後の最初のステップは復元 drill で正しさを実証すること。
5. LLM は別セッションで Qwen 3.8 27B 導入進行中 → こちらから触らない。導入時に「provider=disabled が空文字で成功する」挙動の是正を併せて行うべき。
6. 重複コード・層反転（tools.api を 23 バッチが import、小物関数 600 定義超の散在）は「放置」ではなく段階的に解消する方針（オーナーは凍結運用を好まない）。前提として ODR-0019 G-2（shared/** が publish 不能）の解消が先。
7. 新機能比率 25% は目標ではない（[[feat-ratio-not-owner-target]]）。worktree 整理の徹底（[[worktree-cleanup-discipline]]）。

## オーナー判断の結果（同日・第2ラウンドで確定）

- **D1 → 案A採用**: 「速報=J-Quants、確定・詳細=EDINET」の役割分担として明文化（ODR 起票要）。優先順位そのものへのこだわりはなく、真の要望は「決算短信レベルの速報性ある PL/BS/CF を DB 化し銘柄ページで見られる体制」。網羅性の結論: J-Quants Standard は短信サマリー水準まで（BS/PL 全科目は Premium 限定）、EDINET は年次/半期のみ（四半期報告書は 2024 年廃止）→ **四半期の速報本表は TDnet 短信 XBRL が唯一の無料公式経路。現在は監査用途のみで fact 昇格していない → 昇格を提案し方向了承**。取れない数値（受注高等）は Qwen 3.8 27B の KPI 抽出で補完する構想（オーナー明言）。
- **コンセンサス → 第3ラウンドで「IFIS 継続使用」に確定**: 有料登録・手動は不可のまま。主目的は **PL 項目（売上・営業利益・経常・純利益）のコンセンサス**で、EPS は重要度低（オーナー明言）。IFIS の PL コンセンサスは既に約 5.5 万件取得済みなので、残課題 = ①品質検証（サンプル銘柄を SBI/楽天の表示と突合。系統は同一 IFIS 配信）②取得指標の網羅確認。四季報予想は無料機械可読経路なしで保留。
- **バックアップ保存先 → C: NAS（オーナーがそのうち用意）**。用意され次第、有効化 + 隔離復元 drill で正しさを実証。それまで待機。
- **Monex Scouter → 凍結・消去の方向**（オーナー発言: 重複データが多く DB 肥大要因。データソースは増やしすぎない。優先軸は網羅性と正確性）。ODR-0009 の「代替証明後に縮小」と整合。データ削除は破壊的操作なので実施時に一覧提示 → 明示承認。
- **依存管理はハーネスの穴として恒久対策**: 宣言修正だけでなく「直接 import と宣言の不一致を機械検出する検査」（deptry 相当）を追加する方向。ODR-0018 の追加承認台帳（守る振る舞い・偽陽性予算・見直し日）を経て登録。desktop 側は knip が既設で対称になる。
- キャッシュ問題は**即効（.wslconfig 上限）と根治（raw の Parquet 退避）の両方を採用**。コード整理も段階案どおり採用。

以下は判断待ち当時の詳細（経緯として保持）:

- **D1: 財務ソースの優先順位**。オーナー記憶は「EDINET XBRL 一次・J-Quants 補完」だが、正本文書（ODR-0009）は両者同格・序列未定義、実装は jquants=1 > edinet_xbrl=2 > derived=3 > monex=4（fact_pipeline.py の seed）。KPI 抽出だけは TDnet+EDINET 優先の決定（kpi-extraction-decisions.md）があり記憶の出所はおそらくこれ。どちらに寄せるにせよ ODR 起票が必要。付随修理: mart.vw_financials_unified が source_priority_rules を無視して COALESCE(jquants, edinet_xbrl) をハードコード、financial_unifier README 内の priority 4 表記矛盾（tdnet vs monex）。
- **コンセンサスの去就（3 案）**: (1) QUICK Money World 有料会員 月 980 円（QUICK コンセンサス、CSV DL 可・個人利用。自動化の規約確認が前提）へ正規化 / (2) IFIS スクレイピング継続・範囲縮小+構造変化監視 / (3) 廃止して会社予想（短信 XBRL）+ 四季報予想で代替。**廃止は簡単ではない**: 文書上は T2/T4 補助扱いだが、実装では F.1 スクリーニングスコア（fundamentals.py の consensus_score）と決算跨ぎ crossing_candidate 判定の必須入力＋BFF/Desktop 約 10 箇所＋Discord enrichment に組み込まれており、外すなら F.1 と earnings_carry の再設計が必要。個人向け機械可読の正規経路は QUICK MW がほぼ唯一（Qr1 Personal 月 2 万はエクスポート不可、海外 API は日本株予想なし、証券会社表示は IFIS/QUICK の OEM で機械取得規約不可）。
- **バックアップ保存先**: 候補は Hetzner Storage Box BX21（5TB €10.90/月、SFTP、restic/pgBackRest 対応）／Backblaze B2（$6.95/TB/月、S3 互換）／外付け HDD 8TB 約 3〜4 万円（高騰中）／NAS 一式 13〜15 万円。推奨構成はクラウド 1 本 + 外付け HDD で 3-2-1。ツールは pgBackRest 定番（2026 年のメンテ危機はスポンサー連合で存続確定）。OneDrive/Google Drive は速度・容量で主枠に不適。

## 提案済みだが未着手の改善（優先順）

1. 無音死検知: self-hosted Healthchecks（単一 Docker コンテナ、無料、280 ジョブ可）+ ジョブラッパーから ping。「実行記録ごと消える」financial_unifier 型の問題への標準解。healthchecks.io 無料枠（20 checks）はメタ監視用。
2. raw 層の Parquet 退避（pg_parquet or DuckDB 経由、月次パーティション）→ DB 縮小でキャッシュ・バックアップ・移行自由度が全て改善。3 層契約と方向一致。ただし凍結リスト（dataset 別 storage）に触れる可能性があり ODR 経由。
3. pyproject に pandas/numpy 宣言 + easyocr/torch/anthropic 削除（小 PR）。
4. logs/runlogs の FS 側 GC 導入。
5. スケジューラは移行せず現状+補強（Prefect 3 は将来新規ジョブから任意）。DB クラウド移設は費用（年 $3,000+）とレイテンシで非推奨と結論。

## 実行順（第2ラウンドで整理した着手順。1 タスク = 1 worktree = 1 セッション）

1. WSL メモリ上限設定（repo 外、10 分）+ ClickHouse 退役（compose / bootstrap CoreServices / 文書）
2. Docker ゴミ掃除 約 500GB（削除一覧提示 → 承認 → 実行）
3. 大量保有 J-Quants API 置き換え（壊れた regex/PDF パーサ廃止。P0 解消で効果最大）
4. マクロ復旧（estat 修理 + boj を日銀公式 API へ切替）+ 「success かつ 0 件 N 連続 = 失敗」化
5. financial_unifier 復旧（49 日停止・監視から消失中）+ 無音死検知（self-hosted Healthchecks）
6. 依存整理（pandas/numpy 宣言 + easyocr/torch/anthropic 削除 + deptry 相当の検査を台帳経由で追加）
7. 財務ソース ODR 起票（案A 明文化 + TDnet 短信 XBRL 本表の fact 昇格設計 + mart ハードコード修正 + README 矛盾修正）
8. J-Quants 残りの置き換え（空売り/信用残/決算予定日）+ Scouter 退役
9. raw 層 Parquet 退避（ODR 起票 → 段階実装。根治）
10. コード整理（G-2 解消 → 小物関数集約 → 層反転解消）

コンセンサス課題精査とバックアップ有効化（NAS 待ち）は上記と独立に、オーナーの合図で実施。

## 第3ラウンド決定（同日・追加）

- **依存管理の恒久設計をオーナー了承**: 宣言+バージョン固定は uv（pyproject + uv.lock）が既に担う。欠けていた「宣言せず直接 import を検出する機械検査」（deptry 相当）を PR ゲートへ追加し、以後は「新ライブラリ使用 → 宣言・ロック更新がセットでないとマージ不能」を機械強制。未使用宣言（デッドウェイト）も同検査で検出。ODR-0018 追加承認台帳を経由。
- **TDnet 短信 XBRL 本表の fact 昇格は「確定要求」に格上げ**（オーナー: 「昇格させてもらわないと困る」）。J-Quants Standard で取れない四半期 PL/BS/CF 全科目がアプリで扱えない現状は明確な問題との認識。
- **派生値は維持 + 「出せていないものを確実に出す」**を financial_unifier 復旧タスクの受入条件に含める。
- **Scouter 退役は確定**（「もういらない」）。
- **Qwen 3.8 27B の KPI 抽出（受注高・決算説明資料の KPI 等）を正式に DB 採用する方針**（オーナー明言）。ただし AGENTS.md の変更禁止契約「LLM 出力を検証なしに判断・DB へ入れない」に触れるため、**検証付き採用**の設計で両立させる: ①出典紐付け（文書・ページ・引用）②数値妥当性検証（単位・範囲・整合）③来歴列（LLM 抽出と識別可能）④公式値（XBRL/API）と同一項目が出たら公式が必ず勝つ（priority 下位）。この境界改定は ODR 起票必須。**第4ラウンド決定: 検証付き採用の方針自体は採用。ただし今回は記録のみで実装しない**。背景: もともと LLM の精度が信用できず DB 登録を避けていたが、現在別セッションで導入中の Qwen 3.8 27B なら任せられそうとの判断。導入完了後に採用モデル・構成・精度の実状を確認してから改めて着手する。実行順 7 番の ODR は役割分担明文化 + 短信 XBRL 昇格を主体とし、Qwen 境界改定は導入確認後に追記・起票する。
- **レーティング取得経路の再設計を課題に追加**: 現状は個人サイト grail-legends.com 単独依存。IFIS 株予報にはレーティング・目標株価コンセンサスも掲載されており、既存 IFIS 収集への統合で個人サイト依存を解消するのが第一候補。課題精査セッションで掲載内容を確認して設計。
- **バックアップは今回の作業から除外**（オーナーが NAS を用意した時点で有効化+復元 drill を割り込み実施）。

## セッション終了時点の状態（2026-08-28）

- 方向性はすべて確定。オーナーは着手準備に入り、コンテキスト都合でセッションを切って再開する意向。
- **実行順 1 番は完全完了（PR #260、2026-08-28〜29）**: ClickHouse 退役着地・コンテナ停止（volume `infra_clickhouse_data` はタスク 2 で承認削除）・**.wslconfig 20GB 上限は 08-29 に wsl --shutdown 実施で反映済み**（MemTotal 20GB 実測確認、従来既定 47GB）。着地の経緯と gate 修理は [[clickhouse-retirement-landing-2026-08-28]]。
- **実行順 2 番も完了（2026-08-29）**: Docker ゴミ掃除で約 692GB 回収（rehearsal volume 312.9GB / build cache 128.8GB / 匿名 volume 93 本 / dangling 30 本 / ClickHouse 残 14.8GB / MinIO 一式 / **B 群の OCR 55.2GB + PaddleOCR vLLM 22GB もオーナー承認で削除**）。Docker 全体 1.59TB→902GB、残 volume は本番 DB のみ。**未実施: ホスト側 vhdx（1.38TB）の物理圧縮**（wsl --shutdown + 管理者 diskpart compact が必要。オーナー希望時のみ）。
- **実行順 3 番も完了（PR #275、2026-08-29/30）**: 大量保有を J-Quants 化。データは 67,674 行・割合入り 95.8%（着手前 0%）で本番反映済み。詳細と罠は [[jquants-large-holdings-2026-08-29]]。
- **次の入口: 実行順 4 番（マクロ復旧＝estat 修理 + boj を日銀公式 API へ切替、および「success かつ 0 件 N 連続 = 失敗」化）**。その後 5 番 financial_unifier 復旧（49 日停止）+ 無音死検知。1 タスク = 1 worktree = 1 worklog。マージ後の worktree/branch 後片付けまでを完了条件に含める（[[worktree-cleanup-discipline]]）。
- **オーナーからの包括指示（2026-08-29）**: 「大量保有以外の業績データなども、欠損や過去データ未取得があれば取得体制を整えて取得しておいてほしい。許可は全て与えるので勝手にやってよい」。破壊的操作・実通知・Scheduler 実登録の人手境界は維持したまま、データ欠損の棚卸しと解消を自律的に進める。
- 保留中のトリガー: ①NAS 用意 → バックアップ有効化+復元 drill を最優先割り込み ②Qwen 3.8 27B 導入完了 → 状況確認の上で KPI 抽出の検証付き DB 採用に着手 ③コンセンサス品質検証+レーティング経路再設計は課題精査セッションで。
