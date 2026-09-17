thread_id: 01a0438d-bfc2-7bb3-9340-2d996df99816
updated_at: 2026-09-05T11:35:42+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\08\27\rollout-2026-08-27T23-09-18-01a0438d-bfc2-7bb3-9340-2d996df99816.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# マクロ画面を裁量投資向けに再設計し、統計履歴を公式データで補完したが未完了

Rollout context: `D:\Dev\Investment`。ユーザーは、マクロ画面が意味不明な数値・専門語・価格チャートの羅列になっており、裁量投資の意思決定、業種・企業・決算KPIへの接続に役立たないと強く指摘した。実装を急がず、現行UI・BFF契約・投資フレームワーク・公式データ経路を照合して再設計する方針を取った。

## Task 1: マクロ画面の目的・情報設計の再定義

Outcome: partial

Preference signals:
- ユーザーは「その機能一つ一つに意味を持たせてほしい」「どういう意図があって、どういう解釈ができて、裁量投資の意思決定を補佐するもの」と要求した -> 各表示項目に目的、解釈、投資上の使い道、次に見る業種・企業・決算を明示し、意味のない装飾的な指標は表示しない。
- ユーザーは、価格推移そのものはTradingView等で見るため「このアプリのグラフはロウソク足で表示してほしい」と述べた -> 単純な線グラフや現在値だけで既存チャートを代替せず、価格を扱う場合は時間軸・軸・変動幅・イベントとの対応が読める形にする。
- ユーザーは統計について、鉱工業生産指数やTSMC月次売上のような具体的な実数値を「ヒストリカルに追える」「項目ごとにグラフ化」したいと述べた -> 指標ごとに水準、変化率、実日付、単位、欠測、出典、鮮度を表示する。
- 過去の指示でも「何を表示しているのかを明確に」「ブレッドスのようなよくわからない単語は使わない」と求めている -> 専門用語だけのラベルを避け、平易な日本語の定義と判断上の意味を併記する。

Key steps:
- `AGENTS.md`、`docs/OWNER_INTENT.md`、Matt Pocock Skills、UI/UX・Playwright方針を確認。
- 現行 `/macro` が「環境・レジーム／指数・市場ストレス／テーマ・季節性／統計」の4分類に、価格、スコア、専門語、ニュース分類、統計一覧を混在させていることを確認。
- `desktop/src/pages/Macro.tsx`、`EnvironmentTab.tsx`、`StatisticsTab.tsx`、`MarketBreadthTab.tsx`、投資フレームワークのマクロレジーム・セクターRS資料を調査。
- 再設計の中心を、単なる4タブではなく `観測データ → 変化の意味 → 影響を受ける業種・企業 → 次に確認する決算/KPI` を返す「マクロ判断文脈」モジュールと定義した。ただしこれは設計方針であり、実装完了ではない。
- Matt Pocock Skills の Design It Twice に従い、最小インターフェース、探索重視、日常利用重視の複数設計案をサブエージェントに依頼したが、最終案の統合・実装は完了していない。

Failures and how to do differently:
- 現行UIには実データや部品が存在しても、各指標の目的・因果仮説・関連企業・次アクションを共通形式で返すインターフェースがない。今後は見た目の整理だけでなく、指標の意味と下流接続を契約として先に定義する。
- 複雑なPowerShellコマンドはハーネスに拒否され、「Use the harness PowerShell directly so encoded-shell guardrails apply」となった。コマンドを分割し、引用符を単純化する。
- 既存のPlaywrightテストを実行したところ、`tests/visual/macro-statistics-inbox.spec.ts` の通常状態テストが30秒でタイムアウトし、期待していた `/api/v1/market/macro-statistics` のHTTP 200レスポンスを捕捉できなかった。スクリーンショットは取得されたが、この検証は成功扱いにしない。

Reusable knowledge:
- DesktopはFastAPI BFF `127.0.0.1:8010` 経由のみ。DB、外部API、ファイルストレージへ直接接続しない。
- `docs/OWNER_INTENT.md` とODR-0012は、マクロ統計を平易な参考情報として決算まで連続表示し、スコアや自動判断には接続しない方針を定めている。
- IIPはシリコンサイクル分析の文脈で使うが、単独の売買サイン・スコア・閾値にはしない。想定フローは e-Stat/業界統計 → 33業種 → 企業 → 決算。
- 既存 `driver_evidence` には source、series key、value/change、frequency、freshness、lag、correlation、hit rate、sample count、contribution などの下流接続に有用な情報がある。

## Task 2: 機械受注・IIPの履歴データ回復と実BFF/実画面確認

Outcome: partial

Key steps:
- 別worktree `D:\Dev\Investment-macro-statistics-data-recovery-20260905` で公式資料とローカルDB/BFFを照合。
- 機械受注は内閣府公式Excel `2606chouki-1.xlsx` とe-Stat表0003355222を照合し、2005-04〜2026-06の255か月、欠測0・重複0・数値不一致0を確認。既存26か月に229か月追加し、既存値の改定はなかった。
- IIPはe-Stat公式Excel `statInfId=000040172364` を取得。5群×4活動×103か月の範囲を確認し、非速報の2018-01〜2026-06の2040値を正本照合。既存値は全一致で、4〜6月の60件を追加した。
- IIP書込前のDecimal/float比較assert初回失敗時は全rollbackし、文字列経由Decimalで同値比較する形に直して再実行。既存値を書き換えずcommitした。
- localhost:8010の実BFFでHTTP 200を確認。機械受注255観測、生産用機械の生産・出荷・在庫・在庫率は各102観測で、最新観測日は2026-06-01。
- 実アプリで、IIPの生産用機械について2026-06-01、生産137.4、出荷136.3、単位2020年=100、実数値表、出所リンクを確認した。

Failures and how to do differently:
- 最初の検証スクリプトは `observations` が配列ではなく辞書形式だったため、`AttributeError: 'str' object has no attribute 'get'` で失敗。実データ形状を確認して、`p['observations'].values()` を展開してから検証した。
- 機械受注は履歴がBFFに存在しても、一覧側の「今日から10年以内に120か月要求」という表示条件と公表ラグが両立せず一覧に出ない。データを改変して条件を満たしたことにせず、一覧条件と詳細履歴契約を分離して修正する必要がある。
- IIPの7月速報16実数と4未掲載セル、公表日表示、自動更新経路は未対応。現在のBFFはIIP公表日をNone固定にし、観測月初から75日で古さ判定するため、公表間隔を正確に反映しない。
- 定期IIP APIは3月までしか返さない取得先のままで、今回の公式Excel回復は一回限り。Schedulerや恒久的な取得修正は実施していない。
- 製品コード変更、共有/本番DB変更、DDL、外部配布、最終Ready gateは未実施。全統計整備や全面刷新の完了は主張しない。

References:
- `D:\Dev\Investment\docs\OWNER_INTENT.md`
- `D:\Dev\Investment\docs\decisions\20260812-iip-silicon-cycle-purpose.md`
- `D:\Dev\Investment\docs\decisions\20260813-macro-statistics-continuity-reference-only.md`
- `desktop/src/pages/Macro.tsx`
- `desktop/src/components/market/EnvironmentTab.tsx`
- `desktop/src/components/market/StatisticsTab.tsx`
- `tools/api/decision_api/serving/_iip.py`
- `tools/api/decision_api/serving/market/_macro_statistics.py`
- `tools/market_data/estat_tracker/README.md`
- `投資フレームワーク/09_環境認識/01_マクロレジーム判定_運用SOP.md`
- `投資フレームワーク/09_環境認識/02_セクター相対強度.md`
- `desktop/tests/visual/macro-statistics-inbox.spec.ts`
- `docs/worklogs/20260905-macro-statistics-data-recovery.md`
- 検証結果: `machine-all counts {'estat.machine.orders': 255}`、最新値 `2026-06-01 = 10557.617610599998`; IIP生産用機械最新値 `production=137.4`, `shipment=136.3`, `inventory=98.2`, `inventory_ratio=79.1`。
- Playwright失敗: `Test timeout of 30000ms exceeded`、`page.waitForResponse` が `/api/v1/market/macro-statistics` のHTTP 200を捕捉できず。
