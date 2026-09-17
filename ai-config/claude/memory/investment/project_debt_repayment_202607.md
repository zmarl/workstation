---
name: project-debt-repayment-202607
description: "負債返済バッチ着地 (2026-07-03)。ゲート4本再着地 + デッドコード14,500行削除 + T20 grandfather 1,202件完全返済。並行セッション協調の知見あり"
metadata: 
  node_type: memory
  type: project
  originSessionId: 438515cb-6871-48b1-90c4-b06e81772123
---

# 負債返済バッチ (2026-07-03 完了、branch feat/reform-phases-batch、コミット14本)

プラン: `proud-kindling-yeti.md`。closeout worklog: `docs/worklogs/20260703-debt-repayment-closeout.md`。[[project-reform-program-202607]] と同日並行稼働（衝突ゼロで共存、分担は当該 memory 参照）。

## 着地内容
- **ゲート4本を現行 tree に再着地**（guardrails ブランチはユーザー決定で破棄・参照のみ）: check_file_size_budget (800行/205凍結) / check_tools_dependency_policy (64凍結) / check_t20_ratchet (新規) / check_desktop_api_client_usage (新規)。scripts/ci/run_check_suite.py (44 checks) + framework-docs-quality-extended.yml 3ジョブ分割 (parity マーカーは verbatim コメント方式) + ci-test-lint に高速4ゲート配線。knip 導入 (desktop、`npm run lint:dead`、report-only)
- **T20 grandfather 完全返済**: per-file-ignores 28→恒久2エントリ、baseline 空。~200 main.py で print→print_json/logger/明示noqa。check スクリプト系は file-level `# ruff: noqa: T201` が house style
- **デッドコード削除 ~14,500行**: 未参照 check 7本+テスト7本 / 死んだ.bat 15本 / api-client 59メソッド+孤児型27 (486→427メソッド、unused baseline 0) / knip 完全孤児79ファイル (11,282行、旧業種パネル20・pipeline サブシステム・死んだ pages) / pixelmatch/pngjs devDeps
- 検証: 全フェーズで Phase 0 ベースライン比「新規失敗ゼロ」維持 (pytest 既存失敗3件 + extended スイート既存6件は継続、いずれも本バッチ以前から)

## 重要な知見
- **T20 変換の決め手は capsys**: `capsys.readouterr().out` をアサートするテストがあるツールの print は logger 化厳禁 (stdout→stderr でテスト即死)。市場データバッチで6件回帰→pytest が検出→修正。変換前に capsys grep が必須工程
- **print_json は default= 引数なし**: to_jsonable が date/Decimal 吸収するが custom serializer 付き json.dumps は等価変換不可 → noqa 維持が正
- **api-client 未使用検出は `\bapi\s*\.\s*name\b`**: 複数行メソッドチェーン (`api\n .method()`) を同一行 regex は見落とす (偽陽性2件発生→修正済み)。knip はオブジェクトリテラルのプロパティ未使用を検出できないためカスタム checker 必須
- **並行セッション協調**: 同一 working tree で他セッション稼働中は (1) 新規ファイル追加と自分専用ファイル編集に限定 (2) baseline 生成は編集静止後 (3) コミットは明示的パス指定 stage (git add -A 禁止) (4) 分担を reform-program memory に記録。今回この方式で巻き込みゼロ
- **pngjs 削除で @types/node が消える**: desktop は @types/node を推移的依存に頼っていた → 明示宣言で解決

## Follow-up 完了 (2026-07-04)
- **manifest 健全性レビュー着地**: 乖離61件を全分類 — 27件は登録済み親 pack が module 内で内包実行 (market_context_pack 6 / law_tracker daily-pack 5 / screening_routine 4 等、証拠は各 main.py)、21件は意図的手動、真のドリフト10件。fold 済み3タスク (earnings-schedule-prefetch / news-detector-stale-check / db-ingest-freshness) を manual_only 化、run_revision_predictor.bat 削除で整合性バグ解消、tool_tiers 既存ドリフト5件修正
- **市場指標8タスク+DbConnectivityWatchdog15m を登録** (ユーザー承認): .bat 8本新設 + register_schedules.ps1 + expected 正本 104→113。scheduler_integrity は依存タイミングも静的検査する (theme-narrative は 20:00 の disclosure-search-index 依存で 20:35 に配置)。expected_task_ids.txt は manifest の meta.scheduler_audit.expected_task_ids と完全一致 (順序含む) が要求される
- **knip export 返済**: duplicate 92→0 / unused exports 227→2 / unused types 637→47 (残は全て誤検知 or 意図保持)。純減 ~1,650行。knip は `import("./types/x").Type` インライン型参照とバレル再エクスポート消費を追跡できない (誤検知源)。`--fix` は過剰除去するので tsc を正解に復元する手順が必須
- `.worktrees/wave-l-port` 47MB 削除済み

## 申し送り (残)
- ~~スケジューラ実機登録~~ **完了 (2026-07-04)**: 9件 + 並行セッション由来の未登録5件 (DqiMonthlyScoring / ImprovementProposal×2 / IngestFailureBridge / NotificationDigestDispatch) = 計14タスク登録。runtime 込み integrity check で **strict_failure=0 (三者一致)**。**注意: Git Bash から `schtasks /query` は MSYS パス変換 (`/query`→`C:/Program Files/Git/query`) で必ず壊れる → PowerShell `Get-ScheduledTask` を使う**
- edinet-cleanup-stale-runs (低優先ドリフト): どの live タスクも実行せず stale run が残存。edinet 日次に畳むか単独登録
- knip 残 47 types を本気でゼロ化するなら api-client のインライン import 型→named import 化が必要 (大規模改修)
- extended スイート既存6失敗 (internal_boundary / p5_llm / tdnet_strict / tool_tiers→解消済みの可能性 / backlog_drift / kpi_audit)
