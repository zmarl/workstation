---
name: project-desktop-design-reform-2026-07-19
description: Desktop デザイン全体改善プログラム。Phase A=セクター司令塔 /sector 完了 (07-19、PR 15本・worktree 片付け済)。次は Phase B スクリーニング（着手前にユーザー確認）
metadata: 
  node_type: memory
  type: project
  originSessionId: 60cac97c-1a3b-4147-902c-8c047702f4fb
  modified: 2026-07-19T13:12:50.892Z
---

# Desktop デザイン全体改善プログラム (2026-07-19 開始)

正本プラン: `C:\Users\kazum\.claude\plans\1-stateful-quokka.md`（ユーザー承認済み・詳細は全部そこにある）。
ユーザー確定方針: 優先=①セクター②スクリーニング③個別銘柄 / 縦スクロール1本型 / 段階的リリース /
**ダッシュボード（pages/today/・components/dashboard/）は不可触のゴールドスタンダード**。

## フェーズ

- **A（実行中）**: `/sector` セクター司令塔ページ新設 + 共有プリミティブ（HoverCard/DataBarCell/HeatMatrix/ColorScaleLegend/RRGScatter/SectionJumpNav/ViewportSection）+ Panel Standard を desktop/AGENTS.md へ追記。PR スライス A0〜A11（プラン参照）。サイドバー差し替えは最後の PR。
- B=スクリーニング、C=個別銘柄+決算正本化、D=市況統合(optional)、E=/review 正本化、F=ops/参照統合(optional)。D〜F は実施前に都度ユーザー確認。

## 進捗

- **A0 完了 (07-19, PR #86)**: probe スクリプト `scripts/dev/probe_sector_endpoints.py` + fixture 21本
  `desktop/src/lib/api/__fixtures__/sector/`。副産物: scheduled_tasks.lock 誤追跡の根治 (PR #87,
  [[bugs-scheduled-tasks-lock-dirty-main]])
- **A1 完了 (07-19, PR #89)**: 共有プリミティブ5種 — components/shared/{HoverCard, DataBarCell,
  ColorScaleLegend, SectionJumpNav}.tsx + layout/primitives/ViewportSection.tsx + テスト24件 +
  DesignSystem カタログ「セクター再設計プリミティブ」節。design-system visual baseline 3枚は
  **main 時点で既存赤**（サイドバー registry 変遷に未追随）だったため更新済み。
  DataBarCell はマトリクス短期Pt バーの抽出昇格（bg-semantic-up/down・幅% inline style 前例）
- **A2 完了 (PR #91)**: RRGScatter + HeatMatrix (components/charts/)。**A3 完了 (PR #92)**: api-client 5本
  （sectorAnalyticsMatrixDetail 他、実在場所は lib/api/simulation.ts）+ sector-fixtures.test.ts ドリフトガード。
  **発見: 共有 DecisionGate 型の required_inputs/usable_inputs は BFF が返さない既存型嘘**（後続 PR で optional 化推奨）。
  **A4 完了 (PR #93)**: DataTable 行展開 opt-in（renderExpandedRow 等 5 props、オフ時 DOM 完全不変を全スイートで実証）
- **A5 実装済・gate 中**: /sector 未掲載ルート + SectorSummaryStrip（強弱 TOP3 は sectorMacroImpact 起点=
  マトリクス短期Pt と同一ソース・同一 query key。specific_drivers 合算は不整合として却下済み）
- **A6 完了 (PR #95)**: マトリクス v2 — title= 全廃（grep+実画面で実測 0）・DataBarCell/HoverCard 化・
  既定ソート短期Pt desc・列 14→12。**既知問題申し送り: /macro?view=sector はウィンドウが 1280px で 278px
  横パン**（表は内部スクロール正常・sticky 無効化でも不変・screening では起きず=このビュー固有の既存挙動が
  濃厚。A10 で根治）。FundFlowCell 空ラベルは whitespace-nowrap 必須（縦潰れ）
- **A8 実装済・gate 中**: ②フロー/回転（HeatMap onSelect + RRGScatter 実データ + フロー top/bottom8）+
  ?sector= 導入。ヒートマップ key はマトリクスと共有（["sector-performance"]）
- **A9 部品完了・配線待ち**: SectorValuation（33s API対応: ViewportSection lazy + daily stale + 30秒注記、
  PER/PBR/EV は色反転で緑=割安）+ SectorRelatedNews（matched_codes∩sector instruments）。
  sector-medians の行キーは業種名（コード無し）→ページ側で name→code 対応要
- **A7 完了 (PR #98)**: 4タブドロワー（概況/サブセクター/銘柄/ピア）。行クリック=その場展開・遷移廃止。
  展開は industry_code キーで sort/filter 耐性。銘柄タブはページネーション（仮想化は DataTable tbody 所有と衝突で見送り）
- **A8 完了 (PR #97)**: ②フロー/回転 + ?sector= 導入。inline QueryClient は ratchet 違反 → renderWithProviders 必須
- **A9 完了 (PR #99)**: ⑤⑥ + 全結線。**実 BFF 全面実画面 QA 通過**（ドロワーその場展開・URL 同期実証、証跡 scratchpad/a9-0*.png）。
  ページ機能完成（未掲載ルートのまま）
- **A10 完了 (PR #100)**: サイドバー「セクター分析」→ /sector 切替（同ラベル同位置）。旧経路 11 本 redirect。
  /fundamentals は「比較・開示」へ改称・サイドバー除外（残タブ直接アクセス可、Phase C で /earnings 正本化）
- **A11 完了 (PR #104) = Phase A 全完了**: 退役掃除（Macro セクター撤去・CyclicalClusterMacroPanel 削除・
  FUND/リンク直行化）+ **横パン根治**（真因 sr-only、[[bugs-sronly-absolute-page-pan]]）。
  削除系 PR の追随台帳は **3 系統**（decision-surface 分類 / 時間カバレッジ known_unmapped pinned pytest /
  scripts/desktop_test_query_client_baseline.txt）
- **セッション総括: マージ 15 本（#86,87,89,91-95,97-101,103,104）、worktree 全片付け済み（claim 式 cleanup --apply）**
- **UX フィードバック第1弾完了 (PR #103)**: ヒートマップ面積=時価総額（BFF: get_sector_performance に
  total_market_cap[百万円]+coverage、mart.vw_daily_valuation 集計・DDL なし・[[reference-sector-market-cap-source]]）
  + 全幅2段組 + キャプション常設 / RRG 点ラベル+「この図の見方」+軌跡は選択時のみ（[[feedback-sector-page-visualization]]）。
  gatefix も完了 (PR #101)
- 配布: dev ビルドで検証済み。Tauri 配布ビルドはユーザー承認待ち（未実施）
- 既知のデータ側課題: 資金フロー方向が空（外国人フロー実測元停止 — マトリクス警告バナーにも表示。UI は正常な空状態）。
  screening 系 33 秒レイテンシの BFF 最適化も未着手（Phase B 前に再評価）
- QA 知見: 実画面アサーションはニュースティッカーの実見出しと衝突し得る→セクションスコープ必須。ドロワータブは role=tab
- worktree 後片付け: sector-a0/a1/lockfix は旧方式で削除済み。a2〜a10/gatefix は cleanup_deferred（claim ID 付き
  cleanup --apply が必要。claim ID は各 merge-pr 実行ログ参照）
- **新運用 (07-19夕方〜)**: worktree は `sync_repo.py create-worktree/claim-worktree` で claim 必須、
  merge-pr に --claim-id 必須、merge 後は cleanup_deferred（削除は claim ID 付き cleanup --apply のみ）
- 運用教訓: ⓪**新規 Page/Panel/Tab/Section/Dashboard 名の export 追加は
  `shared/catalogs/decision_surface_candidate_classifications.yaml` の追随必須**（record + wrapper review group +
  candidate_count + fingerprint=sha256(sorted paths joined LF) + pinned テスト側の count/fingerprint/ambiguous 数）。
  gate の decision_indicator_temporal_coverage と pytest 両方で検出される（A5 で発覚、A10 でも再発予定）
  ①gate 中に並行セッションが main を進めると base_unchanged=false → rebase+registry 追随+再 gate が定型
  ②**Playwright visual の port 1420 固定 + reuseExistingServer は並行セッションの dev サーバーを掴んで
  別ツリーのコードを検証する事故になる**（/sector 404 で発覚）。隔離ポートは BFF CORS 外 → fixture 注入 QA で回避。
  恒久対策（PORT 環境変数化）は未着手の申し送り ③実画面 QA の起動ゲート越えは decision-lists-smoke 方式
  （__APP_STORE__ setState + route interception）が正

## A0 実測の重要知見（Phase A 設計に効く）

- 未使用エンドポイント全部生存・実データあり（analytics-matrix detail / sub-sectors / instruments /
  peer-groups / industry-ranking / sector-medians）→ Phase A 続行確定
- **screening 系は毎回 ~33 秒**（sectors/sector-medians/industry-ranking、再現性あり）。market 系は <2.3s。
  → ⑤バリュエーションとドロワーランキングは遅延ロード+長 staleTime 必須。BFF 最適化は後続課題（A9 前に再評価）
- **peer-groups は 24/33 業種のみ非空** → ピアグループタブは空状態必須
- `/market/sectors` は業種名キーで**コード無し**（avg_return 等は文字列型）。名前→コードは analytics-matrix の
  sector_name→sector_code join で解決
- matrix item の `earnings_momentum` は **null あり**。sector-medians の medians 内も null 多数
- iip-sector-cycle / cyclical-clusters は items 空 → A11 で退役確定。event-impact/sector-heatmap は
  実データ 170KB あり → 退役せず将来採用候補（query key 温存）
- 代表業種 fixture: largest=9050 / smallest=5150 / warned=0050（data_warnings 非空）

## 運用メモ

- worktree 命名: D:/Dev/Investment-sector-a<N>。本プログラムの専有ファイル: components/sector-analysis/、
  新規 pages/sector/、新規 shared プリミティブ。共有ファイル（api/market.ts・workspace-registry.ts・
  DesignSystem.tsx）は additive 最小 diff・即日マージ
- probe 再実行: `DOTENV_PATH=D:/Dev/Investment/.env uv run python scripts/dev/probe_sector_endpoints.py`
  （worktree には .env が無いため DOTENV_PATH 必須）

## 次セッション再開手順（ユーザーが「続き」と言ったらここから）

**次 = Phase B スクリーニング強化の計画**。正本プラン `C:\Users\kazum\.claude\plans\1-stateful-quokka.md` の
「後続フェーズ概要」を読み、Phase A と同じ流れ（read-only 監査 → AskUserQuestion で要件確認 → 設計 → PR 分割実行）で進める。

### Phase B の既知の材料（プラン + Phase A で判明した分）
- industryLeague（/screening?mode=industryLeague, IndustryLeagueTable.tsx）の再定義: 「指標スクリーニング」として
  整理 or /api/v1/screening/industry-ranking を使う本物の業種ランキング化。セクターページのドロワー銘柄タブが
  既に industry-ranking を消費中（重複回避の設計判断が必要）
- DataTable 仮想化 opt-in 昇格（use-virtualized-rows は既存 8 箇所で直接利用、DataTable 統合は tbody 所有と衝突
  — A7 で見送った経緯あり。設計から）
- 共有 FilterToolbar 新設（各パネルのフィルタ再実装を統一）
- 未使用 screening エンドポイント検討: /screening/history（時間旅行 diff）・/screening/market-expectation・
  /screening/iip-tailwind（いずれも client 未接続）
- **screening 系 33 秒レイテンシの BFF 最適化**（Phase B 前に要再評価。sector-medians/industry-ranking/sectors 全て）
- スクリーニング→セクター文脈→銘柄の導線接続（/sector ドロワーフッタ「この業種でスクリーニング」は配線済み、逆方向が未）

### Phase A からの申し送り（Phase B と独立に拾える）
- 配布用 Tauri ビルド未実施（ユーザー承認待ち。dev ビルドは反映済み）
- データ側課題: 外国人フロー実測元停止（資金フロー方向が空）/ 決算モメンタム 0/33 — UI でなくデータ復旧トラック
- RRG 中央密集帯のラベル重なりが軽微に残存（次回フィードバックで要否判断）
- series_meta.freshness の型宣言 + ドロワー KPI 鮮度表示（A7 見送り）
- news エンドポイントへの sector= パラメタ追加（現状クライアント側交差。lossy なら BFF 化）

### 運用の型（Phase A で確立、そのまま再利用）
- worktree: `sync_repo.py create-worktree --task <t> --branch <b> --owner claude` → merge は
  `merge-pr --claim-id` → `cleanup --apply --claim-id`。gate 中に main が動いたら rebase+registry 追随+再 gate
- md 追加 = docs/research/registry.yaml 件数追随 / 新 Page・Panel 系 export = decision-surface 台帳 2 系統 +
  test query-client baseline の 3 台帳追随（削除も同様）
- 実装は persistent サブエージェント 1 体への SendMessage 逐次委任が効率的だった（規約学習の再利用）。
  実画面 QA は __APP_STORE__ setState 起動ゲート越え + 実 BFF（port 1420 空き確認必須）or fixture 注入
- 検証教訓: 新規 tsx テストは renderWithProviders 必須（inline QueryClient は ratchet 違反）/
  overflow スクロール枠には relative 併記 / 可視化には意味キャプション+「この図の見方」必須
- 関連: [[project-ui-ux-reform-202607]] [[project-design-reform-phase1]] [[feedback-sector-page-visualization]]
  [[bugs-sronly-absolute-page-pan]] [[reference-sector-market-cap-source]]
