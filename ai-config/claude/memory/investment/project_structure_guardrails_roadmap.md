---
name: project-structure-guardrails-roadmap
description: リポジトリ構造改善 6 フェーズロードマップと Phase 1 (ガードレール敷設) 完了状態
metadata: 
  node_type: memory
  type: project
  originSessionId: 18551a3f-2106-499a-8dbe-0fea55a67ead
---

# 構造改善ロードマップ (2026-06-11 策定、プラン: vectorized-petting-puddle.md)

**⚠️ 2026-07-03 更新: feat/structure-guardrails-phase1 ブランチはユーザー決定で破棄**（現行コードと乖離しすぎて再マージ不能）。P1 のゲート類は [[project-debt-repayment-202607]] が現行 tree にゼロから再着地済み（+T20 ラチェット / api-client usage ゲート新設、T20 grandfather 完全返済、P6 相当の負債返済完了）。P2 (shared/ 再編) と P3 (BFF 分割) の成果はブランチごと放棄 — 再実施する場合は [[project-reform-program-202607]] の管轄。以下の P1-P3 記述は歴史記録。

方針: 「ゲート先行 → リファクタ」。段階的・互換維持（各フェーズ後 ruff+pytest+vitest 全緑）。シムは Tier 1 恒久ファサード（db_contracts 方式、database/logger/config 等の最多被参照）と Tier 2 廃止予定シム（shared/cli.py 方式、DeprecationWarning + re-export、Phase 6 でゼロ化）の 2 層。

- **P1 完了 (2026-06-12, commit 29b07af2, branch feat/structure-guardrails-phase1, worktree D:/Dev/Investment-guardrails-p1)**: 越境 import ラチェット（check_tools_dependency_policy.py、baseline 64 件縮小専用）+ shared/ 平置き凍結（check_shared_layout.py、allowlist 49）+ 低リスク 15 モジュールを shared/text/・shared/domain/ へシム移動 + run_check_suite.py（42 check、timing 可視化）で extended CI を 3 ジョブ並列化 + ci-test-lint.yml に新ゲート 2 本配線
- **P2 完了 (2026-06-12, commit a4b13529, 152 files)**: shared/ 全 49 本移動完遂（Tier 1 ファサード 5 + Tier 2 シム 44、**sys.modules エイリアス方式** — plain re-export は conftest の _get_pool setattr / reload / 属性パッチ 40+ 箇所が壊れるため不採用）。pytest 既存失敗 31 件全修復（serving gate 23 = .env の SERVING_READ_MODE 漏れ→ tests/tools/api/conftest.py autouse fixture で `_auth.settings` を直接パッチ。get_settings() パッチでは config reload テスト後に効かない）。baseline 64→46（improvement_backlog→shared/ops、jp_holidays→shared/domain）。T20 を glob 11→明示 147 に ratchet 化。check_*.py 67 本監査（完全未参照 3 本、docs/worklogs/20260612-check-scripts-audit.md）。pytest CI 同条件 **10,790 passed / 0 failed** 達成。extended suite の既存失敗 7 件（p5/p6/internal_boundary/tdnet_strict/tool_tiers/backlog_drift/kpi_audit）は HEAD 再現で既存と確定 — 本体未コミット作業が一部修正を保持
- **P3 完了 (2026-06-19, commit df0459c7, 66 files)**: BFF 巨大5ファイル(25,170行)をドメインパッケージ分割。repository.py→repository/(8) / serving/_decision.py→serving/decision/(13) / serving/_market.py→serving/market/(13) / serving_repository_extensions.py→9モジュール+365行ファサード / routers/company.py→routers/company/(10)。**パッチ互換の核心**: パッケージ __init__ が全サブモジュールに call-time プロキシ install (serving_repository._install_proxy パターン、_PROXY_TARGET_NAMES に対象関数列挙) → monkeypatch.setattr(pkg,name) が全サブモジュールに届く。横断参照は `from ... import pkg as _pkg` + `_pkg.<name>` 属性参照。データ属性パッチ(DATASET_PROBES/AUDIT_COVERAGE_PROBES 等、プロキシ不可)はテスト宛先を repository._catalog 等サブモジュールに書換(13箇所)。旧パスは sys.modules エイリアス(serving/_decision.py 等5行) or 同名パッケージ(repository/・routers/company/ は dotted path 不変でエイリアス不要)。**OpenAPI+生成d.ts SHA256 完全一致(API 不変の決定的証明、check_decision_api_typegen)**、pytest 10,790 passed/0 failed。行数予算ゲート check_file_size_budget.py 新設(800行上限・203 baseline 凍結・縮小専用、run_check_suite=43checks)。internal_boundary の probe→serving._company violation は HEAD 既存(P2 と同じ7件、増加ゼロ)
- P3.5+: 分割後も 800超のモジュール(earnings_analysis 1,958 / routers/company __init__ 1,759 / repository/_catalog 1,294 等、budget 凍結済)の再分割 / research_repository 4,720 / endpoint_registry 3,543 分割 / 極小ルーター11本統合
- P4: Desktop 再編（api-client.ts 4,898 行ドメイン分割 + 未使用 52 メソッド削除、CompanySnapshot/Dashboard 分解、Zod はクリティカル 20-30 endpoint 限定）。P3 と別 worktree で並走可
- P5: DB 統治（foundation parity / alembic squash 検討 / run_manifest 分割 / check 統合ランナー本格化）
- P6: 負債返済（T20 1,202 件 burn-down、fact_pipeline.py 6,389 行分割、シム削除、DB テスト PR-blocking 化）

**Why:** テスト網が薄い（main.py 293 本 vs tools unit test 19 本）ため、静的ゲート + ラチェットが並列エージェント運用での唯一の安全網。
**How to apply:** 次セッションで P2 着手時はこのロードマップと両 ADR（20260611-tools-dependency-policy / 20260611-shared-package-layout）を正本として参照。ファイル移動時は pyproject per-file-ignores と check_*.py の allowlist がパスキーなので同一 PR で更新。

## 関連発見 (2026-06-12)

- **alembic は依存未宣言だった**: main 環境に手動インストールのみで uv.lock に不在 → クリーン環境で tests/db/test_alembic_chain_integrity.py が collection error → pytest 全体中断（CI が 2026-05-14 以降赤の一因）。P1 で pyproject に alembic>=1.16.0 宣言済み
- **pytest 既存失敗 31 件**（pipeline_router 13 / scenario_serving 5 / market_expectation_surface 4 / ops_command_runs 3 / hypothesis_router_thesis 2 / case_study 2 / template_codegen 1 / supply_chain_extractor 1）は HEAD ff60937f 時点から存在（クリーン HEAD で同一内訳を確認）。修復は別 issue。main 側 worktree の未コミット 52 件（テーマ分類リデザイン）が一部対処中の可能性
- run_manifest.yaml の 4 区分（disabled_tasks 等）は実装済み（L5434〜）。「未実装」という調査報告は誤り
- worktree 新規作成時は `.env`（gitignored）のコピーと `uv sync` が必要。.env が無いと DSN 系テストが別パターンで失敗し、失敗の切り分けを誤る
