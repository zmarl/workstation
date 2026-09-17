thread_id: 01a0550d-2465-7032-b120-6af6ed0b8fc9
updated_at: 2026-09-06T12:19:23+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\08\31\rollout-2026-08-31T08-41-59-01a0550d-2465-7032-b120-6af6ed0b8fc9.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# J-Quants・EDINET/XBRL・統計データ基盤を監査し、未完了事項を専用タスクへ引き継いだ

Rollout context: ユーザーは、J-Quants、XBRL、財務・業績、統計・分析データが最新まで正しく取得・反映され、分析基盤として設計・運用できているかを根拠付きで確認し、課題があれば改善計画を求めた。最終的に、実装済み・未完了・横断的な開発基盤課題を分離し、追加実装はせず継続タスクへ引き継いだ。

## Task 1: データ取得・鮮度・運用状態の監査

Outcome: partial

Preference signals:
- ユーザーは「正しく最新までできているのか」「隅々まで確認した上で」と依頼しており、設計の存在ではなく、実DBの最新日、層間反映、運用証跡、一次情報との差分を根拠付きで確認することを重視している。
- 監査では再取得・再実行・共有DB変更を避け、未確認箇所を明示したうえで、影響度と優先順位付きの改善計画へ進める方針が採られた。

Key steps:
- `ops-morning-check` に従い、BFF read-only health、Scheduler integrity、freshness SLA、ingest-runs、runlogs、財務/XBRLの層間状態を確認した。
- BFF health read は `bff_timeout` で取得不能だった。
- Schedulerはmanifest/parityは概ね一致したが、無効化済みタスク2件が残りstrict drift failureとなった。freshness SLAは直近14日で実行された未登録source 8件により失敗した。
- J-Quantsは最新 `jquants` run自体は成功扱いだが、2330 errorsを含み、`jquants-update-daily` と標準backfillには古いERRORが残っていた。
- EDINET/XBRLは最新incrementalが成功扱いでも `edinet_xbrl` に189,760 errors、`financial_unifier` は直近4回中3回失敗していた。
- e-Statでは鉱工業生産指数が2026-02-01で211日遅れ、revisionも140日遅れ。macroにも複数のstale/revision staleがあった。
- 一方、F5 EPS CAGRは3,448/3,448 filled、EDINETの2020-01-01〜2023-02-23 gap auditはXBRL欠損0で、古い一部範囲は良好だった。ただしこれは当時の測定値であり、現在の全体鮮度を保証しない。

Failures and how to do differently:
- 朝の監査では副作用のあるhealth-dashboard runnerを起動せず、`scripts/read_decision_api.py ops-health` を優先する。取得不能はunavailableとして報告する。
- 長大なDB出力は保存せず、source単位の最新status、latest date、records、error数へ集約する。
- Windows runlog JSONにはBOMがあるため `encoding='utf-8-sig'` で読む。複雑なPowerShell引用は避け、単純なjq/Python処理を使う。

Reusable knowledge:
- 主なread-only監査入口は、`uv run python scripts/check_scheduler_integrity.py --json`、`uv run python scripts/check_freshness_sla_coverage.py --json`、`uv run python -m tools.db_admin.status.main ingest-runs --window-hours 168 --json`。
- `f5-upstream-audit` はraw J-Quants/EDINETからfinancial_reports、normalized/resolved層までEPS CAGRの欠損を切り分けられる。

References:
- `D:\Dev\Investment\scripts\read_decision_api.py`（BFF `127.0.0.1:8010` のread-only resource map、timeout 10秒）
- `D:\Dev\Investment\logs\runlogs\*.json`（構造化運用証跡）

## Task 2: J-Quants/EDINET復旧とデータ正本の修正

Outcome: partial

Preference signals:
- ユーザーは「できていないことに関して、情報の取得をちゃんとやるようにしてほしい」と求めており、未完了キューの報告だけで終わらず、公式取得、保存、反映、検証まで進めることを期待している。
- 既存データを直接SQLで書き換えず、公式一次データを再取得し、期間限定・冪等・fail-closedで修復する方針が維持された。

Key steps:
- J-Quants bulkを`(endpoint,file key)`で重複排除し、公式gzip、SHA-256、raw snapshot、typed table反映を行う経路を実装。日次上限は1,200 unique taskへ拡大した。
- `/equities/master`の過去bulkを現行`main.stocks`へcodeだけでupsertすると古い名称・市場・業種で上書きするため、historical masterのtyped persistenceから除外し、日次`get_eq_master`を現行マスタの正本とした。
- EDINET正規化を停止中のraw replayではなく、public producer `disclosure-reingest-pack-daily` のfresh success依存へ変更し、Scheduler順序をpublic producer 20:30→正規化20:35→partner text 20:50へ整理した。
- EDINET 2026-09-03は169文書・30,596 source factsを正規化し、missing/date mismatch/lineage gap 0を確認した。
- 2026-02-21〜02-24の正規化では37,941 facts中357件の提出日不一致を検出し、書き込み0・rollbackで停止した。全履歴では同種の不一致が103文書あり、後日再掲された文書にAPI照会日が保存されていたことが原因だった。
- `full_ingest_service._persist_doc_rows` が文書自身の`submitDateTime`をfact提出日の正本として使うよう修正し、回帰テストを追加した。修正後はEDINET関連47 passed/4 skipped、J-Quants関連68 passed/17 skipped、Ruff pass。
- 2026-04-15〜05-07の安全区間では477,122 normalized rowsを復旧し、XBRL欠損6文書も公式APIから再取得した。ただし全期間復旧、J-Quants backlog完走、PR #368統合は未完了。
- 共有DBでは複数のbtree/index破損が発見された。`core.edinet_concept_catalog`には392件の重複`concept_qname`があり、削除とREINDEXは破壊的変更のため未実施。

Failures and how to do differently:
- EDINET fact日付はAPI検索日を使わず、文書metadataの`submitDateTime`を使う。不一致を無視して正規化を進めず、fail-closedでrollbackする。
- EDINET backfillは全期間一括ではなく短い日付chunkで実行し、各chunkのrecords、coverage、lineage、latest dateを確認する。
- J-Quantsはrouting testだけで完了扱いにせず、全endpointごとに実データの取得、raw保存、typed反映、鮮度を証明する。
- 既存のPR/branchのReady証拠はbase/headが変われば再利用しない。現在mainへのrebase後にfocused tests、独立review、exact-head Ready、PR更新をやり直す。
- 共有DBの重複削除、REINDEX、Scheduler登録、実通知は、対象・影響・rollbackを示して明示承認を得るまで実行しない。

Reusable knowledge:
- EDINET正規化入口: `uv run python -m tools.market_data.disclosure.main edinet-facts-refresh --from-date YYYY-MM-DD --to-date YYYY-MM-DD --rebuild --skip-catalog-seed --format json`
- 層は`raw`原本、public producer、`core.edinet_facts_normalized`、最新版cache、分析snapshotに分け、各層の鮮度・欠損・改訂・lineageを別々に確認する。
- EDINET保護writerはactivation evidenceとleaseが必要であり、安全境界を迂回しない。

References:
- 継続worktree: `D:\Dev\Investment-data-acquisition-recovery`
- branch: `codex/data-acquisition-recovery`
- worklog: `docs/worklogs/20260904-data-acquisition-recovery.md`
- 継続PR: #368 `Resume complete J-Quants and EDINET acquisition`
- 新規継続タスク: `J-Quants・EDINET復旧を引き継ぐ`

## Task 3: 横断的なリファクタリング・開発基盤への引継ぎ

Outcome: success

Preference signals:
- ユーザーは、データ復旧と他のリファクタリング課題を分け、ここでの作業を終了できる形にすることを求めた。今後も既存タスクの所有や差分を壊さず、重複実装なしで引き継ぐのが望ましい。

Key steps:
- 全面リファクタ計画へ、公式取得/raw、文書正本、正規化、最新版cache、分析snapshotの責務分離と、鮮度・欠損・改訂・lineageの契約を引き継いだ。
- 共有開発基盤タスクへ、PR #355/#356のsuperseded判定、ACTIVE worktreeの状態分類、`harness_status --summary`の無期限待ち、DB index全域のread-only健全性監査を引き継いだ。
- `harness_status --summary`は一時的に90秒超無出力だったが、自己所有と確認できたPID chainのみ停止した。後続のPR #401で軽量経路が導入され、2026-09-06 21:18 JSTに約2.17秒・exit 0で現行job一覧を取得できた。原因は未確定のまま、無期限集計を再実装せずbounded/read-only診断へ移行した。

Failures and how to do differently:
- 所有外のprocess、terminal、worktree、lock、PR、共有DBには触れない。停止できるのは自セッション起動でPIDと開始時刻の両方を証明できるprocessだけ。
- 59 worktreeという観測値は実行中process数ではない。ACTIVEは所有・cleanup適格性の状態として扱う。
- 既存index checkはCREATE EXTENSIONや強いleaseを含む可能性があるため、read-only監査としてそのまま流用せず、全index棚卸し→時間制限付き軽量check→隔離復元上の詳細検証の順に進める。

Reusable knowledge:
- PR #400はmainへ統合済みで、共有監査のmain/head誤判定、途中証拠消失、timeout診断の問題を修正した。
- PR #356の静的検査性能問題はmain側のmemoize修正で約48秒PASSになった記録があり、古いPRを盲目的に統合せずsuperseded判定する。
- DB index破損が同日に複数発見されているため、単一テーブル修復ではなくDB全体・保存装置を含む共通原因の調査が必要。

References:
- PR #400: shared audit lifecycle repair（main反映済み）
- PR #401: `harness_status --summary`軽量経路（後続タスクで検証済み）
- worklog: `D:\Dev\Investment-data-acquisition-recovery\docs\worklogs\20260904-data-acquisition-recovery.md`
- 新規データ復旧タスク: thread `01a0769c-ceec-7680-bb05-36c4d92b815b`
