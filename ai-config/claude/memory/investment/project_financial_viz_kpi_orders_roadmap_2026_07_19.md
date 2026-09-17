---
name: project-financial-viz-kpi-orders-roadmap-2026-07-19
description: 財務可視化+KPI/受注データ基盤ロードマップ(16PR)の進捗と、gate運用・並行セッション調停の教訓
metadata: 
  node_type: memory
  type: project
  originSessionId: cfd40bdc-1202-4b9b-aa0c-df27d13da79a
  modified: 2026-07-19T17:32:31.075Z
---

# 財務可視化 + KPI/受注データ基盤ロードマップ (2026-07-19 承認・実行中)

計画正本: C:\Users\kazum\.claude\plans\pl-bs-cf-kpi-kpi-linked-heron.md（調査サマリー・PR分解・DDL詳細込み）

## ユーザー決定
- 段階的に両方（Phase A 可視化9PR → Phase B KPI/受注基盤7PR、並行可）
- 抽出は**全自動+信頼度表示**（レビュー承認ゲートなし。confidence+出典リンク常時添付）
- 全上場銘柄対象。LLM は「XBRLタグが無い所」だけ（EDINET MD&A TextBlock表→決定的パース優先）
- 業界受注統計(B6)は採用、チャートCSVエクスポートは見送り

## 進捗
- [x] Day-0 検証: MD&A TextBlock は DB 完全格納(4,438社/11.8万文書/うち68,484文書に「受注」) → B1 は DB 直読み。tdnet_order_table_rows は 04-15 で流入停止(writer不在確定) → B3 で再配線。metric_observations は60.7万行稼働中
- [x] **A1 完了 (PR #88 merged 2026-07-19)**: WaterfallChart primitive + 営業利益増減分解ウォーターフォール（変化タブ）。8角度レビュー P0/P1=0、P2 7件修正。gate passed(base a2d6ccff/head 95f8329d)
- [x] **A2 完了 (PR #90 merged 2026-07-19)**: CFブリッジ（期首現金→営業/投資/財務→為替その他→期末現金、対象期セレクタ、四半期は前年度末アンカーの累計ブリッジ）。**既存バグ発見・修正: /financials は FY 行を fiscal_quarter="4" で返し quarterless 行なし → 旧分類で年次系列が常に空 = CF タブの通期チャートパネルが全銘柄で非表示だった**。splitFinancialRows（Q4=年次スタンドイン、明示FY優先）+ financialPeriodLabel（通期は年のみ）を charts/financial-row-split.utils に新設し CF のみ配線
- [x] **PL タブ通期チャート復活 完了 (PR #102 merged 2026-07-19, merge 7c40156c)**: CompanyPL を splitFinancialRows へ移行、PLTrendChart/MarginTrendChart/PerShareChart に mode prop + financialPeriodLabel 配線（引数は最小構造型 PeriodLabelFields に拡大）。レビューで P1/P2 各1件検出・修正:
  - **P1 guidance 意味論（重要データ仕様）**: /financials の Q4 行の guidance_* は「その終了済み FY 自身の最終予想」（実績とほぼ同値。7203 で完全一致を実測）。翌期予想は同 Q4 行の next_guidance_*（dividend なし5種）か、進行中 FY の四半期行の guidance_*。→ `charts/financial-row-split.utils` に **resolveForecastGuidanceRow**（進行中FY最新四半期 guidance_* 優先 → 最新完了FY Q4 の next_guidance_* 合成、完了FY自身の guidance_* は不使用）を新設。BFF の _build_guidance_panel_row と同じ意味論
  - **P2 配当**: dividend_per_share は DivFY（期末配当のみ）で年間合計は dividend_annual（**raw 止まり・vw_financials_unified 未公開**）。FY行の約39%で年間 DPS 過小 → PerShareChart は annual モードで配当ライン非表示。年間 DPS 表示は dividend_annual の unifier/ビュー/BFF 公開が必要（別PR候補）
  - 残課題（別PR候補）: Y軸大金額ラベル左端見切れ（チャート家族共通）、SegmentBreakdownPanel/SegmentTimeseriesPanel の旧分類（/segments のデータ形状要確認）
- [x] **A3 完了 (PR #105 merged 2026-07-19 夜, merge d2b23cf7)**: PL タブ表示モード切替（実額｜YoY%｜指数100）。新 charts/display-mode.utils（期キー照合 YoY: annual=前年/quarterly=前年同Q、スライス前全系列から base 参照。指数化=可視範囲先頭非null=100。±1000% 超 null 化）+ DisplayModeToggle + PLTrendChart/PerShareChart に displayMode/allPeriods props。guidance は実額のみ、指数はバー→ライン+100破線+右軸統合。**BFF forward-fill 値(_filled_from)は非実額モードの演算から除外**。6角度レビュー P0/P1=0・P2 14件全対応。MarginTrendChart/OrdersTrendChart は対象外（注記に明記）
- [x] **A9 完了 (PR #111 merged 2026-07-20 未明, merge 2665d3f1。#107 は force-push 不可で -v2 引き継ぎ close)**: GET /dupont-roe（financial_facts_resolved_v2 の FQ4 pivot + LAG 期中平均、reported ROE は ratio→percent、9837 で computed==reported 0.01pt 一致実証）+ 変化タブ DuPontPanel（4連ミニチャート、teaser 差し替え、研究タブリンク温存）。レビューで P1×3 修正: **①新 endpoint の契約は ReadObjectContractResponse 禁止（read-object ゼロ件ラチェット3箇所が赤化）→ wave10 専用 contract + typed_scope + scope.txt + pin 群更新が正**②**BS 整合ガード必須（screening pivot の assets≥equity×0.95。resolved_v2 は metric 独立解決なので単位混在年が実在: 9696 FY2021）**③**自己資本符号反転年は期中平均が無意味（3350 FY2021 で 891x/-4754% 無フラグ）→ 前期末≤0 は期末値フォールバック+期末≤0 判定**。研究タブ DuPontDecompositionPanel の endpoint 移行は follow-up
- [ ] **次セッションの入口: A5(KPIタブ) / A7(セグメント) から着手（並列可）** → A4 → A6 → A8。A4/A6 は CompanyPL.tsx 所有が重なるため相互に直列。各PRの詳細要点は計画正本 plans/pl-bs-cf-kpi-kpi-linked-heron.md の「A系 詳細要点」節。Phase B は B0(DDL,単独worktree,レーン外時間帯)→B2→{B1∥B3∥B5}→B4→B6
- PL タブ実画面検証スクリプトの最新版: `D:\DevTemp\kazum\claude\D--Dev-Investment\68de49ec-f3d8-40db-88ff-1f4a631e0a5a\scratchpad\ui_check_pl_annual.py`（銘柄コード引数、通期/四半期ラベル・予想バー・配当凡例を一括検証。readReady 注入 + port 1420 + focus イベント再発火のパターン込み）

## 重要な設計メモ
- WaterfallChart は汎用 primitive（start/delta/total、カテゴリ軸は maxLabels=labels.length で間引き無効、ゼロdeltaは中立色、データ変化でtooltipクリア）。A2 はこれを再利用（凡例文言が合わなければプロップ化）
- **メモリの「派生指標ビュー未配線」は stale**: mart.vw_financial_derived_metrics は /financial-derived-metrics で配線済み・増減分解パネルが消費中（project_next_session_followups_2026_07_18 の②は解消済み扱いにする）
- P2 申し送り: ホバー基盤(.fin-chart-wrap/closest)と axis フォント literal がチャート家族で重複(3-4コピー) → 家族全体の抽出は別PR。/margin-bridge と派生指標ビューの二重実装解消も別PR

## 教訓（Gate / 並行セッション運用）

**Why:** A1 の gate を4回走らせる羽目になった実測連鎖。再発防止に直結する。

**How to apply:**
- **gate を TaskStop で中断しない**: npm ci 中断で desktop/node_modules が半壊し .bin が消える（tsc/vitest not found）。復旧は `npm --prefix desktop install`
- **vite dev を TaskStop しても子プロセス(node/vite + esbuild --service)が残存**し node_modules をロック → 次の npm ci が「OSにより拒否」で失敗。Get-CimInstance Win32_Process で worktree パスを含む node/esbuild を探して Stop-Process。[[bugs]] の「serve 常駐は schtasks /End でも子python生存」と同族
- **md ファイル追加は docs/research/registry.yaml の expected_managed_markdown_count を同一PRで+1**（check_suite: docs_research_registry）。並行セッションも同時に上げるため rebase で自コミットが「already upstream」で drop されたら実カウントを再確認して積み直す（2151→…→2154 と3回競合した）
- **worklog テンプレの「Plan Delta: 」行末スペースは git diff --check で gate 赤**。起票時に落とす
- **gate 実行中(~25分)に origin/main が進むと base_unchanged=False で evidence が failed になる**（全コマンド green でも）。並行セッションのマージが頻発する時間帯はリトライ前提。exit code ではなく evidence JSON の overall_status/base_unchanged で判定
- Screening.test.tsx のエラー経路テストは gate 並列実行時にフレークすることがある（単独再実行で green 確認）
- Desktop 実画面確認の注意: アプリ設定(Runtime Root等)は localStorage=オリジン単位。vite のポートを変えると(1420→1421)未設定状態になり起動ゲートで止まる。**必ず 1420 を使う**
- Playwright での銘柄ページ検証は store 注入に **readReady: true が必須**（bffReachable/readToken/startupPhase だけではエントリーゲート hasOperationalReadConnection が解除されない）。スクリプト正本: セッション scratchpad の ui_check_cf_waterfall.py 型
- CF 検証銘柄: 7203 は営業CF未取得（データソースなし）。CF一式が揃うのは 2303/2593/2134 等（mart.vw_financials_unified で fiscal_quarter=4 かつ CF 3本+現金 non-null の銘柄を SELECT で確認してから選ぶ）
- **pr-ready-gate は claim 方式に移行済み (07-19 PR #84)**: 生 `git worktree add` した既存 worktree は `sync_repo.py claim-worktree --owner claude` で claim ID を取得 → `merge-pr --claim-id` 必須 → 成功後は cleanup_deferred（自動削除されない）→ `cleanup --apply --worktree <path> --claim-id` で明示片付け
- **base 前進 race は連発する**: PL 小PRで gate 6回（sector A6〜A10 + #101 が各 gate 実行中に着地）。全て自 diff 起因の赤ゼロ。対処はリトライのみだが、`gh pr list --state open` で残りの競合 PR 数を見てから再走するとよい。registry 件数は毎 rebase で +1 追随（peer も worklog を足すため）
- **force push deny の復旧実証**: rebase 済み branch の PR 更新は不可 → 同一 head で新ブランチ `-v2` を push → 新 PR 作成 → 旧 PR close → merge-pr は新 PR 番号で成功
- **pytest pr lane のインフラフレーク**: peer gate と同時実行時、テスト用一時 PostgreSQL が「database system is shutting down」で setup ERROR 連発（所要 2381s vs 通常 771s）。自 diff 無関係なら単独再走で green
- **新 endpoint 追加の必須5点セット (07-19 A9 で実測)**: ①endpoint_registry.py に EndpointSpec（**専用 wave10 contract 名 + typed_scope=True。ReadObjectContractResponse はラチェット違反**）②response_models.py の WAVE10_DOMAIN_READ_CONTRACT_MODEL_NAMES に名前追加③scripts/decision_api_typed_response_scope.txt に1行④pin 更新: test_decision_api_response_models.py の area_counts/total と test_decision_api_endpoint_contracts.py の typed count⑤`npm --prefix desktop run api:typegen` + `scripts/generate_current_docs_snapshot.py --write`。忘れは check_suite (current_docs_snapshot) と契約テストが検出
- **file_size_budget は shrink-only ratchet**: endpoint_registry.py / response_models.py / test_company.py 等の凍結ファイルは1行も増やせない。新規テストは新ファイルへ、registry 追記はコンパクト形式（2引数/行）+ 隣接エントリ圧縮で相殺
- **generated-repository-snapshot.json は worktree_dirty を焼き込む**: rebase 競合解決の最中に --write すると true が入り、クリーンな gate で恒久不一致になる。**必ず全コミット後のクリーンツリーで再生成**（registry 先コミット→再生成→スナップショットコミットの順）
- **worktree での pytest は DOTENV_PATH=D:/Dev/Investment/.env 必須**（conftest の ops.agent_actions seed が get_connection を要求）
- **gate 実行中に自分でも重い処理（フルスイート等）を並行させない**: A3 初回 gate の npm test フレークは自前の A9 フルスイート並行実行との資源競合が濃厚
- **未マージ endpoint の実画面 QA**: 稼働中 BFF は旧コードのため、実データを serving 直叩きで JSON 捕捉 → Playwright route interception で該当ルートだけ差し替えるのが正（A9 で実証）
