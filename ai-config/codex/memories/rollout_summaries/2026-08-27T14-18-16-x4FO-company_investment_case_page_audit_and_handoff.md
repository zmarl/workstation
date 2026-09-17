thread_id: 01a04395-f5cd-7ce2-b1d1-a35ec6a2ce38
updated_at: 2026-08-28T01:28:38+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\08\27\rollout-2026-08-27T23-18-16-01a04395-f5cd-7ce2-b1d1-a35ec6a2ce38.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# 銘柄ページを投資ケース中心へ再設計するための調査と引き継ぎ文書作成

Rollout context: `D:\Dev\Investment` を対象に、投資フレームワークと現行Desktop/BFF実装を照合し、情報過多・ページ分散・用途不明データを改善する方針を整理した。最終的に、次セッションが実装を再開できる自己完結した引き継ぎ文書を専用worktreeへ追加した。

## Task 1: 投資フレームワークと銘柄ページの整合監査

Outcome: partial

Preference signals:
- ユーザーは「何のためにその投資、その情報を使うかがわかる」状態と、「余分なスクロールや視点移動を減らし、デザイン的にわかりやすく」することを要求した。今後はrawデータ量ではなく、判断目的・根拠・次アクションの明確さを優先する。
- ユーザーは機能を一つずつ機関投資家のような目線で確認し、投資手法との接続を改善することを求めた。大規模UI変更では、先に現状・目的・情報の役割・実装境界を整理してから編集する。

Key steps:
- `docs/OWNER_INTENT.md`、`docs/design/裁量投資判断OS_全体設計.md`、投資フレームワークの正本、現行routes、workspace registry、company aggregateをread-onlyで調査した。
- 銘柄単位の「銘柄ケース」と、Ready以降の1トランシェ単位の「売買仮説」を分離した。売買仮説は`strategy_primary`を1つ、`factor_path_primary`（E/M/F）を1つ固定し、変更時は別トランシェとする。
- 主画面に残す情報を「仮説を支持・反証する」「判断を止める」「次に確認する」「U/D・否定条件・T-stop・サイズに影響する」「市場期待との差を説明する」に限定した。

Failures and how to do differently:
- 現行の投資ケース入口は高密度化されているが、財務・業績・事業・評価・テクニカル・需給の詳細画面はまだ十分に統合されていない。入口改善だけで銘柄ページ全体の完成と判断しない。
- `投資フレームワーク/06_インプット設計/02_取得ルーチン/スクリーニング_ルーチン.md` に旧ラベル`B / D / E / S`が残り、正本・production contractの22戦略（F.1〜F.7、T.1〜T.4、S.1〜S.7、E.1〜E.4）と不整合。画面へ旧語彙を流し込まず、文書修正は別途扱う。

Reusable knowledge:
- 製品の本質はデータカタログではなく、`何が起きたか → なぜ起きたか → 企業/業種/PFへの影響 → 仮説との差 → 判断 → 次の監視 → 結果/学習`を証拠付きで閉じる意思決定支援。
- 主画面はファンダメンタルズを背骨にし、主因子に応じて優先順位を変える。EはKPI・決算・利益率・CF、Mは市場期待・倍率・資本効率・カタリスト、Fは価格・出来高・需給・イベントを優先する。
- UIはDesktop→FastAPI BFFのみ。DB・外部APIへの直接接続、発注、通知、Scheduler、DB/Alembic変更は今回の銘柄ページ作業の境界外。
- 既存`read_aggregates.py`のcompany snapshot aggregate、`screening_catalog.py`、`framework_contract.py`を再利用し、Desktopが多数の個別endpointやMarkdown正本を直接知る構造を避ける。

References:
- `docs/OWNER_INTENT.md`
- `docs/design/裁量投資判断OS_全体設計.md`
- `投資フレームワーク/00_INDEX/意思決定プロセス.md`
- `投資フレームワーク/02_用語定義/仮説設計.md`
- `投資フレームワーク/02_用語定義/市場期待_織り込み.md`
- `投資フレームワーク/02_用語定義/業績倍率需給_E_M_F.md`
- `投資フレームワーク/02_用語定義/戦略定義_マスター表.md`
- `tools/api/decision_api/read_aggregates.py`
- `tools/api/decision_api/screening_catalog.py`
- `tools/decision_support/daily_screener/framework_contract.py`

## Task 2: 次セッション用の銘柄ページ再設計ブリーフ作成

Outcome: success

Key steps:
- 専用worktree `D:\Dev\Investment-company-investment-case-dense-ui` に `docs/handoff/20260828-company-investment-decision-page-redesign.md` を追加した。
- 文書に、現状の訂正、用語モデル、代表ケース、1366x768/375x812の情報設計、詳細ナビゲーション、BFF投影案、受入条件、作業順、再開時の解釈エコー、変更しない範囲を記録した。
- 文書は215行・604語で、構造確認済み。専用worktreeはこの未commit文書のみ変更、`D:\Dev\Investment`のmainはclean。

Failures and how to do differently:
- exact-head Ready gateは未完了。`python-fast`の300秒制限に対しbroad実行が約646秒でtimeoutしたため、gate green、publish、mergeを主張しない。別所有のgate修復後にlatest mainへrebaseして再実行する。
- 実データ画面helperはcompany snapshot-core等が200で表示できた一方、対象外の既存`briefing/daily`と`decision/priority-queue`の503でexit 1となる。企業ページ証拠と背景障害を分離して評価する。

Reusable knowledge:
- 引き継ぎ文書は正本ではなくDraft。次セッション開始時にHEAD、正本文書、worktree、worklog、ODR、所有状態を再確認し、セクション10の解釈エコーを提示して承認を得る。
- 推奨UI構成は、市場前提→自分の見立て→ミスプライス差分→支持/反証/欠損→ファンダメンタルズ→外部環境/タイミング→次の判断。詳細は「事業・KPI」「決算・財務」「評価・資本効率」「外部環境」「株価・需給」「証拠・履歴」の目的付き導線で開く。

References:
- `D:\Dev\Investment-company-investment-case-dense-ui\docs\handoff\20260828-company-investment-decision-page-redesign.md`
- `D:\Dev\Investment-company-investment-case-dense-ui\docs\worklogs\20260827-company-investment-case-dense-ui.md`
- `D:\Dev\Investment-company-investment-case-dense-ui\docs\decisions\20260827-company-investment-case-dense-workspace.md`
- Worktree branch: `codex/company-investment-case-dense-ui`
- Claim ID: `39e61164ed5b7072a4b7ef83d14ed18b`
