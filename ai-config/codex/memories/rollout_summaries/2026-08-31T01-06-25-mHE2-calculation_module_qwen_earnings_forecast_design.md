thread_id: 01a0555a-6f05-7a03-a1d6-9cc5d2d1a79e
updated_at: 2026-09-06T10:13:35+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\08\31\rollout-2026-08-31T10-06-25-01a0555a-6f05-7a03-a1d6-9cc5d2d1a79e.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# 計算モジュールの設計方針をQwen決算分析と分離して整理したローアウト

Rollout context: `D:\Dev\Investment`。ユーザーはQwen決算分析の議論を踏まえ、数値計算・営業利益予測を担当する計算モジュールの設計を深掘りしたいと依頼した。初期方針は調査・提案のみで実装しないことだったが、後半では計画文書を整理するdocs-only変更まで進めた。

## Task 1: 計算モジュールの責務・営業利益予測設計

Outcome: partial

Preference signals:

- ユーザーは「ここでは計算モジュールに関しての作業を進めていきたい」「調査をして、どのように進めていくべきか提案してほしい」と依頼し、当初は議論と設計を優先した -> 実装へ進む前に、現状・設計思想・未決事項を整理して提示する。
- ユーザーは「深掘りの内容っていうのは全部記録してね。どういう設計思想か確認できないと後からいけない」と明示した -> 合意事項だけでなく、理由、反例、未実装範囲、将来の再開条件をCurrent設計・決定記録・worklogへ残す。
- ユーザーは、値上げなど個別要因の効果と決算全体評価を分け、「決算はトータルで評価される」と説明した -> 計算・要因寄与・決算全体評価・市場反応を別軸で扱い、単一の総合点や単一原因へ潰さない。
- ユーザーは、良い会社でも高値なら買えず、悪い会社でも期待が低ければ小さな改善が投資機会になり得ると指摘した -> 企業品質、決算変化、市場期待、現在価格での投資妙味を分離する。
- ユーザーは質問を「できるだけ多め」に投げる進め方を好み、詳細な設計選択では基本的に推奨案を採用する傾向を示した -> 技術細部を勝手に固定するのではなく、投資上の意味が変わる論点を多めに提示し、推奨案・デメリット・不具合リスクを添える。
- ユーザーは、Qwen側の議論が固まった後に計算モジュール計画を再議論することを望んだ -> Qwenの定性証拠契約が固まる前に、DB/API/UI/Qwen接続へ拡張しない。

Key steps:

- Matt Pocock Skillsの`codebase-design`、`domain-modeling`、`DEEPENING`を確認し、計算処理を「LLMの補助関数集」ではなく、小さなinterfaceの深いModuleとして捉えた。
- 現行正本とコードを照合し、`FinancialPerformanceCompiler.compile(event_id) -> FinancialPerformanceSnapshot`を後続の決定論計算Module候補として確認した。
- 数値、単位、期間、scope、単独四半期化、YoY/QoQ、margin、sign transition、bridge、guidance履歴、segment/KPI比較、provenanceは決定論処理へ置き、Qwenは会社説明、文言差、因果、持続性、反証、不明点、投資仮説への意味付けだけを担当する方針を整理した。
- 営業利益予測について、実績snapshot、条件付き参照シナリオ、将来実績予測、会社予想開示予測、実際の会社予想を別系列に分離した。
- 公開PLだけでは固定費・変動費を一意に分解できないため、「限界利益率」という表現を避け、`営業利益ランレート感応度`、`局所営業利益感応度`、`条件付き営業利益シナリオ`へ用語を分離した。
- 初回pure compilerは一般事業会社のFY Q1〜Q3を起点に、前年同期売上成長、起点粗利率、販管費率、その他営業損益率を維持する`run_rate_reference_scenario_v1`。Q4→翌Q1、PIT永続化、BFF、Desktop、統計モデル、Qwen接続は未実装と整理した。
- 全率維持ケースは代数的に「予測対象売上 × 起点営業利益率」へ縮約するため、三成分分解は監査と後続シナリオの土台であり、それ自体が予測力を増やすわけではないと記録した。
- 2026-09-04、計算モジュールの現状・Q4→翌Q1課題・CPU-only方針・Qwen確定後の再開手順を`docs/design/operating-profit-forecast-model.md`へ追記し、Docs Indexとworklogも更新した。
- docs metadata、Markdown links、diff check、local Ready gateは通過した。PR #352を作成したが、先行する共有監査の修復待ちとなり、main統合は確認できていない。

Failures and how to do differently:

- PR #352の`finish-pr`は、文書変更の失敗ではなく、先行する全体監査が共有統合機構を停止していたため`WAITING_REPAIR / merge_not_attempted`となった。将来はPRがmerge済みかを必ず再確認し、open PRをmain統合済みと報告しない。
- 初期のdocs metadata検査でREADME/worklogを`--include`するとpath profileを上書きして誤検知した。通常のmetadata scopeで再実行するとPASSしたため、検査対象の指定方法とprofileを確認してから結果を解釈する。
- `sync_repo.py publish-pr`でタイトルをスペース付き引数として渡した際にCLI解析エラーが出た。最終的に`--title=Document-operating-profit-forecast-handoff-plan`形式で成功した。Windows環境ではhelperの引数形式を確認してから実行する。
- Q4を単純に許可すると同一年度の`quarter+1`ロジックが翌年度へ誤接続するため、Q4→翌Q1は年度繰越を扱う専用period resolver、欠落時fail-closed、Q4導出元factの複数ID保持が必要。

Reusable knowledge:

- リポジトリの基本境界: Desktop→FastAPI BFFのみ、LLMはGateway経由、LLM出力を検証なしに数値正本やDBへ入れない。DB変更はAlembicのみ。発注・売買操作は扱わない。
- `financial-performance-compiler-spec.md`は、Q1は報告値、Q2/Q3は同一年度の累計差、Q4は通期−Q3累計で単独四半期化する契約を定義している。Q4導出時はsource fact IDs、式version、scope、unit、cutoffを保持する。
- YoYは前年同四半期、QoQは連続する直前四半期、YTD YoYは累計比較として別fieldにする。赤字・黒字転換では通常成長率を避け、`turnaround`等のsign transitionを使う。
- 粗利のprovenanceは`reported`、`derived_revenue_minus_cost`、`derived_operating_plus_sga`、`unavailable`を分ける。営業利益＋販管費による恒等値は表示には使えても、同じ入力を使うbridgeの独立原因証拠にはしない。
- 欠損、単位・期間・scope・会計profile・source identity不整合、PIT違反は0補完せず、`not_evaluable`、`not_applicable`、`not_comparable`等の理由を返す。
- `operational`と`archival_publication`のknowledge basisを混在させない。後日取得した過去資料を当時の実運用知識として扱わない。
- 将来実績予測は売上、粗利率、販管費、その他営業損益を別成分で予測し、最後に`営業利益 = 粗利 - 販管費 + その他営業損益`で再構成する。会社予想開示予測は別目的変数にする。
- 初期の将来予測はCPU baseline・rolling-origin検証を優先し、QwenがGPUを使用する現行hostで予測学習を並走させない。GPU/PyTorchはCPU baselineを継続的に上回る証拠がある場合だけ将来再検討する。
- Qwen側の最終設計が固まった後に、定性証拠のpromotion条件、Qwen候補をどの数値特徴へ接続するか、ケース集合、snapshot/version管理、Q4期間比較、P10/P50/P90 calibration、表示上の誤認防止を再議論する。

References:

- `D:\Dev\Investment\docs\design\operating-profit-forecast-model.md`
- `D:\Dev\Investment\docs\design\financial-performance-compiler-spec.md`
- `D:\Dev\Investment\docs\decisions\20260831-operating-profit-forecast-model.md`（ODR-0033）
- `D:\Dev\Investment\docs\worklogs\20260831-operating-profit-forecast-foundation.md`
- `D:\Dev\Investment\docs\worklogs\20260904-operating-profit-forecast-plan-handoff.md`（PR #352上、main未統合時点の記録）
- `D:\Dev\Investment\docs\design\qwen38-earnings-operating-evidence-pipeline.md`
- `D:\Dev\Investment\docs\design\qwen38-earnings-profit-structure-analysis.md`
- `D:\Dev\Investment\docs\design\qwen38-financial-quality-and-resilience-analysis.md`
- `D:\Dev\Investment\docs\design\earnings-analysis-language.md`
- Commands/evidence: `uv run python scripts/check_docs_metadata.py` (PASS, 120 files); `uv run python scripts/check_md_links.py --scope docs/design` (PASS); `git diff --check` (PASS); local Ready gate passed for head `98bac4f858157b779448d7a7bb5d85f8e9f287b9`; PR `https://github.com/zmarl/Investment/pull/352` remained OPEN with `mergeCommit:null` when checked on 2026-09-06.
