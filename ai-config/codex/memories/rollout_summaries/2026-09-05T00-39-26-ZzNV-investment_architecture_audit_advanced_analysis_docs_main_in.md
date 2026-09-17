thread_id: 01a06f01-8924-78c1-88ca-72b1ac9e62eb
updated_at: 2026-09-06T12:26:33+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\09\05\rollout-2026-09-05T09-39-26-01a06f01-8924-78c1-88ca-72b1ac9e62eb.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# Investmentリポジトリの技術診断と高度分析候補の文書化・main統合

Rollout context: `D:\Dev\Investment` を対象に、非エンジニアのオーナーが現行構成・技術スタック・性能・分析深度・保守性について忌憚のない診断を依頼。調査は当初read-onlyで行い、その後ユーザーの「今回まとめたことを文章に全部記録して、計算モジュールやQwenの分析の方につなげてほしい」「メインに統合。」を受け、文書化・引継ぎ・PR統合まで実施した。

## Task 1: リポジトリ全体の技術・アーキテクチャ診断

Outcome: success

Preference signals:
- ユーザーは「いろんな視点」「忌憚のない意見」「非エンジニア向け」を求めたため、技術の新しさだけでなく、アプリとして使えるか、性能、分析の深さ、保守負担、実装・稼働・設計の差を分けて説明するのが望ましい。
- 既存構成の全面置換より「ここを変えればこう改善される」という具体的な改善効果を求めていたため、採用技術の入替え案と局所改善案を比較し、優先順位・理由・未確認事項を明示するのが望ましい。

Key steps:
- `AGENTS.md`、`docs/OWNER_INTENT.md`、`docs/README.md`、設計・アーキテクチャ文書、コード、実行中サービスを照合。
- 現行スタックを確認: Tauri 2 + React 19 + Vite + TanStack、FastAPI、PostgreSQL/Alembic、DuckDB read-only、Polars、PyTorch CUDA、OpenTelemetry、LLM Gateway。
- 実稼働確認: `/health` はHTTP 200、`/api/v1/system/ping` はDB接続・read-ready、PostgreSQL/OTel/LLM gatewayコンテナ稼働、Desktopプロセスは存在せず、Qwen3.8-27B固定runtimeは設定上`local_runtime`でないため停止状態。
- リポジトリ規模を計測: Desktop約39万行、tools約79万行、docs約37万行、テスト約48万行など。大規模化による保守・探索負担を診断材料にした。

Reusable knowledge:
- 製品の基本方針は、単一中核ホスト型のモジュラーモノリスを維持し、マイクロサービス化・BFF分割・新しい常駐基盤の導入を急がないこと。
- DesktopはFastAPI BFF `127.0.0.1:8010`のみを利用し、DB・外部API・LLMへ直接接続しない。LLMはGateway経由、DB書込みはPostgreSQL/Alembicのみ。
- BFFでは同期PostgreSQL処理をイベントループ上で呼ぶ可能性があり、`market.py`等の同期I/Oを棚卸しし、必要箇所を`run_in_threadpool`へ統一するのが局所的な性能改善候補。全面async化は現時点で不要。
- Company Snapshotには最大8並列の集約読取、180秒single-flight、部分失敗表示、section duration計測が既にある。一方DB pool上限10のため、同時に複数銘柄を開くと接続待ちの可能性があり、`first_screen`と後続遅延取得を優先する。
- キャッシュは`raw.ingest_runs`更新で広範囲に全消去されるため、株価・開示・マクロ・企業情報などのタグ別世代へ分割すると無関係な更新による再計算を減らせる。Redis導入は不要。
- GETで期待ギャップ等の計算・保存が起きる経路があり、表示と再計算を分ける方が監査性・再現性・体感速度を改善する。
- OpenAPI/TypeScript生成型は整備済みだが、全518 endpointを一括型検証するより、Company Snapshot・Dashboard・Marketなど重要集約APIから実`response_model`検証を追加する方が現実的。
- DBのstatement timeout既定値は0だが、共有層全体を短縮せず、BFF読取専用接続に短いtimeout/read-only transactionを設定する。
- Desktop基盤は十分妥当で、Electron/Flutter/Next.jsへの移行優先度は低い。最大の候補は起動時にQwen3.8-27Bを常時起動する設計、広い先読み、更新・配布経路である。
- Qwenや新PCを選ぶときは、同じ資料・同じsnapshotで品質、根拠忠実性、反証、速度、GPUメモリを比較し、モデル名やハードウェアを先に決めない。

Failures and how to do differently:
- 複雑なPowerShellのネスト・長大なラッパーはハーネスに拒否された（`Use the harness PowerShell directly so encoded-shell guardrails apply`）。短い直接コマンド、`cmd.exe`、一時スクリプトを使う。
- 過去の文書や古い起動記録だけでアプリ稼働中と判断しない。live `/health`、`system/ping`、実プロセス、実ウィンドウを別々に確認する。
- 設計文書・既存フラグメント・PRのReady合格は、end-to-endのcompiler、Qwen、BFF、Desktop deliveryを意味しない。実装・保存・表示・通常アプリ利用を分離して報告する。

References:
- `D:\Dev\Investment\AGENTS.md`
- `D:\Dev\Investment\docs\OWNER_INTENT.md`
- `D:\Dev\Investment\docs\README.md`
- `tools/api/decision_api/routers/market.py`
- `tools/api/decision_api/read_aggregates.py`
- `tools/api/decision_api/read_cache.py`
- `tools/api/decision_api/routers/company/market_intel.py`
- `shared/db/pool.py`
- `desktop/src-tauri/src/qwen_runtime.rs`
- 実測: `/health` HTTP 200、`/api/v1/system/ping` `db_connectable=true`, `read_ready=true`。

## Task 2: 高度分析候補・計算/Qwen接続文書の作成

Outcome: success

Preference signals:
- ユーザーは「今回まとめたことを文章に全部記録して」「計算モジュールやQwenの分析の方につなげて」と求めたため、候補だけでなく目的、必要データ、方法、限界、既存設計との接続、採用/未採用状態を文書化する。
- 未開示数値を作らず、合理的な仮説は根拠・別解釈・確認条件付きで扱う既存方針を維持する必要がある。

Key steps:
- A01〜A13の高度分析候補を`docs/research/20260906-advanced-analysis-candidates.md`へ保存。
- 計算、統計/PyTorch、初回Qwen、深掘りQwen、後継LLM/GPU研究の責務分担を`docs/research/20260906-advanced-analysis-integration.md`へ整理。
- `docs/README.md`に探索導線を追加し、Research Registryへ`RES-ADVANCED-ANALYSIS-20260906`を登録。
- 初回・深掘り分析の担当文書へ参照を引き継ぎ、A03は既存の実績・黒字化・評価計算を再利用すること、13候補は未採用であることを明記。

Reusable knowledge:
- 推奨接続は「公式資料 → 出典/期間/単位/scope/PIT検証 → 決定論snapshot/compiler → 統計/PyTorch分析またはQwen解釈 → 保存 → BFF → Desktop」。
- 計算結果をQwenに再計算させず、同じ検証済みsnapshotと原文を渡す。開示実績、決定論導出、条件付き試算、統計推定、会社予想、Qwen仮説を識別する。
- 欠損・未開示・競合・比較不能・対象外・計算失敗を理由付きで保持し、0やLLM推測で埋めない。
- Qwenは会社説明、文言差、因果候補、持続性、反証、投資文脈、次に確認することを担当し、数値正本・計算式・品質ゲート・売買判断を変更しない。
- 13候補の採用・依存追加・GPU研究・PC購入・モデル切替は承認されていない。文書化と引継ぎのみが承認範囲。

References:
- `docs/research/20260906-advanced-analysis-candidates.md`
- `docs/research/20260906-advanced-analysis-integration.md`
- `docs/worklogs/20260906-advanced-analysis-documentation.md`
- `docs/research/registry.yaml` entry `RES-ADVANCED-ANALYSIS-20260906`
- `docs/design/financial-performance-compiler-spec.md`
- `docs/design/qwen38-earnings-analysis-spec.md`
- `docs/design/qwen38-earnings-operating-evidence-pipeline.md`

## Task 3: 文書PRのmain統合

Outcome: success

Key steps:
- 5ファイルをcommitし、docs-only Ready gateを実行。最新main追随後の最終head `cf8b08ac2d0ef04f71becc6f5bdf272b3d62c3c0`でschema v4 Ready `passed`、`harness-docs`と`git-diff-check`成功、clean before/after。
- PR #402を作成し、共有監査証拠が一時的に読めず`merge_not_attempted`になったが、読み取り専用診断で218件のattested aggregateと最新`status=passed`, `stop_scope=none`を確認。
- 同じPR・claimで統合を再開し、merge commit `3ac7009b694e0effa66a4ac1e8a7521236a26d71`を確認。
- mainとorigin/mainの一致、42件のローカルリンク欠落なし、作業worktree削除を確認。

Failures and how to do differently:
- publish helperはworklogが`Implementing`のままだと拒否した。公開前にworklog状態を`Verifying`または`Done`へ更新して新しいexact-head Readyを取り直す。
- Ready後にorigin/mainが進み、古い証拠でのfinishは不可。rebase後にbase/headを更新し、Readyを再実行する。
- 共有監査の読み取り不能時は停止を迂回せず、同じPR/claimを保持し、読み取り専用で監査証拠を確認してから`finish-pr`を再開する。

References:
- PR #402: `https://github.com/zmarl/Investment/pull/402`
- merge commit: `3ac7009b694e0effa66a4ac1e8a7521236a26d71`
- final Ready head: `cf8b08ac2d0ef04f71becc6f5bdf272b3d62c3c0`
- local verification: main/origin/main一致、42 links、worktree removed、clean=true。
