---
name: project-structural-cleanup-202607
description: 大規模構造リファクタリング 2026-07-05 完了・PR #22 で main へマージ済み（a35d2d4e）。37 パネル配線も完了。残る申し送りはシム削除・parity 後分割など 5 件
metadata: 
  node_type: memory
  type: project
  originSessionId: 867257d0-6d65-48fe-89f5-4aba2f857b02
---

# 大規模構造リファクタリング（2026-07-05 完了、**PR #22 で main へマージ済み a35d2d4e**）

- ブランチ: `refactor/structural-cleanup-202607`（24 コミット、worktree Investment-refactor は削除済み）
- 方針: 保守性・重複排除 / 構造整理 / デッドコード掃除。挙動・API 契約・レスポンス不変（rust-parity 保護）。alembic revision ゼロ。
- 詳細な実施記録: `docs/worklogs/20260705-structural-cleanup.md`（main に取り込み済み）
- 最終検証: pytest 13,637 green（除外ゼロ）/ desktop typecheck・eslint・vitest 2,399・build green / 全ゲート PASS

## 主な着地
- 旧 shared.database 系 import → shared.db.*（624 ファイル）。シムは decision_api が使うため残存
- 死んだ noqa 983 件 / Desktop 旧世代 81 ファイル(-14,358行) / Python デッド 18 モジュール削除。併設テスト 22 本を中央 tests/ へ（CI 初収集）
- BFF: endpoint_registry が実配線され SSOT 化（app.py -1,187行、**endpoint 追加は decorator+EndpointSpec の 2 箇所**）。503 定型 256 → exception handler 1 本。認証は Depends 化（**テストでの認証バイパスは `routers._auth._require_*` を patch**）。business_model は `_frameworks/_catalog.py` の FRAMEWORK_CATALOG が正本（手動同期 7→2 箇所、CLAUDE.md 更新済み）
- 巨大ファイル解体: fact_pipeline 6402→2366 / eq_labeler repo 5606→4089 / BFF repository 3 本 14,820→façade+20 モジュール / 巨大テスト 2 本→26 ファイル / CompanySnapshot 2389→1444 / api-client 4542→836+12 ドメイン
- 業種パネル: 15 枚を SegmentBucketPanel 共通シェル化（DOM byte 一致検証）+ **未配線 37 枚を全配線**（availability 連動 bm-* タブ、tabId=framework_id、knip unused 110→23）
- shared/domain/ 新設（ipo_analysis/stock_stage/earnings_kpi/famous_holders、旧パスシム付き）
- 並行セッション（feat/functional-uplift-p1 → main の Phase 6 + uplift-p2）と 2 回照合マージ。相手の新機能（jsf_lending・correction_only・regulation kpi-snapshot 等）は新レイアウトへ移植済み
- 事前故障も回収: internal_boundary allowlist（probe_weekly）、run_pg_trgm_status_probe の docstring 誤検知（governance）、file-size baseline 再生成

## Phase 2（つづき、2026-07-05 完了・**PR #23 で main マージ済み**）
- decision_api を canonical パスへ移行（74 ファイル）→ **旧パスシム 9 本 + 識別テスト削除**（shared/database 系・shared/domain 系はもう存在しない。import は shared.db.* / shared.domain.* のみ）
- B9 完了: serving/_market → serving/market/ 8 分割、serving/_decision → serving/decision/ 9 分割。**serving_repository の proxy 注入機構**が新サブモジュール 17 本をカバー（monkeypatch は serving_repository.<name> か呼び出し元モジュールへ）
- FrameworkView 1,194→324 / CompanySnapshotPage 1,485→1,117（密結合コアは意図的残置）
- 台帳 B' 処遇完了: **12 枚配線**（ops-hub 各タブ・Macro・Dashboard・InstrumentMaster。SectorRRGTab は Macro の market タブとして復活、TdnetKpiGateBanner 用に tdnetKpiGateStatus client メソッド新設）+ **重複 4 枚削除**（JpxDrift/HiddenEdgeRegime/SectorMacroImpact/JpxProtectedCodes）。knip 本番 unused 23→6（残は fixtures+テスト基盤のみ）
- excluded payload の frameworks dict を FRAMEWORK_CATALOG 導出化（63→74、恒久整合）
- 検証: pytest 13,630 green / desktop 2,388 green / ゲート 8 本 PASS

## Phase 3（2026-07-09 完了）
- 4 日間未 push で main を分岐させていた consensus collector 修理コミットを PR #25 として公開（局所 main は以後 fast-forward 可能に、実際に解消済み）
- _dev/BusinessModelCatalog に 37 業種パネル登録（PR #26。汎用 makeMockIndustryFrameworks + レジストリ駆動ディスパッチ、カタログ 22→59 エントリ）
- マージ済みブランチをローカル・リモートとも掃除、worktree Investment-refactor2 削除

## 残る申し送り（1 件のみ）
1. **rust-parity 完了後**（rust_global_mode はまだ既定 off/shadow 段階）に daily_screener/repository（4,097行）・tdnet/main（3,767行）の分割。parity smoke workflow が該当パスを監視中のため据え置き
